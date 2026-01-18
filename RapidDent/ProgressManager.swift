//
//  ProgressManager.swift
//  DentalExamPrep
//
//  Singleton to manage user progress with UserDefaults persistence
//

import Foundation
import Combine

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
            print("✅ Loaded \(completedIDs.count) completed questions")
        }
        
        if let wrongData = UserDefaults.standard.array(forKey: wrongKey) as? [String] {
            wrongIDs = Set(wrongData)
            print("✅ Loaded \(wrongIDs.count) questions needing review")
        }
    }
    
    /// Save current progress to UserDefaults
    func save() {
        UserDefaults.standard.set(Array(completedIDs), forKey: completedKey)
        UserDefaults.standard.set(Array(wrongIDs), forKey: wrongKey)
        print("💾 Progress saved: \(completedIDs.count) completed, \(wrongIDs.count) need review")
    }
    
    /// Mark a question as answered
    /// - Parameters:
    ///   - id: Question ID
    ///   - correct: Whether the answer was correct
    func markAsAnswered(id: String, correct: Bool) {
        // Add to completed set
        completedIDs.insert(id)
        
        // If wrong, add to wrong IDs; if correct, remove from wrong IDs (in case they got it right this time)
        if correct {
            wrongIDs.remove(id)
            print("✅ Question \(id) answered correctly")
        } else {
            wrongIDs.insert(id)
            print("❌ Question \(id) needs review")
        }
        
        save()
    }
    
    /// Reset all progress (for testing or starting fresh)
    func resetProgress() {
        completedIDs.removeAll()
        wrongIDs.removeAll()
        save()
        print("🔄 Progress reset")
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
}
