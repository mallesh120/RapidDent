//
//  Question.swift
//  Dental Rapid Fire
//
//  Data model for quiz questions from Firestore
//

import Foundation
import FirebaseFirestore
import os

struct QuestionOption {
    let id: String
    let text: String
    let isCorrect: Bool
}

struct Question: Identifiable {
    let id: String
    let questionText: String
    let type: String
    let correctOption: String  // "A" for True, "B" for False, or "A", "B", "C", "D" for multiple choice
    let explanation: String
    let scenarioId: String?
    let options: [QuestionOption]
    let imageUrl: String?  // Optional image URL for questions with visual content
    
    // Direct initializer for testing/previews
    init(id: String, questionText: String, type: String, correctOption: String, explanation: String, scenarioId: String? = nil, options: [QuestionOption] = [], imageUrl: String? = nil) {
        self.id = id
        self.questionText = questionText
        self.type = type
        self.correctOption = correctOption
        self.explanation = explanation
        self.scenarioId = scenarioId
        self.options = options
        self.imageUrl = imageUrl
    }
    
    // Custom initializer to parse Firestore document
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        // Safely unwrap required fields
        guard let questionText = data["question_text"] as? String,
              let type = data["type"] as? String,
              let explanation = data["explanation"] as? String else {
            AppLogger.data.warning("Missing required fields in document: \(document.documentID)")
            return nil
        }
        
        // Parse scenario_id (optional for non-scenario questions)
        self.scenarioId = data["scenario_id"] as? String
        
        // Parse image_url (optional)
        self.imageUrl = data["image_url"] as? String
        
        // Parse options array
        var parsedOptions: [QuestionOption] = []
        if let optionsData = data["options"] as? [[String: Any]] {
            for optionData in optionsData {
                if let id = optionData["id"] as? String,
                   let text = optionData["text"] as? String,
                   let isCorrect = optionData["is_correct"] as? Bool {
                    parsedOptions.append(QuestionOption(id: id, text: text, isCorrect: isCorrect))
                } else {
                    AppLogger.data.debug("Skipping malformed option in \(document.documentID)")
                }
            }
        }
        self.options = parsedOptions
        
        // Parse correct_option from either direct field or options array
        var correctOption: String?
        
        if let directOption = data["correct_option"] as? String {
            correctOption = directOption
        } else if !parsedOptions.isEmpty {
            correctOption = parsedOptions.first(where: { $0.isCorrect })?.id
        }
        
        guard let finalCorrectOption = correctOption else {
            AppLogger.data.error("Could not determine correct_option for: \(document.documentID)")
            return nil
        }
        
        self.id = document.documentID
        self.questionText = questionText
        self.type = type
        self.correctOption = finalCorrectOption
        self.explanation = explanation
    }
    
    // Helper computed property
    var isCorrectAnswerTrue: Bool {
        return correctOption == "A"
    }
}
