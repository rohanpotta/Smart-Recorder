import Testing
import Foundation
import SwiftData
@testable import Smart_Recorder

@Suite("Smart Recorder Core Tests")
struct Smart_RecorderTests {

    // MARK: - Model Logic Tests

    @Test("Model Computed Properties")
    func testModelComputedProperties() {
        let session = RecordingSession(filePath: "test.caf")

        let completedSegment = AudioSegment(startTime: Date(), duration: 30.0, filePath: "s1.caf")
        completedSegment.transcription = Transcription(text: "Hello", status: "completed")

        let pendingSegment = AudioSegment(startTime: Date(), duration: 15.0, filePath: "s2.caf")
        pendingSegment.transcription = Transcription(status: "pending")

        session.segments = [completedSegment, pendingSegment]

        #expect(session.totalDuration == 45.0)
        #expect(session.transcriptionStatus == "In Progress")
        #expect(session.fullTranscriptionText == "Hello")
    }

    // MARK: - KeychainHelper Tests

    @Test("Keychain Save, Get, and Delete")
    func testKeychain() {
        let key = "test-api-key"
        let value = "secret-token-123"

        // Save
        let didSave = KeychainHelper.shared.save(value: value, for: key)
        #expect(didSave)

        // Get
        let retrievedValue = KeychainHelper.shared.get(key: key)
        #expect(retrievedValue == value)

        // Delete
        KeychainHelper.shared.delete(key: key)
        let deletedValue = KeychainHelper.shared.get(key: key)
        #expect(deletedValue == nil)
    }

    // MARK: - StorageManager Tests
    
    @Test("StorageManager Cleanup")
    @MainActor
    func testStorageManagerCleanup() async throws {
        // Setup in-memory context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: AudioSegment.self, configurations: config)
        let modelContext = container.mainContext

        // Create dummy files
        let fm = FileManager.default
        let dir = fm.temporaryDirectory
        let completedURL = dir.appendingPathComponent("completed.caf")
        let pendingURL = dir.appendingPathComponent("pending.caf")
        fm.createFile(atPath: completedURL.path, contents: Data("1".utf8))
        fm.createFile(atPath: pendingURL.path, contents: Data("2".utf8))

        // Create and insert segments
        let completedSegment = AudioSegment(startTime: Date(), duration: 10, filePath: completedURL.path)
        completedSegment.transcription = Transcription(text: "Done", status: "completed")
        modelContext.insert(completedSegment)
        
        let pendingSegment = AudioSegment(startTime: Date(), duration: 10, filePath: pendingURL.path)
        pendingSegment.transcription = Transcription(status: "pending")
        modelContext.insert(pendingSegment)
        
        try modelContext.save()

        // Run cleanup
        StorageManager.shared.clearTranscribedAudioFiles(modelContext: modelContext)

        // Assertions
        #expect(!fm.fileExists(atPath: completedURL.path))
        #expect(fm.fileExists(atPath: pendingURL.path))

        // Cleanup
        try? fm.removeItem(at: pendingURL)
    }
}