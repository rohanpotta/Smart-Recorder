# Audio System Design

## Core Technology

Smart Recorder uses **`AVAudioEngine`** for advanced audio control:
- Enables real-time audio tap for waveform monitoring and segmentation.
- Offers more flexibility than `AVAudioRecorder`.

## Audio Session Configuration
- Category: `.record`
- Options: `.mixWithOthers`, `.allowBluetooth`
- Activated dynamically on recording start.

## Interruption Handling
- Listens to `AVAudioSession.interruptionNotification`
- On begin: pauses recording and removes audio tap.
- On end: checks for `.shouldResume` and resumes recording if applicable.

## Route Change Handling
- Subscribes to `AVAudioSession.routeChangeNotification`
- Detects `.oldDeviceUnavailable` (e.g., unplugged headphones)
- Automatically pauses recording to avoid unexpected speaker output.

## Background Recording
- Enabled via "Audio, AirPlay, and Picture in Picture" in `Info.plist`.
- Lifecycle event handlers ensure the recording continues in the background.
- Graceful shutdown if the app is terminated by the system.

