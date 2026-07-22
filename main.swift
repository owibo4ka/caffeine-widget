import AppKit
import ServiceManagement

// A tiny menu-bar widget that toggles `caffeinate` on and off.
// Left-click  -> toggle awake / allow-sleep (indefinite)
// Right-click -> menu (status, timed modes, launch-at-login, quit)
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var caffeinate: Process?
    private var autoOffTimer: Timer?
    private var offDate: Date?

    private var isAwake: Bool { caffeinate?.isRunning ?? false }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        refresh()
    }

    @objc private func handleClick(_ sender: Any?) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        if isRightClick {
            showMenu()
        } else {
            toggle()
        }
    }

    private func toggle() {
        isAwake ? stop() : start(duration: nil)
        refresh()
    }

    private func start(duration: TimeInterval?) {
        stop() // start clean
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = ["-dimsu"] // display, idle, disk, system, + on battery
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async { self?.refresh() }
        }
        try? p.run()
        caffeinate = p

        if let duration {
            offDate = Date().addingTimeInterval(duration)
            autoOffTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.stop()
                    self?.refresh()
                }
            }
        }
    }

    private func stop() {
        autoOffTimer?.invalidate(); autoOffTimer = nil
        offDate = nil
        caffeinate?.terminate(); caffeinate = nil
    }

    private func refresh() {
        guard let button = statusItem.button else { return }
        let name = isAwake ? "cup.and.saucer.fill" : "cup.and.saucer"
        button.image = NSImage(systemSymbolName: name, accessibilityDescription: "Caffeine")
        button.image?.isTemplate = true
        if isAwake {
            button.toolTip = offDate != nil
                ? "Awake until \(Self.timeFormatter.string(from: offDate!))"
                : "Awake — your Mac won't sleep"
        } else {
            button.toolTip = "Sleep allowed — click to keep awake"
        }
    }

    // MARK: - Menu

    private func showMenu() {
        let menu = NSMenu()

        let statusText: String
        if isAwake, let offDate {
            statusText = "☕️  Awake until \(Self.timeFormatter.string(from: offDate))"
        } else if isAwake {
            statusText = "☕️  Awake — staying up"
        } else {
            statusText = "😴  Sleep allowed"
        }
        let status = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        menu.addItem(item(
            title: isAwake ? "Let it sleep" : "Keep awake",
            action: #selector(menuToggle), key: "t"))

        // Timed submenu
        let timedItem = NSMenuItem(title: "Keep awake for…", action: nil, keyEquivalent: "")
        let timed = NSMenu()
        for (label, minutes) in [("15 minutes", 15), ("30 minutes", 30),
                                 ("1 hour", 60), ("2 hours", 120), ("4 hours", 240)] {
            let mi = item(title: label, action: #selector(startTimed(_:)), key: "")
            mi.representedObject = TimeInterval(minutes * 60)
            timed.addItem(mi)
        }
        timedItem.submenu = timed
        menu.addItem(timedItem)
        menu.addItem(.separator())

        let login = item(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), key: "")
        login.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())

        menu.addItem(item(title: "Quit Caffeine Widget", action: #selector(quit), key: "q"))

        if let button = statusItem.button {
            menu.popUp(positioning: nil,
                       at: NSPoint(x: 0, y: button.bounds.height + 4),
                       in: button)
        }
    }

    private func item(title: String, action: Selector, key: String) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: key)
        mi.target = self
        return mi
    }

    @objc private func menuToggle() { toggle() }

    @objc private func startTimed(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? TimeInterval else { return }
        start(duration: seconds)
        refresh()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSSound.beep()
        }
    }

    @objc private func quit() {
        stop()
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        stop()
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // no Dock icon, menu-bar only
let delegate = AppDelegate()
app.delegate = delegate
app.run()
