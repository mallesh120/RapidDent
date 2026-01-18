//
//  ExamView.swift
//  RapidDent
//
//  Mock exam mode with 30 questions and 15-minute timer
//

import SwiftUI
import Combine
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
    
    @Environment(\.dismiss) var dismiss
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
#if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
#endif
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 0.99),
                    Color(red: 0.90, green: 0.94, blue: 0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
            
            // Hidden NavigationLink for results (outside ZStack)
            NavigationLink(
                destination: ScoreReportView(
                    score: score,
                    total: questions.count,
                    wrongQuestions: wrongQuestions
                ),
                isActive: $isExamFinished
            ) {
                EmptyView()
            }
            .hidden()
        }
        .onAppear {
            fetchExamQuestions()
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 && !isExamFinished {
                timeRemaining -= 1
            }
            
            // Check if time is up
            if timeRemaining == 0 && !isExamFinished {
                finishExam()
            }
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
                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.8))
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Mock Exam 📝")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.8))
            
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
                .tint(Color(red: 0.0, green: 0.4, blue: 0.8))
            
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
                    .background(Color(red: 0.0, green: 0.4, blue: 0.8))
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
                    print("❌ Error fetching exam questions: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    errorMessage = "No questions found in database"
                    print("❌ No documents found")
                    return
                }
                
                let fetchedQuestions = documents.compactMap { Question(document: $0) }
                
                if fetchedQuestions.count < 30 {
                    errorMessage = "Not enough questions available. Need at least 30 questions."
                    print("⚠️ Only \(fetchedQuestions.count) questions available")
                } else {
                    // Shuffle and take first 30
                    questions = Array(fetchedQuestions.shuffled().prefix(30))
                    print("✅ Mock Exam ready with 30 questions")
                }
            }
#else
        // Fallback when FirebaseFirestore isn't available
        isLoading = false
        errorMessage = "Firebase is not configured. Please ensure Firebase is properly set up."
        print("⚠️ Firebase not available - cannot fetch questions")
#endif
    }
    
    // MARK: - Exam Logic
    
    private func handleAnswer(userAnsweredTrue: Bool, question: Question) {
        let isCorrect: Bool
        
        if userAnsweredTrue {
            // User answered True
            isCorrect = question.correctOption == "A"
        } else {
            // User answered False
            isCorrect = question.correctOption == "B"
        }
        
        if isCorrect {
            score += 1
            print("✅ Correct! Score: \(score)")
        } else {
            wrongQuestions.append(question)
            print("❌ Wrong!")
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
        print("🏁 Exam finished! Score: \(score)/\(questions.count)")
        isExamFinished = true
    }
}

// MARK: - Preview

struct ExamView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExamView()
        }
    }
}

