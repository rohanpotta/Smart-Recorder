import AVFoundation
import SwiftData
import Combine
import Speech
import Security
import Foundation

enum RecordingQuality: String, CaseIterable, Identifiable {
    case low, medium, high
    var id: Self { self }
    var displayName: String {
        switch self {
        case .low:    "Low"
        case .medium: "Medium"
        case .high:   "High"
        }
    }
    var sampleRate: Double {
        switch self {
        case .low:    12_000
        case .medium: 24_000
        case .high:   44_100
        }
    }
}

class AudioRecorder: ObservableObject {
    private let engine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()
    private var audioFile: AVAudioFile?
    private var segmentTimer: Timer?
    private let segmentDuration: TimeInterval = 30
    private var currentSession: RecordingSession?
    private var currentSegmentFileURL: URL?
    private var currentSegmentStartTime: Date?
    private var transcriptionTasks = [UUID: String]()
    
    private var assemblyAIKey: String {
        KeychainHelper.shared.get(key: "assemblyAIKey") ?? ""
    }
    private let urlSession = URLSession.shared

    @Published var isRecording = false
    @Published var audioLevel: Float = 0
    @Published var recordingQuality: RecordingQuality = .high
    @Published var availableStorageGB: Double = 0
    @Published var isStorageLow: Bool = false
    @Published var isPaused = false
    private let minimumStorageGB: Double = 1.0  // 1GB minimum

    init() {
        // Observe audio interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        // Observe route changes (e.g. headphones unplugged)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startRecording(modelContext: ModelContext) {
        guard KeychainHelper.shared.isValidAPIKey(assemblyAIKey) else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .microphonePermissionDenied, // Re-using this notification for simplicity
                    object: nil, 
                    userInfo: ["message": "Please set a valid AssemblyAI API key in Settings before recording."]
                )
            }
            print("🚨 Recording stopped: Invalid or missing AssemblyAI API key.")
            return
        }

        AVAudioApplication.requestRecordPermission { [weak self] granted in
            guard let self = self, granted else {
                print("Microphone permission denied")
                return
            }

            Task {
                do {
                    try await self.checkStorageSpace()
                    if self.isStorageLow {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .storageLowWarning, object: nil)
                        }
                        return
                    }

                    try self.session.setCategory(.record, options: [.mixWithOthers, .allowBluetooth])
                    try self.session.setActive(true)

                    self.currentSession = RecordingSession(date: Date(), filePath: "") // filePath will be updated later

                    try self.startNewSegment(modelContext: modelContext)

                    self.engine.prepare()
                    try self.engine.start()
                    print("Engine started")
                    
                    self.monitorStorageDuringRecording()

                    await MainActor.run {
                        self.isRecording = true
                    }
                } catch {
                    print("Failed to start recording: \(error)")
                }
            }
        }
    }

    private func startNewSegment(modelContext: ModelContext) throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".caf")
        self.currentSegmentFileURL = fileURL
        self.currentSegmentStartTime = Date()

        let inputNode = self.engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        var fileSettings = format.settings
        fileSettings[AVSampleRateKey as String] = recordingQuality.sampleRate
        self.audioFile = try AVAudioFile(forWriting: fileURL, settings: fileSettings)
        
        inputNode.removeTap(onBus: 0) // Remove previous tap if any
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            do {
                try self.audioFile?.write(from: buffer)
                print("Writing buffer...")
            } catch {
                print("Error writing buffer: \(error)")
            }
            if let channelData = buffer.floatChannelData?[0] {
                let values = UnsafeBufferPointer(start: channelData,
                                                  count: Int(buffer.frameLength))
                let rms = sqrt(values.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
                let level = min(max(rms * 20, 0), 1)
                DispatchQueue.main.async { self.audioLevel = level }
            }
        }

        // Update currentSession filePath if empty (first segment)
        if self.currentSession?.filePath.isEmpty == true {
            self.currentSession?.filePath = fileURL.path
        }

        // Schedule timer to split after 30 seconds
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.segmentTimer?.invalidate()
            self.segmentTimer = Timer.scheduledTimer(withTimeInterval: self.segmentDuration, repeats: false) { _ in
                self.finishCurrentSegmentAndStartNew(modelContext: modelContext)
            }
        }
    }
    
    private func finishCurrentSegmentAndStartNew(modelContext: ModelContext) {
        guard let fileURL = currentSegmentFileURL,
              let segmentStart = currentSegmentStartTime,
              let session = currentSession else {
            print("Missing info to finish segment")
            return
        }

        // Calculate segment duration
        let segmentDuration = Date().timeIntervalSince(segmentStart)

        // Create and add segment WITHOUT auto-creating transcription
        let segment = AudioSegment(startTime: segmentStart, duration: segmentDuration, filePath: fileURL.path)
        session.segments.append(segment)

        // Save or update session and segment
        modelContext.insert(session)
        modelContext.insert(segment)
        try? modelContext.save()

        // Encrypt the completed audio file
        do {
            try self.encryptAudioFile(at: fileURL)
        } catch {
            print("🚨 Failed to encrypt audio file: \(error)")
        }

        print("Saved segment starting at \(segmentStart) duration: \(segmentDuration)")

        // **Call transcription here**
        transcribeSegment(segment, modelContext: modelContext)

        // Start new segment recording
        do {
            try startNewSegment(modelContext: modelContext)
        } catch {
            print("Failed to start new segment: \(error)")
        }
    }

    func stopRecording(modelContext: ModelContext) {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        segmentTimer?.invalidate()
        segmentTimer = nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isRecording = false

            guard let session = self.currentSession else {
                print("No active session on stop")
                return
            }

            // If the current segment is still recording, save it as well
            if let fileURL = self.currentSegmentFileURL, let segmentStart = self.currentSegmentStartTime {
                let segmentDuration = Date().timeIntervalSince(segmentStart)
                let segment = AudioSegment(startTime: segmentStart, duration: segmentDuration, filePath: fileURL.path)
                session.segments.append(segment)
                modelContext.insert(segment)
                
                // Encrypt the final segment
                do {
                    try self.encryptAudioFile(at: fileURL)
                } catch {
                    print("⚠️ Failed to encrypt final audio file: \(error)")
                }
            }

            modelContext.insert(session)
            try? modelContext.save()

            print("Recording stopped and session saved with \(session.segments.count) segments")

            //Transcribe all segments (including previously recorded ones)
            for segment in session.segments {
                self.transcribeSegment(segment, modelContext: modelContext)
            }

            // Clear current session data
            self.currentSession = nil
            self.currentSegmentFileURL = nil
            self.currentSegmentStartTime = nil
        }
    }
    
    func transcribeSegment(_ segment: AudioSegment, modelContext: ModelContext) {
        if !OfflineTranscriptionManager.shared.isNetworkAvailable {
            OfflineTranscriptionManager.shared.enqueue(segment: segment, modelContext: modelContext)
            return
        }
        
        Task {
            let filePath = segment.filePath
            let segmentID = segment.id

            let maxRetries = 5
            var attempt = 0

            while attempt < maxRetries {
                do {
                    print("🛰️ Transcribing remotely (attempt \(attempt + 1)) for segment \(segmentID)")

                    let uploadURL = try await uploadAudioFile(URL(fileURLWithPath: filePath))
                    let transcriptID = try await requestTranscription(audioURL: uploadURL)
                    let transcriptText = try await pollTranscriptionResult(transcriptID: transcriptID)

                    await applyTranscription(transcriptText, to: segment, modelContext: modelContext)
                    print("✅ Remote transcription succeeded for segment \(segmentID)")
                    return
                } catch {
                    attempt += 1
                    print("⚠️ Remote transcription failed (attempt \(attempt)) for segment \(segmentID): \(error.localizedDescription)")

                    // Backoff before retry
                    let delay = pow(2.0, Double(attempt)) // 2, 4, 8, etc.
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }

            // Fallback after 5 failed attempts
            print("🔴 ASSEMBLY AI FAILED! NOW ATTEMPTING LOCAL FALLBACK. 🔴")
            print("🔁 Falling back to local transcription for segment \(segmentID)")
            do {
                let transcriptText = try await transcribeLocal(URL(fileURLWithPath: filePath))
                await applyTranscription(transcriptText, to: segment, modelContext: modelContext)
                print("✅ Local transcription succeeded for segment \(segmentID)")
            } catch {
                print("❌ Local transcription failed for segment \(segmentID): \(error.localizedDescription)")
                await markTranscriptionFailed(for: segment, modelContext: modelContext)
            }
        }
    }

    func uploadAudioFile(_ fileURL: URL) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.assemblyai.com/v2/upload")!)
        request.httpMethod = "POST"
        request.setValue(assemblyAIKey, forHTTPHeaderField: "authorization")

        let audioData = try Data(contentsOf: fileURL)
        
        let (data, response) = try await urlSession.upload(for: request, from: audioData)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "UploadFailed", code: 1, userInfo: nil)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let uploadURL = json?["upload_url"] as? String {
            return uploadURL
        } else {
            throw NSError(domain: "UploadFailed", code: 2, userInfo: nil)
        }
    }

    func requestTranscription(audioURL: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.assemblyai.com/v2/transcript")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(assemblyAIKey, forHTTPHeaderField: "authorization")

        let body: [String: Any] = ["audio_url": audioURL]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "TranscriptionRequestFailed", code: 1, userInfo: nil)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let transcriptID = json?["id"] as? String {
            return transcriptID
        } else {
            throw NSError(domain: "TranscriptionRequestFailed", code: 2, userInfo: nil)
        }
    }
    
    func pollTranscriptionResult(transcriptID: String) async throws -> String {
        let url = URL(string: "https://api.assemblyai.com/v2/transcript/\(transcriptID)")!
        var request = URLRequest(url: url)
        request.setValue(assemblyAIKey, forHTTPHeaderField: "authorization")

        while true {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "No response body"
                print("🚨 Transcription poll failed with status \((response as? HTTPURLResponse)?.statusCode ?? 0): \(errorBody)")
                throw NSError(domain: "TranscriptionPollFailed", code: 1, userInfo: [NSLocalizedDescriptionKey: "Polling failed: \(errorBody)"])
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let errorMessage = json?["error"] as? String {
                print("🚨 Transcription API returned an error: \(errorMessage)")
                throw NSError(domain: "TranscriptionAPIError", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }

            if let status = json?["status"] as? String {
                switch status {
                case "completed":
                    if let text = json?["text"] as? String {
                        return text
                    } else {
                        throw NSError(domain: "TranscriptionResultInvalid", code: 1, userInfo: [NSLocalizedDescriptionKey: "Transcription completed but no text found."])
                    }
                case "error":
                    let errorMessage = json?["error"] as? String ?? "Unknown transcription error from API."
                    print("🚨 Transcription failed with API error: \(errorMessage)")
                    throw NSError(domain: "TranscriptionAPIError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                default: 
                    try await Task.sleep(nanoseconds: 3_000_000_000) 
                }
            } else {
                throw NSError(domain: "InvalidResponse", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not decode transcription status."])
            }
        }
    }
    
    func transcribeLocal(_ url: URL) async throws -> String {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)

        return try await withCheckedThrowingContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else if let error = error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func pauseRecording() {
        if engine.isRunning {
            engine.pause()
            
            engine.inputNode.removeTap(onBus: 0)
            
            DispatchQueue.main.async { [weak self] in
                self?.isPaused = true
            }
            print("⏸️ Recording paused & audio writing stopped")
        }
    }

    func resumeRecording() {
        do {
            try engine.start()
            
            let format = engine.inputNode.outputFormat(forBus: 0)
            engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                do {
                    try self.audioFile?.write(from: buffer)
                } catch {
                    print("Error writing buffer: \(error)")
                }
                if let channelData = buffer.floatChannelData?[0] {
                    let values = UnsafeBufferPointer(start: channelData,
                                                      count: Int(buffer.frameLength))
                    let rms = sqrt(values.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
                    let level = min(max(rms * 20, 0), 1)
                    DispatchQueue.main.async { self.audioLevel = level }
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.isPaused = false
            }
            print("▶️ Recording resumed & audio writing re-started")
        } catch {
            print("Failed to resume recording: \(error)")
        }
    }
    
    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            print("🔕 Interruption began — pausing recording")
            pauseRecording()
        case .ended:
            print("🔔 Interruption ended — trying to resume")
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resumeRecording()
                }
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            print("🎧 Headphones unplugged or Bluetooth disconnected")
            pauseRecording()
        case .newDeviceAvailable:
            print("🔌 New audio route available (e.g., headphones plugged in)")
            
        default:
            break
        }
    }
    
    @MainActor
    func applyTranscription(_ transcriptText: String, to segment: AudioSegment, modelContext: ModelContext) {
        let transcription = Transcription(text: transcriptText, status: "completed")
        segment.transcription = transcription
        modelContext.insert(transcription)
        modelContext.insert(segment)
        try? modelContext.save()
    }

    @MainActor
    func markTranscriptionFailed(for segment: AudioSegment, modelContext: ModelContext) {
        if segment.transcription == nil {
            let transcription = Transcription(text: "", status: "failed")
            segment.transcription = transcription
            modelContext.insert(transcription)
        } else {
            segment.transcription?.status = "failed"
        }
        try? modelContext.save()
    }
    
    func checkStorageSpace() async throws {
        let fileManager = FileManager.default
        let systemAttributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
        
        if let freeBytes = systemAttributes[.systemFreeSize] as? NSNumber {
            let freeGB = Double(freeBytes.int64Value) / (1024 * 1024 * 1024)
            
            let minimumStorage = self.minimumStorageGB
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.availableStorageGB = freeGB
                self.isStorageLow = freeGB < minimumStorage
            }
        }
    }

    func encryptAudioFile(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("⚠️ Audio file not found for encryption: \(url.path)")
            return
        }
        
        try FileManager.default.setAttributes([
            FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ], ofItemAtPath: url.path)
        
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(resourceValues)
        
        print("🔒 Audio file encrypted and excluded from backup: \(url.lastPathComponent)")
    }

    func monitorStorageDuringRecording() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] timer in
            guard let self = self, self.isRecording else {
                timer.invalidate()
                return
            }
            
            Task {
                try? await self.checkStorageSpace()
                if self.isStorageLow {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .storageCriticalWarning, object: nil)
                    }
                }
            }
        }
    }
}