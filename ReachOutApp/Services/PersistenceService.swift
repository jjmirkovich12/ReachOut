import Foundation

protocol PersistenceServiceProtocol {
    func loadPeople() -> [TrackedPerson]
    func savePeople(_ people: [TrackedPerson])
    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings)
}

final class PersistenceService: PersistenceServiceProtocol {
    private enum Keys {
        static let people = "reachout.people"
        static let settings = "reachout.settings"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadPeople() -> [TrackedPerson] {
        guard let data = defaults.data(forKey: Keys.people),
              let people = try? decoder.decode([TrackedPerson].self, from: data)
        else {
            return []
        }

        return people
    }

    func savePeople(_ people: [TrackedPerson]) {
        guard let data = try? encoder.encode(people) else { return }
        defaults.set(data, forKey: Keys.people)
    }

    func loadSettings() -> AppSettings {
        guard let data = defaults.data(forKey: Keys.settings),
              let settings = try? decoder.decode(AppSettings.self, from: data)
        else {
            return AppSettings()
        }

        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: Keys.settings)
    }
}
