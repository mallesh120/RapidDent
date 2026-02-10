//
//  ProgressManager.swift
//  DentalExamPrep
//
//  Singleton to manage user progress with UserDefaults persistence
//

import Foundation
import Combine
import os

class ProgressManager: ObservableObject {
    static let shared = ProgressManager()
    
    // Published properties to trigger UI updates
    @Published var completedIDs: Set<String> = []
    @Published var wrongIDs: Set<String> = []
    
    // UserDefaults keys
    private let completedKey = "completedQuestionIDs"
    private let wrongKey = "wrongQuestionIDs"
    
    private init() {
        load()
    }
    
    // MARK: - Public Methods
    
    /// Load saved progress from UserDefaults
    func load() {
        if let completedData = UserDefaults.standard.array(forKey: completedKey) as? [String] {
            completedIDs = Set(completedData)
            AppLogger.progress.info("Loaded \(self.completedIDs.count) completed questions")
        }
        
        if let wrongData = UserDefaults.standard.array(forKey: wrongKey) as? [String] {
            wrongIDs = Set(wrongData)
            AppLogger.progress.info("Loaded \(self.wrongIDs.count) questions needing review")
        }
    }
    
    /// Save current progress to UserDefaults
    func save() {
        UserDefaults.standard.set(Array(completedIDs), forKey: completedKey)
        UserDefaults.standard.set(Array(wrongIDs), forKey: wrongKey)
        AppLogger.progress.debug("Saved: \(self.completedIDs.count) completed, \(self.wrongIDs.count) review")
    }
    
    /// Mark a question as answered
    func markAsAnswered(id: String, correct: Bool) {
        completedIDs.insert(id)
        
        if correct {
            wrongIDs.remove(id)
        } else {
            wrongIDs.insert(id)
        }
        
        save()
    }
    
    /// Reset all progress
    func resetProgress() {
        completedIDs.removeAll()
        wrongIDs.removeAll()
        save()
        AppLogger.progress.info("Progress reset")
    }
    
    // MARK: - Computed Properties
    
    /// Number of questions completed
    var questionsCompleted: Int {
        completedIDs.count
    }
    
    /// Number of questions needing review
    var questionsNeedingReview: Int {
        wrongIDs.count
    }
    
    /// IDs of correctly answered questions (completed but not wrong)
    var correctIDs: Set<String> {
        completedIDs.subtracting(wrongIDs)
    }
    
    /// Number of correctly answered questions
    var questionsCorrect: Int {
        correctIDs.count
    }
}
