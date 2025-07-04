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
        NavigationStack {
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
                        let totalDuration = session.segments.reduce(0.0) { $0 + $1.duration }
                        let completedCount = session.segments.filter { $0.transcription?.status == "completed" }.count
                        let failedCount = session.segments.filter { $0.transcription?.status == "failed" }.count
                        let totalSegments = session.segments.count

                        let transcriptionStatus: String = {
                            if failedCount > 0 {
                                return "❌ Failed"
                            } else if completedCount == totalSegments && totalSegments > 0 {
                                return "✅ Completed"
                            } else if totalSegments == 0 {
                                return "— No Segments"
                            } else {
                                return "⏳ In Progress"
                            }
                        }()

                        NavigationLink(destination: SessionView(session: session)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Session on \(session.date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.headline)

                                Text("Duration: \(String(format: "%.1f", totalDuration)) seconds")
                                    .font(.subheadline)

                                Text("Segments: \(totalSegments)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Text("Transcription: \(transcriptionStatus)")
                                    .font(.subheadline)
                                    .foregroundColor(transcriptionStatus.contains("✅") ? .green :
                                                    transcriptionStatus.contains("❌") ? .red : .orange)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Smart Recorder")
        }
    }
}
