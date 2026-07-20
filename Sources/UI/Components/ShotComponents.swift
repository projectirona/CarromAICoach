import SwiftUI

// MARK: - Power Indicator
/// Visual power meter displaying shot power on a 1-10 scale.

struct PowerIndicator: View {
    
    let power: Int
    
    private var fillColor: Color {
        switch power {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.caption)
                .foregroundColor(fillColor)
            
            // Power bars
            HStack(spacing: 2) {
                ForEach(1...10, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(level <= power ? fillColor : Color.white.opacity(0.1))
                        .frame(width: 4, height: 16)
                }
            }
            
            Text("\(power)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundColor(fillColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Probability Badge
/// Displays the success probability as a colored percentage badge.

struct ProbabilityBadge: View {
    
    let probability: Double
    
    private var color: Color {
        switch probability {
        case 0.7...: return .green
        case 0.4..<0.7: return .yellow
        default: return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(Int(probability * 100))%")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundColor(color)
            
            Text("success")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
                .overlay(
                    Capsule()
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Shot Info Card
/// Compact card showing the recommended shot details.

struct ShotInfoCard: View {
    
    let recommendation: Recommendation
    
    var body: some View {
        VStack(spacing: 8) {
            // Shot details grid
            HStack(spacing: 16) {
                infoItem(
                    icon: "scope",
                    label: "Target",
                    value: recommendation.targetCoinDisplay
                )
                
                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.1))
                
                infoItem(
                    icon: "arrow.down.right.circle",
                    label: "Pocket",
                    value: recommendation.targetPocketDisplay
                )
                
                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.1))
                
                infoItem(
                    icon: "arrow.triangle.branch",
                    label: "Type",
                    value: recommendation.shotTypeDisplay
                )
            }
            
            // Pocketable coins count
            HStack {
                Image(systemName: "circle.grid.2x2.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("\(recommendation.pocketableCoinsCount) pocketable coin\(recommendation.pocketableCoinsCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                // Aim angle
                Text("Aim: \(Int(recommendation.shot.aimAngle * 180 / .pi))°")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 4)
        }
    }
    
    private func infoItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.orange)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}
