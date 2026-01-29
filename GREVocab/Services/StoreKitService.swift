import Foundation
import StoreKit

// MARK: - StoreKit Service for In-App Purchases
@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    // Product identifiers - must match App Store Connect configuration
    enum ProductID: String, CaseIterable {
        case monthlySubscription = "com.ganguly.GREVocab.premium.monthly"
        case yearlySubscription = "com.ganguly.GREVocab.premium.yearly"
    }

    // Published state
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products on init
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Load products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
            print("StoreKit Error: Failed to load products - \(error)")
        }
    }

    // MARK: - Purchase

    /// Purchase a product
    /// - Parameter product: The product to purchase
    /// - Returns: Transaction if successful, nil otherwise
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // IMPORTANT: Verify the transaction with Apple
                let transaction = try checkVerified(verification)

                // Update purchased products
                await updatePurchasedProducts()

                // Finish the transaction
                await transaction.finish()

                isLoading = false
                return transaction

            case .userCancelled:
                isLoading = false
                return nil

            case .pending:
                // Transaction is pending (e.g., Ask to Buy)
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return nil

            @unknown default:
                isLoading = false
                errorMessage = "Unknown purchase result"
                return nil
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Transaction Verification

    /// Verify transaction signature with Apple
    /// - Parameter result: The verification result from StoreKit
    /// - Returns: Verified transaction
    /// - Throws: StoreKitError if verification fails
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            // SECURITY: Transaction failed verification - do NOT grant access
            print("StoreKit Security: Transaction verification failed - \(error)")
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Entitlement Updates

    /// Update the list of purchased products by checking current entitlements
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        // Check current entitlements (active subscriptions)
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Only include if not expired and not revoked
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("StoreKit: Failed to verify entitlement - \(error)")
            }
        }

        purchasedProductIDs = purchased
    }

    // MARK: - Transaction Listener

    /// Listen for transaction updates (renewals, refunds, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)

                    if let transaction = transaction {
                        await self?.updatePurchasedProducts()
                        await transaction.finish()
                    }
                } catch {
                    print("StoreKit: Transaction update verification failed - \(error)")
                }
            }
        }
    }

    // MARK: - Convenience

    /// Check if user has active premium subscription
    var hasPremiumEntitlement: Bool {
        !purchasedProductIDs.isEmpty
    }

    /// Get product by ID
    func product(for productID: ProductID) -> Product? {
        products.first { $0.id == productID.rawValue }
    }

    /// Restore purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            // This will trigger the transaction listener for any restorable purchases
            try await AppStore.sync()
            await updatePurchasedProducts()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("StoreKit: Restore failed - \(error)")
        }
    }
}

// MARK: - Custom Errors

enum StoreKitError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed(String)

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed. Please contact support if this persists."
        case .productNotFound:
            return "Product not found. Please try again later."
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        }
    }
}
