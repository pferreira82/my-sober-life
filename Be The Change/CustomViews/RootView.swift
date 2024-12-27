//
//  RootView.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/21/24.
//

import SwiftUI
import FirebaseFirestore

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isFirestoreAccessible = true // Firestore accessibility tracker

    var body: some View {
        Group {
            if !isFirestoreAccessible {
                VStack {
                    Text("We're currently experiencing server issues.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()

                    AuthView().environmentObject(authViewModel)
                }
            } else {
                switch authViewModel.authenticationState {
                case .unauthenticated:
                    AuthView().environmentObject(authViewModel)
                case .authenticated:
                    if authViewModel.hasCompletedFirstLogin {
                        MainAppView().environmentObject(authViewModel)
                    } else {
                        FirstTimeLoginView().environmentObject(authViewModel)
                    }
                case .authenticating:
                    ProgressView("Authenticating...")
                }
            }
        }
        .onAppear {
            checkFirestoreAccess() // Verify Firestore access on app start
        }
    }

    /// Check if Firestore is accessible
    private func checkFirestoreAccess() {
        let firestore = Firestore.firestore()
        let testDoc = firestore.collection("test").document("connectivity_check")
        
        testDoc.setData(["status": "connected"], merge: true) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Firestore emulator access error: \(error.localizedDescription)")
                    isFirestoreAccessible = false
                } else {
                    isFirestoreAccessible = true
                    print("Connected to Firestore emulator successfully.")
                }
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AuthViewModel())
    }
}


//#Preview {
//    RootView()
//        .environmentObject(AuthViewModel())
//}
