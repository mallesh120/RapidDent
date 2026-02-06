# RapidDent - AI Coding Instructions

## Project Overview
RapidDent is a SwiftUI-based dental exam preparation app targeting iOS, macOS, and visionOS platforms. The app provides scenario-based learning with patient cases, questions, and performance tracking.

## Architecture & Structure

### Core Components
- **Views**: SwiftUI views organized by feature (Menu, Dashboard, Exam, Feedback, Score)
  - `MainMenuView.swift` - App entry point navigation
  - `DashboardView.swift` - Progress overview and stats
  - `ExamView.swift` - Main exam interface
  - `ScenarioRunnerView.swift` - Interactive patient scenario flow
  - `FeedbackView.swift` - Answer feedback display
  - `ScoreReportView.swift` - Performance analytics
  - `CardView.swift`, `PatientBoxView.swift` - Reusable UI components
  
- **Models**: Data structures in `RapidDent/` root
  - `Scenario.swift` - Patient case scenarios
  - `Question.swift` - Exam questions with answers
  - `ProgressManager.swift` - User progress and analytics tracking

- **App Entry**: `DentalExamPrepApp.swift` - SwiftUI App lifecycle with Firebase initialization

### Firebase Integration
- **Dependencies**: FirebaseAI, FirebaseAILogic, FirebaseAnalytics, FirebaseFirestore
- **Config**: `GoogleService-Info.plist` required in `RapidDent/` directory
- Uses Firebase for AI-powered features, analytics, and data persistence
- Initialize Firebase in app delegate or main app struct

## Development Workflow

### Building & Running
- Open `RapidDent.xcodeproj` in Xcode 26.2+
- Select target: "RapidDent" for main app
- Supports: iPhone, iPad, Mac (Catalyst), visionOS
- Deployment targets: iOS 26.2, macOS 26.2, visionOS 26.2

### Testing
- **Unit Tests**: `RapidDentTests/DentalExamPrepTests.swift`
- **UI Tests**: `RapidDentUITests/` - Launch tests and interaction tests
- Use XCTest framework with `@MainActor` for UI testing

### Dependencies Management
- Swift Package Manager via Xcode
- Firebase iOS SDK 12.7.0+ (specified in `Package.resolved`)
- Dependencies auto-resolve on project open

## SwiftUI Conventions

### State Management
- Use `@State`, `@StateObject`, `@ObservedObject` for reactive UI
- `ProgressManager` likely uses `ObservableObject` protocol
- Follow unidirectional data flow pattern

### View Structure
- Separate views by responsibility (Menu, Exam, Feedback, Dashboard)
- Reusable components in dedicated files (`CardView`, `PatientBoxView`)
- SwiftUI previews should be included for rapid development

### Naming Patterns
- Views: `*View.swift` suffix
- Models: Singular nouns (`Scenario`, `Question`)
- Managers: `*Manager.swift` suffix for service objects

## Project-Specific Patterns

### Scenario-Based Learning
- Patient scenarios are central to the app's pedagogy
- Questions are embedded within scenarios
- Progress tracking persists across sessions

### Multi-Platform Support
- Code must work on iOS, macOS, and visionOS
- Use conditional compilation where platform-specific features needed
- Test on multiple device sizes (iPhone, iPad, Mac)

### Firebase Features
- AI-powered question generation or feedback (FirebaseAI)
- Analytics for tracking user engagement
- Firestore for cloud data sync

## File Organization
```
RapidDent/
├── DentalExamPrepApp.swift      # App entry point
├── Views/                        # All SwiftUI views (flat structure)
│   ├── MainMenuView.swift
│   ├── DashboardView.swift
│   ├── ExamView.swift
│   ├── ScenarioRunnerView.swift
│   ├── FeedbackView.swift
│   ├── ScoreReportView.swift
│   ├── CardView.swift
│   └── PatientBoxView.swift
├── Models/                       # Data models
│   ├── Scenario.swift
│   ├── Question.swift
│   └── ProgressManager.swift
├── Assets.xcassets/             # App icons and images
└── GoogleService-Info.plist     # Firebase configuration
```

## Common Tasks

### Adding New Questions/Scenarios
- Update model definitions in `Question.swift` or `Scenario.swift`
- Consider Firestore schema if using cloud storage
- Maintain Codable conformance for JSON serialization

### Modifying UI
- Views use SwiftUI declarative syntax
- Components are composable - prefer extracting reusable subviews
- Use SF Symbols for icons (system integrated)

### Debugging
- Use Xcode's SwiftUI preview for rapid iteration
- Firestore/Analytics debugger for backend issues
- Test on simulator and real devices for platform-specific bugs

## Important Notes
- Bundle ID: `com.manya.RapidDent`
- Development Team: U8B97NVD7G
- App supports sandboxing and hardened runtime (macOS)
- String catalogs enabled for localization readiness
