import SwiftUI

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.bodyFont)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [DesignSystem.primaryPink, DesignSystem.primaryOrange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.easeInOutAnimation, value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style  
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.bodyFont)
            .foregroundColor(DesignSystem.primaryPink)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                    .stroke(DesignSystem.primaryPink, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.easeInOutAnimation, value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.bodyFont)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.easeInOutAnimation, value: configuration.isPressed)
    }
}

// MARK: - Card Button Style
struct CardButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let borderColor: Color
    
    init(gradient: LinearGradient, borderColor: Color) {
        self.gradient = gradient
        self.borderColor = borderColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(DesignSystem.cardPadding)
            .background(gradient)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                    .stroke(borderColor, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.springAnimation, value: configuration.isPressed)
    }
}

// MARK: - Floating Action Button Style
struct FloatingActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(DesignSystem.headerGradient)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(DesignSystem.springAnimation, value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style
struct IconButtonStyle: ButtonStyle {
    let color: Color
    let size: CGFloat
    
    init(color: Color = DesignSystem.primaryPink, size: CGFloat = 44) {
        self.color = color
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.1))
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(DesignSystem.easeInOutAnimation, value: configuration.isPressed)
    }
}

// MARK: - Chip Button Style
struct ChipButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.captionFont)
            .foregroundColor(isSelected ? .white : DesignSystem.primaryPink)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? DesignSystem.primaryPink : Color.white
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(DesignSystem.primaryPink, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.easeInOutAnimation, value: configuration.isPressed)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Button("Primary Button") {}
                .buttonStyle(PrimaryButtonStyle())
            
            Button("Secondary Button") {}
                .buttonStyle(SecondaryButtonStyle())
            
            Button("Destructive") {}
                .buttonStyle(DestructiveButtonStyle())
            
            Button(action: {}) {
                Text("Card Content")
                    .font(DesignSystem.titleFont)
            }
            .buttonStyle(CardButtonStyle(
                gradient: DesignSystem.pinkCardGradient,
                borderColor: DesignSystem.primaryPink
            ))
            
            Button(action: {}) {
                Image(systemName: "plus")
            }
            .buttonStyle(FloatingActionButtonStyle())
            
            Button(action: {}) {
                Image(systemName: "heart")
            }
            .buttonStyle(IconButtonStyle())
            
            HStack {
                Button("Selected") {}
                    .buttonStyle(ChipButtonStyle(isSelected: true))
                
                Button("Unselected") {}
                    .buttonStyle(ChipButtonStyle(isSelected: false))
            }
        }
        .padding()
    }
    .background(DesignSystem.backgroundColor)
}