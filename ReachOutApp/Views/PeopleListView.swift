import SwiftUI

struct PeopleListView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showingContactPicker = false
    @State private var selectedContact: ContactSelection?
    @State private var showContactAccessAlert = false

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
                        }
                        .onDelete(perform: appState.removePeople)
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
                    appState.addPerson(
                        contactIdentifier: selection.contactIdentifier,
                        displayName: selection.displayName,
                        birthdayMonth: selection.birthdayMonth,
                        birthdayDay: selection.birthdayDay,
                        cadenceDays: cadenceDays,
                        lastCheckInDate: lastCheckInDate
                    )
                }
            }
            .alert("Contacts access denied", isPresented: $showContactAccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enable Contacts access in Settings to add people.")
            }
        }
    }
}
