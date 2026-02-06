//
//  ExamView.swift
//  RapidDent
//
//  Mock exam mode with 30 questions and 15-minute timer
//

import SwiftUI
import Combine
import os
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct ExamView: View {
    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var score = 0
    @State private var wrongQuestions: [Question] = []
    @State private var timeRemaining = 900 // 15 minutes in seconds
    @State private var isExamFinished = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var timerSubscription: AnyCancellable?
    
    @Environment(\.dismiss) var dismiss
    
#if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
#endif
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with timer and progress
                headerView
                
                // Main content
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if !isExamFinished && currentIndex < questions.count {
                    examView
                } else {
                    // This should not show as we navigate to ScoreReportView
                    EmptyView()
                }
            }
            
            // Hidden NavigationLink for results
            .navigationDestination(isPresented: $isExamFinished) {
                ScoreReportView(
                    score: score,
                    total: questions.count,
                    wrongQuestions: wrongQuestions
                )
            }
        }
        .onAppear {
            fetchExamQuestions()
            startTimer()
        }
        .appBackground()
        .onDisappear {
            timerSubscription?.cancel()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Exit")
                    }
                    .foregroundColor(.rdBrand)
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Mock Exam 📝")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.rdBrand)
            
            HStack(spacing: 20) {
                // Timer
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .foregroundColor(timeRemaining < 60 ? .red : .blue)
                    Text(timeString)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(timeRemaining < 60 ? .red : .primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Progress
                if !questions.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "list.number")
                            .foregroundColor(.blue)
                        Text("\(min(currentIndex + 1, 30)) of 30")
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
            
            Text("Preparing Mock Exam...")
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
            
            Text("Error")
                .font(.system(size: 24, weight: .bold))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: fetchExamQuestions) {
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
    
    // MARK: - Exam View
    
    private var examView: some View {
        ZStack {
            // Stack cards (show next 2 cards behind)
            ForEach(Array(questions.enumerated().reversed()), id: \.element.id) { index, question in
                if index >= currentIndex && index < currentIndex + 3 {
                    CardView(question: question) { userAnsweredTrue in
                        handleAnswer(userAnsweredTrue: userAnsweredTrue, question: question)
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
    }
    
    // MARK: - Helper Properties
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard timeRemaining > 0, !isExamFinished else {
                    if timeRemaining == 0, !isExamFinished { finishExam() }
                    return
                }
                timeRemaining -= 1
            }
    }
    
    // MARK: - Data Fetching
    
    private func fetchExamQuestions() {
#if canImport(FirebaseFirestore)
        isLoading = true
        errorMessage = nil
        
        db.collection("questions")
            .whereField("type", isEqualTo: "RAPID_FIRE")
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Failed to load exam questions: \(error.localizedDescription)"
                    AppLogger.data.error("Error fetching exam questions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    errorMessage = "No questions found in database"
                    AppLogger.data.warning("No exam documents found")
                    return
                }
                
                let fetchedQuestions = documents.compactMap { Question(document: $0) }
                
                if fetchedQuestions.count < 30 {
                    errorMessage = "Not enough questions available. Need at least 30 questions."
                    AppLogger.data.warning("Only \(fetchedQuestions.count) exam questions available")
                } else {
                    // Shuffle and take first 30
                    questions = Array(fetchedQuestions.shuffled().prefix(30))
                    AppLogger.data.info("Mock Exam ready with 30 questions")
                }
            }
#else
        // Fallback when FirebaseFirestore isn't available
        isLoading = false
        errorMessage = "Firebase is not configured. Please ensure Firebase is properly set up."
        AppLogger.data.warning("Firebase not available")
#endif
    }
    
    // MARK: - Exam Logic
    
    private func handleAnswer(userAnsweredTrue: Bool, question: Question) {
        let isCorrect: Bool
        
        if userAnsweredTrue {
            isCorrect = question.correctOption == "A"
        } else {
            isCorrect = question.correctOption == "B"
        }
        
        if isCorrect {
            score += 1
            HapticManager.notification(.success)
        } else {
            wrongQuestions.append(question)
            HapticManager.notification(.error)
        }
        
        // Move to next question immediately (no feedback shown)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring()) {
                currentIndex += 1
                
                // Check if exam is complete
                if currentIndex >= questions.count {
                    finishExam()
                }
            }
        }
    }
    
    private func finishExam() {
        timerSubscription?.cancel()
        HapticManager.notification(.warning)
        AppLogger.game.info("Exam finished! Score: \(score)/\(questions.count)")
        isExamFinished = true
    }
}

// MARK: - Preview

struct ExamView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ExamView()
        }
    }
}

