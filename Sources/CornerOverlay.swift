import AppKit

enum Corner { case bottomLeft, bottomRight, topLeft, topRight }

/// Draws a black "inverse quarter circle": a square minus a circle.
final class CornerView: NSView {
    let corner: Corner

    init(frame: NSRect, corner: Corner) {
        self.corner = corner
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.width
        let center: NSPoint
        switch corner {
        case .bottomLeft:  center = NSPoint(x: r, y: r)
        case .bottomRight: center = NSPoint(x: 0, y: r)
        case .topLeft:     center = NSPoint(x: r, y: 0)
        case .topRight:    center = NSPoint(x: 0, y: 0)
        }
        let path = NSBezierPath(rect: bounds)
        path.appendOval(in: NSRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
        path.windingRule = .evenOdd
        NSColor.black.setFill()
        path.fill()
    }
}

/// Owns the small borderless windows sitting in the screen corners.
@MainActor
final class OverlayManager {
    private var windows: [NSWindow] = []

    func rebuild() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        guard Settings.enabled else { return }

        for screen in NSScreen.screens where Settings.allDisplays || isBuiltIn(screen) {
            let f = screen.frame
            let r = min(Settings.radius, f.width / 2, f.height / 2)

            var corners: [(Corner, NSPoint)] = [
                (.bottomLeft,  NSPoint(x: f.minX,     y: f.minY)),
                (.bottomRight, NSPoint(x: f.maxX - r, y: f.minY)),
            ]
            if Settings.topCorners {
                corners += [
                    (.topLeft,  NSPoint(x: f.minX,     y: f.maxY - r)),
                    (.topRight, NSPoint(x: f.maxX - r, y: f.maxY - r)),
                ]
            }
            for (corner, origin) in corners {
                windows.append(makeWindow(rect: NSRect(origin: origin, size: NSSize(width: r, height: r)),
                                          corner: corner))
            }
        }
    }

    private func makeWindow(rect: NSRect, corner: Corner) -> NSWindow {
        let w = NSWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
        w.isReleasedWhenClosed = false
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.ignoresMouseEvents = true                 // clicks pass through
        w.level = .screenSaver                      // above Dock, menus and full-screen apps
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        w.isExcludedFromWindowsMenu = true
        w.animationBehavior = .none
        w.sharingType = .none                       // try to stay out of screenshots
        w.contentView = CornerView(frame: NSRect(origin: .zero, size: rect.size), corner: corner)
        w.orderFrontRegardless()
        return w
    }

    private func isBuiltIn(_ screen: NSScreen) -> Bool {
        guard let n = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else { return false }
        return CGDisplayIsBuiltin(CGDirectDisplayID(n.uint32Value)) != 0
    }
}
