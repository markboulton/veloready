import Foundation
import StoreKit

/// Manager for in-app subscriptions using StoreKit 2
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published State
    
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var isLoading = false
    @Published var error: SubscriptionError?
    
    // MARK: - Product IDs
    
    private let monthlyProductID = "com.rideready.pro.monthly"
    private let yearlyProductID = "com.rideready.pro.yearly"
    
    // MARK: - Products
    
    @Published var monthlyProduct: Product?
    @Published var yearlyProduct: Product?
    
    // MARK: - Transaction Listener
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products and check subscription status
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let products = try await Product.products(for: [monthlyProductID, yearlyProductID])
            
            for product in products {
                switch product.id {
                case monthlyProductID:
                    monthlyProduct = product
                case yearlyProductID:
                    yearlyProduct = product
                default:
                    break
                }
            }
            
            print("✅ Loaded \(products.count) subscription products")
        } catch {
            self.error = .productLoadFailed(error.localizedDescription)
            print("❌ Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check verification
                let transaction = try checkVerified(verification)
                
                // Update subscription status
                await updateSubscriptionStatus()
                
                // Finish the transaction
                await transaction.finish()
                
                print("✅ Purchase successful: \(product.id)")
                
            case .userCancelled:
                print("ℹ️ User cancelled purchase")
                
            case .pending:
                print("⏳ Purchase pending (Ask to Buy)")
                
            @unknown default:
                break
            }
        } catch {
            self.error = .purchaseFailed(error.localizedDescription)
            print("❌ Purchase failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ Purchases restored")
        } catch {
            self.error = .restoreFailed(error.localizedDescription)
            print("❌ Restore failed: \(error)")
        }
    }
    
    // MARK: - Update Subscription Status
    
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        var isInTrialPeriod = false
        var expirationDate: Date?
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if it's one of our subscription products
                if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
                    hasActiveSubscription = true
                    
                    // Check if in trial period
                    if let offerType = transaction.offerType {
                        isInTrialPeriod = (offerType == .introductory)
                    }
                    
                    // Get expiration date
                    expirationDate = transaction.expirationDate
                    
                    print("✅ Active subscription: \(transaction.productID)")
                    if isInTrialPeriod {
                        print("🎁 In trial period")
                    }
                }
            } catch {
                print("❌ Transaction verification failed: \(error)")
            }
        }
        
        // Update status
        if hasActiveSubscription {
            if isInTrialPeriod {
                let daysRemaining = calculateDaysRemaining(until: expirationDate)
                subscriptionStatus = .trial(daysRemaining: daysRemaining)
            } else {
                subscriptionStatus = .subscribed(expiresAt: expirationDate)
            }
        } else {
            subscriptionStatus = .notSubscribed
        }
        
        // Update ProFeatureConfig
        updateProFeatureConfig()
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { @MainActor in
            // Iterate through any transactions that don't come from a direct call to `purchase()`
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Update subscription status
                    await self.updateSubscriptionStatus()
                    
                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("❌ Transaction update failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Helpers
    
    private func calculateDaysRemaining(until date: Date?) -> Int {
        guard let date = date else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return max(0, components.day ?? 0)
    }
    
    private func updateProFeatureConfig() {
        Task { @MainActor in
            let config = ProFeatureConfig.shared
        
        switch subscriptionStatus {
        case .subscribed:
            config.isProUser = true
            config.isInTrialPeriod = false
            config.trialDaysRemaining = 0
            
        case .trial(let daysRemaining):
            config.isProUser = false
            config.isInTrialPeriod = true
            config.trialDaysRemaining = daysRemaining
            
        case .notSubscribed:
            config.isProUser = false
            config.isInTrialPeriod = false
            config.trialDaysRemaining = 0
        }
        
            config.saveSubscriptionState()
        }
    }
    
    // MARK: - Product Info Helpers
    
    var monthlyPrice: String {
        monthlyProduct?.displayPrice ?? "$9.99"
    }
    
    var yearlyPrice: String {
        yearlyProduct?.displayPrice ?? "$5.99"
    }
    
    var yearlyTotalPrice: String {
        if let product = yearlyProduct {
            return product.displayPrice
        }
        return "$71.88"
    }
    
    var yearlySavingsPercent: Int {
        guard let monthly = monthlyProduct?.price,
              let yearly = yearlyProduct?.price else {
            return 40
        }
        
        let monthlyYearly = monthly * Decimal(12)
        let savings = (monthlyYearly - yearly) / monthlyYearly
        let savingsDouble = NSDecimalNumber(decimal: savings).doubleValue
        return Int(savingsDouble * 100)
    }
}

// MARK: - Subscription Status

enum SubscriptionStatus: Equatable {
    case notSubscribed
    case trial(daysRemaining: Int)
    case subscribed(expiresAt: Date?)
    
    var isActive: Bool {
        switch self {
        case .notSubscribed:
            return false
        case .trial, .subscribed:
            return true
        }
    }
    
    var displayText: String {
        switch self {
        case .notSubscribed:
            return "Free"
        case .trial(let days):
            return "Trial (\(days) days left)"
        case .subscribed:
            return "RideReady Pro"
        }
    }
}

// MARK: - Subscription Error

enum SubscriptionError: LocalizedError {
    case productLoadFailed(String)
    case purchaseFailed(String)
    case restoreFailed(String)
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .productLoadFailed(let message):
            return "Failed to load products: \(message)"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        case .verificationFailed:
            return "Transaction verification failed"
        }
    }
}
