import SwiftUI
@preconcurrency import WebKit

struct OAuthWebView: UIViewRepresentable {
    let url: URL
    let onCallback: (URL) -> Void
    let onDismiss: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Configure for better SSL/TLS handling
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Set user agent to avoid potential blocking
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, URLSessionDelegate, @unchecked Sendable {
        let parent: OAuthWebView
        
        init(_ parent: OAuthWebView) {
            self.parent = parent
        }
        
        // Handle SSL certificate challenges
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            Logger.debug("🔒 SSL Challenge received for: \(challenge.protectionSpace.host)")
            
            // For intervals.icu, we'll accept the certificate
            if challenge.protectionSpace.host.contains("intervals.icu") {
                Logger.debug("🔒 Accepting certificate for intervals.icu")
                if let serverTrust = challenge.protectionSpace.serverTrust {
                    let credential = URLCredential(trust: serverTrust)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
            
            // Default behavior for other hosts
            completionHandler(.performDefaultHandling, nil)
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
            
            // Check for intervals.icu domain to ensure we're on the right site
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
            
            // Check if it's a network error
            if let nsError = error as NSError? {
                Logger.error("Error domain: \(nsError.domain)")
                Logger.error("Error code: \(nsError.code)")
                Logger.error("Error userInfo: \(nsError.userInfo)")
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Logger.error("WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Logger.debug("✅ WebView finished loading: \(webView.url?.absoluteString ?? "unknown")")
        }
    }
}

struct OAuthWebViewContainer: View {
    let url: URL
    let onCallback: (URL) -> Void
    let onDismiss: () -> Void
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                OAuthWebView(
                    url: url,
                    onCallback: onCallback,
                    onDismiss: onDismiss
                )
                .onAppear {
                    Logger.debug("🌐 Starting OAuth WebView with URL: \(url.absoluteString)")
                }
            }
            .navigationTitle("Connect to intervals.icu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
            .alert("Network Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}
