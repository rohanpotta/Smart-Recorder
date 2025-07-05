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
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
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
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    @Relationship var transcription: Transcription?
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
    var status: String
    var createdAt: Date = Date()
    @Attribute(.externalStorage)
    var text: String
    var remoteID: String?
    var retryCount: Int = 0
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        text: String = "",
        status: String = "pending",
        remoteID: String? = nil,
        retryCount: Int = 0
    ) {
        self.id = id
        self.text = text
        self.status = status
        self.remoteID = remoteID
        self.retryCount = retryCount
    }

    var statusEnum: TranscriptionStatus {
        get { TranscriptionStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }
}

enum TranscriptionStatus: String, Codable {
    case pending, completed, failed
}

extension RecordingSession {
    var totalDuration: TimeInterval {
        segments.reduce(0) { $0 + $1.duration }
    }

    var transcriptionStatus: String {
        if segments.allSatisfy({ $0.transcription?.statusEnum == .completed }) {
            return "Completed"
        } else if segments.contains(where: { $0.transcription?.statusEnum == .failed }) {
            return "Failed"
        } else {
            return "In Progress"
        }
    }

    var fullTranscriptionText: String {
        segments
            .sorted(by: { $0.startTime < $1.startTime })
            .compactMap { $0.transcription?.text }
            .joined(separator: " ")
    }
}
