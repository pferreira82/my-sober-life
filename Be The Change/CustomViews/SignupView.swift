//
// SignupView.swift
// Favourites
//
// Created by Peter Friese on 08.07.2022
// Copyright © 2022 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI
import Combine

private enum FocusableField: Hashable {
    case email
    case password
    case confirmPassword
}

struct SignupView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var focus: FocusableField?
    
    private func signUpWithEmailPassword() {
        Task {
            if await viewModel.signUpWithEmailPassword() == true {
                dismiss() // Dismiss the view after successful sign-up
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // App Logo or Header
            VStack(spacing: 10) {
                Text("Create an Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Welcome to Be The Change!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 50)
            
            // Sign Up Form
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focus = .password
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                    SecureField("Password", text: $viewModel.password)
                        .focused($focus, equals: .password)
                        .submitLabel(.next)
                        .onSubmit {
                            focus = .confirmPassword
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.gray)
                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                        .focused($focus, equals: .confirmPassword)
                        .submitLabel(.done)
                        .onSubmit {
                            signUpWithEmailPassword()
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Display Error Message (if any)
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Sign Up Button
            Button(action: signUpWithEmailPassword) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!viewModel.isValid)
            .padding(.horizontal)
            
            Spacer()
            
            // Toggle to Login
            HStack {
                Text("Already have an account?")
                Button(action: {
                    viewModel.switchFlow() // Switch to Login Flow
                }) {
                    Text("Log In")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            focus = .email // Focus on the email field when the view appears
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
            .environmentObject(AuthViewModel())
    }
}

