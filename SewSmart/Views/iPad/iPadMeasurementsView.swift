import SwiftUI
import SwiftData

struct iPadMeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeasurementProfile.createdDate, order: .reverse) private var profiles: [MeasurementProfile]
    @State private var selectedProfile: MeasurementProfile?
    @State private var showingAddProfile = false
    
    var body: some View {
        NavigationSplitView {
            // Profiles List
            VStack {
                List(profiles) { profile in
                    Button(action: { selectedProfile = profile }) {
                        iPadMeasurementProfileRowView(profile: profile)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(selectedProfile?.id == profile.id ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Measurement Profiles")
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
        } detail: {
            // Profile Detail
            if let profile = selectedProfile {
                iPadMeasurementProfileDetailView(profile: profile)
            } else {
                MeasurementsEmptyStateView()
            }
        }
    }
}

struct iPadMeasurementProfileRowView: View {
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
            
            HStack {
                Text("\(profile.measurements.count) measurements")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(profile.createdDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !profile.notes.isEmpty {
                Text(profile.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct iPadMeasurementProfileDetailView: View {
    @Bindable var profile: MeasurementProfile
    @State private var selectedCategory: MeasurementCategory?
    @State private var showingAddMeasurement = false
    @State private var isEditingProfile = false
    
    var filteredMeasurements: [Measurement] {
        if let category = selectedCategory {
            return profile.measurements.filter { $0.category == category }
        }
        return profile.measurements
    }
    
    var groupedMeasurements: [MeasurementCategory: [Measurement]] {
        Dictionary(grouping: filteredMeasurements) { $0.category }
    }
    
    var body: some View {
        VStack {
            // Profile Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if isEditingProfile {
                        TextField("Profile Name", text: $profile.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .fontWeight(.semibold)
                    } else {
                        Text(profile.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
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
                
                if isEditingProfile {
                    TextField("Notes", text: $profile.notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                } else if !profile.notes.isEmpty {
                    Text(profile.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Stats
                HStack {
                    ForEach(MeasurementCategory.allCases, id: \.self) { category in
                        let count = profile.measurements.filter { $0.category == category }.count
                        if count > 0 {
                            VStack {
                                Text("\(count)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(16)
            .padding()
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterButton(title: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    
                    ForEach(MeasurementCategory.allCases, id: \.self) { category in
                        let count = profile.measurements.filter { $0.category == category }.count
                        if count > 0 {
                            FilterButton(
                                title: "\(category.rawValue) (\(count))",
                                isSelected: selectedCategory == category,
                                color: .orange
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Measurements List
            ScrollView {
                LazyVStack(spacing: 16) {
                    if selectedCategory != nil {
                        // Single category view
                        ForEach(filteredMeasurements.sorted(by: { $0.name < $1.name })) { measurement in
                            iPadMeasurementRowView(measurement: measurement)
                        }
                    } else {
                        // Grouped by category
                        ForEach(MeasurementCategory.allCases, id: \.self) { category in
                            if let measurements = groupedMeasurements[category], !measurements.isEmpty {
                                MeasurementCategorySection(
                                    category: category,
                                    measurements: measurements.sorted(by: { $0.name < $1.name })
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showingAddMeasurement = true }) {
                        Image(systemName: "plus")
                    }
                    
                    Button(isEditingProfile ? "Save" : "Edit") {
                        isEditingProfile.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddMeasurement) {
            AddMeasurementView(profile: profile)
        }
    }
}

struct MeasurementCategorySection: View {
    let category: MeasurementCategory
    let measurements: [Measurement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(measurements.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(measurements) { measurement in
                    iPadMeasurementCardView(measurement: measurement)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct iPadMeasurementRowView: View {
    @Bindable var measurement: Measurement
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.name)
                    .font(.headline)
                
                Text(measurement.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            if isEditing {
                HStack {
                    TextField("Value", value: $measurement.value, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .keyboardType(.decimalPad)
                    
                    Text(measurement.unit.abbreviation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(String(format: "%.1f %@", measurement.value, measurement.unit.abbreviation))
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Button(isEditing ? "Save" : "Edit") {
                isEditing.toggle()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isEditing ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
            .foregroundColor(isEditing ? .green : .blue)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct iPadMeasurementCardView: View {
    @Bindable var measurement: Measurement
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(measurement.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if isEditing {
                VStack {
                    TextField("Value", value: $measurement.value, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                    
                    Button("Save") {
                        isEditing = false
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(6)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", measurement.value))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(measurement.unit.abbreviation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onTapGesture {
                    isEditing = true
                }
            }
        }
        .frame(height: 100)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct MeasurementsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "ruler")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Select a Profile")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose a measurement profile to view and edit measurements")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    iPadMeasurementsView()
        .modelContainer(for: MeasurementProfile.self, inMemory: true)
}