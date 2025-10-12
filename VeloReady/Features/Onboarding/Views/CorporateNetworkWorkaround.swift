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
                Text("Corporate Network Issue Detected")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.semantic.warning)
                
                Text("Your corporate network is intercepting HTTPS traffic with Netskope certificates. This prevents OAuth from working.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Workaround Options:")
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
            .navigationTitle("Network Workaround")
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
                    Text("\(method) Instructions")
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
                        Text("No instructions available")
                    }
                }
                .padding()
            }
            .navigationTitle("Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var personalHotspotInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Use Personal Hotspot")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("This bypasses your corporate network entirely:")
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Enable Personal Hotspot on your phone")
                Text("2. Connect your Mac to the hotspot")
                Text("3. Run the app - OAuth should work normally")
                Text("4. Switch back to corporate network after testing")
            }
            .font(.body)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text("✅ Pros: Completely bypasses corporate network")
                .foregroundColor(Color.semantic.success)
            Text("❌ Cons: Uses cellular data")
                .foregroundColor(Color.semantic.error)
        }
    }
    
    private var vpnInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Use VPN Connection")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Connect to a VPN to bypass corporate network:")
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Install a VPN client (NordVPN, ExpressVPN, etc.)")
                Text("2. Connect to a server outside your corporate network")
                Text("3. Run the app - OAuth should work normally")
                Text("4. Disconnect VPN after testing")
            }
            .font(.body)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text("✅ Pros: Bypasses corporate network, keeps internet")
                .foregroundColor(Color.semantic.success)
            Text("❌ Cons: Requires VPN subscription")
                .foregroundColor(Color.semantic.error)
        }
    }
    
    private var differentNetworkInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Use Different Network")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Connect to a network without corporate security:")
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Go to a coffee shop, library, or home network")
                Text("2. Connect to their WiFi")
                Text("3. Run the app - OAuth should work normally")
                Text("4. Return to corporate network after testing")
            }
            .font(.body)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text("✅ Pros: No additional setup required")
                .foregroundColor(Color.semantic.success)
            Text("❌ Cons: Requires physical location change")
                .foregroundColor(Color.semantic.error)
        }
    }
    
    private var certificateBypassInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Certificate Bypass (Advanced)")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Configure the app to accept corporate certificates:")
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. This requires modifying the app's SSL handling")
                Text("2. Accept corporate certificates for intervals.icu")
                Text("3. May require IT approval for security reasons")
                Text("4. Not recommended for production apps")
            }
            .font(.body)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text("⚠️ Warning: This reduces security and may violate corporate policy")
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
