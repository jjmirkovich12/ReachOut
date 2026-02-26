import XCTest
@testable import ReachOutApp

final class TrackedPersonTests: XCTestCase {
    func testNextCheckInDateAddsCadenceDays() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!

        let person = TrackedPerson(
            contactIdentifier: "abc",
            displayName: "Alex",
            cadenceDays: 14,
            lastCheckInDate: start
        )

        let expected = calendar.date(byAdding: .day, value: 14, to: start)
        XCTAssertEqual(person.nextCheckInDate, expected)
    }
}
