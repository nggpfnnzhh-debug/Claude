import XCTest
@testable import KleineEntdecker

final class AdventCalendarTests: XCTestCase {
    override func tearDown() {
        AdventCalendar.dayOverride = nil
    }

    func testTwentyFourDoorsInMixedOrder() {
        XCTAssertEqual(AdventCalendar.doors.map(\.number), Array(1...24))
        XCTAssertEqual(AdventCalendar.layout.sorted(), Array(1...24))
        XCTAssertNotEqual(AdventCalendar.layout, Array(1...24))
    }

    func testSpokenTexts() {
        XCTAssertEqual(AdventCalendar.findDoor(3), "Finde die Tür mit der Zahl drei!")
        XCTAssertEqual(AdventCalendar.findDoor(21), "Finde die Tür mit der Zahl einundzwanzig!")
        XCTAssertEqual(AdventCalendar.sleepsUntil(1), "Noch einmal schlafen!")
        XCTAssertEqual(AdventCalendar.sleepsUntil(3), "Noch dreimal schlafen!")
        XCTAssertEqual(AdventCalendar.sleepsUntil(23), "Noch dreiundzwanzigmal schlafen!")
    }

    func testVisibleOnlyFromFirstToTwentySixthOfDecember() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        func date(_ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
        }
        XCTAssertNil(AdventCalendar.day(at: date(11, 30), calendar: calendar))
        XCTAssertEqual(AdventCalendar.day(at: date(12, 1), calendar: calendar), 1)
        XCTAssertEqual(AdventCalendar.day(at: date(12, 26), calendar: calendar), 26)
        XCTAssertNil(AdventCalendar.day(at: date(12, 27), calendar: calendar))
    }
}
