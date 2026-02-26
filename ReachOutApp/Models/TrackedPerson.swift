import Foundation

struct TrackedPerson: Identifiable, Codable, Equatable {
    let id: UUID
    let contactIdentifier: String
    var displayName: String
    var birthdayMonth: Int?
    var birthdayDay: Int?
    var cadenceDays: Int
    var lastCheckInDate: Date
    let createdAt: Date

    init(
        id: UUID = UUID(),
        contactIdentifier: String,
        displayName: String,
        birthdayMonth: Int? = nil,
        birthdayDay: Int? = nil,
        cadenceDays: Int,
        lastCheckInDate: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.contactIdentifier = contactIdentifier
        self.displayName = displayName
        self.birthdayMonth = birthdayMonth
        self.birthdayDay = birthdayDay
        self.cadenceDays = cadenceDays
        self.lastCheckInDate = lastCheckInDate
        self.createdAt = createdAt
    }

    var nextCheckInDate: Date {
        Calendar.current.date(byAdding: .day, value: cadenceDays, to: lastCheckInDate) ?? lastCheckInDate
    }

    var isOverdue: Bool {
        Date() > nextCheckInDate
    }
}
