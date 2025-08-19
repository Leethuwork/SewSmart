import SwiftUI

struct DesignSystem {
    
    // MARK: - Vibrant Color Palette
    static let primaryPink = Color(red: 1.0, green: 0.42, blue: 0.62)      // #FF6B9D
    static let primaryOrange = Color(red: 0.97, green: 0.58, blue: 0.12)   // #F7931E
    static let primaryYellow = Color(red: 1.0, green: 0.82, blue: 0.25)    // #FFD23F
    static let primaryTeal = Color(red: 0.31, green: 0.80, blue: 0.77)     // #4ECDC4
    static let primaryPurple = Color(red: 0.61, green: 0.35, blue: 0.71)   // #9B59B6
    
    // MARK: - Gradient Definitions
    static let headerGradient = LinearGradient(
        colors: [primaryPink, primaryOrange, primaryYellow],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let pinkCardGradient = LinearGradient(
        colors: [primaryPink.opacity(0.1), primaryPink.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let orangeCardGradient = LinearGradient(
        colors: [primaryOrange.opacity(0.1), primaryOrange.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let tealCardGradient = LinearGradient(
        colors: [primaryTeal.opacity(0.1), primaryTeal.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let purpleCardGradient = LinearGradient(
        colors: [primaryPurple.opacity(0.1), primaryPurple.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Project Status Colors
    static func colorForStatus(_ status: ProjectStatus) -> Color {
        switch status {
        case .planning:
            return primaryOrange
        case .inProgress:
            return primaryPink
        case .completed:
            return primaryTeal
        case .onHold:
            return primaryPurple
        }
    }
    
    static func gradientForStatus(_ status: ProjectStatus) -> LinearGradient {
        switch status {
        case .planning:
            return orangeCardGradient
        case .inProgress:
            return pinkCardGradient
        case .completed:
            return tealCardGradient
        case .onHold:
            return purpleCardGradient
        }
    }
    
    // MARK: - Background Colors
    static let backgroundColor = Color(red: 1.0, green: 0.97, blue: 0.94)  // #FFF8F0
    static let cardBackgroundColor = Color.white
    static let secondaryBackgroundColor = Color(red: 0.96, green: 0.97, blue: 0.98)  // #F5F7FA
    
    // MARK: - Text Colors
    static let primaryTextColor = Color(red: 0.17, green: 0.24, blue: 0.31)  // #2C3E50
    static let secondaryTextColor = Color(red: 0.42, green: 0.46, blue: 0.51)  // #6C757D
    
    // MARK: - Typography
    static let largeTitleFont = Font.system(size: 32, weight: .heavy, design: .default)
    static let titleFont = Font.system(size: 20, weight: .bold, design: .default)
    static let headlineFont = Font.system(size: 18, weight: .semibold, design: .default)
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 12, weight: .medium, design: .default)
    
    // MARK: - Spacing
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 16
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
    
    // MARK: - Animations
    static let springAnimation = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let easeInOutAnimation = Animation.easeInOut(duration: 0.3)
}

// MARK: - View Extensions
extension View {
    func vibrantCard(gradient: LinearGradient, borderColor: Color) -> some View {
        self
            .padding(DesignSystem.cardPadding)
            .background(gradient)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                    .stroke(borderColor, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
    }
    
    func statusBadge(status: ProjectStatus) -> some View {
        Text(status.rawValue.uppercased())
            .font(DesignSystem.captionFont)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(DesignSystem.colorForStatus(status))
            .clipShape(Capsule())
    }
    
    func vibrantProgressBar(progress: Double, color: Color) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: 8)
                
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .offset(x: geometry.size.width * progress - 4)
            }
        }
        .frame(height: 8)
    }
}