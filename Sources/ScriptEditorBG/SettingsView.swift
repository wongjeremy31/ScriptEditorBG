import SwiftUI
import Carbon

struct SettingsView: View {
    @ObservedObject var configManager: ConfigManager
    @State private var newCharacterName: String = ""
    @State private var recordingShortcut: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(configManager.localized("menuTitle"))
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            Divider()
            
            // Language Selection
            VStack(alignment: .leading, spacing: 10) {
                Text(configManager.localized("language"))
                    .font(.headline)
                
                Picker("Language", selection: $configManager.language) {
                    Text("English").tag(AppLanguage.english)
                    Text("繁體中文").tag(AppLanguage.traditionalChinese)
                }
                .pickerStyle(.segmented)
                .onChange(of: configManager.language) { _ in
                    configManager.saveConfig()
                }
            }
            
            Divider()
            
            // Format Selection
            VStack(alignment: .leading, spacing: 10) {
                Text(configManager.localized("format"))
                    .font(.headline)
                
                Picker("Format", selection: $configManager.format) {
                    Text(configManager.localized("stagePlay")).tag(ScriptFormat.stage)
                    Text(configManager.localized("screenplay")).tag(ScriptFormat.screenplay)
                }
                .pickerStyle(.segmented)
                .onChange(of: configManager.format) { _ in
                    configManager.saveConfig()
                }
            }
            
            Divider()
            
            // Shortcuts Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(configManager.localized("keyboardShortcuts"))
                        .font(.headline)
                    Spacer()
                    Text(configManager.localized("global"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Modifier key selector
                HStack {
                    Text(configManager.localized("modifier"))
                    Picker("Modifier", selection: $configManager.modifierKey) {
                        Text("⌘ Command").tag(ModifierKey.command)
                        Text("⌥ Option").tag(ModifierKey.option)
                        Text("⌃ Control").tag(ModifierKey.control)
                        Text("⇧ Shift").tag(ModifierKey.shift)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: configManager.modifierKey) { _ in
                        configManager.saveConfig()
                    }
                }
                
                // Customizable shortcuts
                VStack(alignment: .leading, spacing: 8) {
                    Text(configManager.localized("customizeShortcuts"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ShortcutConfigRow(
                        label: configManager.localized("sceneHeading"),
                        shortcut: "\(configManager.modifierKey.symbol)⇧\(keyCodeToLetter(configManager.shortcuts.sceneHeadingKey))",
                        keyCode: $configManager.shortcuts.sceneHeadingKey
                    )
                    
                    ShortcutConfigRow(
                        label: configManager.localized("actionLine"),
                        shortcut: "\(configManager.modifierKey.symbol)⇧\(keyCodeToLetter(configManager.shortcuts.actionLineKey))",
                        keyCode: $configManager.shortcuts.actionLineKey
                    )
                    
                    ShortcutConfigRow(
                        label: configManager.localized("parenthetical"),
                        shortcut: "\(configManager.modifierKey.symbol)⇧\(keyCodeToLetter(configManager.shortcuts.parentheticalKey))",
                        keyCode: $configManager.shortcuts.parentheticalKey
                    )
                }
                .padding(.vertical, 4)
                
                // Character shortcuts (fixed to numbers)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(configManager.characters.enumerated()), id: \.element.id) { index, character in
                        HStack {
                            Text("\(configManager.modifierKey.symbol)\(index + 1)")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 50, alignment: .leading)
                            
                            Text(character.name)
                            
                            Spacer()
                            
                            Button("×") {
                                configManager.removeCharacter(at: IndexSet([index]))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.red)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                // Add character
                HStack {
                    TextField(configManager.language == .traditionalChinese ? "新角色名稱" : "New character name", text: $newCharacterName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(configManager.language == .traditionalChinese ? "新增" : "Add") {
                        if !newCharacterName.isEmpty {
                            configManager.addCharacter(name: newCharacterName)
                            newCharacterName = ""
                        }
                    }
                    .disabled(newCharacterName.isEmpty)
                }
            }
            
            Divider()
            
            // Notifications Toggle
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(configManager.localized("showNotifications"))
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $configManager.showNotifications)
                        .onChange(of: configManager.showNotifications) { _ in
                            configManager.saveConfig()
                        }
                }
            }
            
            Divider()
            
            // Permissions
            VStack(alignment: .leading, spacing: 8) {
                Text(configManager.localized("permissions"))
                    .font(.headline)
                
                HStack {
                    Image(systemName: AXIsProcessTrusted() ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(AXIsProcessTrusted() ? .green : .red)
                    Text(AXIsProcessTrusted() ? configManager.localized("accessibilityGranted") : configManager.localized("accessibilityRequired"))
                    Spacer()
                }
                
                if !AXIsProcessTrusted() {
                    Button(configManager.language == .traditionalChinese ? "開啟系統偏好設定 → 私隱 → 輔助使用" : "Open System Preferences → Privacy → Accessibility") {
                        NSWorkspace.shared.open(
                            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        )
                    }
                }
                
                Text(configManager.language == .traditionalChinese ? "此應用程式需要輔助使用權限才能在其他應用程式中插入文字。" : "The app needs Accessibility permission to insert text into other apps.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Instructions
            VStack(alignment: .leading, spacing: 4) {
                Text(configManager.localized("howToUse"))
                    .font(.headline)
                Text(configManager.localized("step1"))
                Text(configManager.localized("step2"))
                Text(configManager.localized("step3"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 520, height: 700)
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
}

struct ShortcutConfigRow: View {
    let label: String
    let shortcut: String
    @Binding var keyCode: Int64
    
    let availableKeys: [(String, Int64)] = [
        ("A", 0), ("B", 11), ("C", 8), ("D", 2), ("E", 14),
        ("F", 3), ("G", 5), ("H", 4), ("I", 34), ("J", 38),
        ("K", 39), ("L", 37), ("M", 41), ("N", 40), ("O", 31),
        ("P", 35), ("Q", 12), ("R", 15), ("S", 1), ("T", 17),
        ("U", 32), ("V", 9), ("W", 13), ("X", 7), ("Y", 16),
        ("Z", 6)
    ]
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            Spacer()
            
            Picker("Key", selection: $keyCode) {
                ForEach(availableKeys, id: \.1) { key, code in
                    Text(key).tag(code)
                }
            }
            .frame(width: 80)
            .pickerStyle(.menu)
        }
    }
}
