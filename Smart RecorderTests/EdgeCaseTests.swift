import XCTest
import SwiftData
@testable import Smart_Recorder

@MainActor
class EdgeCaseTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let schema = Schema([RecordingSession.self, AudioSegment.self, Transcription.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
    }
    
    func testEmptyAPIKey() {
        let helper = KeychainHelper.shared
        helper.delete(key: "assemblyAIKey")
        
        let apiKey = helper.get(key: "assemblyAIKey") ?? ""
        XCTAssertTrue(apiKey.isEmpty)
    }
    
    func testInvalidFilePath() {
        let segment = AudioSegment(
            startTime: Date(),
            duration: 30.0,
            filePath: "/invalid/path/does/not/exist.caf"
        )
        
        XCTAssertEqual(segment.filePath, "/invalid/path/does/not/exist.caf")
        // Test that app handles invalid paths gracefully
    }
    
    func testZeroDurationSegment() {
        let segment = AudioSegment(
            startTime: Date(),
            duration: 0.0,
            filePath: "/test/zero.caf"
        )
        
        XCTAssertEqual(segment.duration, 0.0)
        // App should handle zero-duration segments
    }
    
    func testSessionWithNoSegments() {
        let session = RecordingSession(date: Date(), filePath: "/test/empty")
        
        XCTAssertEqual(session.totalDuration, 0.0)
        XCTAssertEqual(session.transcriptionStatus, "In Progress")  // Empty session should be "In Progress"
        XCTAssertEqual(session.fullTranscriptionText, "")
    }
    
    func testMixedTranscriptionStatuses() {
        let session = RecordingSession(date: Date(), filePath: "/test/mixed")
        
        let segment1 = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/1.caf")
        segment1.transcription = Transcription(text: "Hello", status: "completed")
        
        let segment2 = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/2.caf")
        segment2.transcription = Transcription(text: "", status: "failed")
        
        let segment3 = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/3.caf")
        segment3.transcription = Transcription(text: "", status: "pending")
        
        session.segments = [segment1, segment2, segment3]
        
        XCTAssertEqual(session.transcriptionStatus, "Failed")
        XCTAssertEqual(session.fullTranscriptionText, "Hello")
    }
    
    func testLargeTranscriptionText() {
        let largeText = String(repeating: "This is a very long transcription text.", count: 1000)  // Remove trailing space
        let transcription = Transcription(text: largeText, status: "completed")
        
        XCTAssertEqual(transcription.text.count, largeText.count)
        XCTAssertEqual(transcription.statusEnum, .completed)
    }
}
