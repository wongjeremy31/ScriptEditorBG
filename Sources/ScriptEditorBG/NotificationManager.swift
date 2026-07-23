import Foundation
import UserNotifications

class NotificationManager: NSObject {
    private let configManager: ConfigManager
    
    init(configManager: ConfigManager) {
        self.configManager = configManager
        super.init()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    func notifyInserted(_ content: String) {
        guard configManager.showNotifications else { return }
        
        let center = UNUserNotificationCenter.current()
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = configManager.localized("notificationSuccess")
        notificationContent.body = content
        notificationContent.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notificationContent,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
}
