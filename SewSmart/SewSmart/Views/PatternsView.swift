import SwiftUI
import SwiftData

struct PatternsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pattern.createdDate, order: .reverse) private var patterns: [Pattern]
    @State private var viewModel: PatternsViewViewModel?
    
    private var filteredPatterns: [Pattern] {
        viewModel?.filteredPatterns(from: patterns) ?? patterns
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
                        
                        Button(action: { viewModel?.showAddPattern() }) {
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
                                isSelected: viewModel?.selectedCategory == nil,
                                color: .gray
                            ) {
                                viewModel?.selectCategory(nil)
                            }
                            
                            ForEach(PatternCategory.allCases, id: \.self) { category in
                                CategoryFilterChip(
                                    title: category.rawValue,
                                    isSelected: viewModel?.selectedCategory == category,
                                    color: viewModel?.categoryColor(for: category) ?? .gray
                                ) {
                                    viewModel?.selectCategory(category)
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
                            
                            if viewModel?.hasActiveFilters == true {
                                Button("Clear filters") {
                                    viewModel?.clearFilters()
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
                            let config = (viewModel?.hasActiveFilters == true) ? 
                                viewModel?.getFilteredEmptyStateConfiguration() : 
                                viewModel?.getEmptyStateConfiguration()
                            
                            VStack(spacing: 16) {
                                Text(config?.emoji ?? "📄")
                                    .font(.system(size: config?.emojiSize ?? 64))
                                Text(config?.title ?? "No Patterns Yet")
                                    .font(DesignSystem.titleFont)
                                    .foregroundColor(DesignSystem.primaryTextColor)
                                Text(config?.subtitle ?? "Add your first sewing pattern! ✨")
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
                                                viewModel?.selectPattern(pattern)
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
            .searchable(text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ), prompt: "Search patterns...")
            .sheet(isPresented: Binding(
                get: { viewModel?.showingAddPattern ?? false },
                set: { _ in viewModel?.hideAddPattern() }
            )) {
                AddPatternView()
            }
            .sheet(item: Binding(
                get: { viewModel?.selectedPattern },
                set: { _ in viewModel?.deselectPattern() }
            )) { pattern in
                PatternDetailView(pattern: pattern)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = PatternsViewViewModel(modelContext: modelContext)
                }
            }
        }
    }
    
    private func deletePatterns(offsets: IndexSet) {
        withAnimation {
            viewModel?.deletePatterns(at: offsets, from: filteredPatterns)
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