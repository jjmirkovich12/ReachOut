import SwiftUI
import UIKit

struct PeopleListView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showingContactPicker = false
    @State private var selectedContact: ContactSelection?
    @State private var personToEdit: TrackedPerson?
    @State private var showContactAccessAlert = false
    @State private var showDuplicateAlert = false
    @State private var personToDelete: TrackedPerson?

    private let contactsService: ContactsServiceProtocol = ContactsService()

    var body: some View {
        NavigationStack {
            Group {
                if appState.people.isEmpty {
                    ContentUnavailableView(
                        "No people yet",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Tap + to add your first person and start receiving check-in reminders.")
                    )
                } else {
                    List {
                        ForEach(appState.people.sorted(by: { $0.displayName < $1.displayName })) { person in
                            PersonRowView(person: person) {
                                appState.checkInToday(person)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                personToEdit = person
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    personToDelete = person
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("ReachOut")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let granted = await contactsService.requestAccessIfNeeded()
                            if granted {
                                showingContactPicker = true
                            } else {
                                showContactAccessAlert = true
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView { contact in
                    selectedContact = contact
                    showingContactPicker = false
                }
            }
            .sheet(item: $selectedContact) { selection in
                AddPersonSheet(selection: selection) { cadenceDays, lastCheckInDate in
                    let result = appState.addPerson(
                        contactIdentifier: selection.contactIdentifier,
                        displayName: selection.displayName,
                        birthdayMonth: selection.birthdayMonth,
                        birthdayDay: selection.birthdayDay,
                        cadenceDays: cadenceDays,
                        lastCheckInDate: lastCheckInDate
                    )

                    if result == .duplicate {
                        showDuplicateAlert = true
                    } else {
                        Task {
                            await appState.requestNotificationPermissionIfNeeded()
                        }
                    }
                }
            }
            .sheet(item: $personToEdit) { person in
                let selection = ContactSelection(
                    contactIdentifier: person.contactIdentifier,
                    displayName: person.displayName,
                    birthdayMonth: person.birthdayMonth,
                    birthdayDay: person.birthdayDay
                )

                AddPersonSheet(
                    selection: selection,
                    initialCadenceDays: person.cadenceDays,
                    initialLastCheckInDate: person.lastCheckInDate,
                    title: "Edit Person"
                ) { cadenceDays, lastCheckInDate in
                    appState.updatePerson(person, cadenceDays: cadenceDays, lastCheckInDate: lastCheckInDate)
                }
            }
            .alert("Contacts access denied", isPresented: $showContactAccessAlert) {
                Button("Not now", role: .cancel) { }
                Button("Open Settings") {
                    openSystemSettings()
                }
            } message: {
                Text("Please enable Contacts access in Settings to add people.")
            }
            .alert("Already added", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("That contact is already in your ReachOut list.")
            }
            .alert("Remove person?", isPresented: Binding(
                get: { personToDelete != nil },
                set: { if !$0 { personToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    personToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let personToDelete {
                        appState.removePerson(personToDelete)
                    }
                    self.personToDelete = nil
                }
            } message: {
                Text("This will remove the person and all scheduled reminders for them.")
            }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url)
        else {
            return
        }

        UIApplication.shared.open(url)
    }
}
