import SwiftUI

// MARK: - Color Picker View
/// First screen: player selects their coin color (Black or White).

struct ColorPickerView: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Title
            VStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Carrom AI Coach")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Select your color to begin")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Color selection buttons
            HStack(spacing: 30) {
                ColorButton(
                    color: .black,
                    label: "Black",
                    fillColor: Color(white: 0.15),
                    borderColor: .white.opacity(0.3)
                ) {
                    appState.selectColor(.black)
                }
                
                ColorButton(
                    color: .white,
                    label: "White",
                    fillColor: Color(white: 0.95),
                    borderColor: .gray.opacity(0.3)
                ) {
                    appState.selectColor(.white)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Version info
            Text("v\(AppConstants.appVersion)")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom, 20)
        }
    }
}

// MARK: - Color Button

private struct ColorButton: View {
    let color: Color
    let label: String
    let fillColor: Color
    let borderColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Coin circle
                Circle()
                    .fill(fillColor)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .strokeBorder(borderColor, lineWidth: 2)
                    )
                    .shadow(color: fillColor.opacity(0.3), radius: 10)
                
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
        }
    }
}

// MARK: - Press Events Modifier

private struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}
