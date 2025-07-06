//
//  Models.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/2/25.
//

import Foundation
import Network
import SwiftData

class OfflineTranscriptionManager: ObservableObject {
    static let shared = OfflineTranscriptionManager()
    
    private let monitor = NWPathMonitor()
    @Published private var isConnected = false
    private var queue: [(AudioSegment, ModelContext)] = []
    private var transcriber: ((AudioSegment, ModelContext) -> Void)?
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if self?.isConnected == true {
                    self?.processQueue()
                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "OfflineTranscriptionManager.Network"))
    }
    
    var isNetworkAvailable: Bool { isConnected }
    
    func setTranscriber(_ block: @escaping (AudioSegment, ModelContext) -> Void) {
        transcriber = block
        if isConnected { processQueue() }
    }
    
    func enqueue(segment: AudioSegment, modelContext: ModelContext) {
        if !queue.contains(where: { $0.0.id == segment.id }) {
            queue.append((segment, modelContext))
        }
    }
    
    private func processQueue() {
        guard isConnected, let transcriber else { return }
        for (segment, ctx) in queue {
            transcriber(segment, ctx)
        }
        queue.removeAll()
    }
    
    func loadPendingSegments(from context: ModelContext) {
        let descriptor = FetchDescriptor<AudioSegment>(
            predicate: #Predicate { segment in
                segment.transcription?.status == "pending"
            }
        )
        do {
            let pending = try context.fetch(descriptor)
            for seg in pending {
                enqueue(segment: seg, modelContext: context)
            }
        } catch {
            print("Failed to fetch pending segments: \(error)")
        }
    }
}