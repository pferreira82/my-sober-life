import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import Combine

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

enum AuthenticationFlow {
    case login
    case signUp
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var hasCompletedFirstLogin: Bool = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var errorMessage: String = ""
    @Published var displayName: String = ""
    @Published var user: User? {
        didSet {
            displayName = user?.displayName ?? "No Name"
        }
    }

    @Published var flow: AuthenticationFlow = .login
    @Published var isValid: Bool = false
    private var cancellables: Set<AnyCancellable> = []

    init() {
        Task {
            await registerAuthStateHandler()
        }
        
        validateInputs()

        $flow
            .sink { newFlow in
                print("Flow updated to: \(newFlow == .login ? "Login" : "Sign Up")")
            }
            .store(in: &cancellables)
    }

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    private func updateAuthenticationState(with user: User?) async {
        self.user = user
        if let user = user {
            print("User authenticated: \(user.uid)")
            authenticationState = .authenticated
            hasCompletedFirstLogin = (try? await fetchHasCompletedFirstLogin(userId: user.uid)) ?? false
            print("Has completed first login: \(hasCompletedFirstLogin)")
        } else {
            print("User not authenticated.")
            authenticationState = .unauthenticated
            hasCompletedFirstLogin = false
        }
    }
    
    private func validateInputs() {
        $email
            .combineLatest($password, $confirmPassword)
            .map { email, password, confirmPassword in
                // Email must be valid, password must have at least 6 characters, and passwords must match
                return !email.isEmpty &&
                       email.contains("@") &&
                       email.contains(".") &&
                       password.count >= 6 &&
                       confirmPassword == password
            }
            .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread
            .assign(to: &$isValid)
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            reset()
            
            print("User successfully signed out.")
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
            print(errorMessage)
        }
    }
    
    func switchFlow() {
        flow = (flow == .login) ? .signUp : .login
        print("Flow switched to: \(flow == .login ? "Login" : "Sign Up")")
        errorMessage = "" // Clear any previous errors
    }

    func registerAuthStateHandler() async {
        guard FirebaseApp.app() != nil else {
            print("FirebaseApp not initialized.")
            return
        }

        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task {
                    await self?.updateAuthenticationState(with: user)
                }
            }
        }
    }
    
    func reset() {
        // Reset the authentication-related properties
        user = nil
        email = ""
        password = ""
        confirmPassword = ""
        authenticationState = .unauthenticated
        hasCompletedFirstLogin = false
        errorMessage = ""
        displayName = "No Name"

        // Reset flow to default (e.g., login)
        self.flow = .login

        // Reset authentication state to unauthenticated
        self.authenticationState = .unauthenticated
    }

    func signInWithEmailPassword() async -> Bool {
        authenticationState = .authenticating
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            user = authResult.user
            authenticationState = .authenticated

            let hasCompleted = try await fetchHasCompletedFirstLogin(userId: authResult.user.uid)
            hasCompletedFirstLogin = hasCompleted

            return true
        } catch {
            errorMessage = error.localizedDescription
            authenticationState = .unauthenticated
            return false
        }
    }

    func signUpWithEmailPassword() async -> Bool {
        authenticationState = .authenticating
        guard isValid else {
            errorMessage = "Please ensure all fields are valid."
            return false
        }
        do {
            let authResult = try await createUserSafely(withEmail: email, password: password)
            user = authResult.user
            authenticationState = .authenticated

            // Create a user document in Firestore
            try await createUserDocument(userId: authResult.user.uid, email: email)
            print("User signed up successfully.")
            return true
        } catch {
            print("Sign up error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            authenticationState = .unauthenticated
            return false
        }
    }

    private func createUserSafely(withEmail email: String, password: String) async throws -> AuthDataResult {
        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let result = result {
                    continuation.resume(returning: result)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "AuthError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred while creating user"]
                    ))
                }
            }
        }
    }

    private func fetchHasCompletedFirstLogin(userId: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            Firestore.firestore().collection("users").document(userId).getDocument { document, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = document?.data(), let hasCompleted = data["hasCompletedFirstLogin"] as? Bool {
                    continuation.resume(returning: hasCompleted)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "FetchError",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Missing or invalid data"]
                    ))
                }
            }
        }
    }

    private func createUserDocument(userId: String, email: String) async throws {
        try await Firestore.firestore().collection("users").document(userId).setData([
            "email": email,
            "displayName": "User",
            "hasCompletedFirstLogin": false
        ])
    }
    
    func completeFirstLogin() async {
        guard let userId = user?.uid else {
            print("Error: User ID not found.")
            return
        }
        
        let data: [String: Any] = [
            "hasCompletedFirstLogin": true
        ]
        let firestore = Firestore.firestore()
        
        do {
            try await firestore.collection("users").document(userId).updateData(data)
            DispatchQueue.main.async {
                self.hasCompletedFirstLogin = true
            }
            print("First login completion status updated successfully.")
        } catch {
            print("Error updating first login status: \(error.localizedDescription)")
        }
    }

}
