refactor: reorganize file structure for scalability and maintainability

- Split Core/ into Domain/ and Infrastructure/ following Clean Architecture
- Move app entry points to App/ folder for better organization
- Rename DesignSystem/ to UIComponents/ for clarity
- Create Shared/ folder with Constants, Extensions, Helpers, Utilities
- Extract FirestoreKeys to Shared/Constants/FirestoreKeys.swift
- Add centralized Logger utility in Shared/Utilities/Logger.swift
- Group domain models by concept (User, Recording, Onboarding)
- Organize infrastructure services by dependency (Auth, Audio, Analytics, Uploading)
- Create comprehensive README.md documenting new structure
- Maintain feature-based organization for team scalability

Benefits:
- Follows industry best practices and Clean Architecture principles
- Improves code discoverability and maintainability
- Supports team growth and feature ownership
- Centralizes shared resources and reduces duplication
- Provides clear separation between business logic and infrastructure 