import SwiftUI

struct VibrantPatternRowView: View {
    let pattern: Pattern
    
    private var categoryColor: Color {
        switch pattern.category {
        case .dress:
            return DesignSystem.primaryPink
        case .top:
            return DesignSystem.primaryOrange
        case .pants:
            return DesignSystem.primaryTeal
        case .skirt:
            return DesignSystem.primaryTeal
        case .jacket:
            return DesignSystem.primaryPurple
        case .accessory:
            return DesignSystem.primaryYellow
        case .other:
            return Color.gray
        }
    }
    
    private var difficultyColor: Color {
        switch pattern.difficulty {
        case .beginner:
            return Color.green
        case .intermediate:
            return DesignSystem.primaryOrange
        case .advanced:
            return Color.red
        case .expert:
            return Color.yellow
        }
    }
    
    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [categoryColor.opacity(0.1), categoryColor.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Vibrant thumbnail
            RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                .fill(categoryColor.opacity(0.1))
                .frame(width: 70, height: 90)
                .overlay(
                    VStack {
                        Text("📄")
                            .font(.title)
                        Text("Pattern")
                            .font(DesignSystem.captionFont)
                            .foregroundColor(categoryColor)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                        .stroke(categoryColor, lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("✂️ \(pattern.name)")
                    .font(DesignSystem.headlineFont)
                    .foregroundColor(DesignSystem.primaryTextColor)
                    .lineLimit(1)
                
                if !pattern.brand.isEmpty {
                    Text("🏷️ \(pattern.brand)")
                        .font(DesignSystem.bodyFont)
                        .foregroundColor(DesignSystem.secondaryTextColor)
                }
                
                HStack(spacing: 8) {
                    Text(pattern.category.rawValue)
                        .font(DesignSystem.captionFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor)
                        .clipShape(Capsule())
                    
                    Text(pattern.difficulty.rawValue)
                        .font(DesignSystem.captionFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    if pattern.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= pattern.rating ? "star.fill" : "star")
                                    .foregroundColor(DesignSystem.primaryYellow)
                                    .font(DesignSystem.captionFont)
                            }
                        }
                    }
                    
                    if pattern.pdfData != nil, let fileType = pattern.fileType {
                        Image(systemName: fileType.icon)
                            .font(DesignSystem.captionFont)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
        }
        .vibrantCard(gradient: cardGradient, borderColor: categoryColor)
        .shadow(color: categoryColor.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}


#Preview {
    let samplePattern = Pattern(
        name: "Summer Dress",
        brand: "Burda",
        category: .dress,
        difficulty: .intermediate
    )
    samplePattern.rating = 4
    
    return VibrantPatternRowView(pattern: samplePattern)
        .padding()
}