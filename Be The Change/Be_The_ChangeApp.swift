//
//  Be_The_ChangeApp.swift
//  Be The Change
//
//  Created by Peter Ferreira on 11/12/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Network

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        initializeFirebase()
//        configureEmulators()
        monitorNetworkConnectivity()
        print("Firebase initialized successfully.")
        return true
    }

    /// Initialize Firebase SDK
    private func initializeFirebase() {
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
    }

    /// Configure Firebase emulators for development
    private func configureEmulators() {
        let host = "192.168.68.63" // Replace with your local IP if testing on a physical device

        // Configure Firebase Authentication emulator
        Auth.auth().useEmulator(withHost: host, port: 9099)

        // Configure Firestore emulator
        configureFirestoreEmulator(withHost: host, port: 8080)

        // Configure Firebase Storage emulator
        Storage.storage().useEmulator(withHost: "localhost", port: 9199)

        // Ensure session persistence for Authentication
        let auth = Auth.auth()
        auth.settings?.isAppVerificationDisabledForTesting = false
    }

    /// Configure Firestore emulator with specific host and port
    private func configureFirestoreEmulator(withHost host: String, port: Int) {
        let settings = Firestore.firestore().settings
//        settings.host = "192.168.68.63:8080"
//        127.0.0.1
        settings.host = "127.0.0.1:8080"
        settings.cacheSettings = MemoryCacheSettings() // Disable persistence for emulators
        settings.isSSLEnabled = false // No SSL for local emulators
        Firestore.firestore().settings = settings
        print("Firestore emulator configured at \(host):\(port).")
    }
    
    private func monitorNetworkConnectivity() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Connected to the internet.")
            } else {
                print("No internet connection.")
            }
        }
        monitor.start(queue: queue)
    }
}

@main
struct BeTheChangeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}

extension Color {
    static let navyBlue = Color(red: 0.0, green: 0.0, blue: 0.5) // Custom Navy Blue color
}
