import XCTest
@testable import Lernlabor

final class PersonalityTestTests: XCTestCase {
    func testFourStatementsPerTrait() {
        for trait in Trait.allCases {
            XCTAssertEqual(PersonalityTest.statements.filter { $0.trait == trait }.count, 4, "\(trait)")
        }
    }

    func testEachTraitHasPositiveAndReversedStatements() {
        for trait in [Trait.extraversion, .agreeableness, .conscientiousness, .calmness] {
            let keys = Set(PersonalityTest.statements.filter { $0.trait == trait }.map(\.keyed))
            XCTAssertEqual(keys, [1, -1], "\(trait)")
        }
    }

    func testNeutralAnswersGiveMiddleMean() {
        let means = PersonalityTest.means(answers: Array(repeating: 3, count: 20))
        for trait in Trait.allCases {
            XCTAssertEqual(means[trait] ?? 0, 3, accuracy: 0.0001)
        }
    }

    func testReversedStatementsAreReversed() {
        // „Trifft voll zu“ bei allen Aussagen: Bei der Geselligkeit heben sich die Aussagen auf
        let means = PersonalityTest.means(answers: Array(repeating: 5, count: 20))
        XCTAssertEqual(means[.extraversion] ?? 0, 3, accuracy: 0.0001)
    }

    func testMeanAtNormGivesFifty() {
        for trait in Trait.allCases {
            let norm = PersonalityTest.norms[trait]!
            XCTAssertEqual(PersonalityTest.percentile(mean: norm.mean, for: trait), 50)
        }
    }

    func testPercentileSpreadsModerateAnswers() {
        // Nur „trifft eher zu“ bei Geselligkeit bedeutet schon deutlich über dem Durchschnitt
        XCTAssertGreaterThan(PersonalityTest.percentile(mean: 4, for: .extraversion), 80)
        XCTAssertLessThan(PersonalityTest.percentile(mean: 3, for: .agreeableness), 15)
    }

    func testPercentileIsClamped() {
        XCTAssertEqual(PersonalityTest.percentile(mean: 5, for: .extraversion), 99)
        XCTAssertEqual(PersonalityTest.percentile(mean: 1, for: .extraversion), 1)
    }

    func testUnansweredStatementsAreSkipped() {
        var answers: [Int?] = Array(repeating: nil, count: 20)
        answers[0] = 5 // nur „Auf Feiern bin ich oft der Mittelpunkt.“
        let means = PersonalityTest.means(answers: answers)
        XCTAssertEqual(means[.extraversion], 5)
        XCTAssertNil(means[.openness])
    }

    func testLevels() {
        XCTAssertEqual(Level(score: 20), .low)
        XCTAssertEqual(Level(score: 50), .mid)
        XCTAssertEqual(Level(score: 80), .high)
    }
}

final class ExperimentTests: XCTestCase {
    private let tree = RereadVsQuiz.words.first { $0.swahili == "mti" }!
    private let car = RereadVsQuiz.words.first { $0.swahili == "gari" }!

    func testAssignmentSplitsWordsEvenly() {
        let assignment = RereadVsQuiz.randomAssignment()
        XCTAssertEqual(assignment.count, RereadVsQuiz.words.count)
        XCTAssertEqual(assignment.values.filter { $0 == .reread }.count, RereadVsQuiz.perMethod)
        XCTAssertEqual(assignment.values.filter { $0 == .quiz }.count, RereadVsQuiz.perMethod)
    }

    func testAnswerMatching() {
        XCTAssertTrue(RereadVsQuiz.isCorrect("Baum", for: tree))
        XCTAssertTrue(RereadVsQuiz.isCorrect("  der baum ", for: tree))
        XCTAssertTrue(RereadVsQuiz.isCorrect("Baun", for: tree), "ein Tippfehler ist erlaubt")
        XCTAssertTrue(RereadVsQuiz.isCorrect("Wagen", for: car), "Alternative")
        XCTAssertFalse(RereadVsQuiz.isCorrect("Haus", for: tree))
        XCTAssertFalse(RereadVsQuiz.isCorrect("", for: tree))
    }

    func testUmlautsAndSpelling() {
        let pen = RereadVsQuiz.words.first { $0.swahili == "kalamu" }!
        XCTAssertTrue(RereadVsQuiz.isCorrect("Füller", for: pen))
        XCTAssertTrue(RereadVsQuiz.isCorrect("Fueller", for: pen))
    }

    func testVerdict() {
        XCTAssertEqual(RereadVsQuiz.verdict(reread: 3, quiz: 7).winner, .quiz)
        XCTAssertEqual(RereadVsQuiz.verdict(reread: 7, quiz: 3).winner, .reread)
        XCTAssertEqual(RereadVsQuiz.verdict(reread: 5, quiz: 6).winner, .same)
        XCTAssertEqual(RereadVsQuiz.verdict(reread: 5, quiz: 5).winner, .same)
    }

    func testDelayedOnlyAfterLongPause() {
        var run = ExperimentRun(prediction: .quiz, assignment: [:], learnedAt: .now)
        run.testedAt = .now.addingTimeInterval(60)
        XCTAssertFalse(run.delayed)
        run.testedAt = .now.addingTimeInterval(RereadVsQuiz.recommendedDelay)
        XCTAssertTrue(run.delayed)
    }

    func testCorrectCountsPerMethod() {
        var run = ExperimentRun(prediction: .quiz, assignment: ["mti": .reread, "gari": .quiz, "jua": .quiz], learnedAt: .now)
        run.results = ["mti": true, "gari": true, "jua": false]
        XCTAssertEqual(run.correct(.reread), 1)
        XCTAssertEqual(run.correct(.quiz), 1)
    }

    func testRunSurvivesSaving() throws {
        var run = ExperimentRun(prediction: .reread, assignment: RereadVsQuiz.randomAssignment(), learnedAt: .now)
        run.results = ["mti": true]
        let decoded = try JSONDecoder().decode(ExperimentRun.self, from: JSONEncoder().encode(run))
        XCTAssertEqual(decoded.assignment, run.assignment)
        XCTAssertEqual(decoded.results, run.results)
        XCTAssertEqual(decoded.prediction, .reread)
    }
}
