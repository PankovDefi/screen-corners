import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var overlay: OverlayManager!
    private var statusItem: NSStatusItem!

    private var radiusLabel: NSTextField!
    private var radiusSlider: NSSlider!
    private var enabledItem: NSMenuItem!
    private var topItem: NSMenuItem!
    private var displaysItem: NSMenuItem!
    private var loginItem: NSMenuItem!

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Keep the LaunchAgent pointing at the current app location.
        if LoginItem.isEnabled { try? LoginItem.enable() }

        overlay = OverlayManager()
        overlay.rebuild()
        setupStatusItem()

        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged(_:)),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(screensChanged(_:)),
            name: NSWorkspace.didWakeNotification, object: nil)
    }

    /// Opening the app again (Finder / Spotlight / `open -a`) brings the icon back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Settings.hideIcon = false
        statusItem?.isVisible = true
        return false
    }

    @objc private func screensChanged(_ notification: Notification) {
        overlay.rebuild()
    }

    // MARK: - Menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "rectangle.roundedbottom", accessibilityDescription: "Screen Corners")
                ?? NSImage(systemSymbolName: "display", accessibilityDescription: "Screen Corners")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Screen Corners"
        }

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        let header = NSMenuItem(title: "Screen Corners \(AppInfo.version)", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        enabledItem = addItem(to: menu, L10n.enabled, #selector(toggleEnabled))
        menu.addItem(makeSliderItem())
        addItem(to: menu, L10n.resetRadius(Settings.defaultRadius), #selector(resetRadius))
        menu.addItem(.separator())

        topItem = addItem(to: menu, L10n.topCorners, #selector(toggleTop))
        displaysItem = addItem(to: menu, L10n.allDisplays, #selector(toggleDisplays))
        menu.addItem(.separator())

        loginItem = addItem(to: menu, L10n.launchAtLogin, #selector(toggleLogin))
        addItem(to: menu, L10n.hideIcon, #selector(hideIcon))
        menu.addItem(.separator())

        addItem(to: menu, L10n.github, #selector(openGitHub))
        addItem(to: menu, L10n.quit, #selector(quit), key: "q")

        statusItem.menu = menu
        statusItem.isVisible = !Settings.hideIcon
        refreshMenu()
    }

    @discardableResult
    private func addItem(to menu: NSMenu, _ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
        return item
    }

    private func makeSliderItem() -> NSMenuItem {
        let width: CGFloat = 240, height: CGFloat = 46
        let view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        radiusLabel = NSTextField(labelWithString: "")
        radiusLabel.font = NSFont.menuFont(ofSize: 0)
        radiusLabel.frame = NSRect(x: 20, y: 25, width: width - 40, height: 17)

        radiusSlider = NSSlider(value: Double(Settings.radius),
                                minValue: Settings.minRadius, maxValue: Settings.maxRadius,
                                target: self, action: #selector(radiusChanged(_:)))
        radiusSlider.isContinuous = true
        radiusSlider.frame = NSRect(x: 18, y: 3, width: width - 36, height: 22)

        view.addSubview(radiusLabel)
        view.addSubview(radiusSlider)

        let item = NSMenuItem()
        item.view = view
        return item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        refreshMenu()
    }

    private func refreshMenu() {
        enabledItem.state = Settings.enabled ? .on : .off
        topItem.state = Settings.topCorners ? .on : .off
        displaysItem.state = Settings.allDisplays ? .on : .off
        loginItem.state = LoginItem.isEnabled ? .on : .off

        let r = Double(Settings.radius)
        radiusSlider.doubleValue = r
        radiusSlider.isEnabled = Settings.enabled
        radiusLabel.stringValue = L10n.radius(r)
        radiusLabel.textColor = Settings.enabled ? .labelColor : .disabledControlTextColor
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        Settings.enabled.toggle()
        overlay.rebuild()
        refreshMenu()
    }

    @objc private func radiusChanged(_ slider: NSSlider) {
        let value = slider.doubleValue.rounded()
        radiusLabel.stringValue = L10n.radius(value)
        if CGFloat(value) != Settings.radius {
            Settings.radius = CGFloat(value)
            overlay.rebuild()
        }
    }

    @objc private func resetRadius() {
        Settings.radius = CGFloat(Settings.defaultRadius)
        overlay.rebuild()
        refreshMenu()
    }

    @objc private func toggleTop() {
        Settings.topCorners.toggle()
        overlay.rebuild()
        refreshMenu()
    }

    @objc private func toggleDisplays() {
        Settings.allDisplays.toggle()
        overlay.rebuild()
        refreshMenu()
    }

    @objc private func toggleLogin() {
        if LoginItem.isEnabled {
            LoginItem.disable()
        } else {
            do {
                try LoginItem.enable()
            } catch {
                showAlert(title: L10n.loginErrorTitle, text: error.localizedDescription)
            }
        }
        refreshMenu()
    }

    @objc private func hideIcon() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = L10n.hideIconTitle
        alert.informativeText = L10n.hideIconText
        alert.addButton(withTitle: L10n.hide)
        alert.addButton(withTitle: L10n.cancel)
        if alert.runModal() == .alertFirstButtonReturn {
            Settings.hideIcon = true
            statusItem.isVisible = false
        }
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(Settings.repoURL)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func showAlert(title: String, text: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.runModal()
    }
}
