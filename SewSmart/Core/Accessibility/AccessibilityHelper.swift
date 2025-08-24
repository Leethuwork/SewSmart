import SwiftUI
import Foundation

/// Comprehensive accessibility support utilities
struct AccessibilityHelper {
    
    // MARK: - Accessibility Labels
    
    static func projectStatusLabel(for status: ProjectStatus) -> String {
        switch status {
        case .planning:
            return "Planning phase. Project is in initial planning stages."
        case .inProgress:
            return "In progress. Project is currently being worked on."
        case .completed:
            return "Completed. Project has been finished successfully."
        case .onHold:
            return "On hold. Project work has been temporarily paused."
        }
    }
    
    static func patternDifficultyLabel(for difficulty: PatternDifficulty) -> String {
        switch difficulty {
        case .beginner:
            return "Beginner difficulty. Suitable for those new to sewing."
        case .intermediate:
            return "Intermediate difficulty. Requires some sewing experience."
        case .advanced:
            return "Advanced difficulty. Requires significant sewing skills."
        case .expert:
            return "Advanced difficulty. Requires significant sewing skills."
        }
    }
    
    static func fabricTypeLabel(for type: FabricType) -> String {
        switch type {
        case .cotton:
            return "Cotton fabric. Natural fiber, breathable and easy to work with."
        case .silk:
            return "Silk fabric. Luxurious natural fiber with smooth texture."
        case .wool:
            return "Wool fabric. Warm natural fiber from animal sources."
        case .linen:
            return "Linen fabric. Natural fiber with textured appearance."
        case .polyester:
            return "Polyester fabric. Synthetic fiber, durable and wrinkle-resistant."
        case .denim:
            return "Denim fabric. Heavy cotton twill, commonly used for jeans."
//        case .knit:
//            return "Knit fabric. Stretchy fabric formed by interlocking loops."
//        case .leather:
//            return "Leather material. Processed animal hide for durable goods."
        case .other:
            return "Other fabric type. Specialized or mixed fabric materials."
        case .rayon:
            return "Polyester fabric. Synthetic fiber, durable and wrinkle-resistant."
        case .jersey:
            return "Polyester fabric. Synthetic fiber, durable and wrinkle-resistant."
        case .fleece:
            return "Polyester fabric. Synthetic fiber, durable and wrinkle-resistant."
        }
    }
    
    // MARK: - Progress Descriptions
    
    static func progressDescription(for progress: Double) -> String {
        let percentage = Int(progress * 100)
        
        switch percentage {
        case 0:
            return "Not started. 0 percent complete."
        case 1...25:
            return "Just started. \(percentage) percent complete."
        case 26...50:
            return "Making progress. \(percentage) percent complete."
        case 51...75:
            return "More than halfway done. \(percentage) percent complete."
        case 76...99:
            return "Nearly finished. \(percentage) percent complete."
        case 100:
            return "Fully completed. 100 percent done."
        default:
            return "\(percentage) percent complete."
        }
    }
    
    static func priorityDescription(for priority: Int) -> String {
        switch priority {
        case 0:
            return "Low priority. Can be completed when time allows."
        case 1:
            return "Medium priority. Should be completed soon."
        case 2:
            return "High priority. Needs attention soon."
        case 3:
            return "Urgent priority. Requires immediate attention."
        default:
            return "Priority level \(priority)."
        }
    }
    
    // MARK: - Action Descriptions
    
    static func buttonActionDescription(action: AccessibleAction) -> String {
        switch action {
        case .addProject:
            return "Add new project. Opens form to create a new sewing project."
        case .editProject:
            return "Edit project. Opens form to modify project details."
        case .deleteProject:
            return "Delete project. Removes project permanently."
        case .addPattern:
            return "Add new pattern. Opens form to add a sewing pattern."
        case .editPattern:
            return "Edit pattern. Opens form to modify pattern details."
        case .deletePattern:
            return "Delete pattern. Removes pattern permanently."
        case .addFabric:
            return "Add new fabric. Opens form to add fabric to inventory."
        case .editFabric:
            return "Edit fabric. Opens form to modify fabric details."
        case .deleteFabric:
            return "Delete fabric. Removes fabric from inventory."
        case .search:
            return "Search. Filter items by typing search terms."
        case .filter:
            return "Filter. Show only items matching selected criteria."
        case .clearFilters:
            return "Clear filters. Show all items without filtering."
        case .settings:
            return "Settings. Configure app preferences and options."
        case .export:
            return "Export data. Save your data to external file."
        case .import:
            return "Import data. Load data from external file."
        }
    }
    
    // MARK: - Contextual Hints
    
    static func contextualHint(for context: AccessibilityContext) -> String {
        switch context {
        case .projectsList:
            return "Swipe up or down to navigate through projects. Double tap to select."
        case .projectDetail:
            return "Swipe left or right to navigate between project details sections."
        case .patternsList:
            return "Swipe up or down to navigate through patterns. Double tap to select."
        case .fabricList:
            return "Swipe up or down to navigate through fabric inventory. Double tap to select."
        case .searchResults:
            return "Viewing search results. Use clear filters button to see all items."
        case .emptyState:
            return "No items found. Use the add button to create your first item."
        case .loadingState:
            return "Loading content. Please wait while data is retrieved."
        case .errorState:
            return "An error occurred. Pull down to refresh or check your settings."
        }
    }
    
    // MARK: - Measurement Descriptions
    
    static func quantityDescription(quantity: Double, unit: String) -> String {
        let roundedQuantity = (quantity * 100).rounded() / 100
        
        if roundedQuantity == 1.0 {
            return "1 \(unit.dropLast())" // Remove 's' for singular
        } else {
            return "\(roundedQuantity) \(unit)"
        }
    }
    
    static func costDescription(cost: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        if let formatted = formatter.string(from: NSNumber(value: cost)) {
            return "Cost: \(formatted)"
        } else {
            return "Cost: $\(cost)"
        }
    }
    
    // MARK: - Date Descriptions
    
    static func dateDescription(_ date: Date, context: DateContext) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let formattedDate = formatter.string(from: date)
        
        switch context {
        case .created:
            return "Created on \(formattedDate)"
        case .updated:
            return "Last updated on \(formattedDate)"
        case .dueDate:
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                return "Due today"
            } else if calendar.isDateInTomorrow(date) {
                return "Due tomorrow"
            } else if date < Date() {
                return "Overdue since \(formattedDate)"
            } else {
                return "Due on \(formattedDate)"
            }
        case .completedDate:
            return "Completed on \(formattedDate)"
        }
    }
    
    // MARK: - Dynamic Type Support
    
    static func scaledFont(_ font: Font, maxSize: CGFloat = 100) -> Font {
        // SwiftUI handles dynamic type automatically, but we can provide constraints
        return font
    }
    
    // MARK: - Color Accessibility
    
    static func isHighContrastEnabled() -> Bool {
        return UIAccessibility.isDarkerSystemColorsEnabled ||
               UIAccessibility.isInvertColorsEnabled ||
               UIAccessibility.isReduceTransparencyEnabled
    }
    
    static func accessibleColor(primary: Color, highContrast: Color) -> Color {
        return isHighContrastEnabled() ? highContrast : primary
    }
}

// MARK: - Supporting Enums

enum AccessibleAction {
    case addProject, editProject, deleteProject
    case addPattern, editPattern, deletePattern
    case addFabric, editFabric, deleteFabric
    case search, filter, clearFilters
    case settings, export, `import`
}

enum AccessibilityContext {
    case projectsList, projectDetail
    case patternsList, fabricList
    case searchResults, emptyState
    case loadingState, errorState
}

enum DateContext {
    case created, updated, dueDate, completedDate
}

// MARK: - View Extensions

extension View {
    func accessibleProject(_ project: Project) -> some View {
        self
            .accessibilityLabel(project.name)
            .accessibilityValue("\(AccessibilityHelper.projectStatusLabel(for: project.status)). \(AccessibilityHelper.progressDescription(for: project.progress)). \(AccessibilityHelper.priorityDescription(for: project.priority))")
            .accessibilityHint("Double tap to view project details")
    }
    
    func accessiblePattern(_ pattern: Pattern) -> some View {
        self
            .accessibilityLabel(pattern.name)
//            .accessibilityValue("\(AccessibilityHelper.patternDifficultyLabel(for: pattern.difficulty)). Size: \(pattern.size)")
            .accessibilityHint("Double tap to view pattern details")
    }
    
    func accessibleFabric(_ fabric: Fabric) -> some View {
        self
            .accessibilityLabel(fabric.name)
//            .accessibilityValue("\(AccessibilityHelper.fabricTypeLabel(for: fabric.type)). Color: \(fabric.color). \(AccessibilityHelper.quantityDescription(quantity: fabric.quantity, unit: fabric.unit.rawValue))")
            .accessibilityHint("Double tap to view fabric details")
    }
    
    func accessibleButton(action: AccessibleAction) -> some View {
        self
            .accessibilityHint(AccessibilityHelper.buttonActionDescription(action: action))
    }
    
    func accessibleProgress(_ progress: Double) -> some View {
        self
            .accessibilityValue(AccessibilityHelper.progressDescription(for: progress))
            .accessibilityAdjustableAction { direction in
                // This would be implemented by the parent view
            }
    }
    
    func accessibilityContext(_ context: AccessibilityContext) -> some View {
        self
            .accessibilityHint(AccessibilityHelper.contextualHint(for: context))
    }
    
    // Dynamic Type support
    func adaptiveFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.font(.system(size: size, weight: weight, design: design))
    }
    
    // High contrast support
    func highContrastColor(primary: Color, highContrast: Color) -> some View {
        self.foregroundColor(AccessibilityHelper.accessibleColor(primary: primary, highContrast: highContrast))
    }
}
