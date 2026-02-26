import Foundation

enum AddPersonResult: Equatable {
    case added(TrackedPerson)
    case duplicate
}

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var people: [TrackedPerson]
    @Published var settings: AppSettings {
        didSet {
            persistence.saveSettings(settings)
            notificationService.refreshNotifications(for: people, settings: settings)
        }
    }

    private let persistence: PersistenceServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private var notificationPermissionRequested = false

    init(
        persistence: PersistenceServiceProtocol = PersistenceService(),
        notificationService: NotificationServiceProtocol = NotificationService()
    ) {
        self.persistence = persistence
        self.notificationService = notificationService
        self.people = persistence.loadPeople()
        self.settings = persistence.loadSettings()
    }

    func bootstrap() {
        notificationService.refreshNotifications(for: people, settings: settings)
    }

    func requestNotificationPermissionIfNeeded() async {
        guard !notificationPermissionRequested else { return }
        notificationPermissionRequested = true
        _ = await notificationService.requestAuthorization()
    }

    @discardableResult
    func addPerson(
        contactIdentifier: String,
        displayName: String,
        birthdayMonth: Int?,
        birthdayDay: Int?,
        cadenceDays: Int,
        lastCheckInDate: Date
    ) -> AddPersonResult {
        guard !people.contains(where: { $0.contactIdentifier == contactIdentifier }) else {
            return .duplicate
        }

        let person = TrackedPerson(
            contactIdentifier: contactIdentifier,
            displayName: displayName,
            birthdayMonth: birthdayMonth,
            birthdayDay: birthdayDay,
            cadenceDays: cadenceDays,
            lastCheckInDate: lastCheckInDate
        )
        people.append(person)
        persistAndReschedule(for: person)
        return .added(person)
    }

    func updatePerson(_ person: TrackedPerson, cadenceDays: Int, lastCheckInDate: Date) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        people[index].cadenceDays = cadenceDays
        people[index].lastCheckInDate = lastCheckInDate
        persistAndReschedule(for: people[index])
    }

    func checkInToday(_ person: TrackedPerson) {
        updatePerson(person, cadenceDays: person.cadenceDays, lastCheckInDate: Date())
    }

    func removePerson(_ person: TrackedPerson) {
        guard let idx = people.firstIndex(where: { $0.id == person.id }) else { return }
        let removed = people.remove(at: idx)
        persistence.savePeople(people)
        notificationService.removeNotifications(for: removed)
    }

    func refreshAllNotifications() {
        notificationService.refreshNotifications(for: people, settings: settings)
    }

    private func persistAndReschedule(for person: TrackedPerson) {
        persistence.savePeople(people)
        notificationService.scheduleNotifications(for: person, settings: settings)
    }
}
