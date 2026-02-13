import Cocoa
import FlutterMacOS
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if #available(macOS 10.14, *) {
      UNUserNotificationCenter.current().delegate = self
      
      // Native fallback to request permissions immediately
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if granted {
          print("✅ [Native] macOS Notification Permission Granted")
        } else if let error = error {
          print("❌ [Native] macOS Notification Permission Error: \(error.localizedDescription)")
        } else {
          print("⚠️ [Native] macOS Notification Permission Denied")
        }
      }
    }
    super.applicationDidFinishLaunching(notification)
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if #available(macOS 11.0, *) {
      completionHandler([.banner, .list, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
