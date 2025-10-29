# API Response Fixtures

This directory contains **real API responses** from Strava and Intervals.icu, recorded for contract testing.

## Purpose

These fixtures allow us to test our API parsers against **real** data without consuming API quota. Each test run uses **0 API calls**.

## Files

| Fixture | Source | Last Updated | Description |
|---------|--------|--------------|-------------|
| `strava_activities_response.json` | Strava API v3 | - | List of recent activities |
| `strava_activity_detail_response.json` | Strava API v3 | - | Single activity with full details |
| `strava_athlete_response.json` | Strava API v3 | - | Athlete profile |
| `intervals_activities_response.json` | Intervals.icu API | - | List of activities |

## Updating Fixtures

### When to Update

1. **Quarterly** (proactive maintenance)
2. **When Strava/Intervals.icu announces API changes**
3. **When contract tests start failing** (indicates API change)

### How to Update

Run the recording script from the project root:

```bash
# Set your API tokens (do NOT commit these!)
export STRAVA_TOKEN="your_strava_access_token"
export INTERVALS_TOKEN="your_intervals_api_key"

# Record fixtures (makes 3-5 API calls)
./Scripts/record-api-fixtures.sh
```

**API Cost**: 3-5 requests (one-time)

### After Updating

1. Run tests to verify: `swift run VeloReadyCoreTests`
2. Check git diff to see what changed
3. Update parsers if needed
4. Commit the new fixtures

## Privacy Note

These fixtures contain **your real activity data**. Before committing:

1. Remove sensitive fields (personal bests, segment efforts, private routes)
2. Or use test data from a dedicated test account
3. Never commit API tokens to git!

## API Quota Impact

- **Per test run**: 0 requests ✅
- **Per PR**: 0 requests ✅
- **Per day**: 0 requests ✅
- **Quarterly update**: 3-5 requests
- **Annual total**: ~15-20 requests (0.002% of Strava's daily quota)

This approach allows unlimited testing without consuming your precious API quota!

