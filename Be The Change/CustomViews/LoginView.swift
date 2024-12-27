//
//  LoginView.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/19/24.
//

import SwiftUI
import Combine

private enum FocusableField: Hashable {
  case email
  case password
}


struct LoginView: View {
    
//    @Environment(AppController.self) private var appController
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @Environment(\.colorScheme) var colorScheme    // Detect light or dark mode
    
    @State private var glowOpacity: Double = 0.6
    @State private var waveOpacity1: Double = 0.3
    @State private var waveOpacity2: Double = 0.2
    @State private var waveOpacity3: Double = 0.4
    @State private var waveOpacity4: Double = 0.2
    @State private var waveOffset1: CGFloat = -250
    @State private var waveOffset2: CGFloat = -150
    @State private var waveOffset3: CGFloat = -400
    @State private var waveOffset4: CGFloat = 100
    @State private var keyboardVisible: Bool = false
    
    // For animated gradient and glow on the button
    @State private var waveOffset: CGFloat = 0.0
    @State private var buttonGlowOpacity: Double = 0.5 // Button glow animation state
    
    @FocusState private var focus: FocusableField?
    
    private func signInWithEmailPassword() {
      Task {
        if await viewModel.signInWithEmailPassword() == true {
          dismiss()
        }
      }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Aurora Glow and Waves Background
            ZStack {

                // Aurora Wave Layers
                AuroraWave(offset: waveOffset1, amplitude: 80, colors: [.blue.opacity(0.3), .green.opacity(0.2), .clear])
                    .frame(height: 150)
                    .opacity(waveOpacity1)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                            waveOpacity1 = 0.8
                        }
                    }
                AuroraWave(offset: waveOffset2, amplitude: 90, colors: [.red.opacity(0.9), .purple.opacity(0.2), .clear])
                    .frame(height: 150)
                    .opacity(waveOpacity2)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                            waveOpacity2 = 0.9
                        }
                    }
                AuroraWave(offset: waveOffset3, amplitude: 100, colors: [.green.opacity(0.05), .red.opacity(0.1), .clear])
                    .frame(height: 100)
                    .opacity(waveOpacity3)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                            waveOpacity3 = 0.6
                        }
                    }
                AuroraWave(offset: waveOffset4, amplitude: 50, colors: [.blue.opacity(0.9), .green.opacity(0.1), .clear])
                    .frame(height: 100)
                    .opacity(waveOpacity4)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                            waveOpacity4 = 0.7
                        }
                    }
                VStack(spacing: 10) { // Adjust spacing if needed
                    Text("My Sober Life")
                        .font(Font.custom("GreatVibes-Regular", size: 55))
                        .fontWeight(.heavy)
                        .foregroundColor(colorScheme == .dark ? .white : .navyBlue) // Dynamic text color
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [Color.white, Color.gray]), startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.top, 50)
                        .opacity(0.85)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(height: 300)

            // Login Form
            VStack(spacing: 15) {
                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focus, equals: .email)
                    .submitLabel(.next)
                    .padding()
                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2))
                    .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text field text color
                    .cornerRadius(10)
                    .onSubmit {
                      self.focus = .password
                    }
                
                SecureField("Password", text: $viewModel.password)
                    .focused($focus, equals: .password)
                    .submitLabel(.go)
                    .padding()
                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2))
                    .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text field text color
                    .cornerRadius(10)
                    .onSubmit {
                      signInWithEmailPassword()
                    }
                
                Button(action: signInWithEmailPassword) {
                    WavyGradientButton(waveOffset: waveOffset)
                        .frame(maxWidth: .infinity, maxHeight: 50) // Fixed button height
                        .cornerRadius(10)
                        .opacity(buttonGlowOpacity)
                        .shadow(color: Color.blue.opacity(buttonGlowOpacity), radius: 20, x: 0, y: 0) // Glow effect
                        .overlay(
                            Text("Login")
                                .font(Font.custom("ShadowsIntoLight", size: 30))
                                .foregroundColor(colorScheme == .dark ? .white : .navyBlue) // Dynamic text color
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
                        Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
                    ) {
                        buttonGlowOpacity = 0.9
                    }
                }
                
                Text("Don't have an account yet?")
                Button(action: { viewModel.switchFlow() }) {
                  Text("Sign up")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .safeAreaInset(edge: .bottom) {
                // Add padding or UI for the safe area
                Spacer().frame(height: 16)
            }
            .padding([.top, .bottom], 50)
        }
        .background(colorScheme == .dark ? Color.black : Color.white) // Dynamic background
        .ignoresSafeArea()
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

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

