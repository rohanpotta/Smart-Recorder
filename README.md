Smart Recorder
==============

A production-grade iOS app that records audio, transcribes it in real-time, and persists data using SwiftData. Built using SwiftUI, AVAudioEngine, and modern iOS development best practices.

------------------------------------------------------------
GETTING STARTED
------------------------------------------------------------

1. Clone the Repository

   git clone https://github.com/rohanpotta/Smart-Recorder.git
   cd smart-recorder

2. Open the Project

   Open the `Smart Recorder.xcodeproj` file in Xcode.

3. Configure the API Key

   To enable transcription, you must provide an AssemblyAI API key.

   Option 1 (Recommended): In-App Setup
     - Run the app
     - Go to the Settings screen (gear icon)
     - Paste your API key in the provided field

   Option 2: Set via Xcode Environment Variable
     - In Xcode: Product > Scheme > Edit Scheme...
     - Select "Run" on the left
     - Go to the "Arguments" tab
     - Add a new Environment Variable:
         Name: ASSEMBLY_AI_KEY
         Value: your_assembly_ai_api_key_here

4. Build and Run

   - Choose a simulator or device
   - Press Cmd+R to run the app
   - Grant microphone and speech recognition permissions when prompted

------------------------------------------------------------
ARCHITECTURE OVERVIEW
------------------------------------------------------------

This app follows an MVVM (Model-View-ViewModel) architecture using SwiftUI.

Views (SwiftUI):
  - RootView: Manages onboarding
  - ContentView: Controls recording and displays sessions
  - SessionView: Shows details and transcriptions

ViewModels / Managers:
  - AudioRecorder: AVAudioEngine-based core logic
  - OfflineTranscriptionManager: Queues and retries transcription
  - StorageManager: Manages audio file cleanup
  - KeychainHelper: Secure API key storage

Models (SwiftData):
  - RecordingSession
  - AudioSegment
  - Transcription
  Relationships are enforced with cascade delete and external storage for performance.

See the 'Documentation' folder for more details.

------------------------------------------------------------
DOCUMENTATION
------------------------------------------------------------

- Architecture Overview:         Docs/Architecture.md
- Audio System Design:           Docs/AudioSystem.md
- Data Model & Performance:      Docs/DataModel.md
- Known Issues & Limitations:    Docs/KnownIssues.md

------------------------------------------------------------
TESTING
------------------------------------------------------------

- Unit Tests for logic and data models
- Integration Tests for audio and network
- Edge Case Tests for offline mode, interruptions, etc.

------------------------------------------------------------
ASSUMPTIONS
------------------------------------------------------------

- Default audio segments are 30 seconds long
- After 5+ transcription failures, fallback to local Apple transcription

------------------------------------------------------------
KNOWN LIMITATIONS
------------------------------------------------------------

See: Docs/KnownIssues.md

------------------------------------------------------------
FEEDBACK & CONTRIBUTIONS
------------------------------------------------------------

Pull requests and issues are welcome.
Please open an issue to suggest improvements or ask questions.
