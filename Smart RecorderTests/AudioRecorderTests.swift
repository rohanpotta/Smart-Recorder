import XCTest
import AVFoundation
import SwiftData
@testable import Smart_Recorder

@MainActor
class AudioRecorderTests: XCTestCase {
    var audioRecorder: AudioRecorder!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        audioRecorder = AudioRecorder()
        
        let schema = Schema([RecordingSession.self, AudioSegment.self, Transcription.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
    }
    
    override func tearDown() async throws {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording(modelContext: modelContext)
        }
        audioRecorder = nil
        modelContainer = nil
        modelContext = nil
    }
    
    func testRecordingQualitySettings() {
        audioRecorder.recordingQuality = .low
        XCTAssertEqual(audioRecorder.recordingQuality.sampleRate, 12_000)
        
        audioRecorder.recordingQuality = .medium
        XCTAssertEqual(audioRecorder.recordingQuality.sampleRate, 24_000)
        
        audioRecorder.recordingQuality = .high
        XCTAssertEqual(audioRecorder.recordingQuality.sampleRate, 44_100)
    }
    
    func testInitialState() {
        XCTAssertFalse(audioRecorder.isRecording)
        XCTAssertEqual(audioRecorder.audioLevel, 0.0)
        XCTAssertEqual(audioRecorder.recordingQuality, .high)
    }
    
    func testTranscriptionApply() {
        let segment = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/segment.caf")
        let transcriptText = "This is a test transcription"
        
        audioRecorder.applyTranscription(transcriptText, to: segment, modelContext: modelContext)
        
        XCTAssertEqual(segment.transcription?.text, transcriptText)
        XCTAssertEqual(segment.transcription?.status, "completed")
    }
    
    func testTranscriptionFailure() {
        let segment = AudioSegment(startTime: Date(), duration: 30.0, filePath: "/test/segment.caf")
        segment.transcription = Transcription(status: "pending")
        
        audioRecorder.markTranscriptionFailed(for: segment, modelContext: modelContext)
        
        XCTAssertEqual(segment.transcription?.status, "failed")
    }
}