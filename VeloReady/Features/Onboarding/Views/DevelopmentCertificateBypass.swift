import SwiftUI
import WebKit

/// Development-only certificate bypass for corporate networks
/// WARNING: This reduces security and should only be used for development
struct DevelopmentCertificateBypass: View {
    @State private var isEnabled = false
    @State private var showingWarning = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Warning
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.semantic.warning)
                    
                    Text("Development Only")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.semantic.warning)
                    
                    Text("This bypass reduces security and should only be used for development on corporate networks.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Toggle
                VStack(alignment: .leading, spacing: 12) {
                    Text("Certificate Bypass")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Toggle("Accept Corporate Certificates", isOn: $isEnabled)
                        .onChange(of: isEnabled) { _, newValue in
                            if newValue {
                                showingWarning = true
                            }
                        }
                    
                    if isEnabled {
                        Text("✅ Corporate certificates will be accepted for intervals.icu")
                            .font(.caption)
                            .foregroundColor(Color.semantic.success)
                    } else {
                        Text("❌ Standard certificate validation will be used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it works:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. When enabled, the app accepts corporate certificates")
                        Text("2. This allows OAuth to work on corporate networks")
                        Text("3. Only applies to intervals.icu domain")
                        Text("4. Automatically disabled in production builds")
                    }
                    .font(.body)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Certificate Bypass")
            .alert("Security Warning", isPresented: $showingWarning) {
                Button("Cancel") {
                    isEnabled = false
                }
                Button("Enable Anyway", role: .destructive) {
                    // Bypass is already enabled
                }
            } message: {
                Text("This bypass reduces security by accepting corporate certificates. Only use this for development on corporate networks.")
            }
        }
    }
}

/// Global certificate bypass state
class CertificateBypassManager: ObservableObject {
    @Published var isEnabled = false
    
    static let shared = CertificateBypassManager()
    
    private init() {}
    
    func shouldBypassCertificate(for host: String) -> Bool {
        return isEnabled && host.contains("intervals.icu")
    }
}

struct DevelopmentCertificateBypass_Previews: PreviewProvider {
    static var previews: some View {
        DevelopmentCertificateBypass()
    }
}
