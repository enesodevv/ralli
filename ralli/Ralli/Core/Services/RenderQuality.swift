import Foundation
import Combine

/// How much the 3D court may cost. Drops to `.eco` in Low Power Mode or when the phone gets hot,
/// and returns to `.full` once it cools down.
enum RenderQuality: Equatable {
    case full, eco
    var framesPerSecond: Int { self == .full ? 60 : 30 }
}

@MainActor final class RenderQualityMonitor: ObservableObject {
    static let shared = RenderQualityMonitor()
    @Published private(set) var quality: RenderQuality = RenderQualityMonitor.current()
    private var observers: [NSObjectProtocol] = []

    private init() {
        let center = NotificationCenter.default
        for name in [ProcessInfo.thermalStateDidChangeNotification, Notification.Name.NSProcessInfoPowerStateDidChange] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.quality = RenderQualityMonitor.current() }
            })
        }
    }
    nonisolated static func current() -> RenderQuality {
        let info = ProcessInfo.processInfo
        return info.isLowPowerModeEnabled || info.thermalState == .serious || info.thermalState == .critical ? .eco : .full
    }
}
