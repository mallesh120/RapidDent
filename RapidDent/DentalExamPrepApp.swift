//
//  DentalRapidFireApp.swift
//  RapidDent
//
//  App entry point with Firebase configuration
//

import SwiftUI
import FirebaseCore

// AppDelegate for Firebase configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")
        return true
    }
}

@main
struct RapidDentApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
    }
}

