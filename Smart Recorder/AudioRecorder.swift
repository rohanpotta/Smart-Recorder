//
//  AudioRecorder.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/2/25.
//

import AVFoundation
import SwiftData
import Combine

class AudioRecorder: ObservableObject {
    private let engine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()
    private var audioFile: AVAudioFile?
    private var segmentTimer: Timer?
    private let segmentDuration: TimeInterval = 30
    private var currentSession: RecordingSession?
    private var currentSegmentFileURL: URL?
    private var currentSegmentStartTime: Date?

    @Published var isRecording = false

    func startRecording(modelContext: ModelContext) {
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else {
                print("Microphone permission denied")
                return
            }

            Task {
                do {
                    try self.session.setCategory(.record, options: [.mixWithOthers, .allowBluetooth])
                    try self.session.setActive(true)

                    self.currentSession = RecordingSession(date: Date(), filePath: "") // filePath will be updated later

                    try self.startNewSegment(modelContext: modelContext)

                    self.engine.prepare()
                    try self.engine.start()
                    print("Engine started")

                    DispatchQueue.main.async {
                        self.isRecording = true
                    }

                } catch {
                    print("Failed to start recording: \(error)")
                }
            }
        }
    }

    private func startNewSegment(modelContext: ModelContext) throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".caf")
        self.currentSegmentFileURL = fileURL
        self.currentSegmentStartTime = Date()

        let inputNode = self.engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        self.audioFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)

        inputNode.removeTap(onBus: 0) // Remove previous tap if any
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            do {
                try self.audioFile?.write(from: buffer)
                print("Writing buffer...")
            } catch {
                print("Error writing buffer: \(error)")
            }
        }

        // Update currentSession filePath if empty (first segment)
        if self.currentSession?.filePath.isEmpty == true {
            self.currentSession?.filePath = fileURL.path
        }

        // Schedule timer to split after 30 seconds
        segmentTimer?.invalidate()
        segmentTimer = Timer.scheduledTimer(withTimeInterval: segmentDuration, repeats: false) { _ in
            self.finishCurrentSegmentAndStartNew(modelContext: modelContext)
        }
    }
    
    private func finishCurrentSegmentAndStartNew(modelContext: ModelContext) {
        guard let fileURL = currentSegmentFileURL,
              let segmentStart = currentSegmentStartTime,
              let session = currentSession else {
            print("Missing info to finish segment")
            return
        }

        // Calculate segment duration
        let segmentDuration = Date().timeIntervalSince(segmentStart)

        // Create and add segment
        let segment = AudioSegment(startTime: segmentStart, duration: segmentDuration, filePath: fileURL.path)
        session.segments.append(segment)

        // Save or update session and segment
        modelContext.insert(session)
        modelContext.insert(segment)
        try? modelContext.save()

        print("Saved segment starting at \(segmentStart) duration: \(segmentDuration)")

        // Start new segment recording
        do {
            try startNewSegment(modelContext: modelContext)
        } catch {
            print("Failed to start new segment: \(error)")
        }
    }

    func stopRecording(modelContext: ModelContext) {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        segmentTimer?.invalidate()
        segmentTimer = nil

        DispatchQueue.main.async {
            self.isRecording = false

            guard let session = self.currentSession else {
                print("No active session on stop")
                return
            }

            // If the current segment is still recording, save it as well
            if let fileURL = self.currentSegmentFileURL, let segmentStart = self.currentSegmentStartTime {
                let segmentDuration = Date().timeIntervalSince(segmentStart)
                let segment = AudioSegment(startTime: segmentStart, duration: segmentDuration, filePath: fileURL.path)
                session.segments.append(segment)
                modelContext.insert(segment)
            }

            modelContext.insert(session)
            try? modelContext.save()

            print("Recording stopped and session saved with \(session.segments.count) segments")

            self.currentSession = nil
            self.currentSegmentFileURL = nil
            self.currentSegmentStartTime = nil
        }
    }

    private func startSegmentTimer(modelContext: ModelContext, fileURL: URL) {
        segmentTimer = Timer.scheduledTimer(withTimeInterval: segmentDuration, repeats: true) { _ in
            // TODO: Save segment to SwiftData and start a new file
            print("Segment timer fired - save audio chunk")
        }
    }
}
