import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = KeychainHelper.shared.get(key: "assemblyAIKey") ?? ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var recorder: AudioRecorder
    @State private var selectedQuality: RecordingQuality = .high

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
        }
    }
}
