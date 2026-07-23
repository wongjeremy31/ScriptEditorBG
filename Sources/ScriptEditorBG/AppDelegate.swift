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
    var eventTapManager: EventTapManager?
    var configManager: ConfigManager!
    var settingsWindow: NSWindow?
    
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
        
        // Observe language changes to refresh menu
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshMenu),
            name: .init("refreshMenu"),
            object: nil
        )
    }
    
    @objc func refreshMenu() {
        setupMenuBar()
    }
    
    func setupMenuBar() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }
        
        if let button = statusItem.button {
            button.title = "🎭"
            button.font = NSFont.systemFont(ofSize: 14)
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: configManager.localized("menuTitle"), action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Character shortcuts info
        let charactersItem = NSMenuItem(title: configManager.localized("characters"), action: nil, keyEquivalent: "")
        charactersItem.isEnabled = false
        menu.addItem(charactersItem)
        
        for (index, char) in configManager.characters.enumerated() {
            let item = NSMenuItem(
                title: "  \(configManager.modifierKey.symbol)\(index + 1) \(char.name)",
                action: #selector(insertCharacter(_:)),
                keyEquivalent: ""
            )
            item.representedObject = index
            item.target = self
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick actions
        let sceneKey = keyCodeToLetter(configManager.shortcuts.sceneHeadingKey)
        menu.addItem(NSMenuItem(
            title: "\(configManager.modifierKey.symbol)⇧\(sceneKey) \(configManager.localized("sceneHeading"))",
            action: #selector(insertScene),
            keyEquivalent: ""
        ))
        
        let actionKey = keyCodeToLetter(configManager.shortcuts.actionLineKey)
        menu.addItem(NSMenuItem(
            title: "\(configManager.modifierKey.symbol)⇧\(actionKey) \(configManager.localized("actionLine"))",
            action: #selector(insertAction),
            keyEquivalent: ""
        ))
        
        let parenKey = keyCodeToLetter(configManager.shortcuts.parentheticalKey)
        menu.addItem(NSMenuItem(
            title: "\(configManager.modifierKey.symbol)⇧\(parenKey) \(configManager.localized("parenthetical"))",
            action: #selector(insertParenthetical),
            keyEquivalent: ""
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        menu.addItem(NSMenuItem(
            title: configManager.localized("openSettings"),
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(
            title: configManager.localized("quit"),
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        
        statusItem.menu = menu
    }
    
    func keyCodeToLetter(_ keyCode: Int64) -> String {
        let keyCodeMap: [Int64: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H",
            5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 32: "U", 34: "I", 31: "O",
            35: "P", 37: "L", 38: "J", 39: "K", 40: "N",
            41: "M"
        ]
        return keyCodeMap[keyCode] ?? "?"
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
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 700),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = configManager.localized("settingsTitle")
        window.contentView = NSHostingView(rootView: SettingsView(configManager: configManager))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        settingsWindow = window
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
    
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = configManager.language == .traditionalChinese ? "需要權限" : "Permissions Required"
        alert.informativeText = configManager.language == .traditionalChinese 
            ? "劇本編輯器需要輔助使用權限才能擷取全域快捷鍵並插入文字。請在系統偏好設定 > 安全性與私隱 > 私隱 > 輔助使用中授予權限。"
            : "Script Editor needs Accessibility permission to capture global shortcuts and insert text. Please grant this in System Preferences > Security & Privacy > Privacy > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: configManager.language == .traditionalChinese ? "開啟設定" : "Open Settings")
        alert.addButton(withTitle: configManager.language == .traditionalChinese ? "稍後" : "Later")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}
