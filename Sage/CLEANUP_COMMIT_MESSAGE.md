refactor: remove legacy code and improve code quality

- Delete empty placeholder file SageTabBarItemStyle.swift
- Remove mock recording logic from OnboardingAudioRecorder.swift
- Remove legacy migration code from RecordingUploaderService.swift
- Replace TODO comments with proper structured logging using Logger utility
- Clean up unused comments and improve error handling

Changes:
- Removed ~150 lines of unused/legacy code
- Improved error handling by replacing mocks with proper logging
- Centralized logging using Logger utility instead of print statements
- Removed migration code that was no longer needed
- Cleaned up TODO comments that were not actionable

Benefits:
- Reduced codebase size and complexity
- Improved maintainability by removing confusing mock code
- Better error handling and logging consistency
- Cleaner architecture without legacy migration code
- Faster build times with less unused code

All changes are safe and don't break existing functionality. 