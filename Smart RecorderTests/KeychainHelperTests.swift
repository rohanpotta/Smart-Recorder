import XCTest
@testable import Smart_Recorder

class KeychainHelperTests: XCTestCase {
    let helper = KeychainHelper.shared
    let testKey = "test-key"
    let testValue = "test-value-123"
    
    override func tearDown() {
        helper.delete(key: testKey)
    }
    
    func testSaveAndRetrieveValue() {
        let saveResult = helper.save(value: testValue, for: testKey)
        XCTAssertTrue(saveResult)
        
        let retrievedValue = helper.get(key: testKey)
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    func testOverwriteExistingValue() {
        let newValue = "new-test-value-456"
        
        helper.save(value: testValue, for: testKey)
        helper.save(value: newValue, for: testKey)
        
        let retrievedValue = helper.get(key: testKey)
        XCTAssertEqual(retrievedValue, newValue)
    }
    
    func testDeleteValue() {
        helper.save(value: testValue, for: testKey)
        helper.delete(key: testKey)
        
        let retrievedValue = helper.get(key: testKey)
        XCTAssertNil(retrievedValue)
    }
    
    func testRetrieveNonExistentValue() {
        let retrievedValue = helper.get(key: "non-existent-key")
        XCTAssertNil(retrievedValue)
    }
}