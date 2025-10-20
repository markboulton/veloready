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
                Text(SettingsContent.Feedback.title)
                
                Section {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                        .overlay(alignment: .topLeading) {
                            if feedbackText.isEmpty {
                                Text(SettingsContent.Feedback.describeIssue)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                } header: {
                    Text(SettingsContent.Feedback.yourFeedback)
                } footer: {
                    Picker("Type", selection: .constant("general")) {
                        Text(SettingsContent.Feedback.bugReport).tag("bug")
                        Text(SettingsContent.Feedback.featureRequest).tag("feature")
                        Text(SettingsContent.Feedback.general).tag("general")
                    }
                }
                
                // Options section
                Section {
                    Toggle(SettingsContent.Feedback.includeLogs, isOn: $includeLogs)
                    Toggle(SettingsContent.Feedback.includeDeviceInfo, isOn: $includeDeviceInfo)
                } header: {
                    Text(SettingsContent.Feedback.type)
                } footer: {
                    Text(SettingsContent.Feedback.logsFooter)
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
                        Text(SettingsContent.Feedback.deviceInfo)
                    }
                }
                
                // Send button
                Section {
                    Button(action: sendFeedback) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text(SettingsContent.Feedback.title)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(SettingsContent.Feedback.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(SettingsContent.Feedback.cancel) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView(
                    subject: SettingsContent.Feedback.subject,
                    recipients: ["support@veloready.app"],
                    body: buildEmailBody(),
                    attachLogs: includeLogs,
                    isPresented: $showMailComposer,
                    result: $mailResult
                )
            }
            .alert(SettingsContent.Feedback.mailNotAvailable, isPresented: $showNoMailAlert) {
                Button(SettingsContent.Feedback.ok, role: .cancel) { }
            } message: {
                Text(SettingsContent.Feedback.mailNotAvailableMessage)
            }
            .alert(SettingsContent.Feedback.feedbackSent, isPresented: .constant(mailResult != nil && mailResult?.isSuccess == true)) {
                Button(SettingsContent.Feedback.send) {
                    mailResult = nil
                    dismiss()
                }
            } message: {
                Text(SettingsContent.Feedback.thankYou)
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
            body += "\nNote: Diagnostic logs attached as veloready-logs.txt\n"
        }
        
        return body
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
    let attachLogs: Bool
    @Binding var isPresented: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(subject)
        vc.setToRecipients(recipients)
        vc.setMessageBody(body, isHTML: false)
        
        // Attach logs as file if requested
        if attachLogs {
            if let logData = createLogFile() {
                vc.addAttachmentData(logData, mimeType: "text/plain", fileName: "veloready-logs.txt")
            }
        }
        
        return vc
    }
    
    private func createLogFile() -> Data? {
        let logs = Logger.exportLogs()
        return logs.data(using: .utf8)
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
