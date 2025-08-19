import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.createdDate, ascending: false)],
        animation: .default)
    private var projects: FetchedResults<Project>
    
    var body: some View {
        NavigationView {
            TabView {
                ProjectsView()
                    .tabItem {
                        Image(systemName: "folder")
                        Text("Projects")
                    }
                
                PatternsView()
                    .tabItem {
                        Image(systemName: "doc.text")
                        Text("Patterns")
                    }
                
                MeasurementsView()
                    .tabItem {
                        Image(systemName: "ruler")
                        Text("Measurements")
                    }
                
                FabricStashView()
                    .tabItem {
                        Image(systemName: "square.stack.3d.down.forward")
                        Text("Fabric")
                    }
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
        }
        .environment(\.managedObjectContext, viewContext)
    }
}

struct ProjectsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.createdDate, ascending: false)],
        animation: .default)
    private var projects: FetchedResults<Project>
    @State private var showingAddProject = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(projects) { project in
                    ProjectRowView(project: project)
                }
                .onDelete(perform: deleteProjects)
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProject = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView()
            }
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            offsets.map { projects[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name ?? "Untitled Project")
                    .font(.headline)
                Spacer()
                Text(project.status ?? "Unknown")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
            
            if let description = project.projectDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: project.progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            HStack {
                Text("Progress: \(Int(project.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let date = project.createdDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch project.status {
        case "Completed":
            return .green
        case "In Progress":
            return .blue
        case "Planning":
            return .orange
        case "On Hold":
            return .red
        default:
            return .gray
        }
    }
}

struct AddProjectView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var description = ""
    @State private var status = "Planning"
    
    let statusOptions = ["Planning", "In Progress", "On Hold", "Completed"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveProject() {
        let newProject = Project(context: viewContext)
        newProject.id = UUID()
        newProject.name = name
        newProject.projectDescription = description
        newProject.status = status
        newProject.createdDate = Date()
        newProject.progress = 0.0
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct PatternsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                Text("Pattern Library")
                    .font(.title2)
                    .padding()
                Text("Store and organize your sewing patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Patterns")
        }
    }
}

struct MeasurementsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "ruler")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                Text("Measurements")
                    .font(.title2)
                    .padding()
                Text("Track body measurements and sizing profiles")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Measurements")
        }
    }
}

struct FabricStashView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "square.stack.3d.down.forward")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                Text("Fabric Stash")
                    .font(.title2)
                    .padding()
                Text("Manage your fabric inventory and supplies")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Fabric Stash")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "gear")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                Text("Settings")
                    .font(.title2)
                    .padding()
                Text("App preferences and configuration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}