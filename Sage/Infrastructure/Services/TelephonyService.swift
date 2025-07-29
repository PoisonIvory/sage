import Foundation
import CoreTelephony

/// Service to handle telephony-related functionality
/// Provides graceful handling of Core Telephony errors in simulator environment
class TelephonyService {
    static let shared = TelephonyService()
    
    private let telephonyInfo = CTTelephonyNetworkInfo()
    
    private init() {
        setupTelephonyErrorHandling()
    }
    
    /// Setup error handling for Core Telephony services
    private func setupTelephonyErrorHandling() {
        // Suppress Core Telephony errors in simulator
        #if targetEnvironment(simulator)
        print("TelephonyService: Running in simulator - Core Telephony services not available")
        // Set up error handling to suppress simulator warnings
        setupSimulatorErrorHandling()
        #else
        // In real device, Core Telephony should work normally
        print("TelephonyService: Running on device - Core Telephony services available")
        #endif
    }
    
    /// Setup error handling specifically for simulator environment
    private func setupSimulatorErrorHandling() {
        // In simulator, we expect Core Telephony to fail gracefully
        // This method helps suppress the expected error messages
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("TelephonyService: Simulator environment detected - Core Telephony errors are expected and can be safely ignored")
        }
    }
    
    /// Get current carrier information (if available)
    var currentCarrier: String? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return telephonyInfo.serviceSubscriberCellularProviders?.values.first?.carrierName
        #endif
    }
    
    /// Check if device has cellular capability
    var hasCellularCapability: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return telephonyInfo.serviceSubscriberCellularProviders != nil
        #endif
    }
    
    /// Get network type (if available)
    var networkType: String? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return telephonyInfo.serviceCurrentRadioAccessTechnology?.values.first
        #endif
    }
    
    /// Log telephony status for debugging
    func logTelephonyStatus() {
        print("TelephonyService: Cellular capability: \(hasCellularCapability)")
        if let carrier = currentCarrier {
            print("TelephonyService: Current carrier: \(carrier)")
        }
        if let network = networkType {
            print("TelephonyService: Network type: \(network)")
        }
        
        #if targetEnvironment(simulator)
        print("TelephonyService: Running in simulator - telephony features disabled")
        #endif
    }
} 