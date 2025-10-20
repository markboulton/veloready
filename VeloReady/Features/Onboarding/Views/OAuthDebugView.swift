import SwiftUI

struct OAuthDebugView: View {
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @State private var debugInfo = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(OnboardingContent.OAuthDebug.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // OAuth Configuration
                        VStack(alignment: .leading, spacing: 8) {
                            Text(OnboardingContent.OAuthDebug.configuration)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(OnboardingContent.OAuthDebug.clientID)
                            Text(OnboardingContent.OAuthDebug.redirectURI)
                            Text(OnboardingContent.OAuthDebug.scopes)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // Test OAuth URL
                        VStack(alignment: .leading, spacing: 8) {
                            Text(OnboardingContent.OAuthDebug.testURL)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if let authURL = oauthManager.startAuthentication() {
                                Text(authURL.absoluteString)
                                    .font(.caption)
                                    .foregroundColor(Color.button.primary)
                                    .textSelection(.enabled)
                                
                                Button(OnboardingContent.OAuthDebug.openSafari) {
                                    UIApplication.shared.open(authURL)
                                }
                                .buttonStyle(.bordered)
                                
                                Button(OnboardingContent.OAuthDebug.testComponents) {
                                    testURLComponents(authURL)
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(Color.semantic.warning)
                            } else {
                                Text(OnboardingContent.OAuthDebug.failedURL)
                                    .foregroundColor(Color.text.error)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // Debug Information
                        VStack(alignment: .leading, spacing: 8) {
                            Text(OnboardingContent.OAuthDebug.debugInfo)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(debugInfo.isEmpty ? OnboardingContent.OAuthDebug.noDebugInfo : debugInfo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // Test API Connection
                        VStack(alignment: .leading, spacing: 8) {
                            Text(OnboardingContent.OAuthDebug.testAPI)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Button(DebugContent.OAuthDebugActions.testIntervalsConnection) {
                                testAPIConnection()
                            }
                            .buttonStyle(.bordered)
                            
                            Button(DebugContent.OAuthDebugActions.testOAuthTokenExchange) {
                                testTokenExchange()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(Color.button.primary)
                            
                            Button(DebugContent.OAuthDebugActions.testCallbackURL) {
                                testCallbackURL()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(Color.button.danger)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(DebugContent.Navigation.oauthDebug)
        }
    }
    
    private func testAPIConnection() {
        guard let url = URL(string: "https://intervals.icu/api/v1/athlete") else {
            debugInfo = "Invalid API URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    debugInfo = "Connection Error: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse {
                    debugInfo = "HTTP Status: \(httpResponse.statusCode)\nHeaders: \(httpResponse.allHeaderFields)"
                } else {
                    debugInfo = "Unknown response"
                }
            }
        }.resume()
    }
    
    private func testURLComponents(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            debugInfo = "Failed to parse URL components"
            return
        }
        
        var info = "URL Analysis:\n"
        info += "Scheme: \(components.scheme ?? "nil")\n"
        info += "Host: \(components.host ?? "nil")\n"
        info += "Path: \(components.path)\n"
        info += "Query Items:\n"
        
        for item in components.queryItems ?? [] {
            info += "  \(item.name): \(item.value ?? "nil")\n"
        }
        
        debugInfo = info
    }
    
    private func testTokenExchange() {
        // Test the token exchange endpoint directly
        guard let url = URL(string: "https://intervals.icu/oauth/token") else {
            debugInfo = "Invalid token URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Test with dummy data to see if the endpoint responds
        let body = [
            "grant_type": "authorization_code",
            "client_id": "108",
            "client_secret": "lahzoh8pieCha5aiFai4eeveax0aithi",
            "code": "test_code",
            "redirect_uri": "veloready://oauth/callback"
        ]
        
        let bodyString = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    debugInfo = "Token Exchange Error: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse {
                    let responseString = String(data: data ?? Data(), encoding: .utf8) ?? "No response"
                    debugInfo = "Token Exchange Response:\nHTTP \(httpResponse.statusCode)\n\(responseString)"
                } else {
                    debugInfo = "Unknown token exchange response"
                }
            }
        }.resume()
    }
    
    private func testCallbackURL() {
        // Simulate a callback URL to test the handling
        let testCallbackURL = "veloready://oauth/callback?code=test_code&state=test_state"
        
        if let url = URL(string: testCallbackURL) {
            debugInfo = "Testing callback URL: \(testCallbackURL)"
            
            Task {
                await oauthManager.handleCallback(url: url)
                DispatchQueue.main.async {
                    if let error = oauthManager.lastError {
                        debugInfo += "\n\nCallback Error: \(error)"
                    } else {
                        debugInfo += "\n\nCallback handled successfully"
                    }
                }
            }
        } else {
            debugInfo = "Failed to create test callback URL"
        }
    }
}

struct OAuthDebugView_Previews: PreviewProvider {
    static var previews: some View {
        OAuthDebugView()
    }
}
