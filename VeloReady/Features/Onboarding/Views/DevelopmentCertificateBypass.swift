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
                    
                    Text(OnboardingContent.CertificateBypass.devOnly)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.semantic.warning)
                    
                    Text(OnboardingContent.CertificateBypass.securityWarning)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Toggle
                VStack(alignment: .leading, spacing: 12) {
                    Text(OnboardingContent.CertificateBypass.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Toggle(OnboardingContent.CertificateBypass.acceptCerts, isOn: $isEnabled)
                        .onChange(of: isEnabled) { _, newValue in
                            if newValue {
                                showingWarning = true
                            }
                        }
                    
                    if isEnabled {
                        Text(OnboardingContent.CertificateBypass.certsAccepted)
                            .font(.caption)
                            .foregroundColor(Color.semantic.success)
                    } else {
                        Text(OnboardingContent.CertificateBypass.standardValidation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text(OnboardingContent.CertificateBypass.howItWorks)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(OnboardingContent.CertificateBypass.step1)
                        Text(OnboardingContent.CertificateBypass.step2)
                        Text(OnboardingContent.CertificateBypass.step3)
                        Text(OnboardingContent.CertificateBypass.step4)
                    }
                    .font(.body)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle(DebugContent.Navigation.certificateBypass)
            .alert(OnboardingContent.CertificateBypass.alertTitle, isPresented: $showingWarning) {
                Button(CommonContent.Actions.cancel) {
                    isEnabled = false
                }
                Button(OnboardingContent.CertificateBypass.enableAnyway, role: .destructive) {
                    // Bypass is already enabled
                }
            } message: {
                Text(OnboardingContent.CertificateBypass.alertMessage)
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
