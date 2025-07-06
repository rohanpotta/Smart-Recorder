import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = KeychainHelper.shared.get(key: "assemblyAIKey") ?? ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var recorder: AudioRecorder
    @State private var selectedQuality: RecordingQuality = .high
    @State private var showingClearCacheAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("AssemblyAI API Key")) {
                    SecureField("Paste your key here", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section(header: Text("Recording Quality")) {
                    Picker("Quality", selection: $selectedQuality) {
                        ForEach(RecordingQuality.allCases) { q in
                            Text(q.displayName).tag(q)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Storage")) {
                    Button(role: .destructive) {
                        showingClearCacheAlert = true
                    } label: {
                        Text("Clear Transcribed Audio Files")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        KeychainHelper.shared.save(value: apiKey, for: "assemblyAIKey")
                        recorder.recordingQuality = selectedQuality
                        dismiss()
                    }
                }
            }
            .onAppear { selectedQuality = recorder.recordingQuality }
            .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
                Button("Delete", role: .destructive) {
                    StorageManager.shared.clearTranscribedAudioFiles(modelContext: modelContext)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete the audio files for all successfully transcribed recordings to free up space. The transcriptions will remain. This action cannot be undone.")
            }
        }
    }
}