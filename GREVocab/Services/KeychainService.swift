import Foundation
import Security
import os.log

// MARK: - Keychain Service for Secure Storage
/// Provides secure storage for sensitive data like premium status
/// This makes it harder to tamper with on jailbroken devices
final class KeychainService {
    static let shared = KeychainService()

    private let logger = Logger(subsystem: "com.ganguly.GREVocab", category: "Keychain")

    // Keychain identifiers
    private enum KeychainKey: String {
        case premiumStatus = "com.ganguly.GREVocab.premium.status"
        case premiumExpiry = "com.ganguly.GREVocab.premium.expiry"
        case purchaseToken = "com.ganguly.GREVocab.premium.token"
    }

    private init() {}

    // MARK: - Premium Status Management

    /// Store premium status securely in Keychain
    /// - Parameters:
    ///   - isPremium: Whether user has premium access
    ///   - expiryDate: Optional expiry date for the subscription
    ///   - transactionId: Optional transaction ID from StoreKit for verification
    func storePremiumStatus(isPremium: Bool, expiryDate: Date? = nil, transactionId: String? = nil) {
        // Store premium flag
        let premiumValue = isPremium ? "1" : "0"
        save(key: .premiumStatus, value: premiumValue)

        // Store expiry date if provided
        if let expiry = expiryDate {
            let expiryString = String(expiry.timeIntervalSince1970)
            save(key: .premiumExpiry, value: expiryString)
        } else {
            delete(key: .premiumExpiry)
        }

        // Store transaction ID for verification
        if let transactionId = transactionId {
            save(key: .purchaseToken, value: transactionId)
        }

        logger.info("Premium status stored: \(isPremium)")
    }

    /// Retrieve premium status from Keychain
    /// - Returns: Tuple of (isPremium, expiryDate) or nil if not found
    func getPremiumStatus() -> (isPremium: Bool, expiryDate: Date?)? {
        guard let premiumValue = read(key: .premiumStatus) else {
            return nil
        }

        let isPremium = premiumValue == "1"

        var expiryDate: Date? = nil
        if let expiryString = read(key: .premiumExpiry),
           let expiryInterval = Double(expiryString) {
            expiryDate = Date(timeIntervalSince1970: expiryInterval)
        }

        return (isPremium, expiryDate)
    }

    /// Check if premium is valid (not expired)
    func isPremiumValid() -> Bool {
        guard let status = getPremiumStatus() else {
            return false
        }

        guard status.isPremium else {
            return false
        }

        // Check expiry if set
        if let expiryDate = status.expiryDate {
            return expiryDate > Date()
        }

        // No expiry means lifetime
        return true
    }

    /// Get stored transaction ID for verification
    func getStoredTransactionId() -> String? {
        return read(key: .purchaseToken)
    }

    /// Clear all premium data from Keychain
    func clearPremiumStatus() {
        delete(key: .premiumStatus)
        delete(key: .premiumExpiry)
        delete(key: .purchaseToken)
        logger.info("Premium status cleared from Keychain")
    }

    // MARK: - Low-level Keychain Operations

    private func save(key: KeychainKey, value: String) {
        guard let data = value.data(using: .utf8) else {
            logger.error("Failed to encode value for key: \(key.rawValue)")
            return
        }

        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            logger.error("Keychain save failed for key \(key.rawValue): \(status)")
        }
    }

    private func read(key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Premium Verification Helper
extension KeychainService {
    /// Verify that local premium status matches Keychain
    /// Call this on app launch to detect tampering
    func verifyPremiumIntegrity(localIsPremium: Bool, localExpiryDate: Date?) -> Bool {
        guard let keychainStatus = getPremiumStatus() else {
            // No keychain data - could be first launch or cleared
            // Store current status to sync
            storePremiumStatus(isPremium: localIsPremium, expiryDate: localExpiryDate)
            return true
        }

        // Check for mismatch (potential tampering)
        if keychainStatus.isPremium != localIsPremium {
            logger.warning("Premium status mismatch detected! Keychain: \(keychainStatus.isPremium), Local: \(localIsPremium)")

            // In a real app, you might want to:
            // 1. Re-verify with StoreKit
            // 2. Restore purchases
            // 3. Default to the more restrictive status (Keychain)
            return false
        }

        return true
    }
}
