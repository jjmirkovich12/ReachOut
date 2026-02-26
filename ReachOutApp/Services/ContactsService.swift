import Contacts
import Foundation

protocol ContactsServiceProtocol {
    func requestAccessIfNeeded() async -> Bool
}

final class ContactsService: ContactsServiceProtocol {
    private let contactStore = CNContactStore()

    func requestAccessIfNeeded() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)

        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return (try? await contactStore.requestAccess(for: .contacts)) ?? false
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}
