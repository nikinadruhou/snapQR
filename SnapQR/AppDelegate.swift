import Cocoa
import SwiftUI
import CoreImage
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var hotKey: HotKey?
    var settingsWindow: NSWindow?
    var shortcutString: String = UserDefaults.standard.string(forKey: "SnapQRShortcut") ?? "cmd+option+q"

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "qrcode.viewfinder",
                accessibilityDescription: "SnapQR"
            )
            button.action = #selector(scanQRCode)
        }

        registerHotKey(from: shortcutString)
    }

    func registerHotKey(from shortcut: String) {
        hotKey = nil

        let parts = shortcut.lowercased().split(separator: "+")
        var modifiers: NSEvent.ModifierFlags = []
        var key: Key? = nil

        for part in parts {
            switch part {
            case "cmd", "command": modifiers.insert(.command)
            case "option", "alt": modifiers.insert(.option)
            case "shift": modifiers.insert(.shift)
            case "ctrl", "control": modifiers.insert(.control)
            default:
                if let k = Key(string: String(part)) {
                    key = k
                }
            }
        }

        guard let hotKeyKey = key else { return }
        hotKey = HotKey(key: hotKeyKey, modifiers: modifiers)
        hotKey?.keyDownHandler = { [weak self] in
            self?.scanQRCode()
        }
    }

    @objc func scanQRCode() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "/tmp/snapqr.png"]
        task.launch()
        task.waitUntilExit()

        let imageUrl = URL(fileURLWithPath: "/tmp/snapqr.png")
        guard FileManager.default.fileExists(atPath: imageUrl.path) else {
            return
        }
        guard let ciImage = CIImage(contentsOf: imageUrl) else {
            showResult("Failed to load screenshot.")
            return
        }

        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
        let features = detector?.features(in: ciImage) ?? []

        var message = "No QR code found."
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature {
                message = qrFeature.messageString ?? message
                break
            }
        }

        showResult(message)
    }

    func showResult(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "QR Code Result"
            alert.informativeText = message
            alert.alertStyle = .informational

            alert.addButton(withTitle: "OK")

            var hasContent = !message.isEmpty && message != "No QR code found." && message != "Failed to load screenshot."
            if hasContent {
                alert.addButton(withTitle: "Copy content")
                if let url = URL(string: message), url.scheme?.hasPrefix("http") == true {
                    alert.addButton(withTitle: "Open in default browser")
                }
            }

            alert.addButton(withTitle: "Preferences")

            let response = alert.runModal()

            if hasContent {
                if response == .alertSecondButtonReturn {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message, forType: .string)
                } else if response == .alertThirdButtonReturn {
                    if let url = URL(string: message) {
                        NSWorkspace.shared.open(url)
                    }
                } else if response.rawValue == 1003 {
                    self.openSettings()
                }
            } else {
                if response == .alertSecondButtonReturn {
                    self.openSettings()
                }
            }
        }
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView(appDelegate: self)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 120),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Settings"
            window.contentView = NSHostingView(rootView: contentView.environment(\.settingsWindow, window))
            window.isReleasedWhenClosed = false
            window.makeKeyAndOrderFront(nil)
            settingsWindow = window
        } else {
            settingsWindow?.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - SwiftUI Settings View

import SwiftUI

private struct SettingsWindowKey: EnvironmentKey {
    static let defaultValue: NSWindow? = nil
}
extension EnvironmentValues {
    var settingsWindow: NSWindow? {
        get { self[SettingsWindowKey.self] }
        set { self[SettingsWindowKey.self] = newValue }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.settingsWindow) var window

    init(appDelegate: AppDelegate) {
        self.viewModel = SettingsViewModel(appDelegate: appDelegate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Change Shortcut (e.g. cmd+option+q):")
            TextField("Shortcut", text: $viewModel.shortcut)
                .onSubmit {
                    viewModel.applyShortcut()
                    window?.close()
                }
            Button("Apply") {
                viewModel.applyShortcut()
                window?.close()
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 280)
    }
}

class SettingsViewModel: ObservableObject {
    @Published var shortcut: String
    private weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        self.shortcut = appDelegate.shortcutString
    }

    func applyShortcut() {
        appDelegate?.shortcutString = shortcut
        appDelegate?.registerHotKey(from: shortcut)
        UserDefaults.standard.set(shortcut, forKey: "SnapQRShortcut")
    }
}

// MARK: - HotKey Key Helper

extension Key {
    init?(string: String) {
        switch string {
        case "a": self = .a
        case "b": self = .b
        case "c": self = .c
        case "d": self = .d
        case "e": self = .e
        case "f": self = .f
        case "g": self = .g
        case "h": self = .h
        case "i": self = .i
        case "j": self = .j
        case "k": self = .k
        case "l": self = .l
        case "m": self = .m
        case "n": self = .n
        case "o": self = .o
        case "p": self = .p
        case "q": self = .q
        case "r": self = .r
        case "s": self = .s
        case "t": self = .t
        case "u": self = .u
        case "v": self = .v
        case "w": self = .w
        case "x": self = .x
        case "y": self = .y
        case "z": self = .z
        case "1": self = .one
        case "2": self = .two
        case "3": self = .three
        case "4": self = .four
        case "5": self = .five
        case "6": self = .six
        case "7": self = .seven
        case "8": self = .eight
        case "9": self = .nine
        case "0": self = .zero
        default: return nil
        }
    }
}
