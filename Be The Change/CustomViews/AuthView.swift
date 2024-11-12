//
//  AuthView.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/12/24.
//

import SwiftUI

struct AuthView: View {
    
//    @Environment(AppController.self) private var appController
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var glowOpacity: Double = 0.6
    @State private var waveOpacity1: Double = 0.2
    @State private var waveOpacity2: Double = 0.1
    @State private var waveOpacity3: Double = 0.3
    @State private var waveOpacity4: Double = 0.1
    @State private var waveOffset1: CGFloat = -250
    @State private var waveOffset2: CGFloat = -150
    @State private var waveOffset3: CGFloat = -400
    @State private var waveOffset4: CGFloat = 100
    
    // For animated gradient and glow on the button
    @State private var waveOffset: CGFloat = 0.0
    @State private var buttonGlowOpacity: Double = 0.4 // Button glow animation state
    @State private var textGlowOpacity: Double = 0.6 // Text glow animation state
    
    var body: some View {
        VStack(spacing: 20) {
            // Aurora Glow and Waves Background
            ZStack {

                // Aurora Wave Layers
                AuroraWave(offset: waveOffset1, amplitude: 80, colors: [.blue.opacity(0.3), .green.opacity(0.2), .clear])
                    .frame(height: 150)
                    .opacity(waveOpacity1)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                            waveOpacity1 = 0.7
                        }
                    }
                AuroraWave(offset: waveOffset2, amplitude: 90, colors: [.red.opacity(0.9), .purple.opacity(0.2), .clear])
                    .frame(height: 150)
                    .opacity(waveOpacity2)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                            waveOpacity2 = 0.8
                        }
                    }
                AuroraWave(offset: waveOffset3, amplitude: 100, colors: [.green.opacity(0.05), .red.opacity(0.1), .clear])
                    .frame(height: 100)
                    .opacity(waveOpacity3)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                            waveOpacity3 = 0.5
                        }
                    }
                AuroraWave(offset: waveOffset4, amplitude: 50, colors: [.blue.opacity(0.9), .green.opacity(0.1), .clear])
                    .frame(height: 100)
                    .opacity(waveOpacity4)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
                            waveOpacity4 = 0.5
                        }
                    }
                
                // "Be The Change" Text with Gradient
                Text("Be The CHANGE")
                    .font(Font.custom("Forum", size: 46))
                    .fontWeight(.heavy)
                    .shadow(color: Color.blue.opacity(textGlowOpacity), radius: 20, x: 0, y: 0) // Glowing effect
                      .onAppear {
                          withAnimation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                              textGlowOpacity = 1.0
                          }
                      }
                    .foregroundStyle(
                        LinearGradient(gradient: Gradient(colors: [Color.white, Color.gray]), startPoint: .leading, endPoint: .trailing)
                    )
                    .opacity(0.85)
            }
            .frame(height: 300)

            // Login Form
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                Button(action: {
                    // Handle login action
                }) {
                    WavyGradientButton(waveOffset: waveOffset)
                        .frame(maxWidth: .infinity, maxHeight: 50) // Fixed button height
                        .cornerRadius(10)
                        .opacity(buttonGlowOpacity)
                        .shadow(color: Color.blue.opacity(buttonGlowOpacity), radius: 20, x: 0, y: 0) // Glow effect
                        .overlay(
                            Text("Login")
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                }
                .onAppear {
                    // Animate the wave offset for wavy effect
                    withAnimation(
                        Animation.easeInOut(duration: 6).repeatForever(autoreverses: true)
                    ) {
                        waveOffset = 100
                    }
                    // Animate the button glow opacity
                    withAnimation(
                        Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)
                    ) {
                        buttonGlowOpacity = 0.9
                    }
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                waveOffset1 = 50
            }
            withAnimation(Animation.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
                waveOffset2 = -60
            }
        }
    }
}

struct WavyGradientButton: View {
    var waveOffset: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let waveHeight: CGFloat = 20

            // Create the wavy path
            let wavyPath = Path { path in
                path.move(to: CGPoint(x: -200, y: height / 2))
                for x in stride(from: 0, through: width, by: 1) {
                    let relativeX = x / width
                    let sine = sin(relativeX * .pi * 2 + waveOffset * .pi / 67)
                    let y = height / 2 + waveHeight * sine
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }

            ZStack {
                // Render the wavy gradient masked to the button's rectangular shape
                wavyPath
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple, Color.red]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Rectangle()) // Mask the wavy gradient inside the rectangle
            }
        }
    }
}

struct AuroraWave: View {
    var offset: CGFloat
    var amplitude: CGFloat
    var colors: [Color]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width * 1.5
                let height = geometry.size.height
                
                path.move(to: CGPoint(x: -200, y: height * 0.5))
                path.addCurve(to: CGPoint(x: width + 200, y: height * 0.5),
                              control1: CGPoint(x: width * 0.25, y: height * 0.2 - amplitude),
                              control2: CGPoint(x: width * 0.75, y: height * 0.8 + amplitude))
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom))
            .offset(x: offset)
        }
    }
}

#Preview {
    AuthView()
}
