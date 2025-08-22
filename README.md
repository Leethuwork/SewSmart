# SewSmart

A comprehensive iOS app for managing your sewing projects, patterns, and fabric stash built with SwiftUI and SwiftData.

## Features

### 📄 Pattern Management
- Store and organize sewing patterns with categories (Dress, Top, Pants, Skirt, Jacket, Accessory)
- Support for PDF documents and images with direct camera/photo library access
- Pattern difficulty tracking (Beginner, Intermediate, Advanced, Expert)
- Rating system, tags, and notes
- Print and share functionality with native iOS sharing
- Search and filter capabilities by name, brand, or tags

### 🧵 Fabric Stash
- Track fabric inventory with detailed information
- Photo support with camera and photo library integration
- Fabric type categorization (Cotton, Wool, Silk, Linen, Jersey, etc.)
- Yardage tracking with flexible measurement units
- Visual fabric cards with vibrant design system
- Color and texture tracking

### 🎯 Project Tracking
- Manage sewing projects with status tracking (Planning, In Progress, On Hold, Completed)
- Link patterns and fabrics to projects
- Progress tracking with visual indicators
- Project categories and priority levels
- Deadline management

### ⚙️ Centralized Settings
- Measurement unit preferences (Imperial/Metric)
- Length unit selection (Yards, Meters, Inches, Centimeters)
- History tracking for user actions with context
- Centralized configuration management
- User preference persistence

## Technical Stack

- **Framework**: SwiftUI with iOS 17.0+
- **Database**: SwiftData for modern data persistence
- **Architecture**: MVVM with @Observable and @Bindable property wrappers
- **Design System**: Custom vibrant color palette with gradients
- **File Management**: DocumentPicker, ImagePicker with camera/photo library support
- **Sharing**: UIActivityViewController for native print and share functionality

## Project Structure

```
SewSmart/
├── Models/
│   ├── Pattern.swift             # Pattern data model with file support
│   ├── Fabric.swift              # Fabric inventory model
│   ├── Project.swift             # Project management model
│   └── UserSettings.swift        # Settings and history tracking
├── Views/
│   ├── PatternsView.swift        # Pattern list with search/filter
│   ├── FabricStashView.swift     # Fabric inventory management
│   ├── ProjectsView.swift        # Project tracking interface
│   ├── AddPatternView.swift      # Pattern creation form
│   ├── PatternDetailView.swift   # Pattern details and editing
│   ├── SettingsView.swift        # User preferences
│   └── DesignSystem.swift        # UI design system
├── Components/
│   ├── VibrantPatternRowView.swift    # Pattern list item component
│   ├── DocumentPicker.swift           # PDF file selection
│   ├── ImagePicker.swift              # Camera/photo library picker
│   └── PrintAndShareControllers.swift # Print/share functionality
└── Services/
    └── UserSettingsManager.swift      # Centralized settings management
```

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd SewSmart
   ```

2. Open `SewSmart.xcodeproj` in Xcode 15+

3. Build and run on iOS 17.0+ device or simulator

## Key Features Implemented

✅ **Pattern Management**
- Complete CRUD operations for sewing patterns
- PDF and image file support with native iOS document/camera integration
- Advanced search and filtering system
- Print and share functionality

✅ **Fabric Stash Management**
- Photo integration with camera and photo library
- Comprehensive fabric categorization
- Flexible measurement unit system
- Visual card-based interface

✅ **Centralized Settings**
- User preference management with history tracking
- Measurement unit standardization across the app
- Persistent configuration storage

✅ **Modern iOS Architecture**
- SwiftData for data persistence
- Component-based architecture with reusable UI elements
- Native iOS design patterns and user interactions

## Contributing

This is a personal project for managing sewing workflows. Feel free to fork and adapt for your own needs.

## License

Private project - All rights reserved.