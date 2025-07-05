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

    @EnvironmentObject var recorder: AudioRecorder

    @State private var timer: Timer?

    @State private var searchText = ""
    @State private var elapsedSeconds = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private var elapsedString: String {
        String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    private func sectionTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)      { return "Today" }
        if cal.isDateInYesterday(date)  { return "Yesterday" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private var sectionedSessions: [(title: String, data: [RecordingSession])] {
        let filtered = sessions.filter { session in
            guard !searchText.isEmpty else { return true }
            
            // Search inside full transcript OR the formatted date text
            let dateString = session.date.formatted(date: .abbreviated,
                                                    time: .shortened)
            
            return session.fullTranscriptionText
                        .localizedCaseInsensitiveContains(searchText)
                || dateString
                        .localizedCaseInsensitiveContains(searchText)
        }
        let groups = Dictionary(grouping: filtered, by: { sectionTitle(for: $0.date) })
        return groups
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.1.first!.date > $1.1.first!.date }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Button(recorder.isRecording ? "Stop Recording" : "Start Recording") {
                    if recorder.isRecording {
                        recorder.stopRecording(modelContext: modelContext)
                    } else {
                        // Check for API key before starting
                        if KeychainHelper.shared.get(key: "assemblyAIKey")?.isEmpty != false {
                            alertMessage = "Please set your AssemblyAI API key in Settings before recording."
                            showingAlert = true
                            return
                        }
                        recorder.startRecording(modelContext: modelContext)
                    }
                }
                .padding()
                .background(recorder.isRecording ? Color.red : Color.green)
                .foregroundColor(.white)
                .clipShape(Capsule())

                HStack {
                    Label(elapsedString, systemImage: "timer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(recorder.recordingQuality.displayName)
                        .font(.footnote)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.3))
                        Capsule().fill(Color.blue)
                            .frame(width: geo.size.width * CGFloat(recorder.audioLevel))
                    }
                }
                .frame(height: 6)
                .padding(.horizontal)

                List {
                    ForEach(sectionedSessions, id: \.title) { section in
                        Section(section.title) {
                            ForEach(section.data) { session in
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
                }
                .searchable(text: $searchText, prompt: "Search sessions")
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationTitle("Smart Recorder")
            .onChange(of: recorder.isRecording) {
                if recorder.isRecording {
                    elapsedSeconds = 0
                    // Start the timer when recording begins
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        elapsedSeconds += 1
                    }
                } else {
                    // Stop the timer when recording ends
                    timer?.invalidate()
                    timer = nil
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
            .onReceive(NotificationCenter.default.publisher(for: .microphonePermissionDenied)) { _ in
                alertMessage = "Microphone permission is required to record audio. Please enable it in Settings."
                showingAlert = true
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let microphonePermissionDenied = Notification.Name("microphonePermissionDenied")
}
