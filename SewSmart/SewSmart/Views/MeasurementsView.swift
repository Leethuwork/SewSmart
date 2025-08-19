import SwiftUI
import SwiftData

struct MeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeasurementProfile.createdDate, order: .reverse) private var profiles: [MeasurementProfile]
    @State private var showingAddProfile = false
    @State private var selectedProfile: MeasurementProfile?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(profiles) { profile in
                    MeasurementProfileRowView(profile: profile)
                        .onTapGesture {
                            selectedProfile = profile
                        }
                }
                .onDelete(perform: deleteProfiles)
            }
            .navigationTitle("Measurements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProfile = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                AddMeasurementProfileView()
            }
            .sheet(item: $selectedProfile) { profile in
                MeasurementProfileDetailView(profile: profile)
            }
        }
    }
    
    private func deleteProfiles(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(profiles[index])
            }
        }
    }
}

struct MeasurementProfileRowView: View {
    let profile: MeasurementProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(profile.name)
                    .font(.headline)
                Spacer()
                if profile.isDefault {
                    Text("Default")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            
            Text("\(profile.measurements.count) measurements")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !profile.notes.isEmpty {
                Text(profile.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Text(profile.createdDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddMeasurementProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var notes = ""
    @State private var isDefault = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile Details")) {
                    TextField("Profile Name", text: $name)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    Toggle("Set as Default Profile", isOn: $isDefault)
                }
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveProfile() {
        let newProfile = MeasurementProfile(name: name, isDefault: isDefault)
        newProfile.notes = notes
        
        modelContext.insert(newProfile)
        dismiss()
    }
}

struct MeasurementProfileDetailView: View {
    @Bindable var profile: MeasurementProfile
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddMeasurement = false
    @State private var selectedCategory: MeasurementCategory?
    
    var filteredMeasurements: [Measurement] {
        if let category = selectedCategory {
            return profile.measurements.filter { $0.category == category }
        }
        return profile.measurements
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button("All") {
                            selectedCategory = nil
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .cornerRadius(16)
                        
                        ForEach(MeasurementCategory.allCases, id: \.self) { category in
                            Button(category.rawValue) {
                                selectedCategory = category
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Measurements List
                List {
                    ForEach(filteredMeasurements) { measurement in
                        MeasurementRowView(measurement: measurement)
                    }
                    .onDelete(perform: deleteMeasurements)
                }
            }
            .navigationTitle(profile.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMeasurement = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeasurement) {
                AddMeasurementView(profile: profile)
            }
        }
    }
    
    private func deleteMeasurements(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                if let measurementIndex = profile.measurements.firstIndex(of: filteredMeasurements[index]) {
                    profile.measurements.remove(at: measurementIndex)
                }
            }
        }
    }
}

struct MeasurementRowView: View {
    @Bindable var measurement: Measurement
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var settingsManager: UserSettingsManager?
    @State private var originalValue: Double = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.name)
                    .font(.headline)
                Text(measurement.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isEditing {
                TextField("Value", value: $measurement.value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .keyboardType(.decimalPad)
            } else {
                Text(String(format: "%.1f %@", measurement.value, measurement.unit.abbreviation))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Button(isEditing ? "Done" : "Edit") {
                if isEditing {
                    // Save and track if value changed
                    if originalValue != measurement.value {
                        settingsManager?.addHistory(
                            action: .updatedMeasurement,
                            details: "\(measurement.name): \(originalValue) → \(measurement.value) \(measurement.unit.abbreviation)",
                            context: .measurements
                        )
                    }
                } else {
                    originalValue = measurement.value
                }
                isEditing.toggle()
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isEditing ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
            .foregroundColor(isEditing ? .green : .blue)
            .cornerRadius(8)
        }
        .padding(.vertical, 4)
        .onAppear {
            if settingsManager == nil {
                settingsManager = UserSettingsManager(modelContext: modelContext)
            }
            originalValue = measurement.value
        }
    }
}

struct AddMeasurementView: View {
    let profile: MeasurementProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var value: Double = 0
    @State private var category = MeasurementCategory.body
    @State private var settingsManager: UserSettingsManager?
    
    private let commonMeasurements = [
        "Bust/Chest", "Waist", "Hips", "Shoulder Width", "Arm Length",
        "Inseam", "Outseam", "Neck", "Wrist", "Ankle"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Measurement Details")) {
                    TextField("Measurement Name", text: $name)
                    
                    HStack {
                        Text("Value")
                        Spacer()
                        TextField("0.0", value: $value, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .keyboardType(.decimalPad)
                        
                        Text(settingsManager?.userSettings.preferredMeasurementUnit.abbreviation ?? "in")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(MeasurementCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Common Measurements")) {
                    ForEach(commonMeasurements, id: \.self) { measurementName in
                        Button(measurementName) {
                            name = measurementName
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeasurement()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if settingsManager == nil {
                    settingsManager = UserSettingsManager(modelContext: modelContext)
                }
            }
        }
    }
    
    private func saveMeasurement() {
        let unit = settingsManager?.userSettings.preferredMeasurementUnit ?? .inches
        let newMeasurement = Measurement(
            name: name,
            value: value,
            unit: unit,
            category: category
        )
        newMeasurement.profile = profile
        profile.measurements.append(newMeasurement)
        
        // Add to history
        settingsManager?.addHistory(
            action: .addedMeasurement,
            details: "\(name): \(value) \(unit.abbreviation)",
            context: .measurements
        )
        
        dismiss()
    }
}

#Preview {
    MeasurementsView()
        .modelContainer(for: MeasurementProfile.self, inMemory: true)
}