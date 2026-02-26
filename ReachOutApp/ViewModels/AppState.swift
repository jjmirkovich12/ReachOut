import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var people: [TrackedPerson]
    @Published var settings: AppSettings {
        didSet {
            persistence.saveSettings(settings)
            notificationService.refreshBirthdayNotifications(for: people, enabled: settings.birthdayRemindersEnabled)
        }
    }

    private let persistence: PersistenceServiceProtocol
    private let notificationService: NotificationServiceProtocol

    init(
        persistence: PersistenceServiceProtocol = PersistenceService(),
        notificationService: NotificationServiceProtocol = NotificationService()
    ) {
        self.persistence = persistence
        self.notificationService = notificationService
        self.people = persistence.loadPeople()
        self.settings = persistence.loadSettings()
    }

    func bootstrap() async {
        await notificationService.requestAuthorization()
        notificationService.refreshBirthdayNotifications(for: people, enabled: settings.birthdayRemindersEnabled)
        people.forEach { notificationService.scheduleNotifications(for: $0, birthdayEnabled: settings.birthdayRemindersEnabled) }
    }

    func addPerson(
        contactIdentifier: String,
        displayName: String,
        birthdayMonth: Int?,
        birthdayDay: Int?,
        cadenceDays: Int,
        lastCheckInDate: Date
    ) {
        guard !people.contains(where: { $0.contactIdentifier == contactIdentifier }) else { return }

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

    func removePeople(at offsets: IndexSet) {
        let removed = offsets.map { people[$0] }
        people.remove(atOffsets: offsets)
        persistence.savePeople(people)
        removed.forEach { notificationService.removeNotifications(for: $0) }
    }

    private func persistAndReschedule(for person: TrackedPerson) {
        persistence.savePeople(people)
        notificationService.scheduleNotifications(for: person, birthdayEnabled: settings.birthdayRemindersEnabled)
    }
}
