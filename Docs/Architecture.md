# Architecture Document

## Overall Design

Smart Recorder is built using **SwiftUI** and structured around the **MVVM (Model-View-ViewModel)** architecture pattern. It uses `@EnvironmentObject` and dependency injection to maintain clean separation of concerns and enable scalability.

### Layers and Responsibilities

#### 🖼️ View Layer (SwiftUI)
- `RootView`: Handles launch state and decides between showing `GreetView` or `ContentView`.
- `ContentView`: Core interface for recording controls, session list, and real-time updates.
- `SessionView`: Displays segment-level transcription and session metadata.
- `SettingsView`: Manages user preferences like API key and recording quality.

#### ⚙️ ViewModel / Managers
- `AudioRecorder`: Core recording engine using `AVAudioEngine`. Handles full lifecycle of audio capture, segmentation, and transcription.
- `OfflineTranscriptionManager`: Monitors connectivity using `NWPathMonitor`, queues transcription jobs offline, and resumes when online.
- `StorageManager`: Handles audio file cleanup and space-saving tasks.
- `KeychainHelper`: Manages secure storage of the AssemblyAI API key.

#### 💾 Model Layer (SwiftData)
- Relational schema with `RecordingSession`, `AudioSegment`, and `Transcription` entities.
- Designed for speed and reliability with large datasets (1000+ sessions).

### Dependency Injection
- `AudioRecorder` is initialized once in `Smart_RecorderApp` and injected into the SwiftUI environment.
- `ModelContext` for SwiftData is also passed via environment to ensure consistency across views.

