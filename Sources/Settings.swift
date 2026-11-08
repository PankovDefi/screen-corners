import Foundation
import CoreGraphics

/// User settings stored in UserDefaults (domain: com.screencorners.app).
enum Settings {
    static let defaultRadius: Double = 15
    static let minRadius: Double = 4
    static let maxRadius: Double = 40

    static let repoURL = URL(string: "https://github.com/PankovDefi/screen-corners")!

    private static var store: UserDefaults { .standard }

    static func registerDefaults() {
        store.register(defaults: [
            Key.enabled: true,
            Key.radius: defaultRadius,
            Key.topCorners: false,
            Key.allDisplays: false,
            Key.hideIcon: false,
            Key.allowCapture: false,
        ])
    }

    static var enabled: Bool {
        get { store.bool(forKey: Key.enabled) }
        set { store.set(newValue, forKey: Key.enabled) }
    }

    static var radius: CGFloat {
        get { CGFloat(min(max(store.double(forKey: Key.radius), minRadius), maxRadius)) }
        set { store.set(Double(newValue), forKey: Key.radius) }
    }

    static var topCorners: Bool {
        get { store.bool(forKey: Key.topCorners) }
        set { store.set(newValue, forKey: Key.topCorners) }
    }

    static var allDisplays: Bool {
        get { store.bool(forKey: Key.allDisplays) }
        set { store.set(newValue, forKey: Key.allDisplays) }
    }

    static var hideIcon: Bool {
        get { store.bool(forKey: Key.hideIcon) }
        set { store.set(newValue, forKey: Key.hideIcon) }
    }

    /// Show the corners in screenshots and screen recordings (off by default).
    static var allowCapture: Bool {
        get { store.bool(forKey: Key.allowCapture) }
        set { store.set(newValue, forKey: Key.allowCapture) }
    }

    private enum Key {
        static let enabled = "enabled"
        static let radius = "radius"
        static let topCorners = "topCorners"
        static let allDisplays = "allDisplays"
        static let hideIcon = "hideIcon"
        static let allowCapture = "allowCapture"
    }
}
