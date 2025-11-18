import SwiftUI
@preconcurrency import WebKit

struct IntervalsOAuthWebView: UIViewRepresentable {
    let url: URL
    let onCallback: (URL) -> Void
    let onDismiss: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Configure for better SSL/TLS handling
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Create custom URL scheme handler for better SSL handling
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Set user agent
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Load the URL with custom SSL handling
        loadURLWithSSLHandling(webView: webView, url: url)
    }
    
    private func loadURLWithSSLHandling(webView: WKWebView, url: URL) {
        Logger.debug("🌐 Loading URL with SSL handling: \(url.absoluteString)")
        
        // Create a custom URL session with SSL handling
        let session = URLSession(configuration: .default, delegate: SSLDelegate(), delegateQueue: nil)
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.error("SSL handling failed: \(error.localizedDescription)")
                    // Fallback to regular WebView load
                    let fallbackRequest = URLRequest(url: url)
                    webView.load(fallbackRequest)
                } else {
                    Logger.debug("✅ SSL handling successful")
                    // Load the response in WebView
                    if let data = data, let html = String(data: data, encoding: .utf8) {
                        webView.loadHTMLString(html, baseURL: url)
                    } else {
                        let fallbackRequest = URLRequest(url: url)
                        webView.load(fallbackRequest)
                    }
                }
            }
        }.resume()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: IntervalsOAuthWebView
        
        init(_ parent: IntervalsOAuthWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            Logger.debug("🌐 WebView navigating to: \(url.absoluteString)")
            
            // Check if this is our OAuth callback
            if url.scheme == "veloready" || url.scheme == "com.veloready.app" {
                Logger.debug("✅ OAuth callback detected in WebView: \(url.scheme ?? "unknown")://")
                Logger.debug("   Full URL: \(url.absoluteString)")
                parent.onCallback(url)
                decisionHandler(.cancel)
                return
            }
            
            // Check for intervals.icu domain
            if let host = url.host, host.contains("intervals.icu") {
                Logger.debug("🌐 Navigating within intervals.icu: \(url.absoluteString)")
                decisionHandler(.allow)
                return
            }
            
            // Allow navigation for intervals.icu domain
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Logger.error("WebView navigation failed: \(error.localizedDescription)")
            
            // Check if it's a TLS/SSL error
            if let nsError = error as NSError? {
                Logger.error("Error domain: \(nsError.domain)")
                Logger.error("Error code: \(nsError.code)")
                
                if nsError.code == -1200 { // NSURLErrorSecureConnectionFailed
                    Logger.debug("🔒 TLS/SSL Error detected - trying alternative approach")
                    // Try loading with different approach
                    tryAlternativeLoading(webView: webView)
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Logger.error("WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Logger.debug("✅ WebView finished loading: \(webView.url?.absoluteString ?? "unknown")")
        }
        
        private func tryAlternativeLoading(webView: WKWebView) {
            Logger.debug("🔄 Trying alternative loading approach...")
            
            // Try loading with a different user agent and approach
            let configuration = WKWebViewConfiguration()
            configuration.allowsInlineMediaPlayback = true
            
            // Create a new request with different headers
            if let url = webView.url {
                var request = URLRequest(url: url)
                request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
                request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
                request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
                
                webView.load(request)
            }
        }
    }
}

// Custom SSL delegate to handle certificate challenges
final class SSLDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    nonisolated func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        Logger.debug("🔒 SSL Challenge received for: \(challenge.protectionSpace.host)")
        
        // Check if certificate bypass is enabled for intervals.icu
        if CertificateBypassManager.shared.shouldBypassCertificate(for: challenge.protectionSpace.host) {
            Logger.debug("🔒 Certificate bypass enabled - accepting corporate certificate")
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                DispatchQueue.main.async {
                    completionHandler(.useCredential, credential)
                }
                return
            }
        }
        
        // Default behavior
        DispatchQueue.main.async {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

struct IntervalsOAuthWebViewContainer: View {
    let url: URL
    let onCallback: (URL) -> Void
    let onDismiss: () -> Void
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                IntervalsOAuthWebView(
                    url: url,
                    onCallback: onCallback,
                    onDismiss: onDismiss
                )
                .onAppear {
                    Logger.debug("🌐 Starting OAuth WebView with SSL handling: \(url.absoluteString)")
                }
            }
            .navigationTitle(OnboardingContent.OAuthWebView.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(OnboardingContent.OAuthWebView.cancel) {
                        onDismiss()
                    }
                }
            }
            .alert(OnboardingContent.OAuthWebView.networkError, isPresented: $showingError) {
                Button(OnboardingContent.OAuthWebView.ok) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}
