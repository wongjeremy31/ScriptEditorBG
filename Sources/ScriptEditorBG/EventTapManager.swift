import Cocoa
import Carbon

class EventTapManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    fileprivate let configManager: ConfigManager
    private let textInserter: TextInserter
    private let notificationManager: NotificationManager
    
    init(configManager: ConfigManager) {
        self.configManager = configManager
        self.textInserter = TextInserter()
        self.notificationManager = NotificationManager(configManager: configManager)
        setupEventTap()
    }
    
    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap. Check Input Monitoring permission.")
            return
        }
        
        self.eventTap = tap
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = runLoopSource
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    func insertCharacter(at index: Int) {
        guard index < configManager.characters.count else { return }
        let character = configManager.characters[index]
        let text = configManager.getCharacterDialogueText(character)
        insertText(text)
        configManager.addToHistory(text: text, type: .character)
        notificationManager.notifyInserted(configManager.localized("characterDialogue") + ": \(character.name)")
    }
    
    func insertSceneHeading() {
        let text = configManager.getSceneHeadingText()
        insertText(text)
        configManager.addToHistory(text: text, type: .sceneHeading)
        notificationManager.notifyInserted(configManager.localized("sceneHeading"))
    }
    
    func insertActionLine() {
        let text = configManager.getActionLineText()
        insertText(text)
        configManager.addToHistory(text: text, type: .actionLine)
        notificationManager.notifyInserted(configManager.localized("actionLine"))
    }
    
    func insertParenthetical() {
        let text = configManager.getParentheticalText()
        insertText(text)
        configManager.addToHistory(text: text, type: .parenthetical)
        notificationManager.notifyInserted(configManager.localized("parenthetical"))
    }
    
    func insertSceneTemplate(templateId: UUID) {
        guard let template = configManager.sceneTemplates.first(where: { $0.id == templateId }) else { return }
        insertText(template.text)
        configManager.addToHistory(text: template.text, type: .sceneTemplate)
        notificationManager.notifyInserted(configManager.localized("template") + ": \(template.name)")
    }
    
    func insertText(_ text: String) {
        textInserter.insertText(text)
        configManager.addWordCount(text.count)
        
        // Post notification to refresh menu bar word count
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .init("refreshMenu"), object: nil)
        }
    }
    
    deinit {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
    }
}

// C callback for event tap
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    
    guard type == .keyDown else {
        return Unmanaged.passRetained(event)
    }
    
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags
    
    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
    let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
    
    let configModifier = manager.configManager.modifierKey.cgEventFlags
    let isModifierPressed = flags.contains(configModifier)
    let isShiftPressed = flags.contains(.maskShift)
    
    guard isModifierPressed else {
        return Unmanaged.passRetained(event)
    }
    
    // Number keys: 18=1, 19=2, 20=3, 21=4, 22=5, 23=6, 24=7, 25=8, 26=9
    let numberKeyCodes: [Int64: Int] = [
        18: 0, 19: 1, 20: 2, 21: 3, 22: 4,
        23: 5, 24: 6, 25: 7, 26: 8
    ]
    
    let shortcuts = manager.configManager.shortcuts
    
    // Check scene templates first (Modifier+Shift+template key)
    if isShiftPressed {
        for template in manager.configManager.sceneTemplates {
            if keyCode == template.keyCode {
                manager.insertSceneTemplate(templateId: template.id)
                return nil
            }
        }
    }
    
    // Modifier+Shift+SceneHeadingKey
    if isShiftPressed && keyCode == shortcuts.sceneHeadingKey {
        manager.insertSceneHeading()
        return nil
    }
    
    // Modifier+Shift+ActionLineKey
    if isShiftPressed && keyCode == shortcuts.actionLineKey {
        manager.insertActionLine()
        return nil
    }
    
    // Modifier+Shift+ParentheticalKey
    if isShiftPressed && keyCode == shortcuts.parentheticalKey {
        manager.insertParenthetical()
        return nil
    }
    
    // Modifier+1, Modifier+2, etc. — Characters
    if !isShiftPressed, let charIndex = numberKeyCodes[keyCode] {
        manager.insertCharacter(at: charIndex)
        return nil
    }
    
    return Unmanaged.passRetained(event)
}
