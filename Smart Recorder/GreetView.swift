//
//  GreetView.swift
//  Smart Recorder
//
//  Created by Rohan Potta on 7/4/25.
//

import SwiftUI

struct GreetView: View {
    @State private var animateGradient = false
    @State private var pulseAnimation = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // White background base
            Color.white
                .ignoresSafeArea()
            
            // Dynamic gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.pink.opacity(0.1)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
            
            if showContent {
                VStack(spacing: 32) {
                    // Animated microphone icon
                    VStack(spacing: 16) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.linearGradient(
                                colors: [.blue, .purple],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                        
                        Text("Smart Recorder")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Ready to capture your thoughts")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        // Animated swipe indicator
                        HStack(spacing: 8) {
                            Image(systemName: "hand.draw.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            
                            Text("Swipe up to begin")
                                .font(.headline)
                                .foregroundStyle(.linearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                            
                            Image(systemName: "arrow.up")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .offset(y: pulseAnimation ? -4 : 0)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseAnimation)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(25)
                    }
                }
                .padding(32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Floating particles effect
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(.linearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: CGFloat.random(in: 4...8))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...700)
                    )
                    .animation(.easeInOut(duration: Double.random(in: 2...4)).repeatForever(autoreverses: true), value: animateGradient)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animateGradient = true
            pulseAnimation = true
            
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}
