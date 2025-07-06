//
//  SessionView.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/4/25.
//

import SwiftUI

struct SessionView: View {
    let session: RecordingSession
    
    @State private var fullTranscript: String = ""
    @State private var isLoading = false
    
    // Cache computed values to avoid recalculating
    private var totalDuration: Double {
        session.segments.reduce(0.0) { $0 + $1.duration }
    }
    
    private var segmentCount: Int {
        session.segments.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("📄 Full Transcription")
                    .font(.title2)
                    .bold()

                if isLoading {
                    ProgressView("Loading transcript...")
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else if fullTranscript.isEmpty {
                    Text("Transcription is empty.")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    Text(fullTranscript)
                        .padding(.top, 4)
                        .textSelection(.enabled)
                }

                Divider()

                Text("📌 Session Info")
                    .font(.headline)
                Text("Date: \(session.date.formatted(date: .abbreviated, time: .shortened))")
                Text("Duration: \(totalDuration, specifier: "%.1f") seconds")
                Text("Segments: \(segmentCount)")
            }
            .padding()
        }
        .navigationTitle("Session Details")
        .task {
            await loadTranscript()
        }
    }
    
    // Load transcript asynchronously to avoid blocking UI with large datasets
    private func loadTranscript() async {
        guard fullTranscript.isEmpty else { return }
            
        isLoading = true
            
        // Extract the data we need on the main actor first
        let segments = session.segments
            
        let transcript = await Task.detached {
            segments
                .sorted(by: { $0.startTime < $1.startTime })
                .compactMap { $0.transcription?.text }
                .joined(separator: " ")
        }.value
            
        fullTranscript = transcript
        isLoading = false
    }
}
