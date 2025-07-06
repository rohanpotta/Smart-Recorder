# Known Issues and Limitations

## 1. Pause/Resume Duration Mismatch
- **Issue**: Timer shown in UI may not match final recorded segment duration if user pauses and resumes recording.
- **Cause**: Segment duration is calculated based on total elapsed time (wall-clock), not accounting for paused time.
- **Impact**: Low – audio is not recorded during pause, but duration metadata is inaccurate.
- **Potential Fix**: Track cumulative pause durations and subtract from total elapsed time.

## 2. No UI Indicator for Transcription Failover
- Currently, when the app switches from backend transcription to local transcription after multiple failures, no user-facing status message is shown.
- **Impact**: Transparency issue – user might not know fallback is happening.
- **Future Improvement**: Add UI banners or indicators when fallback is triggered.

## 3. Limited Error Feedback for Audio Failures
- If AVAudioEngine fails to start due to permissions or hardware error, feedback is limited.
- **Suggestion**: Add user-visible alerts or toast messages for clarity.

## 4. Export Functionality Missing
- No built-in support for exporting sessions/transcripts.
- **Improvement**: Add export to `.txt` or `.wav` in the future for user convenience.

