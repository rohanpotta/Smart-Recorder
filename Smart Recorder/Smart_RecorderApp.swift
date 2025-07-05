//
//  Smart_RecorderApp.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/2/25.
//

import SwiftUI
import SwiftData
import Foundation

@main
struct Smart_RecorderApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RecordingSession.self,
            AudioSegment.self,
            Transcription.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // Create a single shared AudioRecorder instance
    @StateObject private var recorder = AudioRecorder()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(recorder)
                .onAppear {
                    OfflineTranscriptionManager.shared.setTranscriber { segment, ctx in
                        recorder.transcribeSegment(segment, modelContext: ctx)
                    }
                    // DEV convenience: pull from env var if key not stored yet
                    if KeychainHelper.shared.get(key: "assemblyAIKey") == nil,
                       let envKey = ProcessInfo.processInfo.environment["ASSEMBLY_AI_KEY"],
                       !envKey.isEmpty {
                        KeychainHelper.shared.save(value: envKey, for: "assemblyAIKey")
                    }
                    OfflineTranscriptionManager.shared.loadPendingSegments(from: sharedModelContainer.mainContext)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // App going to background - save current recording state
                    if recorder.isRecording {
                        recorder.stopRecording(modelContext: sharedModelContainer.mainContext)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    // App terminating - ensure recording stops (backup)
                    if recorder.isRecording {
                        recorder.stopRecording(modelContext: sharedModelContainer.mainContext)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
