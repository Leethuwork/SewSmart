import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]
    @Query private var patterns: [Pattern]
    @Query private var fabrics: [Fabric]
    @Query private var measurementProfiles: [MeasurementProfile]
    @State private var settingsManager: UserSettingsManager?
    @State private var showingHistory = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Measurement Preferences")) {
                    if let manager = settingsManager {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundColor(.blue)
                            Text("Measurement Unit")
                            Spacer()
                            Picker("Measurement Unit", selection: Binding(
                                get: { manager.userSettings.preferredMeasurementUnit },
                                set: { manager.updatePreferredMeasurementUnit($0) }
                            )) {
                                ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue.capitalized).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Image(systemName: "ruler.fill")
                                .foregroundColor(.green)
                            Text("Length Unit")
                            Spacer()
                            Picker("Length Unit", selection: Binding(
                                get: { manager.userSettings.preferredLengthUnit },
                                set: { manager.updatePreferredLengthUnit($0) }
                            )) {
                                ForEach(LengthUnit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.purple)
                            Text("Default Profile")
                            Spacer()
                            Picker("Default Profile", selection: Binding(
                                get: { manager.userSettings.defaultMeasurementProfile ?? "" },
                                set: { newValue in
                                    manager.setDefaultMeasurementProfile(newValue.isEmpty ? nil : newValue)
                                }
                            )) {
                                Text("None").tag("")
                                ForEach(measurementProfiles, id: \.name) { profile in
                                    Text(profile.name).tag(profile.name)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Button(action: { showingHistory = true }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.orange)
                                Text("View History")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("Statistics")) {
                    StatRow(title: "Projects", count: projects.count, icon: "folder")
                    StatRow(title: "Patterns", count: patterns.count, icon: "doc.text")
                    StatRow(title: "Fabrics", count: fabrics.count, icon: "square.stack.3d.down.forward")
                    StatRow(title: "Measurement Profiles", count: measurementProfiles.count, icon: "ruler")
                }
                
                Section(header: Text("App Info")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "swift")
                            .foregroundColor(.orange)
                        Text("Built with SwiftUI & SwiftData")
                    }
                }
                
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SewSmart")
                            .font(.headline)
                        Text("Your complete sewing companion for managing projects, patterns, measurements, and fabric inventory.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                if settingsManager == nil {
                    settingsManager = UserSettingsManager(modelContext: modelContext)
                }
            }
            .sheet(isPresented: $showingHistory) {
                if let manager = settingsManager {
                    HistoryView(settingsManager: manager)
                }
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let count: Int
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Project.self, inMemory: true)
}