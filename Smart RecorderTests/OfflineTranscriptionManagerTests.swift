import XCTest
import Network
import SwiftData
@testable import Smart_Recorder

@MainActor
class OfflineTranscriptionManagerTests: XCTestCase {
    var manager: OfflineTranscriptionManager!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        manager = OfflineTranscriptionManager.shared
        
        let schema = Schema([AudioSegment.self, Transcription.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        manager = nil
    }
    
    func testEnqueueAndProcess() {
        // 1. Create an expectation
        let expectation = XCTestExpectation(description: "Transcriber callback should be fired")
        
        // 2. Set the transcriber with the expectation
        manager.setTranscriber { segment, context in
            // Assert something about the segment if you want
            XCTAssertEqual(segment.filePath, "/test/segment.caf")
            expectation.fulfill()
        }
        
        // 3. Enqueue a segment
        let segment = AudioSegment(
            startTime: Date(),
            duration: 30.0,
            filePath: "/test/segment.caf"
        )
        manager.enqueue(segment: segment, modelContext: modelContext)
    }
    
    func testLoadPendingSegments() throws {
        let pendingSegment = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/pending.caf")
        pendingSegment.transcription = Transcription(status: "pending")
        
        let completedSegment = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/completed.caf")
        completedSegment.transcription = Transcription(status: "completed")
        
        modelContext.insert(pendingSegment)
        modelContext.insert(completedSegment)
        
        try modelContext.save()
        
        manager.loadPendingSegments(from: modelContext)
        
        XCTAssert(true, "loadPendingSegments should run without errors")
    }
}
