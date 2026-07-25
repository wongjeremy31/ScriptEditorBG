import Foundation
import AppKit
import AudioToolbox

class NotificationManager: NSObject {
    private let configManager: ConfigManager
    
    init(configManager: ConfigManager) {
        self.configManager = configManager
        super.init()
    }
    
    func notifyInserted(_ content: String) {
        guard configManager.showNotifications else { return }
        
        // Play system alert sound (UNUserNotificationCenter doesn't work reliably for LSUIElement apps)
        AudioServicesPlaySystemSound(1104) // SMS received sound
        
        // Post notification for visual feedback (menu bar checkmark flash)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .init("showInsertionFeedback"),
                object: nil,
                userInfo: ["text": content]
            )
        }
    }
}
