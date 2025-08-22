import SwiftUI
import SwiftData

@Observable
final class SettingsViewModel {
    var showingHistory: Bool = false
    var showingAbout: Bool = false
    
    private let modelContext: ModelContext
    private var settingsManager: UserSettingsManager?
    
    var userSettings: UserSettings? {
        settingsManager?.userSettings
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupSettingsManager()
    }
    
    private func setupSettingsManager() {
        settingsManager = UserSettingsManager(modelContext: modelContext)
    }
    
    func showHistory() {
        showingHistory = true
    }
    
    func hideHistory() {
        showingHistory = false
    }
    
    func showAbout() {
        showingAbout = true
    }
    
    func hideAbout() {
        showingAbout = false
    }
    
    func updateMeasurementUnit(_ unit: MeasurementUnit) {
        guard let settings = userSettings else { return }
        
        let oldUnit = settings.preferredMeasurementUnit
        settings.preferredMeasurementUnit = unit
        settings.updateLastModified()
        
        do {
            try modelContext.save()
            settingsManager?.addHistory(
                action: .changedMeasurementUnit,
                details: "From \(oldUnit.rawValue) to \(unit.rawValue)",
                context: .settings
            )
        } catch {
            // Handle error silently for now
        }
    }
    
    func updateLengthUnit(_ unit: LengthUnit) {
        guard let settings = userSettings else { return }
        
        let oldUnit = settings.preferredLengthUnit
        settings.preferredLengthUnit = unit
        settings.updateLastModified()
        
        do {
            try modelContext.save()
            settingsManager?.addHistory(
                action: .changedLengthUnit,
                details: "From \(oldUnit.rawValue) to \(unit.rawValue)",
                context: .settings
            )
        } catch {
            // Handle error silently for now
        }
    }
    
    func updateDefaultProfile(_ profileName: String?) {
        guard let settings = userSettings else { return }
        
        settings.defaultMeasurementProfile = profileName
        settings.updateLastModified()
        
        do {
            try modelContext.save()
            settingsManager?.addHistory(
                action: .setDefaultProfile,
                details: profileName ?? "None",
                context: .settings
            )
        } catch {
            // Handle error silently for now
        }
    }
    
    func getVersionInfo() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    func getBuildNumber() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    func getAppName() -> String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "SewSmart"
    }
    
    func getSettingsSections() -> [SettingsSection] {
        [
            SettingsSection(
                title: "Measurements",
                items: [
                    SettingsItem(
                        title: "Preferred Unit",
                        type: .picker,
                        currentValue: userSettings?.preferredMeasurementUnit.rawValue
                    ),
                    SettingsItem(
                        title: "Length Unit",
                        type: .picker,
                        currentValue: userSettings?.preferredLengthUnit.rawValue
                    ),
                    SettingsItem(
                        title: "Default Profile",
                        type: .picker,
                        currentValue: userSettings?.defaultMeasurementProfile
                    )
                ]
            ),
            SettingsSection(
                title: "Data",
                items: [
                    SettingsItem(
                        title: "Activity History",
                        type: .navigation,
                        icon: "clock.arrow.circlepath"
                    )
                ]
            ),
            SettingsSection(
                title: "About",
                items: [
                    SettingsItem(
                        title: "Version",
                        type: .info,
                        currentValue: getVersionInfo()
                    ),
                    SettingsItem(
                        title: "Build",
                        type: .info,
                        currentValue: getBuildNumber()
                    )
                ]
            )
        ]
    }
}

struct SettingsSection {
    let title: String
    let items: [SettingsItem]
}

struct SettingsItem {
    let title: String
    let type: SettingsItemType
    let currentValue: String?
    let icon: String?
    
    init(title: String, type: SettingsItemType, currentValue: String? = nil, icon: String? = nil) {
        self.title = title
        self.type = type
        self.currentValue = currentValue
        self.icon = icon
    }
}

enum SettingsItemType {
    case picker
    case navigation
    case info
    case toggle
}