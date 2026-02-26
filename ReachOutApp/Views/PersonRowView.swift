import SwiftUI

struct PersonRowView: View {
    let person: TrackedPerson
    let onCheckIn: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)

                Text("Last checked in: \(person.lastCheckInDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if person.isOverdue {
                    Text("Overdue")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.15), in: Capsule())
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Button("Check in", action: onCheckIn)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}
