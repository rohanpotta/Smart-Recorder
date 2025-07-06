import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [RecordingSession]

    @EnvironmentObject var recorder: AudioRecorder

    @State private var timer: Timer?
    @State private var searchText = ""
    @State private var elapsedSeconds = 0
    @State private var pausedElapsedSeconds = 0 // Track elapsed time when paused
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteConfirmation = false
    @State private var sessionToDelete: RecordingSession?

    private var elapsedString: String {
        let totalSeconds = elapsedSeconds + pausedElapsedSeconds
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
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
            
            let dateString = session.date.formatted(date: .abbreviated, time: .shortened)
            return session.fullTranscriptionText.localizedCaseInsensitiveContains(searchText) ||
                   dateString.localizedCaseInsensitiveContains(searchText)
        }
        
        let groups = Dictionary(grouping: filtered, by: { sectionTitle(for: $0.date) })
        return groups
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.1.first!.date > $1.1.first!.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section with Recording Controls
                VStack(spacing: 16) {
                    // Main Recording Button
                    Button(action: {
                        if recorder.isRecording {
                            recorder.stopRecording(modelContext: modelContext)
                        } else {
                            if KeychainHelper.shared.get(key: "assemblyAIKey")?.isEmpty != false {
                                alertMessage = "Please set your AssemblyAI API key in Settings before recording."
                                showingAlert = true
                                return
                            }
                            recorder.startRecording(modelContext: modelContext)
                        }
                    }) {
                        HStack(spacing: 8) {
                            // Recording indicator
                            if recorder.isRecording {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 12)
                                    .scaleEffect(recorder.isPaused ? 1.0 : 1.2)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recorder.isPaused ? false : recorder.isRecording)
                            }
                            
                            Text(recorder.isRecording ? "Stop Recording" : "Start Recording")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(recorder.isRecording ? Color.red : Color.green)
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
                        )
                    }
                    .accessibilityLabel(recorder.isRecording ? "Stop Recording" : "Start Recording")
                    .accessibilityHint(recorder.isRecording ? "Stops the current recording session" : "Starts a new recording session")
                    
                    //Pause/Resume Button (only show when recording)
                    if recorder.isRecording {
                        Button(action: {
                            if recorder.isPaused {
                                recorder.resumeRecording()
                            } else {
                                recorder.pauseRecording()
                            }
                        }) {
                            Text(recorder.isPaused ? "Resume" : "Pause")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(recorder.isPaused ? Color.blue : Color.orange)
                                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                )
                        }
                        .accessibilityLabel(recorder.isPaused ? "Resume Recording" : "Pause Recording")
                        .accessibilityHint(recorder.isPaused ? "Resumes the current recording session" : "Pauses the current recording session")
                    }

                    // Recording Info Row
                    HStack {
                        // Timer
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .foregroundColor(.blue)
                            Text(elapsedString)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        
                        Spacer()
                        
                        // Quality Badge
                        Text(recorder.recordingQuality.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }

                    // Audio Level Indicator
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Audio Level")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(recorder.audioLevel * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.quaternary)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(
                                        colors: [.blue, .blue.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(width: geo.size.width * CGFloat(recorder.audioLevel))
                                    .animation(.easeInOut(duration: 0.1), value: recorder.audioLevel)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .background(.ultraThinMaterial)

                // Sessions List
                List {
                    ForEach(sectionedSessions, id: \.title) { section in
                        Section {
                            ForEach(section.data) { session in
                                HStack(spacing: 12) {
                                    // Delete Button
                                    Button {
                                        sessionToDelete = session
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .font(.system(size: 16, weight: .medium))
                                            .frame(width: 24, height: 24)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityLabel("Delete session")
                                    
                                    // Session Row
                                    SessionRowView(session: session)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text(section.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search sessions")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Smart Recorder")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: recorder.isRecording) {
                if !recorder.isRecording {
                    // Recording stopped - invalidate timer and reset counters
                    timer?.invalidate()
                    timer = nil
                    elapsedSeconds = 0
                    pausedElapsedSeconds = 0
                    // Reset audio level after a brief delay to allow final UI update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        recorder.audioLevel = 0
                    }
                } else {
                    // Recording started - reset counters for new session
                    elapsedSeconds = 0
                    pausedElapsedSeconds = 0
                    // Start timer if not paused
                    if !recorder.isPaused {
                        startTimer()
                    }
                }
            }
            .onChange(of: recorder.isPaused) {
                if recorder.isRecording {
                    if recorder.isPaused {
                        // Paused - stop timer and preserve elapsed time
                        timer?.invalidate()
                        timer = nil
                        pausedElapsedSeconds += elapsedSeconds
                        elapsedSeconds = 0
                    } else {
                        // Resumed - start timer again
                        startTimer()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .microphonePermissionDenied)) { notification in
                if let message = notification.userInfo?["message"] as? String {
                    alertMessage = message
                } else {
                    alertMessage = "Microphone permission is required to record audio. Please enable it in Settings."
                }
                showingAlert = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .storageLowWarning)) { _ in
                alertMessage = "Warning: Low storage space (\(String(format: "%.1f", recorder.availableStorageGB))GB remaining). Recording may fail if storage runs out."
                showingAlert = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .storageCriticalWarning)) { _ in
                alertMessage = "Critical: Very low storage space. Recording stopped to prevent system issues."
                showingAlert = true
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .alert("Delete Session", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let session = sessionToDelete {
                        deleteSession(session)
                        sessionToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    sessionToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this recording session? This action cannot be undone.")
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            timer?.invalidate()
            timer = nil
        }
    }

    private func startTimer() {
        timer?.invalidate() // Ensure no duplicate timers
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }



    private func deleteSession(_ session: RecordingSession) {
        // Delete associated audio files (all segments)
        for segment in session.segments {
            let fileURL = URL(fileURLWithPath: segment.filePath)
            try? FileManager.default.removeItem(at: fileURL)
        }

        // Delete session — assumes cascade delete is correctly set up for segments & transcriptions
        modelContext.delete(session)
        
        // SwiftData sometimes needs a slight nudge to update after a cascade delete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? modelContext.save()
        }
    }
}

// MARK: - Beautiful Session Row View
struct SessionRowView: View {
    let session: RecordingSession
    
    var body: some View {
        let totalDuration = session.segments.reduce(0.0) { $0 + $1.duration }
        let completedCount = session.segments.filter { $0.transcription?.status == "completed" }.count
        let failedCount = session.segments.filter { $0.transcription?.status == "failed" }.count
        let totalSegments = session.segments.count

        let transcriptionStatus: (text: String, color: Color, icon: String) = {
            if failedCount > 0 {
                return ("Failed", .red, "xmark.circle.fill")
            } else if completedCount == totalSegments && totalSegments > 0 {
                return ("Completed", .green, "checkmark.circle.fill")
            } else if totalSegments == 0 {
                return ("No Segments", .secondary, "minus.circle.fill")
            } else {
                return ("In Progress", .orange, "clock.circle.fill")
            }
        }()

        NavigationLink(destination: SessionView(session: session)) {
            VStack(spacing: 0) {
                // Card Container
                VStack(alignment: .leading, spacing: 12) {
                    // Header with Date
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recording Session")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Status Badge
                        HStack(spacing: 4) {
                            Image(systemName: transcriptionStatus.icon)
                                .font(.caption)
                            Text(transcriptionStatus.text)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(transcriptionStatus.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(transcriptionStatus.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Stats Row
                    HStack(spacing: 20) {
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("\(String(format: "%.1f", totalDuration))s")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        // Segments
                        HStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text(totalSegments == 1 ? "1 segment" : "\(totalSegments) segments")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    .foregroundColor(.primary)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Recording session from \(session.date.formatted(date: .abbreviated, time: .shortened))")
        .accessibilityValue("Duration \(String(format: "%.1f", totalDuration)) seconds, \(totalSegments) segments, \(transcriptionStatus.text)")
        .accessibilityHint("Double tap to view session details")
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let microphonePermissionDenied = Notification.Name("microphonePermissionDenied")
    static let storageLowWarning = Notification.Name("storageLowWarning")
    static let storageCriticalWarning = Notification.Name("storageCriticalWarning")
}