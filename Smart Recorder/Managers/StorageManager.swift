import Foundation
import SwiftData

class StorageManager {
    static let shared = StorageManager()
    
    @MainActor
    func clearTranscribedAudioFiles(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<AudioSegment>(
            predicate: #Predicate { segment in
                segment.transcription?.status == "completed"
            }
        )
        
        do {
            let transcribedSegments = try modelContext.fetch(descriptor)
            var deletedCount = 0
            
            for segment in transcribedSegments {
                let fileURL = URL(fileURLWithPath: segment.filePath)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        try FileManager.default.removeItem(at: fileURL)
                        print("🗑️ Deleted audio file: \(fileURL.lastPathComponent)")
                        deletedCount += 1
                    } catch {
                        print("🚨 Failed to delete audio file: \(error)")
                    }
                }
            }
            
            print("✅ Successfully deleted \(deletedCount) transcribed audio files.")
            
        } catch {
            print("🚨 Failed to fetch transcribed segments for deletion: \(error)")
        }
    }
}