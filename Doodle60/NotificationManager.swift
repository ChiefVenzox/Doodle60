//
//  NotificationManager.swift
//  Doodle60
//
//  Local daily reminder notification handling.
//

import Foundation
import UserNotifications

enum NotificationManager {
    private static let reminderID = "dailyWordReminder"
    private static let enabledKey = "reminder_enabled"

    static var isReminderEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    static func setReminderEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
        if enabled {
            prepareDailyReminder()
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID])
        }
    }

    static func prepareDailyReminder() {
        guard isReminderEnabled else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
                    let hm = reminderHourMinute()
                    if ok { scheduleDaily(hour: hm.hour, minute: hm.minute) }
                }
            case .authorized, .provisional:
                let hm = reminderHourMinute()
                scheduleDaily(hour: hm.hour, minute: hm.minute)
            default:
                break
            }
        }
    }

    static func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    static func reminderHourMinute() -> (hour: Int, minute: Int) {
        let ud = UserDefaults.standard
        let h = ud.integer(forKey: "reminder_hour")
        let m = ud.integer(forKey: "reminder_minute")
        return (h == 0 && ud.object(forKey: "reminder_hour") == nil) ? (9, 0) : (h, m)
    }

    static func scheduleDaily(hour: Int, minute: Int) {
        guard isReminderEnabled else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Doodle 60"
        content.body = "Draw today's word! 60 seconds 🖌️"
        content.sound = .default

        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    static func updateDailyReminder(hour: Int, minute: Int) {
        let ud = UserDefaults.standard
        ud.set(hour, forKey: "reminder_hour")
        ud.set(minute, forKey: "reminder_minute")
        scheduleDaily(hour: hour, minute: minute)
    }
}
