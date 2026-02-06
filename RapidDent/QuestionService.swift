//
//  QuestionService.swift
//  RapidDent
//
//  Centralised Firestore data-fetching for questions and scenarios.
//  Views call these methods instead of touching Firestore directly.
//

import Foundation
import os
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

final class QuestionService {
    static let shared = QuestionService()

#if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
#endif

    private init() {}

    // MARK: - Rapid Fire Questions

    /// Fetches all RAPID_FIRE questions from Firestore.
    func fetchRapidFireQuestions(completion: @escaping (Result<[Question], Error>) -> Void) {
#if canImport(FirebaseFirestore)
        db.collection("questions")
            .whereField("type", isEqualTo: "RAPID_FIRE")
            .getDocuments { snapshot, error in
                if let error = error {
                    AppLogger.data.error("Error fetching rapid-fire questions: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    AppLogger.data.warning("No rapid-fire documents found")
                    completion(.success([]))
                    return
                }

                let questions = documents.compactMap { Question(document: $0) }
                AppLogger.data.info("Fetched \(questions.count) rapid-fire questions")
                completion(.success(questions))
            }
#else
        completion(.failure(ServiceError.firebaseUnavailable))
#endif
    }

    // MARK: - Exam Questions

    /// Fetches and returns exactly `count` shuffled RAPID_FIRE questions for the mock exam.
    func fetchExamQuestions(count: Int = 30, completion: @escaping (Result<[Question], Error>) -> Void) {
        fetchRapidFireQuestions { result in
            switch result {
            case .success(let all):
                guard all.count >= count else {
                    AppLogger.data.warning("Only \(all.count) questions; need \(count)")
                    completion(.failure(ServiceError.insufficientQuestions(available: all.count, required: count)))
                    return
                }
                completion(.success(Array(all.shuffled().prefix(count))))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Scenario

    /// Fetches a random scenario and its linked questions.
    func fetchRandomScenario(completion: @escaping (Result<(Scenario, [Question]), Error>) -> Void) {
#if canImport(FirebaseFirestore)
        db.collection("scenarios")
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    AppLogger.data.error("Error fetching scenarios: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    AppLogger.data.warning("No scenario documents found")
                    completion(.failure(ServiceError.noData))
                    return
                }

                guard let randomDoc = documents.randomElement(),
                      let scenario = Scenario(document: randomDoc) else {
                    completion(.failure(ServiceError.parseFailed))
                    return
                }

                // Fetch linked questions
                self.fetchQuestionsForScenario(scenarioId: scenario.id) { qResult in
                    switch qResult {
                    case .success(let questions):
                        completion(.success((scenario, questions)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
#else
        completion(.failure(ServiceError.firebaseUnavailable))
#endif
    }

    /// Fetches questions linked to a specific scenario.
    func fetchQuestionsForScenario(scenarioId: String, completion: @escaping (Result<[Question], Error>) -> Void) {
#if canImport(FirebaseFirestore)
        db.collection("questions")
            .whereField("scenario_id", isEqualTo: scenarioId)
            .getDocuments { snapshot, error in
                if let error = error {
                    AppLogger.data.error("Error fetching scenario questions: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let questions = documents.compactMap { Question(document: $0) }
                AppLogger.data.info("Loaded \(questions.count) questions for scenario \(scenarioId)")
                completion(.success(questions))
            }
#else
        completion(.failure(ServiceError.firebaseUnavailable))
#endif
    }

    // MARK: - Errors

    enum ServiceError: LocalizedError {
        case firebaseUnavailable
        case noData
        case parseFailed
        case insufficientQuestions(available: Int, required: Int)

        var errorDescription: String? {
            switch self {
            case .firebaseUnavailable:
                return "Firebase is not configured. Please ensure Firebase is properly set up."
            case .noData:
                return "No data found in the database."
            case .parseFailed:
                return "Failed to parse data from the database."
            case .insufficientQuestions(let available, let required):
                return "Not enough questions available. Need \(required) but only \(available) found."
            }
        }
    }
}
