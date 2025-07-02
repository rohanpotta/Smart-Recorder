//
//  AudioRecorder.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/2/25.
//

import Foundation
import AVFoundation
import SwiftData

class AudioRecorder: ObservableObject {
    private var engine = AVAudioEngine()
    private var file: AVAudioFile?
    private var session = AVAudioSession.sharedInstance()
    
    private var recordingSession: RecordingSession?
    private var segmentTimer: Timer?
    
    private let segmentDuration: TimeInterval = 30
    
    @Published var isRecording = false
    
    func startRecording(modelContext: ModelContext) {
        isRecording = true
        
        // Insert dummy test data
        let testSession = RecordingSession()
        modelContext.insert(testSession)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    func stopRecording() {
        // Stop engine
        // Invalidate timer
        // Save final segment
        isRecording = false
    }

    private func saveSegment() {
        // Export audio to file
        // Create AudioSegment
        // Save to modelContext
    }
}

