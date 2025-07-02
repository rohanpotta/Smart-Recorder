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
    var segments: [AudioSegment]

    init(id: UUID = UUID(), date: Date = Date(), segments: [AudioSegment] = []) {
        self.id = id
        self.date = date
        self.segments = segments
    }
}

@Model
class AudioSegment {
    var id: UUID
    var startTime: Date
    var duration: TimeInterval
    var fileURL: URL
    var transcription: Transcription?

    init(id: UUID = UUID(), startTime: Date, duration: TimeInterval, fileURL: URL, transcription: Transcription? = nil) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.fileURL = fileURL
        self.transcription = transcription
    }
}

@Model
class Transcription {
    var id: UUID
    var text: String
    var status: TranscriptionStatus

    init(id: UUID = UUID(), text: String, status: TranscriptionStatus = .pending) {
        self.id = id
        self.text = text
        self.status = status
    }
}

enum TranscriptionStatus: String, Codable {
    case pending, completed, failed
}
