//
//  RootView.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/4/25.
//

import SwiftUI

struct RootView: View {
    @StateObject var recorder = AudioRecorder()
    @Environment(\.modelContext) private var modelContext
    @State private var showGreet = true

    var body: some View {
        ZStack {
            // Your existing content view
            ContentView()
                .environmentObject(recorder)
                .environment(\.modelContext, modelContext)

            // Show greet only if recording NOT active and showGreet is true
            if showGreet && !recorder.isRecording {
                GreetView()
                    .transition(.move(edge: .bottom))
                    .gesture(
                        DragGesture(minimumDistance: 50, coordinateSpace: .local)
                            .onEnded { value in
                                if value.translation.height < 0 {
                                    withAnimation {
                                        showGreet = false
                                    }
                                }
                            }
                    )
            }
        }
        .onAppear {
            // If recording already active (e.g., resumed from background), hide greet
            if recorder.isRecording {
                showGreet = false
            }
        }
        // Listen for recording start to hide greet automatically
        .onChange(of: recorder.isRecording) {
            if recorder.isRecording {
                withAnimation {
                    showGreet = false
                }
            }
        }
    }
}

