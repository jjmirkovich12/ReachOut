import Foundation

struct ContactSelection: Identifiable {
    let id = UUID()
    let contactIdentifier: String
    let displayName: String
    let birthdayMonth: Int?
    let birthdayDay: Int?
}
