import SwiftUI

// MARK: - SewSmart Navigation Stack
struct SewSmartNavigationStack<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        NavigationStack {
            content()
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(DesignSystem.backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Custom Navigation Bar
struct SewSmartNavigationBar: View {
    let title: String
    let subtitle: String?
    let leadingAction: (() -> Void)?
    let leadingIcon: String?
    let trailingAction: (() -> Void)?
    let trailingIcon: String?
    
    init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: String? = nil,
        leadingAction: (() -> Void)? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.leadingAction = leadingAction
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
    }
    
    var body: some View {
        HStack {
            // Leading button
            if let leadingIcon = leadingIcon, let leadingAction = leadingAction {
                Button(action: leadingAction) {
                    Image(systemName: leadingIcon)
                }
                .buttonStyle(IconButtonStyle(size: 32))
            } else {
                Spacer()
                    .frame(width: 32)
            }
            
            Spacer()
            
            // Title section
            VStack(spacing: 2) {
                Text(title)
                    .font(DesignSystem.titleFont)
                    .foregroundColor(DesignSystem.primaryTextColor)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.captionFont)
                        .foregroundColor(DesignSystem.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Trailing button
            if let trailingIcon = trailingIcon, let trailingAction = trailingAction {
                Button(action: trailingAction) {
                    Image(systemName: trailingIcon)
                }
                .buttonStyle(IconButtonStyle(size: 32))
            } else {
                Spacer()
                    .frame(width: 32)
            }
        }
        .padding(.horizontal, DesignSystem.cardPadding)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(DesignSystem.headerGradient)
                .ignoresSafeArea(edges: .top)
        )
    }
}

// MARK: - Tab Bar Item
struct SewSmartTabItem: View {
    let title: String
    let icon: String
    let selectedIcon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(
        title: String,
        icon: String,
        selectedIcon: String? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? (selectedIcon ?? icon) : icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? DesignSystem.primaryPink : DesignSystem.secondaryTextColor)
                
                Text(title)
                    .font(DesignSystem.captionFont)
                    .foregroundColor(isSelected ? DesignSystem.primaryPink : DesignSystem.secondaryTextColor)
            }
        }
        .animation(DesignSystem.easeInOutAnimation, value: isSelected)
    }
}

// MARK: - Search Bar
struct SewSmartSearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let onSearchTextChanged: ((String) -> Void)?
    
    init(
        searchText: Binding<String>,
        placeholder: String = "Search...",
        onSearchTextChanged: ((String) -> Void)? = nil
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.onSearchTextChanged = onSearchTextChanged
    }
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.secondaryTextColor)
            
            TextField(placeholder, text: $searchText)
                .font(DesignSystem.bodyFont)
                .foregroundColor(DesignSystem.primaryTextColor)
                .onChange(of: searchText) { oldValue, newValue in
                    onSearchTextChanged?(newValue)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onSearchTextChanged?("")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.secondaryTextColor)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(DesignSystem.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                .stroke(DesignSystem.primaryPink.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius))
    }
}

// MARK: - Filter Chips
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(title) {
            action()
        }
        .buttonStyle(ChipButtonStyle(isSelected: isSelected))
    }
}

struct FilterChipsView<T: CaseIterable & RawRepresentable>: View where T.RawValue == String, T: Hashable {
    let options: [T]
    @Binding var selectedOption: T?
    let onSelectionChanged: ((T?) -> Void)?
    
    init(
        options: [T],
        selectedOption: Binding<T?>,
        onSelectionChanged: ((T?) -> Void)? = nil
    ) {
        self.options = options
        self._selectedOption = selectedOption
        self.onSelectionChanged = onSelectionChanged
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedOption == nil
                ) {
                    selectedOption = nil
                    onSelectionChanged?(nil)
                }
                
                ForEach(options, id: \.self) { option in
                    FilterChip(
                        title: option.rawValue.capitalized,
                        isSelected: selectedOption == option
                    ) {
                        selectedOption = option
                        onSelectionChanged?(option)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.cardPadding)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SewSmartNavigationBar(
            title: "Projects",
            subtitle: "5 active projects",
            leadingIcon: "line.3.horizontal",
            leadingAction: {},
            trailingIcon: "plus",
            trailingAction: {}
        )
        
        SewSmartSearchBar(
            searchText: .constant(""),
            placeholder: "Search projects..."
        )
        
        HStack {
            SewSmartTabItem(
                title: "Projects",
                icon: "folder",
                selectedIcon: "folder.fill",
                isSelected: true,
                action: {}
            )
            
            Spacer()
            
            SewSmartTabItem(
                title: "Patterns",
                icon: "doc.text",
                selectedIcon: "doc.text.fill",
                isSelected: false,
                action: {}
            )
            
            Spacer()
            
            SewSmartTabItem(
                title: "Fabric",
                icon: "square.stack.3d.down.forward",
                selectedIcon: "square.stack.3d.down.forward.fill",
                isSelected: false,
                action: {}
            )
        }
        .padding(.horizontal, 40)
        
        Spacer()
    }
    .background(DesignSystem.backgroundColor)
}