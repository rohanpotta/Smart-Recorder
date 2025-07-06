import Testing
import Foundation
@testable import Smart_Recorder

@Suite("KeychainHelper Tests")
struct KeychainHelperTests {

    let testKey = "testAPIKey"
    let testValue = "12345-abcde-67890"

    @Test("Save and Get API Key")
    func testSaveAndGet() {
        // 1. Save the key
        let saveResult = KeychainHelper.shared.save(value: testValue, for: testKey)
        #expect(saveResult == true)

        // 2. Get the key
        let retrievedValue = KeychainHelper.shared.get(key: testKey)
        #expect(retrievedValue == testValue)
        
        // 3. Clean up
        KeychainHelper.shared.delete(key: testKey)
        
        // 4. Verify deletion
        let deletedValue = KeychainHelper.shared.get(key: testKey)
        #expect(deletedValue == nil)
    }
    
    @Test("API Key Validation")
    func testAPIKeyValidation() {
        #expect(KeychainHelper.shared.isValidAPIKey("a-valid-key-with-more-than-32-characters-long"))
        #expect(!KeychainHelper.shared.isValidAPIKey("short"))
        #expect(!KeychainHelper.shared.isValidAPIKey(""))
    }
}