import SwiftUI

/// Paywall view for VeloReady Pro subscription
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var config = ProFeatureConfig.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Trial banner
                    if !config.isInTrialPeriod && !config.isProUser {
                        trialBanner
                    }
                    
                    // Subscription plans
                    planSelector
                    
                    // Features list
                    featuresSection
                    
                    // CTA Button
                    ctaButton
                    
                    // Fine print
                    finePrint
                }
                .padding()
            }
            .background(Color.background.primary)
            .navigationTitle(PaywallContent.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(PaywallContent.closeButton) {
                        dismiss()
                    }
                }
            }
        }
        .alert(PaywallContent.errorAlertTitle, isPresented: $showError) {
            Button(PaywallContent.errorAlertOK, role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(PaywallContent.headline)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(PaywallContent.subheadline)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    private var trialBanner: some View {
        HStack {
            Image(systemName: "gift.fill")
                .foregroundColor(.white)
            Text(PaywallContent.trialBannerText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
    
    private var planSelector: some View {
        VStack(spacing: 12) {
            PlanCard(
                plan: .yearly,
                isSelected: selectedPlan == .yearly,
                badge: PaywallContent.bestValueBadge
            ) {
                selectedPlan = .yearly
            }
            
            PlanCard(
                plan: .monthly,
                isSelected: selectedPlan == .monthly
            ) {
                selectedPlan = .monthly
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(PaywallContent.featuresTitle)
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(config.proFeaturesList) { feature in
                FeatureRow(feature: feature)
            }
        }
    }
    
    private var ctaButton: some View {
        Button(action: handleSubscribe) {
            HStack {
                if subscriptionManager.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(config.isInTrialPeriod ? PaywallContent.ctaButtonTrial : PaywallContent.ctaButtonStartTrial)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.button.primary)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(subscriptionManager.isLoading || subscriptionManager.monthlyProduct == nil)
    }
    
    private var finePrint: some View {
        VStack(spacing: 8) {
            if !config.isInTrialPeriod {
                let price = selectedPlan == .yearly 
                    ? (subscriptionManager.yearlyProduct?.displayPrice ?? "$5.99")
                    : (subscriptionManager.monthlyProduct?.displayPrice ?? "$9.99")
                Text(PaywallContent.priceDisclaimer(price: price, period: selectedPlan.period))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(PaywallContent.cancellationPolicy)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button(PaywallContent.termsButton) {
                    // TODO: Open terms URL
                }
                Button(PaywallContent.privacyButton) {
                    // TODO: Open privacy URL
                }
                Button(PaywallContent.restoreButton) {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                }
            }
            .font(.caption)
            .foregroundColor(Color.button.primary)
        }
        .padding(.top)
    }
    
    private func handleSubscribe() {
        Task {
            do {
                let product = selectedPlan == .yearly 
                    ? subscriptionManager.yearlyProduct 
                    : subscriptionManager.monthlyProduct
                
                guard let product = product else {
                    errorMessage = PaywallContent.productUnavailableError
                    showError = true
                    return
                }
                
                try await subscriptionManager.purchase(product)
                
                // Dismiss on successful purchase
                if subscriptionManager.subscriptionStatus.isActive {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    var badge: String? = nil
    let onTap: () -> Void
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    
    private var priceText: String {
        switch plan {
        case .monthly:
            return subscriptionManager.monthlyProduct?.displayPrice ?? "$9.99"
        case .yearly:
            return subscriptionManager.yearlyProduct?.displayPrice ?? "$5.99"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ColorPalette.warning)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.subtitle(savingsPercent: subscriptionManager.yearlySavingsPercent))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(priceText)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("per \(plan.period)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.interactive.selected : ColorPalette.neutral400)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.interactive.selected : ColorPalette.neutral300.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: ProFeature
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundColor(Color.button.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Subscription Plan Model

enum SubscriptionPlan {
    case monthly
    case yearly
    
    var title: String {
        switch self {
        case .monthly: return PaywallContent.Plans.monthlyTitle
        case .yearly: return PaywallContent.Plans.yearlyTitle
        }
    }
    
    func subtitle(savingsPercent: Int) -> String {
        switch self {
        case .monthly: return PaywallContent.Plans.monthlySubtitle
        case .yearly: return PaywallContent.Plans.yearlySubtitle(savingsPercent: savingsPercent)
        }
    }
    
    var period: String {
        switch self {
        case .monthly: return PaywallContent.Plans.monthlyPeriod
        case .yearly: return PaywallContent.Plans.yearlyPeriod
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
