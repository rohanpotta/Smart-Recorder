//
//  Smart_RecorderApp.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/2/25.
//

import SwiftUI
import SwiftData

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
                .environmentObject(recorder)            // pass recorder as EnvironmentObject
                .environment(\.modelContext, sharedModelContainer.mainContext)  // pass modelContext
        }
    }
}
