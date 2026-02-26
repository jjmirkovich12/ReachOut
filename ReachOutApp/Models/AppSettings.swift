import Foundation

struct AppSettings: Codable, Equatable {
    var birthdayRemindersEnabled: Bool = true
    var overdueRemindersEnabled: Bool = true
}
