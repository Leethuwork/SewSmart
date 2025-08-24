import SwiftUI
import SwiftData

struct iPadPatternsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pattern.createdDate, order: .reverse) private var patterns: [Pattern]
    @State private var selectedPattern: Pattern?
    @State private var showingAddPattern = false
    @State private var searchText = ""
    @State private var selectedCategory: PatternCategory?
    @State private var selectedDifficulty: PatternDifficulty?
    
    var filteredPatterns: [Pattern] {
        var filtered = patterns
        
        if !searchText.isEmpty {
            filtered = filtered.filter { pattern in
                pattern.name.localizedCaseInsensitiveContains(searchText) ||
                pattern.brand.localizedCaseInsensitiveContains(searchText) ||
                pattern.tags.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let difficulty = selectedDifficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationSplitView {
            // Patterns List
            VStack {
                // Filter Controls
                VStack(spacing: 8) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterButton(title: "All Categories", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            
                            ForEach(PatternCategory.allCases, id: \.self) { category in
                                FilterButton(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    color: .blue
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Difficulty Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterButton(title: "All Levels", isSelected: selectedDifficulty == nil) {
                                selectedDifficulty = nil
                            }
                            
                            ForEach(PatternDifficulty.allCases, id: \.self) { difficulty in
                                FilterButton(
                                    title: difficulty.rawValue,
                                    isSelected: selectedDifficulty == difficulty,
                                    color: Color(difficulty.color)
                                ) {
                                    selectedDifficulty = difficulty
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                
                // Patterns Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(filteredPatterns) { pattern in
                            iPadPatternCardView(pattern: pattern, isSelected: selectedPattern?.id == pattern.id)
                                .onTapGesture {
                                    selectedPattern = pattern
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Pattern Library")
            .searchable(text: $searchText, prompt: "Search patterns...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPattern = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPattern) {
                AddPatternView()
            }
        } detail: {
            // Pattern Detail
            if let pattern = selectedPattern {
                iPadPatternDetailView(pattern: pattern)
            } else {
                PatternsEmptyStateView()
            }
        }
    }
}

struct iPadPatternCardView: View {
    let pattern: Pattern
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Pattern Preview
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 120)
                .overlay(
                    Group {
                        if let thumbnailData = pattern.thumbnailData, let uiImage = UIImage(data: thumbnailData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            VStack {
                                Image(systemName: "doc.text")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                Text("PDF")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                )
            
            // Pattern Info
            VStack(alignment: .leading, spacing: 6) {
                Text(pattern.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if !pattern.brand.isEmpty {
                    Text(pattern.brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text(pattern.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text(pattern.difficulty.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(pattern.difficulty.color).opacity(0.2))
                        .foregroundColor(Color(pattern.difficulty.color))
                        .cornerRadius(4)
                }
                
                if pattern.rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= pattern.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct iPadPatternDetailView: View {
    @Bindable var pattern: Pattern
    @State private var isEditing = false
    @State private var showingPDFViewer = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Header Section
                PatternHeaderSection(pattern: pattern, isEditing: $isEditing)
                
                // PDF Section
                if pattern.pdfData != nil {
                    PatternPDFSection(pattern: pattern, showingPDFViewer: $showingPDFViewer)
                }
                
                // Details Section
                PatternDetailsSection(pattern: pattern, isEditing: $isEditing)
                
                // Tags Section
                PatternTagsSection(pattern: pattern, isEditing: $isEditing)
                
                // Projects Section
                if !pattern.projects.isEmpty {
                    PatternProjectsSection(pattern: pattern)
                }
                
                // Notes Section
                PatternNotesSection(pattern: pattern, isEditing: $isEditing)
            }
            .padding()
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if pattern.pdfData != nil {
                        Button(action: { showingPDFViewer = true }) {
                            Image(systemName: "doc.text")
                        }
                    }
                    
                    Button(isEditing ? "Save" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPDFViewer) {
            // PDF Viewer would go here
            Text("PDF Viewer")
                .font(.title)
                .navigationTitle("Pattern PDF")
        }
    }
}

struct PatternHeaderSection: View {
    @Bindable var pattern: Pattern
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pattern Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Rating
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            if isEditing {
                                pattern.rating = star
                            }
                        }) {
                            Image(systemName: star <= pattern.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.title3)
                        }
                        .disabled(!isEditing)
                    }
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    if isEditing {
                        TextField("Brand", text: $pattern.brand)
                            .textFieldStyle(.roundedBorder)
                    } else if !pattern.brand.isEmpty {
                        Text("Brand: \(pattern.brand)")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        if isEditing {
                            Picker("Category", selection: $pattern.category) {
                                ForEach(PatternCategory.allCases, id: \.self) { category in
                                    Text(category.rawValue).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Text(pattern.category.rawValue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        if isEditing {
                            Picker("Difficulty", selection: $pattern.difficulty) {
                                ForEach(PatternDifficulty.allCases, id: \.self) { difficulty in
                                    Text(difficulty.rawValue).tag(difficulty)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Text(pattern.difficulty.rawValue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(pattern.difficulty.color).opacity(0.2))
                                .foregroundColor(Color(pattern.difficulty.color))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            Text("Added: \(pattern.createdDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct PatternPDFSection: View {
    let pattern: Pattern
    @Binding var showingPDFViewer: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern PDF")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button(action: { showingPDFViewer = true }) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("View Pattern")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Tap to open PDF viewer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct PatternDetailsSection: View {
    @Bindable var pattern: Pattern
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Add more pattern-specific details here
            Text("Pattern information and specifications would go here.")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct PatternTagsSection: View {
    @Bindable var pattern: Pattern
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.title2)
                .fontWeight(.semibold)
            
            if isEditing {
                TextField("Tags (comma separated)", text: $pattern.tags)
                    .textFieldStyle(.roundedBorder)
            } else if pattern.tags.isEmpty {
                Text("No tags")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text(pattern.tags)
                    .font(.body)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct PatternProjectsSection: View {
    let pattern: Pattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Used in Projects")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(pattern.projects) { project in
                    ProjectMiniCard(project: project)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ProjectMiniCard: View {
    let project: Project
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(project.status.rawValue)
                    .font(.caption)
                    .foregroundColor(Color(project.status.color))
                
                ProgressView(value: project.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(project.status.color)))
                    .scaleEffect(y: 0.5)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct PatternNotesSection: View {
    @Bindable var pattern: Pattern
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.title2)
                .fontWeight(.semibold)
            
            if isEditing {
                TextField("Add notes...", text: $pattern.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...15)
            } else if pattern.notes.isEmpty {
                Text("No notes yet")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text(pattern.notes)
                    .font(.body)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct PatternsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Select a Pattern")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose a pattern from the library to view details")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    iPadPatternsView()
        .modelContainer(for: Pattern.self, inMemory: true)
}