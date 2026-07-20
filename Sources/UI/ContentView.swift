import SwiftUI

// MARK: - Content View
/// Root view that switches between screens based on app state.

struct ContentView: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            switch appState.currentScreen {
            case .colorSelection:
                ColorPickerView()
                    .transition(.opacity)
                
            case .scanning:
                ScanView()
                    .transition(.move(edge: .trailing))
                
            case .result:
                ResultView()
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
        .preferredColorScheme(.dark)
    }
}
