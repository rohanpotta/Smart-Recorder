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
    @State private var greetDragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Your existing content view
            ContentView()
                .environmentObject(recorder)
                .environment(\.modelContext, modelContext)

            if showGreet && !recorder.isRecording {
                GreetView()
                    .offset(y: greetDragOffset)   // follow the finger
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom),  // comes in from bottom
                            removal: .move(edge: .top)        // exits upward
                        )
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height < 0 {            // only track upward drag
                                    greetDragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height < -150 {          // threshold to dismiss
                                    withAnimation(.easeInOut) {
                                        greetDragOffset = -UIScreen.main.bounds.height
                                    }
                                    // after the slide finishes, remove the view
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        withAnimation {
                                            showGreet = false
                                        }
                                        greetDragOffset = 0
                                    }
                                } else {
                                    // not far enough – snap back
                                    withAnimation(.spring()) {
                                        greetDragOffset = 0
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
