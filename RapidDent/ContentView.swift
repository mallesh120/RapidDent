//
//  ContentView.swift
//  Dental Rapid Fire
//
//  Main game view with swipe logic and scoring
//

import SwiftUI
import os
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct ContentView: View {
    var reviewMode: Bool = false
    
    @ObservedObject private var progressManager = ProgressManager.shared
    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var score = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var activeExplanation: Question?
    @State private var feedbackIsCorrect = false
    @State private var showFeedback = false
    
#if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
#endif
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if questions.isEmpty || currentIndex >= questions.count {
                    completionView
                } else {
                    gameView
                }
            }
        }
        .appBackground()
        .onAppear {
            fetchQuestions()
        }
        .sheet(isPresented: $showFeedback) {
            if let question = activeExplanation {
                FeedbackView(question: question, isCorrect: feedbackIsCorrect) {
                    dismissFeedback()
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("RapidDent 🦷")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.rdBrand)
            
            HStack(spacing: 20) {
                // Score
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Score: \(score)")
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Progress
                if !questions.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                        Text("\(currentIndex + 1)/\(questions.count)")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.rdBrand)
            
            Text("Loading Questions...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.system(size: 24, weight: .bold))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: fetchQuestions) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.rdBrand)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            Text("Quiz Complete! 🎉")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.rdBrand)
            
            VStack(spacing: 12) {
                Text("Final Score")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("\(score) / \(questions.count)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.rdBrand)
                
                let percentage = questions.isEmpty ? 0 : Int((Double(score) / Double(questions.count)) * 100)
                Text("\(percentage)% Correct")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.green)
            }
            .padding(32)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            
            Button(action: resetGame) {
                Text("Play Again")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color.rdBrand)
                    .cornerRadius(30)
                    .shadow(color: Color.rdBrand.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Game View
    
    private var gameView: some View {
        VStack(spacing: 20) {
            // Cards stack
            ZStack {
                // Stack cards (show next 2 cards behind)
                ForEach(Array(questions.enumerated().reversed()), id: \.element.id) { index, question in
                    if index >= currentIndex && index < currentIndex + 3 {
                        CardView(question: question) { userAnsweredTrue in
                            handleSwipe(userAnsweredTrue: userAnsweredTrue, question: question)
                        }
                        .padding(20)
                        .zIndex(Double(questions.count - index))
                        .scaleEffect(index == currentIndex ? 1.0 : 0.95 - (Double(index - currentIndex) * 0.05))
                        .offset(y: CGFloat((index - currentIndex) * 10))
                        .opacity(index == currentIndex ? 1.0 : 0.5)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            
            // True/False buttons
            HStack(spacing: 24) {
                // FALSE button
                Button(action: {
                    if currentIndex < questions.count {
                        handleSwipe(userAnsweredTrue: false, question: questions[currentIndex])
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                        Text("FALSE")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.3, blue: 0.3),
                                    Color(red: 0.85, green: 0.2, blue: 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            // Shine effect
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        }
                    )
                    .cornerRadius(25)
                    .shadow(color: Color.red.opacity(0.5), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .disabled(currentIndex >= questions.count)
                .scaleEffect(currentIndex >= questions.count ? 0.95 : 1.0)
                .opacity(currentIndex >= questions.count ? 0.6 : 1.0)
                
                // TRUE button
                Button(action: {
                    if currentIndex < questions.count {
                        handleSwipe(userAnsweredTrue: true, question: questions[currentIndex])
                    }
                }) {
                    HStack(spacing: 10) {
                        Text("TRUE")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(1)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.8, blue: 0.4),
                                    Color(red: 0.1, green: 0.7, blue: 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            // Shine effect
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        }
                    )
                    .cornerRadius(25)
                    .shadow(color: Color.green.opacity(0.5), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .disabled(currentIndex >= questions.count)
                .scaleEffect(currentIndex >= questions.count ? 0.95 : 1.0)
                .opacity(currentIndex >= questions.count ? 0.6 : 1.0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchQuestions() {
#if canImport(FirebaseFirestore)
        isLoading = true
        errorMessage = nil
        
        db.collection("questions")
            .whereField("type", isEqualTo: "RAPID_FIRE")
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Failed to load questions: \(error.localizedDescription)"
                    AppLogger.data.error("Error fetching questions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    errorMessage = "No questions found in database"
                    AppLogger.data.warning("No documents found")
                    return
                }
                
                let fetchedQuestions = documents.compactMap { Question(document: $0) }
                
                if fetchedQuestions.isEmpty {
                    errorMessage = "No RAPID_FIRE questions available"
                    AppLogger.data.warning("No RAPID_FIRE questions found")
                } else {
                    if reviewMode {
                        // Review Mode: Show ONLY questions that were answered incorrectly
                        let reviewQuestions = fetchedQuestions.filter { progressManager.wrongIDs.contains($0.id) }
                        
                        if reviewQuestions.isEmpty {
                            errorMessage = "No questions need review. Great job! 🎉"
                            AppLogger.data.info("No questions to review")
                        } else {
                            questions = reviewQuestions.shuffled()
                            AppLogger.data.info("Review Mode: Loaded \(reviewQuestions.count) questions")
                        }
                    } else {
                        // Normal Mode: Filter out already completed questions
                        let uncompletedQuestions = fetchedQuestions.filter { !progressManager.completedIDs.contains($0.id) }
                        
                        if uncompletedQuestions.isEmpty {
                            // All questions completed, reset to show all questions
                            questions = fetchedQuestions.shuffled()
                            AppLogger.data.info("All completed! Showing all \(fetchedQuestions.count) questions")
                        } else {
                            questions = uncompletedQuestions.shuffled()
                            AppLogger.data.info("Loaded \(uncompletedQuestions.count) uncompleted of \(fetchedQuestions.count) total")
                        }
                    }
                }
            }
#else
        // Fallback when FirebaseFirestore isn't available
        isLoading = false
        errorMessage = "Firebase is not configured. Please ensure Firebase is properly set up."
        AppLogger.data.warning("Firebase not available")
#endif
    }
    
    // MARK: - Game Logic
    
    private func handleSwipe(userAnsweredTrue: Bool, question: Question) {
        let isCorrect: Bool
        
        if userAnsweredTrue {
            isCorrect = question.correctOption == "A"
        } else {
            isCorrect = question.correctOption == "B"
        }
        
        if isCorrect {
            score += 1
            HapticManager.notification(.success)
            AppLogger.game.debug("Correct! Score: \(score)")
            
            // If in review mode and answered correctly, remove from wrong IDs
            if reviewMode && progressManager.wrongIDs.contains(question.id) {
                progressManager.wrongIDs.remove(question.id)
                progressManager.save()
            }
        } else {
            HapticManager.notification(.error)
            AppLogger.game.debug("Wrong! Answer was: \(question.isCorrectAnswerTrue ? "True" : "False")")
        }
        
        // Mark question as answered in progress manager (only in normal mode)
        if !reviewMode {
            progressManager.markAsAnswered(id: question.id, correct: isCorrect)
        }
        
        // Show feedback sheet for all answers
        activeExplanation = question
        feedbackIsCorrect = isCorrect
        showFeedback = true
    }
    
    private func dismissFeedback() {
        showFeedback = false
        activeExplanation = nil
        
        // Move to next question after dismissing feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring()) {
                currentIndex += 1
            }
        }
    }
    
    private func resetGame() {
        currentIndex = 0
        score = 0
        fetchQuestions()
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
