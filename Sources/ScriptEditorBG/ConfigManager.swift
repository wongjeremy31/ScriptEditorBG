import Foundation
import CoreGraphics

enum ScriptFormat: String, Codable, CaseIterable, Identifiable {
    case stage = "stage"
    case screenplay = "screenplay"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .stage: return NSLocalizedString("Stage Play", comment: "")
        case .screenplay: return NSLocalizedString("Screenplay", comment: "")
        }
    }
}

enum ModifierKey: String, Codable, CaseIterable, Identifiable {
    case command = "command"
    case option = "option"
    case control = "control"
    case shift = "shift"
    
    var id: String { rawValue }
    
    var cgEventFlags: CGEventFlags {
        switch self {
        case .command: return .maskCommand
        case .option: return .maskAlternate
        case .control: return .maskControl
        case .shift: return .maskShift
        }
    }
    
    var symbol: String {
        switch self {
        case .command: return "⌘"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case traditionalChinese = "zh-Hant"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        }
    }
}

struct ScriptCharacter: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

struct ShortcutConfig: Codable, Equatable {
    var sceneHeadingKey: Int64    // keycode
    var actionLineKey: Int64
    var parentheticalKey: Int64
    
    static let `default` = ShortcutConfig(
        sceneHeadingKey: 4,      // H
        actionLineKey: 0,         // A
        parentheticalKey: 35      // P
    )
}

class ConfigManager: ObservableObject {
    @Published var characters: [ScriptCharacter] = [
        ScriptCharacter(name: "Jeremy"),
        ScriptCharacter(name: "Alice"),
        ScriptCharacter(name: "Narrator")
    ]
    @Published var format: ScriptFormat = .stage
    @Published var modifierKey: ModifierKey = .command
    @Published var language: AppLanguage = .traditionalChinese
    @Published var shortcuts: ShortcutConfig = .default
    @Published var showNotifications: Bool = true
    
    private let configURL: URL
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ScriptEditorBG", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        self.configURL = appFolder.appendingPathComponent("config.json")
        
        loadConfig()
    }
    
    func localized(_ key: String) -> String {
        switch language {
        case .english:
            return englishStrings[key] ?? key
        case .traditionalChinese:
            return chineseStrings[key] ?? key
        }
    }
    
    var englishStrings: [String: String] = [
        "menuTitle": "🎭 Script Editor",
        "characters": "Characters:",
        "sceneHeading": "Scene Heading",
        "actionLine": "Action Line",
        "parenthetical": "Parenthetical",
        "openSettings": "Open Settings...",
        "quit": "Quit",
        "settingsTitle": "Script Editor Settings",
        "format": "Script Format",
        "stagePlay": "Stage Play",
        "screenplay": "Screenplay",
        "keyboardShortcuts": "Keyboard Shortcuts",
        "global": "Global — work in any app",
        "modifier": "Modifier:",
        "quickActions": "Quick Actions",
        "permissions": "Permissions",
        "accessibilityGranted": "Granted ✓",
        "accessibilityRequired": "Required — click to fix",
        "howToUse": "How to use:",
        "step1": "1. The 🎭 icon should appear in your menu bar (top right)",
        "step2": "2. Press shortcuts while in any app (Google Docs, Pages, etc.)",
        "step3": "3. Text will be inserted at your cursor position",
        "inserted": "Inserted",
        "sceneHeadingText": "[SCENE: Location - Time]",
        "actionLineText": "▲ [Action description]",
        "parentheticalText": "(emotion/action)",
        "characterDialogue": "Character Dialogue",
        "customizeShortcuts": "Customize Shortcuts",
        "showNotifications": "Show Notifications",
        "language": "Language",
        "notificationSuccess": "Inserted successfully",
        "sceneHeadingLong": "INT. LOCATION - TIME OF DAY"
    ]
    
    var chineseStrings: [String: String] = [
        "menuTitle": "🎭 劇本編輯器",
        "characters": "角色：",
        "sceneHeading": "場景標題",
        "actionLine": "動作線",
        "parenthetical": "舞台指示",
        "openSettings": "開啟設定...",
        "quit": "退出",
        "settingsTitle": "劇本編輯器設定",
        "format": "劇本格式",
        "stagePlay": "舞台劇",
        "screenplay": "電影劇本",
        "keyboardShortcuts": "鍵盤快捷鍵",
        "global": "全域快捷鍵 — 任何程式都可用",
        "modifier": "輔助鍵：",
        "quickActions": "快速動作",
        "permissions": "權限",
        "accessibilityGranted": "已授權 ✓",
        "accessibilityRequired": "需要授權 — 點擊修復",
        "howToUse": "使用方法：",
        "step1": "1. 🎭 圖示會顯示在選單列（右上角）",
        "step2": "2. 在任何程式中按快捷鍵（Google Docs、Pages 等）",
        "step3": "3. 文字會插入到游標位置",
        "inserted": "已插入",
        "sceneHeadingText": "【場景：地點 - 時間】",
        "actionLineText": "▲ 【動作描述】",
        "parentheticalText": "（情緒／動作）",
        "characterDialogue": "角色對白",
        "customizeShortcuts": "自訂快捷鍵",
        "showNotifications": "顯示通知",
        "language": "語言",
        "notificationSuccess": "插入成功",
        "sceneHeadingLong": "內景．地點 - 時間"
    ]
    
    func loadConfig() {
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return
        }
        self.characters = config.characters
        self.format = config.format
        self.modifierKey = config.modifierKey
        self.language = config.language
        self.shortcuts = config.shortcuts
        self.showNotifications = config.showNotifications
    }
    
    func saveConfig() {
        let config = Config(
            characters: characters,
            format: format,
            modifierKey: modifierKey,
            language: language,
            shortcuts: shortcuts,
            showNotifications: showNotifications
        )
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: configURL)
        }
    }
    
    func addCharacter(name: String) {
        let character = ScriptCharacter(name: name)
        characters.append(character)
        saveConfig()
    }
    
    func removeCharacter(at indexSet: IndexSet) {
        characters.remove(atOffsets: indexSet)
        saveConfig()
    }
    
    func updateCharacter(id: UUID, name: String) {
        if let index = characters.firstIndex(where: { $0.id == id }) {
            characters[index].name = name
            saveConfig()
        }
    }
    
    func getSceneHeadingText() -> String {
        let base = language == .traditionalChinese ? "【場景：" : "[SCENE: "
        let suffix = language == .traditionalChinese ? "】\n" : "]\n"
        return base + (language == .traditionalChinese ? "地點 - 時間" : "Location - Time") + suffix
    }
    
    func getActionLineText() -> String {
        let prefix = format == .stage ? "▲ " : ""
        let text = language == .traditionalChinese ? "【動作描述】" : "[Action description]"
        return "\n\(prefix)\(text)\n"
    }
    
    func getParentheticalText() -> String {
        let text = language == .traditionalChinese ? "情緒／動作" : "emotion/action"
        if format == .stage {
            return "（\(text)）"
        } else {
            return "\n          (\(text))\n    "
        }
    }
    
    func getCharacterDialogueText(_ character: ScriptCharacter) -> String {
        if format == .stage {
            return "\(character.name.uppercased())："
        } else {
            return "\n\n          \(character.name.uppercased())\n    "
        }
    }
}

struct Config: Codable {
    var characters: [ScriptCharacter]
    var format: ScriptFormat
    var modifierKey: ModifierKey
    var language: AppLanguage
    var shortcuts: ShortcutConfig
    var showNotifications: Bool
}
