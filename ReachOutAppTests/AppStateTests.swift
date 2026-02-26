import Foundation
import XCTest
@testable import ReachOutApp

@MainActor
final class AppStateTests: XCTestCase {
    func testAddPersonPreventsDuplicateContactIdentifier() {
        let persistence = MockPersistenceService()
        let notifications = MockNotificationService()
        let state = AppState(persistence: persistence, notificationService: notifications)

        let first = state.addPerson(
            contactIdentifier: "contact_1",
            displayName: "Alex",
            birthdayMonth: nil,
            birthdayDay: nil,
            cadenceDays: 14,
            lastCheckInDate: Date()
        )

        let second = state.addPerson(
            contactIdentifier: "contact_1",
            displayName: "Alex",
            birthdayMonth: nil,
            birthdayDay: nil,
            cadenceDays: 7,
            lastCheckInDate: Date()
        )

        XCTAssertNotEqual(first, .duplicate)
        XCTAssertEqual(second, .duplicate)
        XCTAssertEqual(state.people.count, 1)
    }

    func testSettingsChangeRefreshesNotifications() {
        let persistence = MockPersistenceService()
        let notifications = MockNotificationService()
        let state = AppState(persistence: persistence, notificationService: notifications)

        _ = state.addPerson(
            contactIdentifier: "contact_2",
            displayName: "Chris",
            birthdayMonth: 8,
            birthdayDay: 10,
            cadenceDays: 30,
            lastCheckInDate: Date()
        )

        state.settings.birthdayRemindersEnabled = false

        XCTAssertEqual(notifications.refreshCalls.count, 1)
        XCTAssertEqual(notifications.refreshCalls.first?.settings.birthdayRemindersEnabled, false)
    }

    func testCheckInUpdatesLastCheckInDate() {
        let persistence = MockPersistenceService()
        let notifications = MockNotificationService()
        let state = AppState(persistence: persistence, notificationService: notifications)

        _ = state.addPerson(
            contactIdentifier: "contact_3",
            displayName: "Jordan",
            birthdayMonth: nil,
            birthdayDay: nil,
            cadenceDays: 7,
            lastCheckInDate: Date(timeIntervalSince1970: 0)
        )

        let person = try XCTUnwrap(state.people.first)
        state.checkInToday(person)

        XCTAssertTrue(state.people[0].lastCheckInDate > Date(timeIntervalSince1970: 0))
    }
}

private final class MockPersistenceService: PersistenceServiceProtocol {
    var storedPeople: [TrackedPerson] = []
    var storedSettings = AppSettings()

    func loadPeople() -> [TrackedPerson] { storedPeople }
    func savePeople(_ people: [TrackedPerson]) { storedPeople = people }
    func loadSettings() -> AppSettings { storedSettings }
    func saveSettings(_ settings: AppSettings) { storedSettings = settings }
}

private final class MockNotificationService: NotificationServiceProtocol {
    struct RefreshCall {
        let people: [TrackedPerson]
        let settings: AppSettings
    }

    var refreshCalls: [RefreshCall] = []

    func requestAuthorization() async -> Bool { true }
    func scheduleNotifications(for person: TrackedPerson, settings: AppSettings) { }
    func removeNotifications(for person: TrackedPerson) { }

    func refreshNotifications(for people: [TrackedPerson], settings: AppSettings) {
        refreshCalls.append(RefreshCall(people: people, settings: settings))
    }
}
