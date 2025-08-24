import SwiftUI

/// A reusable view for handling loading states
struct LoadingStateView<T: Equatable, Content: View>: View {
    let state: LoadingState<T>
    let content: (T) -> Content
    let retryAction: (() -> Void)?
    
    init(
        state: LoadingState<T>,
        retryAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.state = state
        self.content = content
        self.retryAction = retryAction
    }
    
    var body: some View {
        switch state {
        case .idle:
            ContentUnavailableView(
                "No Data",
                systemImage: "doc.text",
                description: Text("Tap to load data")
            )
            
        case .loading:
            VStack(spacing: DesignSystem.cardSpacing) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading...")
                    .font(DesignSystem.bodyFont)
                    .foregroundColor(DesignSystem.secondaryTextColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.backgroundColor)
            
        case .loaded(let data):
            content(data)
            
        case .failed(let error):
            LoadingErrorView(
                error: error,
                retryAction: retryAction ?? {}
            )
        }
    }
}

/// A reusable view for displaying errors with retry functionality
struct LoadingErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: DesignSystem.cardSpacing) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.primaryOrange)
            
            Text("Something went wrong")
                .font(DesignSystem.titleFont)
                .foregroundColor(DesignSystem.primaryTextColor)
            
            Text(error.localizedDescription)
                .font(DesignSystem.bodyFont)
                .foregroundColor(DesignSystem.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let retryAction = retryAction {
                Button("Try Again") {
                    retryAction()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.backgroundColor)
    }
}

/// A reusable empty state view
struct EmptyStateView: View {
    let title: String
    let description: String
    let systemImage: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        title: String,
        description: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.cardSpacing) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.primaryTeal)
            
            Text(title)
                .font(DesignSystem.titleFont)
                .foregroundColor(DesignSystem.primaryTextColor)
            
            Text(description)
                .font(DesignSystem.bodyFont)
                .foregroundColor(DesignSystem.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle) {
                    action()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.backgroundColor)
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingStateView(state: LoadingState<[String]>.loading) { data in
            List(data, id: \.self) { item in
                Text(item)
            }
        }
        
        ErrorView(
            error: .dataCorruption,
            retryAction: { print("Retry tapped") }
        )
        
        EmptyStateView(
            title: "No Projects",
            description: "Get started by creating your first sewing project",
            systemImage: "folder.badge.plus",
            actionTitle: "Create Project",
            action: { print("Create tapped") }
        )
    }
}
