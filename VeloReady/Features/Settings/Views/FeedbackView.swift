import SwiftUI
import MessageUI

/// In-app feedback and support view
/// Allows users to send feedback and logs via email
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText: String = ""
    @State private var includeLogs: Bool = true
    @State private var includeDeviceInfo: Bool = true
    @State private var showMailComposer = false
    @State private var showNoMailAlert = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    
    var body: some View {
        NavigationView {
            Form {
                // Feedback section
                Section {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                        .overlay(alignment: .topLeading) {
                            if feedbackText.isEmpty {
                                Text("Describe your issue or suggestion...")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                } header: {
                    Text("Your Feedback")
                } footer: {
                    Text("Tell us about bugs, feature requests, or general feedback")
                }
                
                // Options section
                Section {
                    Toggle("Include diagnostic logs", isOn: $includeLogs)
                    Toggle("Include device information", isOn: $includeDeviceInfo)
                } header: {
                    Text("Attachments")
                } footer: {
                    Text("Logs help us diagnose issues faster. No personal data is included.")
                }
                
                // Device info preview (if enabled)
                if includeDeviceInfo {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            FeedbackInfoRow(label: "Build", value: getBuildVersion())
                            FeedbackInfoRow(label: "Environment", value: DebugFlags.buildEnvironment)
                            FeedbackInfoRow(label: "Device", value: UIDevice.current.model)
                            FeedbackInfoRow(label: "iOS", value: UIDevice.current.systemVersion)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    } header: {
                        Text("Device Information")
                    }
                }
                
                // Send button
                Section {
                    Button(action: sendFeedback) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Send Feedback")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView(
                    subject: "VeloReady Feedback",
                    recipients: ["support@veloready.app"],
                    body: buildEmailBody(),
                    isPresented: $showMailComposer,
                    result: $mailResult
                )
            }
            .alert("Mail Not Available", isPresented: $showNoMailAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please configure a mail account in Settings or email us at support@veloready.app")
            }
            .alert("Feedback Sent", isPresented: .constant(mailResult != nil && mailResult?.isSuccess == true)) {
                Button("OK") {
                    mailResult = nil
                    dismiss()
                }
            } message: {
                Text("Thank you for your feedback!")
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            showNoMailAlert = true
        }
    }
    
    // MARK: - Email Body Builder
    
    private func buildEmailBody() -> String {
        var body = feedbackText + "\n\n"
        body += "---\n"
        
        if includeDeviceInfo {
            body += "\nDevice Information:\n"
            body += DebugFlags.getBuildInfo() + "\n"
        }
        
        if includeLogs {
            body += "\nRecent Logs:\n"
            body += collectRecentLogs()
        }
        
        return body
    }
    
    private func collectRecentLogs() -> String {
        // Collect logs from Logger
        // This is a simplified version - you may want to implement
        // a proper log collection system if needed
        var logs = "Log collection placeholder\n"
        logs += "Timestamp: \(Date())\n"
        logs += "Note: Implement Logger.getRecentLogs() for detailed logs\n"
        return logs
    }
    
    // MARK: - Helpers
    
    private func getBuildVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

// MARK: - Feedback Info Row Component

struct FeedbackInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let recipients: [String]
    let body: String
    @Binding var isPresented: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(subject)
        vc.setToRecipients(recipients)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            parent.isPresented = false
        }
    }
}

// MARK: - Result Extension

extension Result where Success == MFMailComposeResult {
    var isSuccess: Bool {
        if case .success(let result) = self {
            return result == .sent
        }
        return false
    }
}

// MARK: - Preview

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView()
    }
}
