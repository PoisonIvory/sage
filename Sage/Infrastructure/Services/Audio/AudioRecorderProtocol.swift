import Foundation



/// Recording UI state for managing recording-related UI elements
/// - Groups related UI state properties
/// - Reduces property clutter in ViewModel
/// - Provides clear state management
struct RecordingUIState: Equatable {
    var showCountdown: Bool = false
    var showProgressBar: Bool = false
    var showWaveform: Bool = false
    
    /// Creates a recording state with all UI elements visible
    static func recording() -> RecordingUIState {
        RecordingUIState(
            showCountdown: true,
            showProgressBar: true,
            showWaveform: true
        )
    }
    
    /// Creates an idle state with no UI elements visible
    static func idle() -> RecordingUIState {
        RecordingUIState(
            showCountdown: false,
            showProgressBar: false,
            showWaveform: false
        )
    }
} 