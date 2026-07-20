import SwiftUI

// MARK: - App Entry Point
/// Main entry point for the Carrom AI Coach application.

@main
struct CarromAICoachApp: App {
    
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
