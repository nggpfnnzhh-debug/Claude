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

    func testAssignmentSplitsItemsEvenly() {
        for kind in ExperimentKind.allCases {
            let assignment = Experiments.randomAssignment(for: kind)
            XCTAssertEqual(assignment.count, kind.items.count, "\(kind)")
            for method in kind.methods {
                XCTAssertEqual(assignment.values.filter { $0 == method }.count, kind.perMethod, "\(kind) \(method)")
            }
        }
    }

    func testItemIDsAreUnique() {
        for kind in ExperimentKind.allCases {
            XCTAssertEqual(Set(kind.items.map(\.id)).count, kind.items.count, "\(kind)")
        }
    }

    func testFactsHaveFourDistinctOptions() {
        for fact in ExplainVsRead.facts {
            let options = [fact.answer] + fact.wrong
            XCTAssertEqual(Set(options).count, 4, fact.id)
        }
        XCTAssertEqual(ExplainVsRead.facts.count % 2, 0)
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

    private func run(_ kind: ExperimentKind, baseline: Int, other: Int) -> ExperimentRun {
        var assignment: [String: StudyMethod] = [:]
        var results: [String: Bool] = [:]
        for (index, item) in kind.items.enumerated() {
            let first = index < kind.perMethod
            assignment[item.id] = first ? kind.methods[0] : kind.methods[1]
            let position = first ? index : index - kind.perMethod
            results[item.id] = position < (first ? baseline : other)
        }
        return ExperimentRun(kind: kind, prediction: nil, assignment: assignment, learnedAt: .now, results: results)
    }

    func testVerdict() {
        XCTAssertEqual(Experiments.verdict(for: run(.rereadQuiz, baseline: 3, other: 7)).winner, .quiz)
        XCTAssertEqual(Experiments.verdict(for: run(.rereadQuiz, baseline: 7, other: 3)).winner, .reread)
        XCTAssertNil(Experiments.verdict(for: run(.rereadQuiz, baseline: 5, other: 6)).winner)
        XCTAssertNil(Experiments.verdict(for: run(.rereadQuiz, baseline: 5, other: 5)).winner)
        XCTAssertEqual(Experiments.verdict(for: run(.explainRead, baseline: 2, other: 5)).winner, .explain)
    }

    func testCorrectCountsPerMethod() {
        let result = run(.explainRead, baseline: 2, other: 4)
        XCTAssertEqual(result.correct(.reread), 2)
        XCTAssertEqual(result.correct(.explain), 4)
        XCTAssertEqual(result.correct(.quiz), 0)
    }

    func testPredictionFeedback() {
        XCTAssertEqual(Experiments.predictionFeedback(prediction: .quiz, winner: .quiz), "Das passt zum Ergebnis.")
        XCTAssertEqual(Experiments.predictionFeedback(prediction: nil, winner: nil), "Das passt zum Ergebnis.")
    }

    func testDelayedOnlyAfterLongPause() {
        var run = ExperimentRun(kind: .rereadQuiz, prediction: .quiz, assignment: [:], learnedAt: .now)
        run.testedAt = .now.addingTimeInterval(60)
        XCTAssertFalse(run.delayed)
        run.testedAt = .now.addingTimeInterval(Experiments.recommendedDelay)
        XCTAssertTrue(run.delayed)
    }

    func testRunSurvivesSaving() throws {
        var run = ExperimentRun(kind: .explainRead, prediction: .explain,
                                assignment: Experiments.randomAssignment(for: .explainRead), learnedAt: .now)
        run.results = ["oktopus": true]
        let decoded = try JSONDecoder().decode(ExperimentRun.self, from: JSONEncoder().encode(run))
        XCTAssertEqual(decoded.kind, .explainRead)
        XCTAssertEqual(decoded.assignment, run.assignment)
        XCTAssertEqual(decoded.results, run.results)
        XCTAssertEqual(decoded.prediction, .explain)
    }
}

@MainActor
final class AppModelTests: XCTestCase {
    private func freshDefaults() -> UserDefaults {
        let name = "LernlaborTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testPendingRunsArePerKindAndPersisted() {
        let defaults = freshDefaults()
        let model = AppModel(defaults: defaults)
        model.startPending(ExperimentRun(kind: .rereadQuiz, prediction: nil, assignment: [:], learnedAt: .now))
        model.startPending(ExperimentRun(kind: .explainRead, prediction: nil, assignment: [:], learnedAt: .now))
        model.startPending(ExperimentRun(kind: .rereadQuiz, prediction: .quiz, assignment: [:], learnedAt: .now))
        XCTAssertEqual(model.pendingRuns.count, 2)
        XCTAssertEqual(model.pending(.rereadQuiz)?.prediction, .quiz)

        let reloaded = AppModel(defaults: defaults)
        XCTAssertEqual(reloaded.pendingRuns.count, 2)
    }

    func testCompleteMovesRunToResults() {
        let model = AppModel(defaults: freshDefaults())
        var run = ExperimentRun(kind: .explainRead, prediction: nil, assignment: [:], learnedAt: .now)
        model.startPending(run)
        run.testedAt = .now
        model.complete(run)
        XCTAssertNil(model.pending(.explainRead))
        XCTAssertEqual(model.runs(of: .explainRead).count, 1)
        XCTAssertTrue(model.runs(of: .rereadQuiz).isEmpty)
    }

    func testPersonalityIsSavedAndReset() {
        let defaults = freshDefaults()
        let model = AppModel(defaults: defaults)
        model.savePersonality(answers: Array(repeating: 4, count: 20))
        XCTAssertNotNil(AppModel(defaults: defaults).personality)
        model.resetAll()
        XCTAssertNil(AppModel(defaults: defaults).personality)
    }
}
