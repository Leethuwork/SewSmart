import SwiftUI
import SwiftData

struct PatternsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PatternsViewModel?
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    private var filteredPatterns: [Pattern] {
        viewModel?.patterns ?? []
    }
    
    var body: some View {
        SewSmartNavigationStack {
            VStack(spacing: 0) {
                // Custom Navigation Bar
                SewSmartNavigationBar(
                    title: "Patterns",
                    subtitle: "\(filteredPatterns.count) patterns",
                    trailingIcon: "plus",
                    trailingAction: { viewModel?.showingAddPattern = true }
                )
                
                VStack(spacing: DesignSystemExtended.mediumSpacing) {
                    // Search Bar
                    SewSmartSearchBar(
                        searchText: Binding(
                            get: { viewModel?.searchText ?? "" },
                            set: { viewModel?.updateSearchText($0) }
                        ),
                        placeholder: "Search patterns..."
                    )
                    .padding(.horizontal, DesignSystem.cardPadding)
                    
                    // Category Filter
                    FilterChipsView(
                        options: PatternCategory.allCases,
                        selectedOption: Binding(
                            get: { viewModel?.selectedCategory },
                            set: { category in
                                viewModel?.selectedCategory = category
                                Task {
                                    await viewModel?.loadPatterns()
                                }
                            }
                        )
                    )
                }
                .padding(.top, DesignSystemExtended.smallSpacing)
                
                // Content Area with Loading States
                LoadingStateView(
                    state: viewModel?.patternsState ?? .idle,
                    retryAction: {
                        Task {
                            await viewModel?.loadPatterns()
                        }
                    }
                ) { patterns in
                    if patterns.isEmpty {
                        EmptyStateView(
                            title: "No Patterns Found",
                            description: viewModel?.selectedCategory != nil || !(viewModel?.searchText.isEmpty ?? true) ?
                                "Try adjusting your search or filters" :
                                "Get started by adding your first sewing pattern",
                            systemImage: "doc.text.badge.plus",
                            actionTitle: "Add Pattern",
                            action: { viewModel?.showingAddPattern = true }
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DesignSystem.cardSpacing) {
                                ForEach(patterns) { pattern in
                                    PatternRowView(pattern: pattern)
                                        .onTapGesture {
                                            viewModel?.selectedPattern = pattern
                                        }
                                }
                            }
                            .padding(.horizontal, DesignSystem.cardPadding)
                            .padding(.bottom, 100) // Tab bar spacing
                        }
                    }
                }
                
            }
            .background(DesignSystem.backgroundColor)
            .sheet(isPresented: Binding(
                get: { viewModel?.showingAddPattern ?? false },
                set: { _ in viewModel?.showingAddPattern = false }
            )) {
                AddPatternView()
            }
            .sheet(item: Binding(
                get: { viewModel?.selectedPattern },
                set: { _ in viewModel?.selectedPattern = nil }
            )) { pattern in
                PatternDetailView(pattern: pattern)
            }
            .task {
                if viewModel == nil {
                    viewModel = dependencyContainer.patternsViewModel
                    await viewModel?.loadPatterns()
                }
            }
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