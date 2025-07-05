//
//  SessionView.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/4/25.
//

import SwiftUI

struct SessionView: View {
    let session: RecordingSession

    var fullTranscript: String {
        session.segments
            .sorted(by: { $0.startTime < $1.startTime })
            .compactMap { $0.transcription?.text }
            .joined(separator: " ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("📄 Full Transcription")
                    .font(.title2)
                    .bold()

                if fullTranscript.isEmpty {
                    Text("Transcription not yet available.")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    Text(fullTranscript)
                        .padding(.top, 4)
                }

                Divider()

                Text("📌 Session Info")
                    .font(.headline)
                Text("Date: \(session.date.formatted(date: .abbreviated, time: .shortened))")
                Text("Duration: \(session.segments.reduce(0.0) { $0 + $1.duration }, specifier: "%.1f") seconds")
                Text("Segments: \(session.segments.count)")
            }
            .padding()
        }
        .navigationTitle("Session Details")
    }
}
