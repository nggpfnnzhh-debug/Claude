import XCTest
@testable import KleineEntdecker

final class SeasonalTests: XCTestCase {
    private func date(_ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    private var berlin: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    override func tearDown() {
        Seasonal.override = nil
    }

    func testSeasonsFollowMonths() {
        XCTAssertEqual(Seasonal.at(date(4, 10), calendar: berlin).season, .spring)
        XCTAssertEqual(Seasonal.at(date(7, 1), calendar: berlin).season, .summer)
        XCTAssertEqual(Seasonal.at(date(10, 1), calendar: berlin).season, .autumn)
        XCTAssertEqual(Seasonal.at(date(1, 15), calendar: berlin).season, .winter)
        XCTAssertEqual(Seasonal.at(date(12, 1), calendar: berlin).season, .winter)
    }

    func testHalloweenWeek() {
        XCTAssertNil(Seasonal.at(date(10, 23), calendar: berlin).festival)

        let before = Seasonal.at(date(10, 25), calendar: berlin)
        XCTAssertEqual(before.festival, .halloween)
        XCTAssertFalse(before.isFestivalDay)
        XCTAssertEqual(before.announcement, "Bald ist Halloween!")

        let day = Seasonal.at(date(10, 31), calendar: berlin)
        XCTAssertTrue(day.isFestivalDay)
        XCTAssertEqual(day.announcement, "Heute ist Halloween!")

        XCTAssertNil(Seasonal.at(date(11, 1), calendar: berlin).festival)
    }

    func testHalloweenMotifsAppearInCounting() {
        Seasonal.override = Seasonal(season: .autumn, festival: .halloween, isFestivalDay: true)
        let emojis = (0..<20).flatMap { _ in TaskFactory.tasks(for: .counting, level: 0) }.compactMap { task -> String? in
            if case let .objects(emoji, _) = task.prompt { return emoji }
            return nil
        }
        XCTAssertTrue(emojis.contains("🎃"))
    }

    func testMemoryHasEnoughCardsInEverySeason() {
        for variant in Seasonal.allVariants {
            XCTAssertGreaterThanOrEqual(variant.memoryCards.count + MemoryGameView.animals.count, MemoryGameView.pairCounts.max()!)
            XCTAssertFalse(variant.decorations.isEmpty)
        }
    }
}
