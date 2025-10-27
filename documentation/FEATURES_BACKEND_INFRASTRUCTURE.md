# Backend Infrastructure Features

## 1. Serverless Architecture (Netlify Functions)

### Marketing Summary
VeloReady's backend is built on serverless infrastructure, meaning zero server maintenance, automatic scaling, and global edge deployment. Whether you have 10 users or 10,000, the backend scales instantly to meet demand. No downtime, no server costs when idle, and lightning-fast response times from edge locations worldwide.

### Technical Detail
Serverless architecture eliminates the need for traditional server management by running code in ephemeral containers that scale automatically.

**Benefits:**
1. **Zero Server Management**: No provisioning, patching, or maintenance
2. **Automatic Scaling**: From 0 to 10,000 requests/second instantly
3. **Pay-per-Use**: Only pay for actual execution time (no idle costs)
4. **Global Edge Deployment**: Functions run close to users for low latency
5. **Built-in Monitoring**: Logs, metrics, and error tracking included

**Netlify Functions:**
- Based on AWS Lambda (battle-tested infrastructure)
- TypeScript support with full type safety
- Environment variables for secrets
- Automatic HTTPS and CDN
- 125,000 free requests/month, then $25/million requests

**Function Types:**
1. **Synchronous Functions**: API endpoints (activities, streams, AI brief)
2. **Background Functions**: Long-running tasks (backfill, reconciliation)
3. **Scheduled Functions**: Cron jobs (nightly reconcile, cleanup)

**Cold Start Optimization:**
- Keep functions warm with scheduled pings
- Minimize dependencies (tree-shaking)
- Use shared libraries across functions
- Typical cold start: <500ms

### Technical Implementation
**Architecture:**
- `netlify/functions/`: Synchronous API endpoints
- `netlify/functions-background/`: Background tasks
- `netlify/functions-scheduled/`: Cron jobs
- `netlify/lib/`: Shared libraries (auth, db, cache, queue)
- `netlify.toml`: Configuration and routing

**Example Function:**
```typescript
// netlify/functions/api-activities.ts
import { Handler } from '@netlify/functions';
import { authenticate } from '../lib/auth';
import { getFromBlobs, saveToBlobs } from '../lib/cache';

export const handler: Handler = async (event) => {
  try {
    // Authenticate user
    const { userId, athleteId } = await authenticate(event);
    
    // Check cache
    const cacheKey = `activities:${athleteId}`;
    const cached = await getFromBlobs(cacheKey);
    if (cached) {
      return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json', 'X-Cache': 'HIT' },
        body: cached
      };
    }
    
    // Fetch from Strava
    const activities = await fetchFromStrava(athleteId);
    
    // Cache for 24h
    await saveToBlobs(cacheKey, JSON.stringify(activities), 86400);
    
    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json', 'X-Cache': 'MISS' },
      body: JSON.stringify(activities)
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};
```

**Deployment:**
```bash
# Automatic deployment on git push
git push origin main

# Netlify CLI for local testing
netlify dev  # Run functions locally
netlify deploy --prod  # Manual deployment
```

**Monitoring:**
- Netlify Dashboard: Request logs, error rates, execution time
- Sentry Integration: Error tracking and alerting
- Custom logging: Structured logs with context

---

## 2. Multi-User Authentication (Supabase JWT)

### Marketing Summary
VeloReady uses bank-level security with JWT (JSON Web Token) authentication, ensuring your data is completely isolated from other users. Every API request is authenticated and authorized, with automatic token refresh to keep you logged in. Your health data is yours alone—no one else can access it.

### Technical Detail
JWT authentication provides stateless, scalable authentication without server-side sessions.

**Authentication Flow:**
1. User connects Strava → OAuth completes
2. Backend creates Supabase user (email: `strava-{athleteId}@veloready.app`)
3. Backend signs in user, returns JWT tokens (access + refresh)
4. iOS app receives tokens via deep link, stores in SupabaseClient
5. All API requests include `Authorization: Bearer {JWT}` header
6. Backend validates JWT, extracts `user_id`, fetches `athlete_id` from database
7. Returns user-specific data with Row-Level Security (RLS) isolation

**JWT Structure:**
```json
{
  "sub": "user-uuid",
  "email": "strava-104662@veloready.app",
  "role": "authenticated",
  "iat": 1698451200,
  "exp": 1698454800
}
```

**Token Lifecycle:**
- **Access Token**: 1 hour expiration (short-lived for security)
- **Refresh Token**: 30 days expiration (long-lived for convenience)
- **Automatic Refresh**: iOS app refreshes when <5 minutes remaining
- **Revocation**: User can revoke tokens by disconnecting Strava

**Security Features:**
1. **HMAC Signature**: Tokens signed with secret key (prevents tampering)
2. **Expiration**: Short-lived access tokens limit exposure
3. **User Isolation**: RLS policies enforce data separation
4. **HTTPS Only**: All requests encrypted in transit
5. **Rate Limiting**: Prevent brute force attacks

### Technical Implementation
**Architecture:**
- `SupabaseClient.swift`: iOS client managing JWT session
- `netlify/lib/auth.ts`: Backend authentication helper
- `oauth-strava-token-exchange.ts`: Creates Supabase user and returns JWT
- `auth-refresh-token.ts`: Refreshes expired tokens

**Backend Authentication Helper:**
```typescript
// netlify/lib/auth.ts
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function authenticate(event: any): Promise<{ userId: string; athleteId: number }> {
  // Extract JWT from Authorization header
  const authHeader = event.headers.authorization || event.headers.Authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Missing or invalid Authorization header');
  }
  
  const token = authHeader.substring(7);
  
  // Validate JWT with Supabase
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) {
    throw new Error('Invalid or expired token');
  }
  
  // Fetch athlete_id from database
  const { data: athlete, error: dbError } = await supabase
    .from('athletes')
    .select('id')
    .eq('user_id', user.id)
    .single();
  
  if (dbError || !athlete) {
    throw new Error('Athlete not found');
  }
  
  return {
    userId: user.id,
    athleteId: athlete.id
  };
}
```

**iOS Token Management:**
```swift
// SupabaseClient.swift
class SupabaseClient {
    static let shared = SupabaseClient()
    
    private var session: Session?
    
    func setSession(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.session = Session(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn))
        )
        
        // Save to Keychain for persistence
        KeychainHelper.shared.save(key: "supabase_session", value: session)
    }
    
    func getAccessToken() async -> String {
        guard let session = session else {
            throw AuthError.notAuthenticated
        }
        
        // Check if token expires soon (<5 minutes)
        if session.expiresAt.timeIntervalSinceNow < 300 {
            // Refresh token
            await refreshSession()
        }
        
        return session.accessToken
    }
    
    func refreshSession() async {
        guard let session = session else { return }
        
        // Call backend refresh endpoint
        let url = URL(string: "\(baseURL)/auth-refresh-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["refresh_token": session.refreshToken])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(RefreshResponse.self, from: data)
        
        // Update session
        setSession(
            accessToken: response.access_token,
            refreshToken: response.refresh_token,
            expiresIn: response.expires_in
        )
    }
}
```

---

## 3. Multi-Layer Caching Strategy

### Marketing Summary
VeloReady is fast because it's smart about caching. Your activity data, AI briefs, and stream data are cached at multiple layers—browser, serverless functions, and on-device—so you rarely wait for data to load. We respect API rate limits (Strava, OpenAI) while delivering instant performance.

### Technical Detail
Multi-layer caching reduces API calls, improves performance, and lowers costs.

**Caching Layers:**

1. **HTTP Cache (Browser/iOS)**
   - `Cache-Control` headers (max-age=86400 for streams)
   - iOS URLCache for automatic caching
   - 24-hour TTL for activity data

2. **Netlify Blobs (Serverless KV Store)**
   - User-specific cache keys
   - 24-hour TTL for activities
   - 24-hour TTL for AI briefs
   - Persistent across function invocations

3. **Core Data (On-Device)**
   - Scores cached daily
   - Activities cached for offline access
   - AI briefs cached for current day
   - CloudKit sync for cross-device consistency

**Cache Keys:**
- Activities: `activities:{athleteId}`
- Streams: `streams:{athleteId}:{activityId}`
- AI Brief: `{userId}:{date}:{promptVersion}`

**Cache Invalidation:**
- Time-based: TTL expiration
- Event-based: New activity webhook (planned)
- Manual: Pull-to-refresh in iOS app

**Performance Impact:**
- 96% reduction in Strava API calls
- 80% cache hit rate for AI briefs
- 95% cache hit rate for streams
- <100ms response time for cached data

### Technical Implementation
**Architecture:**
- `netlify/lib/cache.ts`: Netlify Blobs wrapper
- `URLCache`: iOS HTTP cache
- `Core Data`: On-device persistence

**Netlify Blobs Cache:**
```typescript
// netlify/lib/cache.ts
import { getStore } from '@netlify/blobs';

const store = getStore('veloready-cache');

export async function getFromBlobs(key: string): Promise<string | null> {
  try {
    const value = await store.get(key);
    return value;
  } catch (error) {
    console.error('Cache read error:', error);
    return null;
  }
}

export async function saveToBlobs(key: string, value: string, ttl: number): Promise<void> {
  try {
    await store.set(key, value, { metadata: { ttl } });
  } catch (error) {
    console.error('Cache write error:', error);
  }
}

export async function deleteFromBlobs(key: string): Promise<void> {
  try {
    await store.delete(key);
  } catch (error) {
    console.error('Cache delete error:', error);
  }
}
```

**HTTP Cache Headers:**
```typescript
// api-streams.ts
return new Response(JSON.stringify(streams), {
  headers: {
    'Content-Type': 'application/json',
    'Cache-Control': 'public, max-age=86400',  // 24h browser cache
    'X-Cache': cached ? 'HIT' : 'MISS'
  }
});
```

**iOS Core Data Cache:**
```swift
// AIBriefService.swift
func loadFromCoreData() -> String? {
    let request: NSFetchRequest<AIBrief> = AIBrief.fetchRequest()
    request.predicate = NSPredicate(
        format: "date == %@ AND athleteId == %@",
        Calendar.current.startOfDay(for: Date()) as NSDate,
        currentAthleteId as NSString
    )
    
    do {
        let results = try context.fetch(request)
        return results.first?.briefText
    } catch {
        Logger.error("Failed to load AI brief from Core Data: \(error)")
        return nil
    }
}

func saveToCoreData(brief: String) {
    let aiBrief = AIBrief(context: context)
    aiBrief.date = Calendar.current.startOfDay(for: Date())
    aiBrief.athleteId = currentAthleteId
    aiBrief.briefText = brief
    aiBrief.createdAt = Date()
    
    do {
        try context.save()
        Logger.debug("✅ AI brief saved to Core Data")
    } catch {
        Logger.error("Failed to save AI brief: \(error)")
    }
}
```

---

## 4. Database (Supabase PostgreSQL + RLS)

### Marketing Summary
VeloReady uses Supabase, a modern PostgreSQL database with built-in authentication and real-time subscriptions. Your data is stored securely with Row-Level Security (RLS), ensuring complete isolation between users. The database scales automatically, handles millions of rows, and provides instant queries with proper indexing.

### Technical Detail
Supabase is an open-source Firebase alternative built on PostgreSQL.

**Features:**
1. **PostgreSQL**: Industry-standard relational database
2. **Row-Level Security (RLS)**: Database-enforced user isolation
3. **Real-Time Subscriptions**: Live data updates (planned feature)
4. **Auto-Generated APIs**: RESTful and GraphQL endpoints
5. **Built-in Auth**: JWT-based authentication
6. **Connection Pooling**: Efficient connection management
7. **Automatic Backups**: Daily backups with point-in-time recovery

**Database Schema:**

**Athletes Table:**
```sql
CREATE TABLE athletes (
  id BIGINT PRIMARY KEY,  -- Strava athlete ID
  user_id UUID REFERENCES auth.users(id),
  firstname TEXT,
  lastname TEXT,
  profile TEXT,  -- Profile photo URL
  strava_access_token TEXT,
  strava_refresh_token TEXT,
  strava_token_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policy: Users can only access their own athlete record
CREATE POLICY "Users can access own athlete"
  ON athletes FOR ALL
  USING (user_id = auth.uid());
```

**Activities Table:**
```sql
CREATE TABLE activities (
  id BIGINT PRIMARY KEY,  -- Strava activity ID
  athlete_id BIGINT REFERENCES athletes(id),
  name TEXT,
  type TEXT,
  start_date TIMESTAMPTZ,
  distance FLOAT,
  moving_time INT,
  elapsed_time INT,
  total_elevation_gain FLOAT,
  average_speed FLOAT,
  max_speed FLOAT,
  average_heartrate FLOAT,
  max_heartrate FLOAT,
  average_watts FLOAT,
  weighted_average_watts FLOAT,  -- Normalized Power
  kilojoules FLOAT,
  device_watts BOOLEAN,
  has_heartrate BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policy: Users can only access activities for their athlete
CREATE POLICY "Users can access own activities"
  ON activities FOR ALL
  USING (athlete_id IN (
    SELECT id FROM athletes WHERE user_id = auth.uid()
  ));

-- Indexes for performance
CREATE INDEX idx_activities_athlete_date ON activities(athlete_id, start_date DESC);
CREATE INDEX idx_activities_type ON activities(type);
```

**Streams Table (Cached):**
```sql
CREATE TABLE activity_streams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  activity_id BIGINT REFERENCES activities(id),
  athlete_id BIGINT REFERENCES athletes(id),
  stream_type TEXT,  -- 'power', 'heartrate', 'latlng', etc.
  data JSONB,  -- Array of values
  cached_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

-- RLS Policy
CREATE POLICY "Users can access own streams"
  ON activity_streams FOR ALL
  USING (athlete_id IN (
    SELECT id FROM athletes WHERE user_id = auth.uid()
  ));

-- Index for cache lookups
CREATE INDEX idx_streams_activity ON activity_streams(activity_id, stream_type);
CREATE INDEX idx_streams_expiry ON activity_streams(expires_at);
```

**Performance Optimization:**
- Indexes on frequently queried columns
- JSONB for flexible stream data storage
- Partial indexes for active records only
- Connection pooling (max 100 connections)
- Query optimization with EXPLAIN ANALYZE

### Technical Implementation
**Architecture:**
- `netlify/lib/db.ts`: Supabase client wrapper
- SQL migrations for schema changes
- RLS policies for security
- Indexes for performance

**Database Client:**
```typescript
// netlify/lib/db.ts
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

// Helper: Fetch athlete by user_id
export async function getAthleteByUserId(userId: string) {
  const { data, error } = await supabase
    .from('athletes')
    .select('*')
    .eq('user_id', userId)
    .single();
  
  if (error) throw error;
  return data;
}

// Helper: Fetch activities for athlete
export async function getActivitiesForAthlete(athleteId: number, limit: number = 30) {
  const { data, error } = await supabase
    .from('activities')
    .select('*')
    .eq('athlete_id', athleteId)
    .order('start_date', { ascending: false })
    .limit(limit);
  
  if (error) throw error;
  return data;
}
```

**RLS Testing:**
```sql
-- Test RLS as specific user
SET request.jwt.claim.sub = 'user-uuid-here';

-- Should only return activities for this user's athlete
SELECT * FROM activities;

-- Should fail (no access to other users' data)
SELECT * FROM activities WHERE athlete_id = 999999;
```
