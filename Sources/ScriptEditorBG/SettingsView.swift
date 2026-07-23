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
                Text("🎭 Script Editor")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            Divider()
            
            // Format Selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Script Format")
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
            
            // Shortcuts Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Keyboard Shortcuts")
                        .font(.headline)
                    Spacer()
                    Text("Global — work in any app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Modifier key selector
                HStack {
                    Text("Modifier:")
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
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(configManager.characters.enumerated()), id: \.element.id) { index, character in
                        HStack {
                            Text("\(modifierSymbol(configManager.modifierKey))\(index + 1)")
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
            
            // Quick Actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Actions")
                    .font(.headline)
                
                HStack {
                    Text("\(modifierSymbol(configManager.modifierKey))⇧H")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 60, alignment: .leading)
                    Text("Scene Heading")
                    Spacer()
                }
                
                HStack {
                    Text("\(modifierSymbol(configManager.modifierKey))⇧A")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 60, alignment: .leading)
                    Text("Action Line (▲)")
                    Spacer()
                }
                
                HStack {
                    Text("\(modifierSymbol(configManager.modifierKey))⇧P")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 60, alignment: .leading)
                    Text("Parenthetical")
                    Spacer()
                }
            }
            
            Spacer()
            
            // Permissions
            VStack(alignment: .leading, spacing: 8) {
                Text("Permissions")
                    .font(.headline)
                
                HStack {
                    Image(systemName: AXIsProcessTrusted() ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(AXIsProcessTrusted() ? .green : .red)
                    Text("Accessibility: \(AXIsProcessTrusted() ? "Granted ✓" : "Required — click to fix")")
                    Spacer()
                }
                
                if !AXIsProcessTrusted() {
                    Button("Open System Preferences → Privacy → Accessibility") {
                        NSWorkspace.shared.open(
                            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        )
                    }
                }
                
                Text("The app needs Accessibility permission to insert text into other apps.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Instructions
            VStack(alignment: .leading, spacing: 4) {
                Text("How to use:")
                    .font(.headline)
                Text("1. The 🎭 icon should appear in your menu bar (top right)")
                Text("2. Press shortcuts while in any app (Google Docs, Pages, etc.)")
                Text("3. Text will be inserted at your cursor position")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 480, height: 600)
    }
    
    func modifierSymbol(_ modifier: ModifierKey) -> String {
        switch modifier {
        case .command: return "⌘"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        }
    }
}
