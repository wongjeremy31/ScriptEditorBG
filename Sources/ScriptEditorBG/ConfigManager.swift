import Foundation

enum ScriptFormat: String, Codable, CaseIterable, Identifiable {
    case stage = "stage"
    case screenplay = "screenplay"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .stage: return "Stage Play"
        case .screenplay: return "Screenplay"
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

class ConfigManager: ObservableObject {
    @Published var characters: [ScriptCharacter] = [
        ScriptCharacter(name: "Jeremy"),
        ScriptCharacter(name: "Alice"),
        ScriptCharacter(name: "Narrator")
    ]
    @Published var format: ScriptFormat = .stage
    
    private let configURL: URL
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ScriptEditorBG", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        self.configURL = appFolder.appendingPathComponent("config.json")
        
        loadConfig()
    }
    
    func loadConfig() {
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return
        }
        self.characters = config.characters
        self.format = config.format
    }
    
    func saveConfig() {
        let config = Config(characters: characters, format: format)
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
}

struct Config: Codable {
    var characters: [ScriptCharacter]
    var format: ScriptFormat
}
