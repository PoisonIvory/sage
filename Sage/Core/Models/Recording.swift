import Foundation

/// Recording represents a single voice session, including all required metadata and time-aligned features.
/// - Complies with DATA_DICTIONARY.md, DATA_STANDARDS.md §2.3, §3.3, and RESOURCES.md.
struct Recording: Identifiable, Codable {
    // MARK: - Identifiers
    let id: UUID
    let userID: String
    let sessionTime: Date // ISO 8601 for export
    let task: String // e.g., "vowel", "reading", "spontaneous"

    // MARK: - File Info
    let fileURL: URL
    let filename: String
    let fileFormat: String // e.g., "wav"

    // MARK: - Technical Metadata
    let sampleRate: Double
    let bitDepth: Int
    let channelCount: Int
    let deviceModel: String
    let osVersion: String
    let appVersion: String

    // MARK: - Session Metadata
    let duration: TimeInterval
    let cyclePhase: String?
    let symptomMood: Int?
    // Add more as needed from DATA_DICTIONARY.md

    // MARK: - Feature Data
    /// Frame-level features: array of (timestamp, feature vector) dictionaries
    /// - Each dictionary: ["time_sec": Double, "F0_Hz": Double, ...]
    var frameFeatures: [[String: AnyCodable]]? // Use AnyCodable for flexible export
    /// Summary features: e.g., means, SDs, as per DATA_STANDARDS.md §3.3
    var summaryFeatures: [String: AnyCodable]?

    // MARK: - Initializer
    init(id: UUID = UUID(),
         userID: String,
         sessionTime: Date,
         task: String,
         fileURL: URL,
         filename: String,
         fileFormat: String,
         sampleRate: Double,
         bitDepth: Int,
         channelCount: Int,
         deviceModel: String,
         osVersion: String,
         appVersion: String,
         duration: TimeInterval,
         cyclePhase: String? = nil,
         symptomMood: Int? = nil,
         frameFeatures: [[String: AnyCodable]]? = nil,
         summaryFeatures: [String: AnyCodable]? = nil) {
        self.id = id
        self.userID = userID
        self.sessionTime = sessionTime
        self.task = task
        self.fileURL = fileURL
        self.filename = filename
        self.fileFormat = fileFormat
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.channelCount = channelCount
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.duration = duration
        self.cyclePhase = cyclePhase
        self.symptomMood = symptomMood
        self.frameFeatures = frameFeatures
        self.summaryFeatures = summaryFeatures
    }
}

/// AnyCodable is a type-erased wrapper for Codable values, for flexible feature export.
/// - Complies with DATA_STANDARDS.md, DATA_DICTIONARY.md.
struct AnyCodable: Codable, Hashable, Equatable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self.value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            self.value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            self.value = stringVal
        } else {
            self.value = ""
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        default:
            try container.encode("")
        }
    }
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as Bool, let r as Bool): return l == r
        case (let l as String, let r as String): return l == r
        default: return false
        }
    }
    func hash(into hasher: inout Hasher) {
        switch value {
        case let intVal as Int: hasher.combine(intVal)
        case let doubleVal as Double: hasher.combine(doubleVal)
        case let boolVal as Bool: hasher.combine(boolVal)
        case let stringVal as String: hasher.combine(stringVal)
        default: hasher.combine(0)
        }
    }
} 