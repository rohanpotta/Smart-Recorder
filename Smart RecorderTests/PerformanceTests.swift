import XCTest
import SwiftData
@testable import Smart_Recorder

@MainActor
class PerformanceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let schema = Schema([RecordingSession.self, AudioSegment.self, Transcription.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
    }
    
    func testLargeDatasetCreation() {
        measure {
            for i in 0..<1000 {
                let session = RecordingSession(
                    date: Date().addingTimeInterval(TimeInterval(i)),
                    filePath: "/test/session\(i)"
                )
                modelContext.insert(session)
            }
            
            try? modelContext.save()
        }
    }
    
    func testLargeDatasetQuery() throws {
        // Create test data
        for i in 0..<1000 {
            let session = RecordingSession(
                date: Date().addingTimeInterval(TimeInterval(i)),
                filePath: "/test/session\(i)"
            )
            modelContext.insert(session)
        }
        try modelContext.save()
        
        // Measure query performance
        measure {
            let fetchRequest = FetchDescriptor<RecordingSession>()
            let sessions = try? modelContext.fetch(fetchRequest)
            XCTAssertEqual(sessions?.count, 1000)
        }
    }
    
    func testSessionWithManySegments() {
        let session = RecordingSession(date: Date(), filePath: "/test/large-session")
        
        measure {
            for i in 0..<100 {
                let segment = AudioSegment(
                    startTime: Date().addingTimeInterval(TimeInterval(i * 30)),
                    duration: 30.0,
                    filePath: "/test/segment\(i).caf"
                )
                segment.transcription = Transcription(
                    text: "Transcription for segment \(i)",
                    status: "completed"
                )
                session.segments.append(segment)
            }
            
            // Test computed properties with large dataset
            _ = session.totalDuration
            _ = session.transcriptionStatus
            _ = session.fullTranscriptionText
        }
    }
    
    func testTranscriptionTextConcatenation() {
        let session = RecordingSession(date: Date(), filePath: "/test/concat")
        
        for i in 0..<500 {
            let segment = AudioSegment(
                startTime: Date().addingTimeInterval(TimeInterval(i * 30)),
                duration: 30.0,
                filePath: "/test/segment\(i).caf"
            )
            segment.transcription = Transcription(
                text: "This is segment \(i) with some text content. ",
                status: "completed"
            )
            session.segments.append(segment)
        }
        
        measure {
            _ = session.fullTranscriptionText
        }
    }
    
    func testMemoryUsageWithLargeDataset() {
        measure {
            var sessions: [RecordingSession] = []
            
            for i in 0..<1000 {
                let session = RecordingSession(
                    date: Date().addingTimeInterval(TimeInterval(i)),
                    filePath: "/test/session\(i)"
                )
                
                // Add multiple segments per session
                for j in 0..<10 {
                    let segment = AudioSegment(
                        startTime: Date().addingTimeInterval(TimeInterval(j * 30)),
                        duration: 30.0,
                        filePath: "/test/session\(i)_segment\(j).caf"
                    )
                    segment.transcription = Transcription(
                        text: "Test transcription for session \(i) segment \(j)",
                        status: "completed"
                    )
                    session.segments.append(segment)
                }
                
                sessions.append(session)
            }
            
            // Clear references
            sessions.removeAll()
        }
    }
}
