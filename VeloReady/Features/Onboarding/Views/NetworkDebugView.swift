import SwiftUI
import Network

struct NetworkDebugView: View {
    @State private var networkStatus = "Checking..."
    @State private var testResults = ""
    @State private var isTesting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Network Status
                    networkStatusSection
                    
                    // Network Tests
                    networkTestsSection
                    
                    // Test Results
                    testResultsSection
                }
                .padding()
            }
            .navigationTitle(DebugContent.Navigation.networkDebug)
            .onAppear {
                checkNetworkStatus()
            }
        }
    }
    
    private var networkStatusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(OnboardingContent.NetworkDebug.networkStatus)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(networkStatus)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.background.secondary)
        .cornerRadius(12)
    }
    
    private var networkTestsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(OnboardingContent.NetworkDebug.networkTests)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: Spacing.sm) {
                Button(DebugContent.NetworkDebug.testBasicConnectivity) {
                    testBasicConnectivity()
                }
                .buttonStyle(.bordered)
                
                Button(DebugContent.NetworkDebug.testIntervalsDNS) {
                    testIntervalsDNSS()
                }
                .buttonStyle(.bordered)
                
                Button(DebugContent.NetworkDebug.testIntervalsHTTPS) {
                    testIntervalsHTTPS()
                }
                .buttonStyle(.bordered)
                
                Button(DebugContent.NetworkDebug.testOAuthEndpoint) {
                    testOAuthEndpoint()
                }
                .buttonStyle(.bordered)
                
                Button(DebugContent.NetworkDebug.testAPIEndpoint) {
                    testAPIEndpoint()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.background.secondary)
        .cornerRadius(12)
    }
    
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(OnboardingContent.NetworkDebug.testResults)
                .font(.headline)
                .fontWeight(.semibold)
            
            if isTesting {
                ProgressView("Testing network...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView {
                    Text(testResults.isEmpty ? "No test results yet" : testResults)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .background(Color.background.secondary)
        .cornerRadius(12)
    }
    
    private func checkNetworkStatus() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    let interfaceTypes = path.availableInterfaces.map { interface in
                        switch interface.type {
                        case .wifi: return "WiFi"
                        case .cellular: return "Cellular"
                        case .wiredEthernet: return "Ethernet"
                        case .loopback: return "Loopback"
                        case .other: return "Other"
                        @unknown default: return "Unknown"
                        }
                    }
                    networkStatus = "✅ Connected (\(interfaceTypes.joined(separator: ", ")))"
                } else {
                    networkStatus = "❌ Not Connected"
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    private func testBasicConnectivity() {
        isTesting = true
        testResults = "Testing basic connectivity...\n\n"
        
        guard let url = URL(string: "https://www.apple.com") else {
            testResults += "❌ Invalid test URL\n"
            isTesting = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    testResults += "❌ Basic connectivity failed: \(error.localizedDescription)\n"
                } else if let httpResponse = response as? HTTPURLResponse {
                    testResults += "✅ Basic connectivity: HTTP \(httpResponse.statusCode)\n"
                } else {
                    testResults += "❌ Unknown response type\n"
                }
                isTesting = false
            }
        }.resume()
    }
    
    private func testIntervalsDNSS() {
        isTesting = true
        testResults += "Testing intervals.icu DNS resolution...\n\n"
        
        // Test DNS resolution using URLSession
        guard let url = URL(string: "https://intervals.icu") else {
            testResults += "❌ Invalid URL for DNS test\n"
            isTesting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    testResults += "❌ DNS resolution failed: \(error.localizedDescription)\n"
                } else if let httpResponse = response as? HTTPURLResponse {
                    testResults += "✅ DNS resolution successful: HTTP \(httpResponse.statusCode)\n"
                    testResults += "  Host resolved successfully\n"
                } else {
                    testResults += "❌ Unknown response type\n"
                }
                isTesting = false
            }
        }.resume()
    }
    
    private func testIntervalsHTTPS() {
        isTesting = true
        testResults += "Testing intervals.icu HTTPS connection...\n\n"
        
        guard let url = URL(string: "https://intervals.icu") else {
            testResults += "❌ Invalid intervals.icu URL\n"
            isTesting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    testResults += "❌ HTTPS connection failed: \(error.localizedDescription)\n"
                    if let nsError = error as NSError? {
                        testResults += "  Error domain: \(nsError.domain)\n"
                        testResults += "  Error code: \(nsError.code)\n"
                        testResults += "  Error userInfo: \(nsError.userInfo)\n"
                    }
                } else if let httpResponse = response as? HTTPURLResponse {
                    testResults += "✅ HTTPS connection: HTTP \(httpResponse.statusCode)\n"
                    testResults += "  Response headers: \(httpResponse.allHeaderFields)\n"
                } else {
                    testResults += "❌ Unknown response type\n"
                }
                isTesting = false
            }
        }.resume()
    }
    
    private func testOAuthEndpoint() {
        isTesting = true
        testResults += "Testing OAuth endpoint...\n\n"
        
        guard let url = URL(string: "https://intervals.icu/oauth/authorize") else {
            testResults += "❌ Invalid OAuth URL\n"
            isTesting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    testResults += "❌ OAuth endpoint failed: \(error.localizedDescription)\n"
                } else if let httpResponse = response as? HTTPURLResponse {
                    testResults += "✅ OAuth endpoint: HTTP \(httpResponse.statusCode)\n"
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        testResults += "  Response preview: \(String(responseString.prefix(200)))...\n"
                    }
                } else {
                    testResults += "❌ Unknown response type\n"
                }
                isTesting = false
            }
        }.resume()
    }
    
    private func testAPIEndpoint() {
        isTesting = true
        testResults += "Testing API endpoint...\n\n"
        
        guard let url = URL(string: "https://intervals.icu/api/oauth/token") else {
            testResults += "❌ Invalid API URL\n"
            isTesting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        // Test with dummy data
        let body = "grant_type=authorization_code&client_id=108&client_secret=test&code=test&redirect_uri=test"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    testResults += "❌ API endpoint failed: \(error.localizedDescription)\n"
                } else if let httpResponse = response as? HTTPURLResponse {
                    testResults += "✅ API endpoint: HTTP \(httpResponse.statusCode)\n"
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        testResults += "  Response: \(responseString)\n"
                    }
                } else {
                    testResults += "❌ Unknown response type\n"
                }
                isTesting = false
            }
        }.resume()
    }
}

struct NetworkDebugView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkDebugView()
    }
}
