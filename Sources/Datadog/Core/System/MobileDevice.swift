import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Describes current mobile device.
internal class MobileDevice {
    // MARK: - Info

    let model: String
    let osName: String
    let osVersion: String

    // MARK: - Battery status monitoring

    struct BatteryStatus {
        enum State: Equatable {
            case unknown
            case unplugged
            case charging
            case full
        }

        let state: State
        let level: Float
        let isLowPowerModeEnabled: Bool
    }

    /// Enables battery status monitoring.
    let enableBatteryStatusMonitoring: () -> Void
    /// Resets battery status monitoring.
    let resetBatteryStatusMonitoring: () -> Void
    /// Returns current `BatteryStatus`.
    let currentBatteryStatus: () -> BatteryStatus

    init(
        model: String,
        osName: String,
        osVersion: String,
        enableBatteryStatusMonitoring: @escaping () -> Void,
        resetBatteryStatusMonitoring: @escaping () -> Void,
        currentBatteryStatus: @escaping () -> BatteryStatus
    ) {
        self.model = model
        self.osName = osName
        self.osVersion = osVersion
        self.enableBatteryStatusMonitoring = enableBatteryStatusMonitoring
        self.resetBatteryStatusMonitoring = resetBatteryStatusMonitoring
        self.currentBatteryStatus = currentBatteryStatus
    }

    #if canImport(UIKit)
    convenience init(uiDevice: UIDevice, processInfo: ProcessInfo) {
        let wasBatteryMonitoringEnabled = uiDevice.isBatteryMonitoringEnabled
        self.init(
            model: uiDevice.model,
            osName: uiDevice.systemName,
            osVersion: uiDevice.systemVersion,
            enableBatteryStatusMonitoring: { uiDevice.isBatteryMonitoringEnabled = true },
            resetBatteryStatusMonitoring: { uiDevice.isBatteryMonitoringEnabled = wasBatteryMonitoringEnabled },
            currentBatteryStatus: {
                return BatteryStatus(
                    state: MobileDevice.toBatteryState(uiDevice.batteryState),
                    level: uiDevice.batteryLevel,
                    isLowPowerModeEnabled: processInfo.isLowPowerModeEnabled
                )
            }
        )
    }
    #endif

    /// Returns current mobile device  if `UIDevice` is available on this platform.
    /// On other platforms returns `nil`.
    static var current: MobileDevice? {
        #if canImport(UIKit)
        return MobileDevice(uiDevice: UIDevice.current, processInfo: ProcessInfo.processInfo)
        #else
        return nil
        #endif
    }

    #if canImport(UIKit)
    private static func toBatteryState(_ uiDeviceBatteryState: UIDevice.BatteryState) -> BatteryStatus.State {
        switch uiDeviceBatteryState {
        case .unknown:      return .unknown
        case .unplugged:    return .unplugged
        case .charging:     return .charging
        case .full:         return .full
        @unknown default:   return.unknown
        }
    }
    #endif
}
