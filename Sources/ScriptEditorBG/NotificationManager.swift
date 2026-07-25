import Foundation
import AppKit

class NotificationManager: NSObject {
    private let configManager: ConfigManager
    
    init(configManager: ConfigManager) {
        self.configManager = configManager
        super.init()
    }
    
    func notifyInserted(_ content: String) {
        guard configManager.showNotifications else { return }
        
        // For LSUIElement apps, UNUserNotificationCenter often fails.
        // Use NSBeep + a brief status bar flash as fallback.
        NSBeep()
        
        // Post a notification that AppDelegate can listen to for status bar feedback
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .init("showInsertionFeedback"),
                object: nil,
                userInfo: ["text": content]
            )
        }
    }
}
