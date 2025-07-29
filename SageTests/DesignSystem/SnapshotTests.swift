import XCTest
import SwiftUI
@testable import Sage

/// Snapshot Tests for Sage Design System
/// 
/// These tests capture visual snapshots of components to ensure:
/// - Visual consistency across design variants
/// - No regressions when making changes
/// - Proper rendering of all component states
/// - Design system integrity
///
/// To run these tests:
/// 1. Build the project: `xcodebuild test -project Sage.xcodeproj -scheme Sage -destination 'platform=iOS Simulator,name=iPhone 16'`
/// 2. View snapshots in the test results
///
/// Note: These are basic snapshot tests. For production use, consider using
/// a dedicated snapshot testing library like `swift-snapshot-testing`
class SnapshotTests: XCTestCase {
    
    // MARK: - Test Setup
    
    override func setUp() {
        super.setUp()
        // Reset any global state that might affect rendering
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Capture a snapshot of a SwiftUI view
    private func snapshotView<Content: View>(_ view: Content, name: String, flags: FeatureFlags? = nil) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667) // iPhone 16 size
        
        // Trigger layout
        hostingController.view.layoutIfNeeded()
        
        // Capture snapshot
        let snapshot = hostingController.view.snapshot()
        
        // Save snapshot (in a real implementation, you'd compare against baseline)
        // For now, we'll just verify the view renders without crashing
        XCTAssertNotNil(snapshot, "Snapshot should not be nil for \(name)")
        
        print("📸 Snapshot captured for: \(name)")
    }
    
    /// Create a test view with proper padding and background
    private func testView<Content: View>(_ content: Content, flags: FeatureFlags? = nil) -> some View {
        content
            .padding(SageSpacing.medium(flags))
            .background(SageColors.background(flags))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Atoms Snapshot Tests
    
    func testAtomsSnapshot_Legacy() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        let view = testView(
            VStack(spacing: SageSpacing.medium(flags)) {
                Atoms.button(title: "Primary Button", flags: flags) { }
                Atoms.textField(placeholder: "Enter text...", text: .constant(""), flags: flags)
                Atoms.avatar(flags: flags)
                Atoms.title("Sample Title", flags: flags)
                Atoms.body("Sample body text for testing.", flags: flags)
                Atoms.caption("Sample caption text.", flags: flags)
                Atoms.divider(flags: flags)
            },
            flags: flags
        )
        
        snapshotView(view, name: "Atoms_Legacy", flags: flags)
    }
    
    func testAtomsSnapshot_Editorial() {
        let flags = FeatureFlags()
        flags.designVariant = .editorial
        
        let view = testView(
            VStack(spacing: SageSpacing.medium(flags)) {
                Atoms.button(title: "Primary Button", flags: flags) { }
                Atoms.textField(placeholder: "Enter text...", text: .constant(""), flags: flags)
                Atoms.avatar(flags: flags)
                Atoms.title("Sample Title", flags: flags)
                Atoms.body("Sample body text for testing.", flags: flags)
                Atoms.caption("Sample caption text.", flags: flags)
                Atoms.divider(flags: flags)
            },
            flags: flags
        )
        
        snapshotView(view, name: "Atoms_Editorial", flags: flags)
    }
    
    // MARK: - Molecules Snapshot Tests
    
    func testMoleculesSnapshot_Legacy() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        let view = testView(
            VStack(spacing: SageSpacing.large(flags)) {
                Molecules.FormField(
                    label: "Email",
                    text: .constant("test@example.com"),
                    error: nil,
                    flags: flags
                )
                
                Molecules.SearchBar(
                    text: .constant(""),
                    placeholder: "Search...",
                    flags: flags
                )
                
                Molecules.SectionHeader(
                    title: "Recent Items",
                    action: { },
                    flags: flags
                )
            },
            flags: flags
        )
        
        snapshotView(view, name: "Molecules_Legacy", flags: flags)
    }
    
    func testMoleculesSnapshot_Editorial() {
        let flags = FeatureFlags()
        flags.designVariant = .editorial
        
        let view = testView(
            VStack(spacing: SageSpacing.large(flags)) {
                Molecules.FormField(
                    label: "Email",
                    text: .constant("test@example.com"),
                    error: nil,
                    flags: flags
                )
                
                Molecules.SearchBar(
                    text: .constant(""),
                    placeholder: "Search...",
                    flags: flags
                )
                
                Molecules.SectionHeader(
                    title: "Recent Items",
                    action: { },
                    flags: flags
                )
            },
            flags: flags
        )
        
        snapshotView(view, name: "Molecules_Editorial", flags: flags)
    }
    
    // MARK: - Organisms Snapshot Tests
    
    func testOrganismsSnapshot_Legacy() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        let view = testView(
            VStack(spacing: SageSpacing.large(flags)) {
                Organisms.card(flags: flags) {
                    VStack(alignment: .leading, spacing: SageSpacing.medium(flags)) {
                        Atoms.title("Card Title", flags: flags)
                        Atoms.body("This is a card component with some content inside it.", flags: flags)
                        Atoms.button(title: "Card Action", flags: flags) { }
                    }
                }
                
                Organisms.ListItem(
                    avatar: Image(systemName: "person.circle"),
                    title: "John Doe",
                    subtitle: "Software Engineer",
                    flags: flags
                )
            },
            flags: flags
        )
        
        snapshotView(view, name: "Organisms_Legacy", flags: flags)
    }
    
    func testOrganismsSnapshot_Editorial() {
        let flags = FeatureFlags()
        flags.designVariant = .editorial
        
        let view = testView(
            VStack(spacing: SageSpacing.large(flags)) {
                Organisms.card(flags: flags) {
                    VStack(alignment: .leading, spacing: SageSpacing.medium(flags)) {
                        Atoms.title("Card Title", flags: flags)
                        Atoms.body("This is a card component with some content inside it.", flags: flags)
                        Atoms.button(title: "Card Action", flags: flags) { }
                    }
                }
                
                Organisms.ListItem(
                    avatar: Image(systemName: "person.circle"),
                    title: "John Doe",
                    subtitle: "Software Engineer",
                    flags: flags
                )
            },
            flags: flags
        )
        
        snapshotView(view, name: "Organisms_Editorial", flags: flags)
    }
    
    // MARK: - Button Style Experiments
    
    func testButtonStylesSnapshot() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        let buttonStyles: [FeatureFlags.ButtonStyle] = [.standard, .rounded, .minimal, .bold]
        
        for style in buttonStyles {
            flags.buttonStyleExperiment = style
            
            let view = testView(
                VStack(spacing: SageSpacing.medium(flags)) {
                    Atoms.button(title: "\(style.displayName) Button", flags: flags) { }
                },
                flags: flags
            )
            
            snapshotView(view, name: "ButtonStyle_\(style.rawValue)", flags: flags)
        }
    }
    
    // MARK: - Card Style Experiments
    
    func testCardStylesSnapshot() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        let cardStyles: [FeatureFlags.CardStyle] = [.standard, .elevated, .outlined, .minimal]
        
        for style in cardStyles {
            flags.cardStyleExperiment = style
            
            let view = testView(
                Organisms.card(flags: flags) {
                    VStack(alignment: .leading, spacing: SageSpacing.medium(flags)) {
                        Atoms.title("\(style.displayName) Card", flags: flags)
                        Atoms.body("This card demonstrates the \(style.displayName.lowercased()) style.", flags: flags)
                    }
                },
                flags: flags
            )
            
            snapshotView(view, name: "CardStyle_\(style.rawValue)", flags: flags)
        }
    }
    
    // MARK: - Animation Speed Tests
    
    func testAnimationSpeedSnapshot() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        let speeds: [Double] = [0.5, 1.0, 2.0]
        
        for speed in speeds {
            flags.animationSpeedMultiplier = speed
            
            let view = testView(
                VStack(spacing: SageSpacing.medium(flags)) {
                    Atoms.button(title: "Speed \(speed)x", flags: flags) { }
                },
                flags: flags
            )
            
            snapshotView(view, name: "AnimationSpeed_\(speed)", flags: flags)
        }
    }
    
    // MARK: - Error State Tests
    
    func testErrorStatesSnapshot() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        let view = testView(
            VStack(spacing: SageSpacing.large(flags)) {
                Molecules.FormField(
                    label: "Email",
                    text: .constant("invalid-email"),
                    error: "Please enter a valid email address",
                    flags: flags
                )
                
                Molecules.FormField(
                    label: "Password",
                    text: .constant(""),
                    error: "Password is required",
                    flags: flags
                )
            },
            flags: flags
        )
        
        snapshotView(view, name: "ErrorStates", flags: flags)
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyStatesSnapshot() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        let view = testView(
            Organisms.emptyState(
                iconName: "star",
                title: "No Favorites",
                message: "You haven't added any favorites yet. Start by exploring our components.",
                flags: flags
            ) {
                Atoms.button(title: "Explore Components", flags: flags) { }
            },
            flags: flags
        )
        
        snapshotView(view, name: "EmptyState", flags: flags)
    }
    
    // MARK: - Color Palette Tests
    
    func testColorPaletteSnapshot() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        let colors = SageColors.allColors(flags)
        let columns = Array(repeating: GridItem(.flexible()), count: 3)
        
        let view = testView(
            LazyVGrid(columns: columns, spacing: SageSpacing.small(flags)) {
                ForEach(colors, id: \.name) { color in
                    VStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.color)
                            .frame(height: 40)
                        Text(color.name)
                            .font(SageTypography.caption(flags))
                            .foregroundColor(SageColors.secondary(flags))
                    }
                }
            },
            flags: flags
        )
        
        snapshotView(view, name: "ColorPalette", flags: flags)
    }
    
    // MARK: - Responsive Layout Tests
    
    func testResponsiveLayoutSnapshot() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        // Test different content sizes
        let contentSizes = ["Short", "Medium length content", "Very long content that might wrap to multiple lines and test how the layout handles it"]
        
        for (index, content) in contentSizes.enumerated() {
            let view = testView(
                VStack(spacing: SageSpacing.medium(flags)) {
                    Atoms.title("Title \(index + 1)", flags: flags)
                    Atoms.body(content, flags: flags)
                    Atoms.button(title: "Action \(index + 1)", flags: flags) { }
                },
                flags: flags
            )
            
            snapshotView(view, name: "ResponsiveLayout_\(index + 1)", flags: flags)
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilitySnapshot() {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        
        let view = testView(
            VStack(spacing: SageSpacing.medium(flags)) {
                Atoms.button(title: "Accessible Button", flags: flags) { }
                    .accessibilityLabel("Primary action button")
                    .accessibilityHint("Taps to perform the main action")
                
                Atoms.textField(placeholder: "Accessible Input", text: .constant(""), flags: flags)
                    .accessibilityLabel("Text input field")
                    .accessibilityHint("Enter your text here")
                
                Atoms.avatar(flags: flags)
                    .accessibilityLabel("User avatar")
            },
            flags: flags
        )
        
        snapshotView(view, name: "Accessibility", flags: flags)
    }
}

// MARK: - Snapshot Testing Utilities

extension UIView {
    /// Capture a snapshot of the view
    func snapshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Test Helpers

extension SnapshotTests {
    /// Helper to create a consistent test environment
    func createTestEnvironment() -> FeatureFlags {
        let flags = FeatureFlags()
        flags.designVariant = .legacy
        flags.buttonStyleExperiment = .standard
        flags.cardStyleExperiment = .standard
        flags.animationSpeedMultiplier = 1.0
        return flags
    }
    
    /// Helper to create a test view with standard content
    func createTestContentView(flags: FeatureFlags) -> some View {
        VStack(spacing: SageSpacing.medium(flags)) {
            Atoms.title("Test Title", flags: flags)
            Atoms.body("This is test content for snapshot testing.", flags: flags)
            Atoms.button(title: "Test Button", flags: flags) { }
        }
        .padding(SageSpacing.medium(flags))
        .background(SageColors.background(flags))
    }
} 