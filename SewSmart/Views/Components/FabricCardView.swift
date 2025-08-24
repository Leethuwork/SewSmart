import SwiftUI

struct FabricCardView: View {
    let fabric: Fabric
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystemExtended.smallSpacing) {
            // Fabric Image or Color Preview
            ZStack {
                if let imageData = fabric.photoData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Color-based preview
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [fabricTypeColor, fabricTypeColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: fabricTypeIcon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text(fabric.type.rawValue.capitalized)
                                    .font(DesignSystem.captionFont)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                        )
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius))
            .overlay(
                // Yardage badge
                VStack {
                    HStack {
                        Spacer()
                        Text("\(String(format: "%.1f", fabric.yardage)) yds")
                            .font(DesignSystem.captionFont)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(DesignSystemExtended.smallSpacing)
            )
            
            // Fabric Details
            VStack(alignment: .leading, spacing: DesignSystemExtended.tinySpacing) {
                Text(fabric.name)
                    .font(DesignSystem.headlineFont)
                    .foregroundColor(DesignSystem.primaryTextColor)
                    .lineLimit(2)
                
                if !fabric.color.isEmpty {
                    Text(fabric.color)
                        .font(DesignSystem.bodyFont)
                        .foregroundColor(DesignSystem.secondaryTextColor)
                        .lineLimit(1)
                }
                
                HStack {
                    // Type Badge
                    Text(fabric.type.rawValue)
                        .font(DesignSystem.captionFont)
                        .foregroundColor(fabricTypeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(fabricTypeColor.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Cost
                    if fabric.cost > 0 {
                        Text("$\(String(format: "%.0f", fabric.cost))")
                            .font(DesignSystem.captionFont)
                            .foregroundColor(DesignSystem.primaryTextColor)
                            .fontWeight(.semibold)
                    }
                }
                
                // Brand (if available)
                if !fabric.brand.isEmpty {
                    Text(fabric.brand)
                        .font(DesignSystem.captionFont)
                        .foregroundColor(DesignSystem.secondaryTextColor)
                        .lineLimit(1)
                }
            }
        }
        .padding(DesignSystem.cardPadding)
        .background(DesignSystem.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
        .lightShadow()
    }
    
    private var fabricTypeColor: Color {
        switch fabric.type {
        case .cotton:
            return DesignSystem.primaryTeal
        case .silk:
            return DesignSystem.primaryPurple
        case .wool:
            return DesignSystem.primaryOrange
        case .linen:
            return DesignSystem.primaryYellow
        case .polyester, .rayon, .denim, .jersey, .fleece, .other:
            return DesignSystem.primaryPink
        }
    }
    
    private var fabricTypeIcon: String {
        switch fabric.type {
        case .cotton:
            return "leaf"
        case .silk:
            return "sparkles"
        case .wool:
            return "snow"
        case .linen:
            return "wind"
        case .polyester:
            return "bolt.horizontal"
        case .rayon:
            return "drop"
        case .denim:
            return "rectangle.3.offgrid"
        case .jersey:
            return "sportscourt"
        case .fleece:
            return "cloud"
        case .other:
            return "square.grid.2x2"
        }
    }
}

#Preview {
    ScrollView(.vertical, showsIndicators: false) {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            FabricCardView(
                fabric: Fabric(
                    name: "Cotton Fabric",
                    type: .cotton,
                    color: "Blue",
                    yardage: 2.5
                )
            )
            
            FabricCardView(
                fabric: Fabric(
                    name: "Silk Fabric",
                    type: .silk,
                    color: "Red",
                    yardage: 1.0
                )
            )
        }
        .padding()
    }
}