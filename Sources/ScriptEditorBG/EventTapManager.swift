import Cocoa
import Carbon

class EventTapManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    fileprivate let configManager: ConfigManager
    private let textInserter: TextInserter
    
    init(configManager: ConfigManager) {
        self.configManager = configManager
        self.textInserter = TextInserter()
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
        let text = configManager.format == .stage 
            ? "\(character.name.uppercased()): "
            : "\n\n          \(character.name.uppercased())\n    "
        textInserter.insertText(text)
    }
    
    func insertSceneHeading() {
        let text = configManager.format == .stage
            ? "[SCENE: Location - Time]\n"
            : "\n\nINT. LOCATION - TIME OF DAY\n\n"
        textInserter.insertText(text)
    }
    
    func insertActionLine() {
        let prefix = configManager.format == .stage ? "▲ " : ""
        textInserter.insertText("\n\(prefix)[Action description]\n")
    }
    
    func insertParenthetical() {
        let text = configManager.format == .stage
            ? "(emotion/action) "
            : "\n          (emotion/action)\n    "
        textInserter.insertText(text)
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
    
    // Modifier+Shift+H (keycode 4) — Scene
    if isShiftPressed && keyCode == 4 {
        manager.insertSceneHeading()
        return nil
    }
    
    // Modifier+Shift+A (keycode 0) — Action
    if isShiftPressed && keyCode == 0 {
        manager.insertActionLine()
        return nil
    }
    
    // Modifier+Shift+P (keycode 35) — Parenthetical
    if isShiftPressed && keyCode == 35 {
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
