# Sage iOS App - File Organization

This document describes the file organization structure for the Sage iOS app, following industry best practices and clean architecture principles.

##  Directory Structure

```
Sage/
 App/                          # Application entry points
    SageApp.swift            # Main app file
    ContentView.swift        # Root content view
 Domain/                       # Pure business logic (Clean Architecture)
    Models/                  # Domain models
       Recording/           # Recording-related models
       User/                # User-related models
       Onboarding/          # Onboarding-related models
    Protocols/               # Shared interfaces
 Infrastructure/               # Platform-specific implementations
    Services/                # External service integrations
        Auth/                # Authentication services
        Audio/               # Audio recording services
        Analytics/           # Analytics services
        Uploading/           # File upload services
 Features/                     # Feature modules
    Authentication/          # Auth feature
    Dashboard/               # Dashboard feature
    Onboarding/              # Onboarding feature
    Sessions/                # Sessions feature
 UIComponents/                 # Reusable UI components
 Shared/                      # Shared resources
    Constants/               # App-wide constants
    Extensions/              # Swift extensions
    Helpers/                 # Helper functions
    Utilities/               # Utility classes
 Assets.xcassets/             # App assets
 Sage.xcdatamodeld/          # Core Data model
```

##  Architecture Principles

### Clean Architecture
- **Domain**: Contains pure business logic, independent of frameworks
- **Infrastructure**: Contains platform-specific implementations (Firebase, AVFoundation)
- **Features**: Contains UI and feature-specific logic

### Separation of Concerns
- **Models**: Domain entities and business rules
- **Services**: External integrations and data access
- **Views**: UI components and user interactions
- **ViewModels**: State management and business logic coordination

##  File Organization Guidelines

### Domain Models
- Group related models by domain concept (User, Recording, Onboarding)
- Keep validators with their corresponding models
- Use protocols for shared interfaces

### Infrastructure Services
- Group by external dependency (Auth, Audio, Analytics, Uploading)
- Each service should have a single responsibility
- Use dependency injection for testability

### Features
- Each feature is self-contained with its own Views and ViewModels
- Features can depend on Domain and Infrastructure layers
- Features should not depend on other features directly

### Shared Resources
- **Constants**: App-wide constants like FirestoreKeys
- **Extensions**: Swift extensions for common functionality
- **Helpers**: Helper functions and utilities
- **Utilities**: Reusable utility classes like Logger

##  Migration Notes

### Recent Changes
- Moved from `Core/` to `Domain/` and `Infrastructure/`
- Renamed `DesignSystem/` to `UIComponents/`
- Created `App/` folder for application entry points
- Centralized constants in `Shared/Constants/`
- Added structured logging in `Shared/Utilities/`

### Benefits
- **Scalability**: Supports team growth and feature ownership
- **Maintainability**: Clear separation of concerns
- **Testability**: Clean architecture enables easy testing
- **Discoverability**: Intuitive file organization

##  Testing Structure

Tests mirror the main app structure:
```
SageTests/
 AppFlow/                     # App-level tests
 Authentication/              # Auth feature tests
 Onboarding/                  # Onboarding feature tests
 Recording/                   # Recording domain tests
 Services/                    # Infrastructure service tests
 Mocks/                      # Test mocks and stubs
```

##  Related Documentation

- `DATA_STANDARDS.md`: Data modeling standards
- `UI_STANDARDS.md`: UI component standards
- `AI_GENERATION_RULES.md`: AI code generation guidelines
- `TEST_PLAN.md`: Testing strategy and guidelines 