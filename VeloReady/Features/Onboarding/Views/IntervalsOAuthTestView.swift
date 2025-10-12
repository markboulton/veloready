import SwiftUI

struct IntervalsOAuthTestView: View {
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @StateObject private var apiClient: IntervalsAPIClient
    @State private var testResults = ""
    @State private var isRunningTests = false
    
    init() {
        self._apiClient = StateObject(wrappedValue: IntervalsAPIClient(oauthManager: IntervalsOAuthManager.shared))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // OAuth Status
                    oauthStatusSection
                    
                    // Test Buttons
                    testButtonsSection
                    
                    // Test Results
                    testResultsSection
                }
                .padding()
            }
            .navigationTitle("OAuth Test")
        }
    }
    
    private var oauthStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OAuth Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Circle()
                    .fill(oauthManager.isAuthenticated ? Color.semantic.success : Color.semantic.error)
                    .frame(width: 12, height: 12)
                
                Text(oauthManager.isAuthenticated ? "Authenticated" : "Not Authenticated")
                    .font(.subheadline)
            }
            
            if let user = oauthManager.user {
                Text("User: \(user.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let error = oauthManager.lastError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(Color.text.error)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var testButtonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OAuth Tests")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Button("Test OAuth URL Generation") {
                    testOAuthURLGeneration()
                }
                .buttonStyle(.bordered)
                
                Button("Test Token Exchange Endpoint") {
                    testTokenExchangeEndpoint()
                }
                .buttonStyle(.bordered)
                
                Button("Test API Endpoints") {
                    testAPIEndpoints()
                }
                .buttonStyle(.bordered)
                .disabled(!oauthManager.isAuthenticated)
                
                Button("Test Full OAuth Flow") {
                    testFullOAuthFlow()
                }
                .buttonStyle(.borderedProminent)
                
                NavigationLink("Network Debug") {
                    NetworkDebugView()
                }
                .buttonStyle(.bordered)
                .foregroundColor(Color.semantic.warning)
                
                NavigationLink("Corporate Network Fix") {
                    CorporateNetworkWorkaround()
                }
                .buttonStyle(.bordered)
                .foregroundColor(Color.button.danger)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isRunningTests {
                ProgressView("Running tests...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView {
                    Text(testResults.isEmpty ? "No test results yet" : testResults)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func testOAuthURLGeneration() {
        testResults = "Testing OAuth URL Generation...\n\n"
        
        if let authURL = oauthManager.startAuthentication() {
            testResults += "✅ OAuth URL Generated Successfully\n"
            testResults += "URL: \(authURL.absoluteString)\n\n"
            
            // Test URL components
            if let components = URLComponents(url: authURL, resolvingAgainstBaseURL: false) {
                testResults += "URL Components:\n"
                testResults += "Scheme: \(components.scheme ?? "nil")\n"
                testResults += "Host: \(components.host ?? "nil")\n"
                testResults += "Path: \(components.path)\n"
                testResults += "Query Items:\n"
                
                for item in components.queryItems ?? [] {
                    testResults += "  \(item.name): \(item.value ?? "nil")\n"
                }
            }
        } else {
            testResults += "❌ Failed to generate OAuth URL\n"
        }
    }
    
    private func testTokenExchangeEndpoint() {
        testResults = "Testing Token Exchange Endpoint...\n\n"
        
        guard let url = URL(string: "https://intervals.icu/api/oauth/token") else {
            testResults += "❌ Invalid token URL\n"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "authorization_code",
            "client_id": "108",
            "client_secret": "lahzoh8pieCha5aiFai4eeveax0aithi",
            "code": "test_code",
            "redirect_uri": "com.markboulton.rideready://oauth/callback"
        ]
        
        let bodyString = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        testResults += "Request URL: \(url.absoluteString)\n"
        testResults += "Request Body: \(bodyString)\n\n"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    testResults += "❌ Network Error: \(error.localizedDescription)\n"
                } else if let httpResponse = response as? HTTPURLResponse {
                    testResults += "✅ HTTP Status: \(httpResponse.statusCode)\n"
                    testResults += "Response Headers: \(httpResponse.allHeaderFields)\n"
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        testResults += "Response Body: \(responseString)\n"
                    }
                } else {
                    testResults += "❌ Unknown response type\n"
                }
            }
        }.resume()
    }
    
    private func testAPIEndpoints() {
        guard oauthManager.isAuthenticated else {
            testResults = "❌ Not authenticated. Please complete OAuth flow first.\n"
            return
        }
        
        isRunningTests = true
        testResults = "Testing API Endpoints...\n\n"
        
        Task {
            do {
                // Test activities endpoint
                testResults += "Testing Activities API...\n"
                let activities = try await apiClient.fetchRecentActivities(limit: 5)
                testResults += "✅ Activities API: \(activities.count) activities fetched\n"
                
                // Test wellness endpoint
                testResults += "Testing Wellness API...\n"
                let wellness = try await apiClient.fetchWellnessData()
                testResults += "✅ Wellness API: \(wellness.count) wellness records fetched\n"
                
                testResults += "\n✅ All API tests passed!\n"
                
            } catch {
                testResults += "❌ API Test Error: \(error.localizedDescription)\n"
            }
            
            isRunningTests = false
        }
    }
    
    private func testFullOAuthFlow() {
        testResults = "Testing Full OAuth Flow...\n\n"
        testResults += "1. Generate OAuth URL...\n"
        
        if let authURL = oauthManager.startAuthentication() {
            testResults += "✅ OAuth URL generated\n"
            testResults += "2. Opening in Safari...\n"
            testResults += "Please complete authentication in Safari and return to app\n"
            
            UIApplication.shared.open(authURL)
        } else {
            testResults += "❌ Failed to generate OAuth URL\n"
        }
    }
}

struct IntervalsOAuthTestView_Previews: PreviewProvider {
    static var previews: some View {
        IntervalsOAuthTestView()
    }
}
