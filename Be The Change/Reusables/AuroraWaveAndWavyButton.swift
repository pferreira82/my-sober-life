//
//  AuroraWaveAndWavyButton.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/27/24.
//

import Foundation
import SwiftUI

/// A button with a wavy gradient animation.
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

import SwiftUI

struct RectangularGradientButton: View {
    @State private var gradientOffset: CGFloat = 0.0

    var title: String
    var color1: Color
    var color2: Color
    var color3: Color
    var action: () -> Void

    var body: some View {
        Button(action: {
            action() // Execute the passed action
        }) {
            GeometryReader { geometry in
                ZStack {
                    // Animated Gradient Background
                    LinearGradient(
                        gradient: Gradient(colors: [color1, color2, color3]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .hueRotation(Angle(degrees: Double(gradientOffset)))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .cornerRadius(10)

                    // Button Text
                    Text(title)
                        .font(Font.custom("ShadowsIntoLight", size: 30))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 50) // Fixed height
        .onAppear {
            // Start gradient animation
            withAnimation {
                gradientOffset = 360
            }
        }
    }
}


/// A reusable view for creating animated aurora-like wave effects.
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
