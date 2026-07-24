import SwiftUI
import Carbon

struct SettingsView: View {
    @ObservedObject var configManager: ConfigManager
    @State private var newCharacterName: String = ""
    @State private var newProfileName: String = ""
    @State private var newTemplateName: String = ""
    @State private var newTemplateText: String = ""
    @State private var selectedTemplateKeyCode: Int64 = 18
    
    let availableKeys: [(String, Int64)] = [
        ("1", 18), ("2", 19), ("3", 20), ("4", 21), ("5", 22),
        ("6", 23), ("7", 24), ("8", 25), ("9", 26),
        ("Q", 12), ("W", 13), ("E", 14), ("R", 15), ("T", 17),
        ("Y", 16), ("U", 32), ("I", 34), ("O", 31), ("P", 35),
        ("L", 37), ("K", 39), ("J", 38), ("N", 40), ("M", 41)
    ]
    
    var body: some View {
        ScrollView {
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
                        NotificationCenter.default.post(name: .init("refreshMenu"), object: nil)
                    }
                }
                
                Divider()
                
                // Word Count Display
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(configManager.localized("wordCount"))
                            .font(.headline)
                        Spacer()
                        Text("\(configManager.todayWordCount) \(configManager.localized("words"))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                
                // Profiles Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(configManager.localized("profiles"))
                            .font(.headline)
                        Spacer()
                    }
                    
                    // Active profile indicator
                    HStack {
                        Text(configManager.language == .traditionalChinese ? "目前專案：" : "Active: ")
                            .foregroundColor(.secondary)
                        if let activeId = configManager.activeProfileId,
                           let profile = configManager.profiles.first(where: { $0.id == activeId }) {
                            Text(profile.name)
                                .fontWeight(.semibold)
                        } else {
                            Text(configManager.localized("defaultProfile"))
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    
                    // Profile list
                    ForEach(configManager.profiles) { profile in
                        HStack {
                            Text(profile.name)
                            Spacer()
                            if configManager.activeProfileId == profile.id {
                                Text("✓")
                                    .foregroundColor(.green)
                            }
                            Button(configManager.language == .traditionalChinese ? "切換" : "Switch") {
                                configManager.switchToProfile(profile.id)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            Button("×") {
                                if let index = configManager.profiles.firstIndex(where: { $0.id == profile.id }) {
                                    configManager.deleteProfile(at: IndexSet([index]))
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(.red)
                        }
                    }
                    
                    // Add new profile
                    HStack {
                        TextField(configManager.language == .traditionalChinese ? "新專案名稱" : "New profile name", text: $newProfileName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(configManager.language == .traditionalChinese ? "新增" : "Add") {
                            if !newProfileName.isEmpty {
                                configManager.addProfile(name: newProfileName)
                                newProfileName = ""
                            }
                        }
                        .disabled(newProfileName.isEmpty)
                    }
                    
                    if configManager.activeProfileId != nil {
                        Button(configManager.language == .traditionalChinese ? "返回預設設定檔" : "Back to Default") {
                            configManager.activeProfileId = nil
                            configManager.saveConfig()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                Divider()
                
                // Scene Templates Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(configManager.localized("sceneTemplates"))
                            .font(.headline)
                        Spacer()
                    }
                    
                    // Template list
                    ForEach(configManager.sceneTemplates) { template in
                        HStack {
                            Text("\(configManager.modifierKey.symbol)⇧\(keyCodeToLetter(template.keyCode))")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 50, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.name)
                                    .fontWeight(.medium)
                                Text(template.text)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button("×") {
                                if let index = configManager.sceneTemplates.firstIndex(where: { $0.id == template.id }) {
                                    configManager.removeSceneTemplate(at: IndexSet([index]))
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(.red)
                        }
                    }
                    
                    // Add new template
                    VStack(alignment: .leading, spacing: 6) {
                        TextField(configManager.language == .traditionalChinese ? "範本名稱" : "Template name", text: $newTemplateName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField(configManager.language == .traditionalChinese ? "範本內容" : "Template text", text: $newTemplateText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            Text(configManager.language == .traditionalChinese ? "快捷鍵：" : "Shortcut key:")
                            Picker("Key", selection: $selectedTemplateKeyCode) {
                                ForEach(availableKeys, id: \.1) { key, code in
                                    Text(key).tag(code)
                                }
                            }
                            .frame(width: 80)
                            .pickerStyle(.menu)
                            
                            Spacer()
                            
                            Button(configManager.language == .traditionalChinese ? "新增範本" : "Add Template") {
                                if !newTemplateName.isEmpty && !newTemplateText.isEmpty {
                                    configManager.addSceneTemplate(
                                        name: newTemplateName,
                                        text: newTemplateText,
                                        keyCode: selectedTemplateKeyCode
                                    )
                                    newTemplateName = ""
                                    newTemplateText = ""
                                }
                            }
                            .disabled(newTemplateName.isEmpty || newTemplateText.isEmpty)
                        }
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
                            NotificationCenter.default.post(name: .init("refreshMenu"), object: nil)
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
                    
                    // Character shortcuts
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
            }
            .padding()
            .frame(width: 560)
        }
        .frame(height: 700)
    }
    
    func keyCodeToLetter(_ keyCode: Int64) -> String {
        let keyCodeMap: [Int64: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H",
            5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3",
            21: "4", 22: "5", 23: "6", 24: "7", 25: "8",
            26: "9", 32: "U", 34: "I", 31: "O",
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
