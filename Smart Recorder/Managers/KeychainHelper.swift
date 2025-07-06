import Foundation
import Security

final class KeychainHelper {
    static let shared = KeychainHelper(); private init() {}

    @discardableResult
    func save(value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      key,
            kSecValueData as String:        data,
            // More secure: only accessible when device is unlocked, stays on this device only
            kSecAttrAccessible as String:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly
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
    
    // Optional: Add validation for API keys
    func isValidAPIKey(_ key: String) -> Bool {
        // Basic validation - AssemblyAI keys are typically 32+ characters
        return key.count >= 32 && !key.isEmpty
    }// Add a method specifically for API tokens with a consistent key name
    func saveAPIToken(_ token: String) -> Bool {
        return save(value: token, for: "transcription_api_token")
    }
    
    func getAPIToken() -> String? {
        return get(key: "transcription_api_token")
    }
    
    func clearAPIToken() {
        delete(key: "transcription_api_token")
    }
}
