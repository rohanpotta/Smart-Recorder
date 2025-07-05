import Foundation
import Security

/// Minimal wrapper around the iOS Key-chain for small string secrets.
final class KeychainHelper {
    static let shared = KeychainHelper(); private init() {}

    @discardableResult
    func save(value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      key,
            kSecValueData as String:        data,
            kSecAttrAccessible as String:   kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)            // overwrite if exists
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrAccount as String:     key,
            kSecReturnData as String:      kCFBooleanTrue!,
            kSecMatchLimit as String:      kSecMatchLimitOne
        ]
        var ref: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &ref) == errSecSuccess,
              let data = ref as? Data,
              let str  = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  key
        ]
        SecItemDelete(query as CFDictionary)
    }
}