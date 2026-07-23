import SwiftUI

struct SettingsView: View {
    @ObservedObject var configManager: ConfigManager
    @State private var newCharacterName: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Format Selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Format")
                    .font(.headline)
                
                Picker("Format", selection: $configManager.format) {
                    Text("🎭 Stage Play").tag(ScriptFormat.stage)
                    Text("🎬 Screenplay").tag(ScriptFormat.screenplay)
                }
                .pickerStyle(.segmented)
                .onChange(of: configManager.format) { _ in
                    configManager.saveConfig()
                }
            }
            
            Divider()
            
            // Characters List
            VStack(alignment: .leading, spacing: 10) {
                Text("Characters")
                    .font(.headline)
                
                Text("Shortcuts: Cmd+1, Cmd+2, Cmd+3...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                List {
                    ForEach(configManager.characters) { character in
                        HStack {
                            Text("⌘\(configManager.characters.firstIndex(where: { $0.id == character.id })! + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 30)
                            
                            Text(character.name)
                            
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        configManager.removeCharacter(at: indexSet)
                    }
                }
                .frame(height: 150)
                
                // Add new character
                HStack {
                    TextField("New character name", text: $newCharacterName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        if !newCharacterName.isEmpty {
                            configManager.addCharacter(name: newCharacterName)
                            newCharacterName = ""
                        }
                    }
                    .disabled(newCharacterName.isEmpty)
                }
            }
            
            Divider()
            
            // Shortcuts Reference
            VStack(alignment: .leading, spacing: 10) {
                Text("Global Shortcuts")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    ShortcutRow(keys: "⌘1, ⌘2...", action: "Insert character")
                    ShortcutRow(keys: "⌘⇧H", action: "Scene heading")
                    ShortcutRow(keys: "⌘⇧A", action: "Action line (▲)")
                    ShortcutRow(keys: "⌘⇧P", action: "Parenthetical")
                }
            }
            
            Spacer()
            
            // Permissions Status
            VStack(alignment: .leading, spacing: 5) {
                Text("Permissions")
                    .font(.headline)
                
                HStack {
                    Image(systemName: AXIsProcessTrusted() ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(AXIsProcessTrusted() ? .green : .red)
                    Text("Accessibility: \(AXIsProcessTrusted() ? "Granted" : "Required")")
                }
                
                if !AXIsProcessTrusted() {
                    Button("Open System Preferences") {
                        NSWorkspace.shared.open(
                            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        )
                    }
                }
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
}

struct ShortcutRow: View {
    let keys: String
    let action: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            Text(action)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
