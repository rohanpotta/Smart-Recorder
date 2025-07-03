//
//  Models.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/2/25.
//

import Foundation
import SwiftData

@Model
class RecordingSession {
    var id: UUID
    var date: Date
    var filePath: String
    @Relationship(deleteRule: .cascade, inverse: \AudioSegment.recordingSession)
    var segments: [AudioSegment]
    
    init(id: UUID = UUID(), date: Date = Date(), filePath: String, segments: [AudioSegment] = []) {
        self.id = id
        self.date = date
        self.filePath = filePath
        self.segments = segments
    }
}

@Model
class AudioSegment {
    var id: UUID
    var startTime: Date
    var duration: TimeInterval
    var filePath: String
    @Relationship var transcription: Transcription
    var recordingSession: RecordingSession?

    init(id: UUID = UUID(), startTime: Date, duration: TimeInterval, filePath: String, transcription: Transcription = Transcription(), recordingSession: RecordingSession? = nil) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.filePath = filePath
        self.transcription = transcription
        self.recordingSession = recordingSession
    }
}

@Model
class Transcription {
    var id: UUID
    var text: String
    var status: String

    init(id: UUID = UUID(), text: String = "", status: String = "pending") {
        self.id = id
        self.text = text
        self.status = status
    }

    var statusEnum: TranscriptionStatus {
        get { TranscriptionStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }
}

enum TranscriptionStatus: String, Codable {
    case pending, completed, failed
}
