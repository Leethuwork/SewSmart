import SwiftUI

struct PatternRowView: View {
    let pattern: Pattern
    
    var body: some View {
        HStack(spacing: DesignSystemExtended.mediumSpacing) {
            // Pattern Image or Placeholder
            Group {
                if let thumbnailData = pattern.thumbnailData, let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                        .fill(categoryGradient)
                        .overlay(
                            Image(systemName: "doc.text")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius))
            
            // Pattern Details
            VStack(alignment: .leading, spacing: DesignSystemExtended.tinySpacing) {
                Text(pattern.name)
                    .font(DesignSystem.headlineFont)
                    .foregroundColor(DesignSystem.primaryTextColor)
                    .lineLimit(1)
                
                if !pattern.brand.isEmpty {
                    Text(pattern.brand)
                        .font(DesignSystem.bodyFont)
                        .foregroundColor(DesignSystem.secondaryTextColor)
                        .lineLimit(1)
                }
                
                HStack(spacing: DesignSystemExtended.smallSpacing) {
                    // Category Badge
                    Text(pattern.category.rawValue)
                        .font(DesignSystem.captionFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor)
                        .clipShape(Capsule())
                    
                    // Difficulty Badge
                    Text(pattern.difficulty.rawValue)
                        .font(DesignSystem.captionFont)
                        .foregroundColor(difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Action Indicators
            VStack(spacing: DesignSystemExtended.tinySpacing) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignSystem.secondaryTextColor)
                
                Spacer()
                
                Text(pattern.createdDate, style: .date)
                    .font(DesignSystem.captionFont)
                    .foregroundColor(DesignSystem.secondaryTextColor)
            }
            .frame(height: 60)
        }
        .padding(DesignSystem.cardPadding)
        .background(DesignSystem.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
        .lightShadow()
    }
    
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
    
    private var categoryGradient: LinearGradient {
        LinearGradient(
            colors: [categoryColor, categoryColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var difficultyColor: Color {
        switch pattern.difficulty {
        case .beginner:
            return Color.green
        case .intermediate:
            return Color.orange
        case .advanced:
            return Color.red
        case .expert:
            return Color.purple
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PatternRowView(
            pattern: Pattern(
                name: "Summer Dress Pattern",
                brand: "Mood Fabrics",
                category: .dress,
                difficulty: .intermediate
            )
        )
        
        PatternRowView(
            pattern: Pattern(
                name: "Basic T-Shirt",
                brand: "",
                category: .top,
                difficulty: .beginner
            )
        )
        
        PatternRowView(
            pattern: Pattern(
                name: "Winter Coat with Complex Construction",
                brand: "Advanced Patterns Co.",
                category: .jacket,
                difficulty: .advanced
            )
        )
    }
    .padding()
    .background(DesignSystem.backgroundColor)
}