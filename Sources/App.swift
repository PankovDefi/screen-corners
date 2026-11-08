import AppKit

@main
struct ScreenCornersApp {
    @MainActor
    static func main() {
        let args = Set(CommandLine.arguments.dropFirst())

        if args.contains("--help") || args.contains("-h") {
            print("""
            Screen Corners \(AppInfo.version)

            Usage: ScreenCorners [option]
              --register-login-item     enable launch at login and exit
              --unregister-login-item   disable launch at login and exit
              --version                 print version and exit

            Settings (restart the app after changing):
              defaults write \(AppInfo.bundleID) radius -float 15
              defaults write \(AppInfo.bundleID) topCorners -bool true
              defaults write \(AppInfo.bundleID) allDisplays -bool true
            """)
            exit(0)
        }
        if args.contains("--version") {
            print(AppInfo.version)
            exit(0)
        }
        if args.contains("--register-login-item") {
            do {
                try LoginItem.enable()
                print("Launch at login enabled: \(LoginItem.plistURL.path)")
                exit(0)
            } catch {
                fputs("Failed to enable launch at login: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
        }
        if args.contains("--unregister-login-item") {
            LoginItem.disable()
            print("Launch at login disabled")
            exit(0)
        }

        // Only one copy at a time. Exit code 0 so launchd doesn't restart us.
        let me = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: AppInfo.bundleID)
            .filter { $0.processIdentifier != me }
        if !others.isEmpty { exit(0) }

        Settings.registerDefaults()

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)   // no Dock icon
        withExtendedLifetime(delegate) { app.run() }
    }
}

enum AppInfo {
    static let bundleID = "com.screencorners.app"
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}
