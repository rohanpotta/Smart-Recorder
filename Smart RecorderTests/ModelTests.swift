import Testing
import Foundation
@testable import Smart_Recorder

@Suite("Data Model Tests")
struct ModelTests {

    @Test("RecordingSession Computed Properties")
    func testRecordingSessionComputedProperties() throws {
        // 1. Create a session
        let session = RecordingSession(filePath: "test.caf")

        // 2. Create segments with different statuses
        let completedSegment1 = AudioSegment(startTime: Date(), duration: 30.0, filePath: "segment1.caf")
        completedSegment1.transcription = Transcription(text: "Hello", status: "completed")

        let completedSegment2 = AudioSegment(startTime: Date(), duration: 25.5, filePath: "segment2.caf")
        completedSegment2.transcription = Transcription(text: "world", status: "completed")

        let failedSegment = AudioSegment(startTime: Date(), duration: 10.0, filePath: "segment3.caf")
        failedSegment.transcription = Transcription(text: "", status: "failed")
        
        let pendingSegment = AudioSegment(startTime: Date(), duration: 15.0, filePath: "segment4.caf")
        pendingSegment.transcription = Transcription(text: "", status: "pending")

        // 3. Test totalDuration
        session.segments = [completedSegment1, completedSegment2]
        #expect(session.totalDuration == 55.5)

        // 4. Test transcriptionStatus
        session.segments = [completedSegment1, completedSegment2]
        #expect(session.transcriptionStatus == "Completed")
        
        session.segments = [completedSegment1, failedSegment]
        #expect(session.transcriptionStatus == "Failed")
        
        session.segments = [completedSegment1, pendingSegment]
        #expect(session.transcriptionStatus == "In Progress")

        // 5. Test fullTranscriptionText
        session.segments = [completedSegment2, completedSegment1] // Test sorting
        #expect(session.fullTranscriptionText == "Hello world")
    }
}