import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = KeychainHelper.shared.get(key: "assemblyAIKey") ?? ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("AssemblyAI API Key")) {
                    SecureField("Paste your key here", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        KeychainHelper.shared.save(value: apiKey, for: "assemblyAIKey")
                        dismiss()
                    }
                }
            }
        }
    }
}
