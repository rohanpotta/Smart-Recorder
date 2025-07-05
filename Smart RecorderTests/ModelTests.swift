import XCTest
import SwiftData
@testable import Smart_Recorder

@MainActor
class ModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        // In-memory container for testing
        let schema = Schema([RecordingSession.self, AudioSegment.self, Transcription.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
    }
    
    func testRecordingSessionCreation() {
        let session = RecordingSession(date: Date(), filePath: "/test/path")
        
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.filePath, "/test/path")
        XCTAssertEqual(session.segments.count, 0)
        XCTAssertNotNil(session.createdAt)
    }
    
    func testAudioSegmentCreation() {
        let segment = AudioSegment(
            startTime: Date(),
            duration: 30.0,
            filePath: "/test/segment.caf"
        )
        
        XCTAssertNotNil(segment.id)
        XCTAssertEqual(segment.duration, 30.0)
        XCTAssertEqual(segment.filePath, "/test/segment.caf")
        XCTAssertNotNil(segment.createdAt)
    }
    
    func testTranscriptionCreation() {
        let transcription = Transcription(
            text: "Test transcription",
            status: "completed",
            remoteID: "remote-123"
        )
        
        XCTAssertEqual(transcription.text, "Test transcription")
        XCTAssertEqual(transcription.statusEnum, .completed)
        XCTAssertEqual(transcription.remoteID, "remote-123")
    }
    
    func testSessionWithSegments() {
        let session = RecordingSession(date: Date(), filePath: "/test/session")
        let segment1 = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/1.caf")
        let segment2 = AudioSegment(startTime: Date(), duration: 25.0, filePath: "/test/2.caf")
        
        session.segments = [segment1, segment2]
        
        XCTAssertEqual(session.totalDuration, 55.0)
        XCTAssertEqual(session.segments.count, 2)
    }
    
    func testTranscriptionStatus() {
        let session = RecordingSession(date: Date(), filePath: "/test")
        let segment1 = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/1.caf")
        let segment2 = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/2.caf")
        
        segment1.transcription = Transcription(text: "Hello", status: "completed")
        segment2.transcription = Transcription(text: "World", status: "completed")
        
        session.segments = [segment1, segment2]
        
        XCTAssertEqual(session.transcriptionStatus, "Completed")
        XCTAssertEqual(session.fullTranscriptionText, "Hello World")
    }
    
    func testSwiftDataPersistence() throws {
        let session = RecordingSession(date: Date(), filePath: "/test/session")
        let segment = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/segment.caf")
        let transcription = Transcription(text: "Test text", status: "completed")
        
        segment.transcription = transcription
        session.segments = [segment]
        
        modelContext.insert(session)
        modelContext.insert(segment)
        modelContext.insert(transcription)
        
        try modelContext.save()
        
        let fetchRequest = FetchDescriptor<RecordingSession>()
        let fetchedSessions = try modelContext.fetch(fetchRequest)
        
        XCTAssertEqual(fetchedSessions.count, 1)
        XCTAssertEqual(fetchedSessions.first?.segments.count, 1)
        XCTAssertEqual(fetchedSessions.first?.segments.first?.transcription?.text, "Test text")
    }
}