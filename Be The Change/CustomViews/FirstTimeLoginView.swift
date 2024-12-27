//
//  FirstTimeLoginView.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/19/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct FirstTimeLoginView: View {
    @State private var currentStep: Int = 1 // Track current question
    @State private var dateOfBirth: Date = Date()
    @State private var sobrietyDate: Date = Date()
    @State private var accomplishment: String = ""
    @State private var doingThisFor: String = ""
    @State private var events: String = ""
    @State private var name: String = ""
    @State private var phone: String = ""
    @EnvironmentObject var authViewModel: AuthViewModel // Access the user information
    
    var body: some View {
        VStack {
            if currentStep == 1 {
                QuestionView(
                    title: "What is your name?",
                    content: {
                        TextField("Your answer", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    },
                    onNext: { currentStep += 1 }
                )
            } else if currentStep == 2 {
                QuestionView(
                    title: "What is your birthday?",
                    content: {
                        DatePicker(
                            "Select your birthday",
                            selection: $dateOfBirth,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                    },
                    onNext: { currentStep += 1 }
                )
            } else if currentStep == 3 {
                QuestionView(
                    title: "What date did you decide to become sober?",
                    content: {
                        DatePicker(
                            "Select the date",
                            selection: $sobrietyDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                    },
                    onNext: { currentStep += 1 }
                )
            } else if currentStep == 4 {
                QuestionView(
                    title: "What is one thing you want to accomplish once sober?",
                    content: {
                        TextField("Your answer", text: $accomplishment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    },
                    onNext: { currentStep += 1 }
                )
            } else if currentStep == 5 {
                QuestionView(
                    title: "Why did you decide to become sober?",
                    content: {
                        TextField("Your answer", text: $doingThisFor)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    },
                    onNext: { currentStep += 1 }
                )
            } else if currentStep == 6 {
                QuestionView(
                    title: "What is your Phone Number?",
                    content: {
                        TextField("Your answer", text: $phone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    },
                    onNext: { currentStep += 1 }
                )
            } else if currentStep == 7 {
                VStack(spacing: 20) {
                    Text("Thank you!")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Press Finish to save your responses and start your journey.")
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                    
                    Button(action: {
                        saveResponsesToFirestore()
                    }) {
                        Text("Finish")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            
            Spacer()
            Button(action: authViewModel.signOut) {
                Text("Sign Out")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
        .animation(.easeInOut, value: currentStep)
    }

    private func saveResponsesToFirestore() {
        guard let userId = authViewModel.user?.uid else { return }
        
        let firestore = Firestore.firestore()
        firestore.collection("users").document(userId).setData([
            "name": name,
            "phone": phone,
            "dateOfBirth": dateOfBirth,
            "sobrietyDate": sobrietyDate,
            "accomplishment": accomplishment,
            "doingThisFor": doingThisFor
        ], merge: true) { error in
            if let error = error {
                print("Error saving responses: \(error.localizedDescription)")
            } else {
                Task {
                    await authViewModel.completeFirstLogin()
                }
            }
        }
    }
}

#Preview {
    FirstTimeLoginView()
        .environmentObject(AuthViewModel())
}
