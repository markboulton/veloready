import SwiftUI
import WebKit

/// Workaround for corporate networks that intercept HTTPS traffic
struct CorporateNetworkWorkaround: View {
    @State private var selectedMethod = 0
    @State private var showingInstructions = false
    
    let methods = [
        "Personal Hotspot",
        "VPN Connection", 
        "Different Network",
        "Certificate Bypass"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(OnboardingContent.CorporateNetwork.issueDetected)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.semantic.warning)
                
                Text(OnboardingContent.CorporateNetwork.httpsInterception)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(OnboardingContent.CorporateNetwork.workaroundOptions)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(0..<methods.count, id: \.self) { index in
                        HStack {
                            Button(action: {
                                selectedMethod = index
                                showingInstructions = true
                            }) {
                                HStack {
                                    Image(systemName: selectedMethod == index ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedMethod == index ? Color.interactive.selected : ColorPalette.neutral400)
                                    
                                    Text(methods[index])
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(ColorPalette.neutral400)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle(DebugContent.Navigation.networkWorkaround)
            .sheet(isPresented: $showingInstructions) {
                WorkaroundInstructions(method: methods[selectedMethod])
            }
        }
    }
}

struct WorkaroundInstructions: View {
    let method: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(method) \(OnboardingContent.CorporateNetwork.instructions)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    switch method {
                    case "Personal Hotspot":
                        personalHotspotInstructions
                    case "VPN Connection":
                        vpnInstructions
                    case "Different Network":
                        differentNetworkInstructions
                    case "Certificate Bypass":
                        certificateBypassInstructions
                    default:
                        Text(OnboardingContent.CorporateNetwork.noInstructions)
                    }
                }
                .padding()
            }
            .navigationTitle(DebugContent.Navigation.instructions)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CommonContent.Actions.done) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var personalHotspotInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(OnboardingContent.CorporateNetwork.usePersonalHotspot)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(OnboardingContent.CorporateNetwork.hotspotBypass)
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(OnboardingContent.CorporateNetwork.hotspotStep1)
                Text(OnboardingContent.CorporateNetwork.hotspotStep2)
                Text(OnboardingContent.CorporateNetwork.hotspotStep3)
                Text(OnboardingContent.CorporateNetwork.hotspotStep4)
            }
            .font(.body)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text(OnboardingContent.CorporateNetwork.hotspotPros)
                .foregroundColor(Color.semantic.success)
            Text(OnboardingContent.CorporateNetwork.hotspotCons)
                .foregroundColor(Color.semantic.error)
        }
    }
    
    private var vpnInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(OnboardingContent.CorporateNetwork.useVPN)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(OnboardingContent.CorporateNetwork.vpnBypass)
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(OnboardingContent.CorporateNetwork.vpnStep1)
                Text(OnboardingContent.CorporateNetwork.vpnStep2)
                Text(OnboardingContent.CorporateNetwork.vpnStep3)
                Text(OnboardingContent.CorporateNetwork.vpnStep4)
            }
            .font(.body)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text(OnboardingContent.CorporateNetwork.vpnPros)
                .foregroundColor(Color.semantic.success)
            Text(OnboardingContent.CorporateNetwork.vpnCons)
                .foregroundColor(Color.semantic.error)
        }
    }
    
    private var differentNetworkInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(OnboardingContent.CorporateNetwork.useDifferentNetwork)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(OnboardingContent.CorporateNetwork.networkWithout)
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(OnboardingContent.CorporateNetwork.networkStep1)
                Text(OnboardingContent.CorporateNetwork.networkStep2)
                Text(OnboardingContent.CorporateNetwork.networkStep3)
                Text(OnboardingContent.CorporateNetwork.networkStep4)
            }
            .font(.body)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text(OnboardingContent.CorporateNetwork.networkPros)
                .foregroundColor(Color.semantic.success)
            Text(OnboardingContent.CorporateNetwork.networkCons)
                .foregroundColor(Color.semantic.error)
        }
    }
    
    private var certificateBypassInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(OnboardingContent.CorporateNetwork.certificateAdvanced)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(OnboardingContent.CorporateNetwork.certificateConfigure)
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(OnboardingContent.CorporateNetwork.certificateStep1)
                Text(OnboardingContent.CorporateNetwork.certificateStep2)
                Text(OnboardingContent.CorporateNetwork.certificateStep3)
                Text(OnboardingContent.CorporateNetwork.certificateStep4)
            }
            .font(.body)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text(OnboardingContent.CorporateNetwork.certificateWarning)
                .foregroundColor(Color.semantic.warning)
                .font(.caption)
        }
    }
}

struct CorporateNetworkWorkaround_Previews: PreviewProvider {
    static var previews: some View {
        CorporateNetworkWorkaround()
    }
}
