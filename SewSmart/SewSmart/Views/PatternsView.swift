import SwiftUI
import SwiftData

struct PatternsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pattern.createdDate, order: .reverse) private var patterns: [Pattern]
    @State private var showingAddPattern = false
    @State private var selectedPattern: Pattern?
    @State private var searchText = ""
    @State private var selectedCategory: PatternCategory?
    
    private var filteredPatterns: [Pattern] {
        var filtered = patterns
        
        if !searchText.isEmpty {
            filtered = filtered.filter { pattern in
                pattern.name.localizedCaseInsensitiveContains(searchText) ||
                pattern.brand.localizedCaseInsensitiveContains(searchText) ||
                pattern.tags.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("📄 Patterns")
                                .font(DesignSystem.titleFont)
                                .foregroundColor(DesignSystem.primaryTextColor)
                            Text("Your sewing pattern collection")
                                .font(DesignSystem.bodyFont)
                                .foregroundColor(DesignSystem.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingAddPattern = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(DesignSystem.primaryPink)
                        }
                    }
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryFilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                color: .gray
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(PatternCategory.allCases, id: \.self) { category in
                                CategoryFilterChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    color: categoryColor(for: category)
                                ) {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(DesignSystem.backgroundColor)
                
                Divider()
                    .background(DesignSystem.secondaryTextColor.opacity(0.3))
                
                // Content Area
                ZStack {
                    DesignSystem.backgroundColor.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Stats Bar
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(filteredPatterns.count)")
                                    .font(DesignSystem.titleFont)
                                    .foregroundColor(DesignSystem.primaryTextColor)
                                Text("patterns")
                                    .font(DesignSystem.captionFont)
                                    .foregroundColor(DesignSystem.secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            if !searchText.isEmpty || selectedCategory != nil {
                                Button("Clear filters") {
                                    searchText = ""
                                    selectedCategory = nil
                                }
                                .font(DesignSystem.captionFont)
                                .foregroundColor(DesignSystem.primaryPink)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(DesignSystem.cardBackgroundColor)
                        
                        // Patterns List
                        if filteredPatterns.isEmpty {
                            VStack(spacing: 16) {
                                Text("📄")
                                    .font(.system(size: 64))
                                Text("No Patterns Yet")
                                    .font(DesignSystem.titleFont)
                                    .foregroundColor(DesignSystem.primaryTextColor)
                                Text("Add your first sewing pattern! ✨")
                                    .font(DesignSystem.bodyFont)
                                    .foregroundColor(DesignSystem.secondaryTextColor)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DesignSystem.backgroundColor)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: DesignSystem.cardSpacing) {
                                    ForEach(filteredPatterns) { pattern in
                                        VibrantPatternRowView(pattern: pattern)
                                            .onTapGesture {
                                                selectedPattern = pattern
                                            }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(DesignSystem.backgroundColor)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .searchable(text: $searchText, prompt: "Search patterns...")
            .sheet(isPresented: $showingAddPattern) {
                AddPatternView()
            }
            .sheet(item: $selectedPattern) { pattern in
                PatternDetailView(pattern: pattern)
            }
        }
    }
    
    private func deletePatterns(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredPatterns[index])
            }
        }
    }
    
    private func categoryColor(for category: PatternCategory) -> Color {
        switch category {
        case .dress: return DesignSystem.primaryPink
        case .top: return DesignSystem.primaryOrange
        case .pants: return DesignSystem.primaryTeal
        case .skirt: return DesignSystem.primaryTeal
        case .jacket: return DesignSystem.primaryPurple
        case .accessory: return DesignSystem.primaryYellow
        case .other: return .gray
        }
    }
}

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.captionFont)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(16)
        }
    }
}

#Preview {
    PatternsView()
        .modelContainer(for: Pattern.self, inMemory: true)
}