import Foundation
import UserNotifications

protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func scheduleNotifications(for person: TrackedPerson, settings: AppSettings)
    func removeNotifications(for person: TrackedPerson)
    func refreshNotifications(for people: [TrackedPerson], settings: AppSettings)
}

final class NotificationService: NotificationServiceProtocol {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func scheduleNotifications(for person: TrackedPerson, settings: AppSettings) {
        if settings.overdueRemindersEnabled {
            scheduleOverdueNotification(for: person)
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [overdueIdentifier(for: person.id)])
        }

        if settings.birthdayRemindersEnabled {
            scheduleBirthdayNotification(for: person)
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [birthdayIdentifier(for: person.id)])
        }
    }

    func removeNotifications(for person: TrackedPerson) {
        center.removePendingNotificationRequests(withIdentifiers: [
            overdueIdentifier(for: person.id),
            birthdayIdentifier(for: person.id)
        ])
    }

    func refreshNotifications(for people: [TrackedPerson], settings: AppSettings) {
        let overdueIDs = people.map { overdueIdentifier(for: $0.id) }
        let birthdayIDs = people.map { birthdayIdentifier(for: $0.id) }
        center.removePendingNotificationRequests(withIdentifiers: overdueIDs + birthdayIDs)

        people.forEach { scheduleNotifications(for: $0, settings: settings) }
    }

    private func scheduleOverdueNotification(for person: TrackedPerson) {
        let id = overdueIdentifier(for: person.id)
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let triggerDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: person.nextCheckInDate) ?? person.nextCheckInDate
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)

        let content = UNMutableNotificationContent()
        content.title = "Time to check in"
        content.body = "You planned to reconnect with \(person.displayName)."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleBirthdayNotification(for person: TrackedPerson) {
        guard let month = person.birthdayMonth, let day = person.birthdayDay else { return }

        let id = birthdayIdentifier(for: person.id)
        center.removePendingNotificationRequests(withIdentifiers: [id])

        var components = DateComponents()
        components.month = month
        components.day = day
        components.hour = 9

        let content = UNMutableNotificationContent()
        content.title = "Birthday reminder"
        content.body = "It’s \(person.displayName)’s birthday today."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private func overdueIdentifier(for id: UUID) -> String {
        "overdue_\(id.uuidString)"
    }

    private func birthdayIdentifier(for id: UUID) -> String {
        "birthday_\(id.uuidString)"
    }
}
