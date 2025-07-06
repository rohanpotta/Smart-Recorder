import Testing
import Foundation
import SwiftData
@testable import Smart_Recorder

@Suite("StorageManager Tests")
struct StorageManagerTests {

    @Test("Clear Transcribed Audio Files Logic")
    @MainActor
    func testClearTranscribedAudioFiles() async throws {
        // 1. Setup in-memory SwiftData container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: AudioSegment.self, configurations: config)
        let modelContext = container.mainContext

        // 2. Create dummy audio files
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        
        let completedURL = tempDir.appendingPathComponent(UUID().uuidString)
        let pendingURL = tempDir.appendingPathComponent(UUID().uuidString)
        
        fileManager.createFile(atPath: completedURL.path, contents: Data("completed".utf8))
        fileManager.createFile(atPath: pendingURL.path, contents: Data("pending".utf8))

        // 3. Create and insert segments
        let completedSegment = AudioSegment(startTime: Date(), duration: 30, filePath: completedURL.path)
        completedSegment.transcription = Transcription(text: "Test", status: "completed")
        modelContext.insert(completedSegment)
        
        let pendingSegment = AudioSegment(startTime: Date(), duration: 30, filePath: pendingURL.path)
        pendingSegment.transcription = Transcription(text: "", status: "pending")
        modelContext.insert(pendingSegment)
        
        try modelContext.save()

        // 4. Run the cleanup function
        StorageManager.shared.clearTranscribedAudioFiles(modelContext: modelContext)

        // 5. Assertions
        #expect(!fileManager.fileExists(atPath: completedURL.path)) // Completed should be deleted
        #expect(fileManager.fileExists(atPath: pendingURL.path))    // Pending should still exist

        // Clean up dummy file
        try? fileManager.removeItem(at: pendingURL)
    }
}