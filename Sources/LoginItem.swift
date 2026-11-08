import Foundation

/// Launch at login via a per-user LaunchAgent.
/// Works for locally built, unsigned apps and can be inspected/removed by hand.
enum LoginItem {
    static let label = "com.screencorners.app"

    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func enable() throws {
        guard let exe = Bundle.main.executablePath else {
            throw CocoaError(.fileNoSuchFile)
        }
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [exe],
            "RunAtLoad": true,
            // Restart after a crash, but not after "Quit" from the menu.
            "KeepAlive": ["SuccessfulExit": false],
            "ProcessType": "Interactive",
            "LimitLoadToSessionType": "Aqua",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try FileManager.default.createDirectory(at: plistURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: plistURL, options: .atomic)
    }

    static func disable() {
        try? FileManager.default.removeItem(at: plistURL)
    }
}
