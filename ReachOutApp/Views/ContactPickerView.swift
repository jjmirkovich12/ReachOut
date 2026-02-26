import ContactsUI
import SwiftUI

struct ContactPickerView: UIViewControllerRepresentable {
    var onSelect: (ContactSelection) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactBirthdayKey]
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) { }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        private let onSelect: (ContactSelection) -> Void

        init(onSelect: @escaping (ContactSelection) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let fullName = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            let selection = ContactSelection(
                contactIdentifier: contact.identifier,
                displayName: fullName.isEmpty ? "Unnamed Contact" : fullName,
                birthdayMonth: contact.birthday?.month,
                birthdayDay: contact.birthday?.day
            )
            onSelect(selection)
        }
    }
}
