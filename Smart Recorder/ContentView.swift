//
//  ContentView.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/2/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [RecordingSession]

    @StateObject private var recorder = AudioRecorder()

    var body: some View {
        VStack {
            Button(recorder.isRecording ? "Stop Recording" : "Start Recording") {
                if recorder.isRecording {
                    recorder.stopRecording(modelContext: modelContext)
                } else {
                    recorder.startRecording(modelContext: modelContext)
                }
            }
            .padding()
            .background(recorder.isRecording ? Color.red : Color.green)
            .foregroundColor(.white)
            .clipShape(Capsule())

            List {
                ForEach(sessions) { session in
                    VStack(alignment: .leading) {
                        Text("Session on \(session.date.formatted(date: .abbreviated, time: .shortened))")
                        Text("Segments: \(session.segments.count)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
    }
}
