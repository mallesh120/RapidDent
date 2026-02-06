//
//  RapidDentTests.swift
//  RapidDentTests
//
//  Unit tests for the real RapidDent models and managers.
//

import XCTest
@testable import RapidDent

final class RapidDentTests: XCTestCase {

    // MARK: - Question Model Tests

    func testQuestionDirectInit() throws {
        let question = Question(
            id: "q1",
            questionText: "Is fluoride effective for caries prevention?",
            type: "RAPID_FIRE",
            correctOption: "A",
            explanation: "Fluoride strengthens enamel and inhibits demineralization."
        )

        XCTAssertEqual(question.id, "q1")
        XCTAssertEqual(question.questionText, "Is fluoride effective for caries prevention?")
        XCTAssertEqual(question.type, "RAPID_FIRE")
        XCTAssertEqual(question.correctOption, "A")
        XCTAssertTrue(question.isCorrectAnswerTrue)
        XCTAssertNil(question.scenarioId)
        XCTAssertNil(question.imageUrl)
        XCTAssertTrue(question.options.isEmpty)
    }

    func testQuestionIsCorrectAnswerTrue() throws {
        let trueQ = Question(id: "t", questionText: "T?", type: "RAPID_FIRE", correctOption: "A", explanation: "")
        XCTAssertTrue(trueQ.isCorrectAnswerTrue)

        let falseQ = Question(id: "f", questionText: "F?", type: "RAPID_FIRE", correctOption: "B", explanation: "")
        XCTAssertFalse(falseQ.isCorrectAnswerTrue)
    }

    func testQuestionWithOptions() throws {
        let options = [
            QuestionOption(id: "A", text: "Enamel", isCorrect: true),
            QuestionOption(id: "B", text: "Dentin", isCorrect: false),
            QuestionOption(id: "C", text: "Pulp", isCorrect: false),
            QuestionOption(id: "D", text: "Cementum", isCorrect: false)
        ]

        let question = Question(
            id: "mcq1",
            questionText: "What is the hardest substance in the human body?",
            type: "SCENARIO",
            correctOption: "A",
            explanation: "Enamel is the hardest substance.",
            scenarioId: "scenario_1",
            options: options,
            imageUrl: "https://example.com/image.jpg"
        )

        XCTAssertEqual(question.options.count, 4)
        XCTAssertEqual(question.scenarioId, "scenario_1")
        XCTAssertEqual(question.imageUrl, "https://example.com/image.jpg")
        XCTAssertTrue(question.options.first(where: { $0.id == "A" })!.isCorrect)
    }

    func testQuestionIdentifiable() throws {
        let q1 = Question(id: "abc", questionText: "", type: "", correctOption: "A", explanation: "")
        let q2 = Question(id: "abc", questionText: "", type: "", correctOption: "A", explanation: "")
        let q3 = Question(id: "xyz", questionText: "", type: "", correctOption: "A", explanation: "")

        XCTAssertEqual(q1.id, q2.id)
        XCTAssertNotEqual(q1.id, q3.id)
    }

    // MARK: - QuestionOption Tests

    func testQuestionOption() throws {
        let option = QuestionOption(id: "C", text: "Periodontitis", isCorrect: false)

        XCTAssertEqual(option.id, "C")
        XCTAssertEqual(option.text, "Periodontitis")
        XCTAssertFalse(option.isCorrect)
    }

    // MARK: - ProgressManager Tests

    func testProgressManagerSharedInstance() throws {
        let pm1 = ProgressManager.shared
        let pm2 = ProgressManager.shared
        XCTAssertTrue(pm1 === pm2, "shared should return the same instance")
    }

    func testProgressManagerMarkCorrect() throws {
        let pm = ProgressManager.shared
        pm.resetProgress()

        pm.markAsAnswered(id: "test_q1", correct: true)

        XCTAssertTrue(pm.completedIDs.contains("test_q1"))
        XCTAssertFalse(pm.wrongIDs.contains("test_q1"))
        XCTAssertEqual(pm.questionsCompleted, 1)
        XCTAssertEqual(pm.questionsNeedingReview, 0)

        pm.resetProgress()
    }

    func testProgressManagerMarkIncorrect() throws {
        let pm = ProgressManager.shared
        pm.resetProgress()

        pm.markAsAnswered(id: "test_q2", correct: false)

        XCTAssertTrue(pm.completedIDs.contains("test_q2"))
        XCTAssertTrue(pm.wrongIDs.contains("test_q2"))
        XCTAssertEqual(pm.questionsCompleted, 1)
        XCTAssertEqual(pm.questionsNeedingReview, 1)

        pm.resetProgress()
    }

    func testProgressManagerCorrectAfterIncorrect() throws {
        let pm = ProgressManager.shared
        pm.resetProgress()

        // First attempt: wrong
        pm.markAsAnswered(id: "test_q3", correct: false)
        XCTAssertTrue(pm.wrongIDs.contains("test_q3"))

        // Second attempt: correct — should remove from wrongIDs
        pm.markAsAnswered(id: "test_q3", correct: true)
        XCTAssertFalse(pm.wrongIDs.contains("test_q3"))
        XCTAssertTrue(pm.completedIDs.contains("test_q3"))

        pm.resetProgress()
    }

    func testProgressManagerReset() throws {
        let pm = ProgressManager.shared
        pm.markAsAnswered(id: "reset_test", correct: false)

        pm.resetProgress()

        XCTAssertEqual(pm.questionsCompleted, 0)
        XCTAssertEqual(pm.questionsNeedingReview, 0)
        XCTAssertTrue(pm.completedIDs.isEmpty)
        XCTAssertTrue(pm.wrongIDs.isEmpty)
    }

    func testProgressManagerPersistence() throws {
        let pm = ProgressManager.shared
        pm.resetProgress()

        pm.markAsAnswered(id: "persist_1", correct: true)
        pm.markAsAnswered(id: "persist_2", correct: false)

        // Simulate reload from UserDefaults
        pm.load()

        XCTAssertTrue(pm.completedIDs.contains("persist_1"))
        XCTAssertTrue(pm.completedIDs.contains("persist_2"))
        XCTAssertTrue(pm.wrongIDs.contains("persist_2"))
        XCTAssertFalse(pm.wrongIDs.contains("persist_1"))

        pm.resetProgress()
    }

    func testProgressManagerMultipleQuestions() throws {
        let pm = ProgressManager.shared
        pm.resetProgress()

        pm.markAsAnswered(id: "a", correct: true)
        pm.markAsAnswered(id: "b", correct: true)
        pm.markAsAnswered(id: "c", correct: false)
        pm.markAsAnswered(id: "d", correct: false)
        pm.markAsAnswered(id: "e", correct: true)

        XCTAssertEqual(pm.questionsCompleted, 5)
        XCTAssertEqual(pm.questionsNeedingReview, 2) // c and d

        pm.resetProgress()
    }
}

