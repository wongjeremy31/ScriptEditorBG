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

struct SceneTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var text: String
    var keyCode: Int64
    
    init(id: UUID = UUID(), name: String, text: String, keyCode: Int64) {
        self.id = id
        self.name = name
        self.text = text
        self.keyCode = keyCode
    }
}

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var characters: [ScriptCharacter]
    var sceneTemplates: [SceneTemplate]
    var format: ScriptFormat
    
    init(id: UUID = UUID(), name: String, characters: [ScriptCharacter], sceneTemplates: [SceneTemplate], format: ScriptFormat) {
        self.id = id
        self.name = name
        self.characters = characters
        self.sceneTemplates = sceneTemplates
        self.format = format
    }
}

struct ShortcutConfig: Codable, Equatable {
    var sceneHeadingKey: Int64
    var actionLineKey: Int64
    var parentheticalKey: Int64
    
    static let `default` = ShortcutConfig(
        sceneHeadingKey: 4,      // H
        actionLineKey: 0,         // A
        parentheticalKey: 35      // P
    )
}

struct RecentItem: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let timestamp: Date
    let type: RecentItemType
    
    init(id: UUID = UUID(), text: String, type: RecentItemType) {
        self.id = id
        self.text = text
        self.timestamp = Date()
        self.type = type
    }
}

enum RecentItemType: String, Codable {
    case character
    case sceneHeading
    case actionLine
    case parenthetical
    case sceneTemplate
}

struct WordCountEntry: Codable, Equatable {
    let date: String  // YYYY-MM-DD
    var count: Int
}

class ConfigManager: ObservableObject {
    @Published var characters: [ScriptCharacter] = [
        ScriptCharacter(name: "Jeremy"),
        ScriptCharacter(name: "Alice"),
        ScriptCharacter(name: "Narrator")
    ]
    @Published var sceneTemplates: [SceneTemplate] = []
    @Published var profiles: [Profile] = []
    @Published var activeProfileId: UUID?
    @Published var format: ScriptFormat = .stage
    @Published var modifierKey: ModifierKey = .command
    @Published var language: AppLanguage = .traditionalChinese
    @Published var shortcuts: ShortcutConfig = .default
    @Published var showNotifications: Bool = true
    @Published var recentHistory: [RecentItem] = []
    @Published var wordCounts: [String: Int] = [:]  // date string -> count
    
    private let configURL: URL
    private let maxHistoryItems = 10
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ScriptEditorBG", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        self.configURL = appFolder.appendingPathComponent("config.json")
        
        // Setup default templates
        sceneTemplates = getDefaultSceneTemplates()
        
        loadConfig()
    }
    
    private func getDefaultSceneTemplates() -> [SceneTemplate] {
        return [
            SceneTemplate(name: "內景日景", text: "【場景：內景 - 日景】\n", keyCode: 18), // 1
            SceneTemplate(name: "外景日景", text: "【場景：外景 - 日景】\n", keyCode: 19), // 2
            SceneTemplate(name: "內景夜景", text: "【場景：內景 - 夜景】\n", keyCode: 20), // 3
            SceneTemplate(name: "外景夜景", text: "【場景：外景 - 夜景】\n", keyCode: 21), // 4
            SceneTemplate(name: "黑場", text: "【黑場】\n", keyCode: 22)  // 5
        ]
    }
    
    var todayWordCount: Int {
        let today = currentDateString()
        return wordCounts[today] ?? 0
    }
    
    func addWordCount(_ count: Int) {
        let today = currentDateString()
        wordCounts[today, default: 0] += count
        saveConfig()
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    func addToHistory(text: String, type: RecentItemType) {
        let item = RecentItem(text: text, type: type)
        recentHistory.insert(item, at: 0)
        if recentHistory.count > maxHistoryItems {
            recentHistory.removeLast()
        }
        saveConfig()
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
        "sceneHeadingLong": "INT. LOCATION - TIME OF DAY",
        "profiles": "Profiles",
        "sceneTemplates": "Scene Templates",
        "newProfile": "New Profile",
        "defaultProfile": "Default",
        "recentHistory": "Recent History",
        "wordCount": "Today's Words",
        "words": "words",
        "noRecent": "No recent items",
        "template": "Template"
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
        "sceneHeadingLong": "內景．地點 - 時間",
        "profiles": "專案設定檔",
        "sceneTemplates": "場景範本",
        "newProfile": "新增專案",
        "defaultProfile": "預設",
        "recentHistory": "最近使用",
        "wordCount": "今日字數",
        "words": "字",
        "noRecent": "暫無記錄",
        "template": "範本"
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
        self.sceneTemplates = config.sceneTemplates
        self.profiles = config.profiles
        self.activeProfileId = config.activeProfileId
        self.recentHistory = config.recentHistory
        self.wordCounts = config.wordCounts
    }
    
    func saveConfig() {
        let config = Config(
            characters: characters,
            format: format,
            modifierKey: modifierKey,
            language: language,
            shortcuts: shortcuts,
            showNotifications: showNotifications,
            sceneTemplates: sceneTemplates,
            profiles: profiles,
            activeProfileId: activeProfileId,
            recentHistory: recentHistory,
            wordCounts: wordCounts
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
    
    func addSceneTemplate(name: String, text: String, keyCode: Int64) {
        let template = SceneTemplate(name: name, text: text, keyCode: keyCode)
        sceneTemplates.append(template)
        saveConfig()
    }
    
    func removeSceneTemplate(at indexSet: IndexSet) {
        sceneTemplates.remove(atOffsets: indexSet)
        saveConfig()
    }
    
    func addProfile(name: String) {
        let profile = Profile(
            name: name,
            characters: [
                ScriptCharacter(name: "Jeremy"),
                ScriptCharacter(name: "Alice")
            ],
            sceneTemplates: getDefaultSceneTemplates(),
            format: .stage
        )
        profiles.append(profile)
        saveConfig()
    }
    
    func switchToProfile(_ profileId: UUID) {
        // Save current state to previous profile
        if let currentId = activeProfileId,
           let currentIndex = profiles.firstIndex(where: { $0.id == currentId }) {
            profiles[currentIndex].characters = characters
            profiles[currentIndex].sceneTemplates = sceneTemplates
            profiles[currentIndex].format = format
        }
        
        // Load new profile
        if let newIndex = profiles.firstIndex(where: { $0.id == profileId }) {
            characters = profiles[newIndex].characters
            sceneTemplates = profiles[newIndex].sceneTemplates
            format = profiles[newIndex].format
            activeProfileId = profileId
            saveConfig()
        }
    }
    
    func deleteProfile(at indexSet: IndexSet) {
        profiles.remove(atOffsets: indexSet)
        saveConfig()
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
    var sceneTemplates: [SceneTemplate]
    var profiles: [Profile]
    var activeProfileId: UUID?
    var recentHistory: [RecentItem]
    var wordCounts: [String: Int]
}
