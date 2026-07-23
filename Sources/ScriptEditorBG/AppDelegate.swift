import SwiftUI

@main
struct ScriptEditorBGApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var eventTapManager: EventTapManager!
    var configManager: ConfigManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
        
        configManager = ConfigManager()
        
        setupMenuBar()
        
        // Only create event tap if we have accessibility permission
        if AXIsProcessTrusted() {
            eventTapManager = EventTapManager(configManager: configManager)
        } else {
            showPermissionAlert()
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar().statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "🎭"
            button.font = NSFont.systemFont(ofSize: 14)
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "🎭 Script Editor", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Character shortcuts info
        let charactersItem = NSMenuItem(title: "Characters:", action: nil, keyEquivalent: "")
        charactersItem.isEnabled = false
        menu.addItem(charactersItem)
        
        for (index, char) in configManager.characters.enumerated() {
            let item = NSMenuItem(
                title: "  ⌘\(index + 1) \(char.name)",
                action: #selector(insertCharacter(_:)),
                keyEquivalent: ""
            )
            item.representedObject = index
            item.target = self
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick actions
        menu.addItem(NSMenuItem(
            title: "⌘⇧H Scene Heading",
            action: #selector(insertScene),
            keyEquivalent: ""
        ))
        
        menu.addItem(NSMenuItem(
            title: "⌘⇧A Action Line",
            action: #selector(insertAction),
            keyEquivalent: ""
        ))
        
        menu.addItem(NSMenuItem(
            title: "⌘⇧P Parenthetical",
            action: #selector(insertParenthetical),
            keyEquivalent: ""
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        menu.addItem(NSMenuItem(
            title: "Open Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        
        statusItem.menu = menu
    }
    
    @objc func insertCharacter(_ sender: NSMenuItem) {
        guard let index = sender.representedObject as? Int else { return }
        eventTapManager?.insertCharacter(at: index)
    }
    
    @objc func insertScene() {
        eventTapManager?.insertSceneHeading()
    }
    
    @objc func insertAction() {
        eventTapManager?.insertActionLine()
    }
    
    @objc func insertParenthetical() {
        eventTapManager?.insertParenthetical()
    }
    
    @objc func openSettings() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Script Editor Settings"
        settingsWindow.contentView = NSHostingView(rootView: SettingsView(configManager: configManager))
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
    
    func checkPermissions() {
        // Check Accessibility
        let accessibility = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        )
        
        if !accessibility {
            showPermissionAlert()
        }
    }
    
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Permissions Required"
        alert.informativeText = "Script Editor needs Input Monitoring and Accessibility permissions to capture global shortcuts and insert text. Please grant these in System Preferences > Security & Privacy."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}
