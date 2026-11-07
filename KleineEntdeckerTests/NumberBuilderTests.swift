import XCTest
@testable import KleineEntdecker

final class NumberBuilderTests: XCTestCase {
    func testGermanNumberWords() {
        XCTAssertEqual(NumberBuilder.word(7), "sieben")
        XCTAssertEqual(NumberBuilder.word(17), "siebzehn")
        XCTAssertEqual(NumberBuilder.word(21), "einundzwanzig")
        XCTAssertEqual(NumberBuilder.word(24), "vierundzwanzig")
        XCTAssertEqual(NumberBuilder.word(37), "siebenunddreißig")
        XCTAssertEqual(NumberBuilder.word(80), "achtzig")
        XCTAssertEqual(NumberBuilder.word(99), "neunundneunzig")
    }

    func testLevels() {
        XCTAssertEqual(NumberBuilder.levelNumbers[0].first, 10)
        XCTAssertEqual(NumberBuilder.levelNumbers[0].last, 20)
        XCTAssertTrue(NumberBuilder.levelNumbers[1].allSatisfy { $0 % 10 == 0 })
        XCTAssertTrue(NumberBuilder.levelNumbers[2].allSatisfy { $0 > 20 && $0 < 100 && $0 % 10 != 0 })
    }

    func testRoundHasDistinctTwoDigitNumbers() {
        for level in 0...Game.buildNumbers.maxLevel {
            let tasks = NumberBuilder.tasks(level: level)
            XCTAssertEqual(tasks.count, TaskFactory.tasksPerRound)
            XCTAssertEqual(Set(tasks.map(\.number)).count, tasks.count)
            XCTAssertTrue(tasks.allSatisfy { (10...99).contains($0.number) })
        }
    }

    func testTensAndOnes() {
        let task = BuildTask(number: 80)
        XCTAssertEqual(task.tens, 8)
        XCTAssertEqual(task.ones, 0)
        XCTAssertEqual(NumberBuilder.tensText(8), "Acht Zehner!")
        XCTAssertEqual(NumberBuilder.tensText(1), "Ein Zehner!")
        XCTAssertEqual(NumberBuilder.onesText(0), "Keine Einer!")
        XCTAssertEqual(NumberBuilder.solvedText(for: 80), "Achtzig!")
    }
}
