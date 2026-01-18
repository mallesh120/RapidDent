//
//  ScenarioRunnerView.swift
//  DentalExamPrep
//
//  Scenario-based question runner with patient information
//

import SwiftUI
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct ScenarioRunnerView: View {
    @State private var scenario: Scenario?
    @State private var questions: [Question] = []
    @State private var currentQuestionIndex = 0
    @State private var selectedOption: String?
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var score = 0
    @State private var answeredQuestions: Set<Int> = []
    
#if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
#endif
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.95, green: 0.97, blue: 0.99)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let scenario = scenario {
                    scenarioContentView(scenario: scenario)
                }
            }
        }
        .onAppear {
            fetchScenario()
        }
        .overlay(
            Group {
                if showFeedback {
                    feedbackOverlay
                }
            }
        )
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Clinical Scenario 🏥")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.8))
            
            HStack(spacing: 20) {
                // Score
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Score: \(score)")
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Progress
                if !questions.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "list.number")
                            .foregroundColor(.blue)
                        Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(red: 0.0, green: 0.4, blue: 0.8))
            
            Text("Loading Scenario...")
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
            
            Button(action: fetchScenario) {
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
    
    // MARK: - Scenario Content View
    
    private func scenarioContentView(scenario: Scenario) -> some View {
        VStack(spacing: 0) {
            // Patient Box (Top Half)
            PatientBoxView(scenario: scenario)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            Divider()
                .padding(.vertical, 8)
            
            // Question Section (Bottom Half)
            if !questions.isEmpty && currentQuestionIndex < questions.count {
                questionView(question: questions[currentQuestionIndex])
                    .frame(maxHeight: .infinity)
            } else if questions.isEmpty {
                emptyQuestionsView
            }
        }
    }
    
    // MARK: - Question View
    
    private func questionView(question: Question) -> some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question Text
                    Text(question.questionText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Options
                    VStack(spacing: 12) {
                        ForEach(question.options, id: \.id) { option in
                            optionButton(option: option, question: question)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Navigation Buttons
            navigationButtons
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }
    
    private func optionButton(option: QuestionOption, question: Question) -> some View {
        Button(action: {
            if !answeredQuestions.contains(currentQuestionIndex) {
                selectedOption = option.id
                checkAnswer(question: question)
            }
        }) {
            HStack(spacing: 12) {
                // Option Letter
                Text(option.id)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(getOptionColor(optionId: option.id))
                    .clipShape(Circle())
                
                // Option Text
                Text(option.text)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Checkmark if selected and answered
                if answeredQuestions.contains(currentQuestionIndex) && selectedOption == option.id {
                    Image(systemName: option.id == question.correctOption ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(option.id == question.correctOption ? .green : .red)
                        .font(.system(size: 20))
                }
            }
            .padding(16)
            .background(getOptionBackground(optionId: option.id, question: question))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(getOptionBorder(optionId: option.id, question: question), lineWidth: 2)
            )
        }
        .disabled(answeredQuestions.contains(currentQuestionIndex))
    }
    
    private func getOptionColor(optionId: String) -> Color {
        if answeredQuestions.contains(currentQuestionIndex) && selectedOption == optionId {
            return questions[currentQuestionIndex].correctOption == optionId ? .green : .red
        }
        return Color(red: 0.0, green: 0.4, blue: 0.8)
    }
    
    private func getOptionBackground(optionId: String, question: Question) -> Color {
        if answeredQuestions.contains(currentQuestionIndex) {
            if optionId == question.correctOption {
                return Color.green.opacity(0.1)
            } else if selectedOption == optionId {
                return Color.red.opacity(0.1)
            }
        }
        return Color.white
    }
    
    private func getOptionBorder(optionId: String, question: Question) -> Color {
        if answeredQuestions.contains(currentQuestionIndex) {
            if optionId == question.correctOption {
                return .green
            } else if selectedOption == optionId {
                return .red
            }
        }
        return Color.gray.opacity(0.2)
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Previous Button
            Button(action: previousQuestion) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(currentQuestionIndex > 0 ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(currentQuestionIndex > 0 ? Color(red: 0.0, green: 0.4, blue: 0.8) : Color.gray.opacity(0.3))
                .cornerRadius(12)
            }
            .disabled(currentQuestionIndex == 0)
            
            // Next Button
            Button(action: nextQuestion) {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(currentQuestionIndex < questions.count - 1 ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(currentQuestionIndex < questions.count - 1 ? Color(red: 0.0, green: 0.4, blue: 0.8) : Color.gray.opacity(0.3))
                .cornerRadius(12)
            }
            .disabled(currentQuestionIndex >= questions.count - 1)
        }
    }
    
    // MARK: - Empty Questions View
    
    private var emptyQuestionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No questions found for this scenario")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Feedback Overlay
    
    private var feedbackOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissFeedback()
                }
            
            VStack(spacing: 24) {
                // Result
                VStack(spacing: 16) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(isCorrect ? .green : .red)
                    
                    Text(isCorrect ? "Correct! 🎉" : "Incorrect")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(isCorrect ? .green : .red)
                }
                
                // Explanation
                if currentQuestionIndex < questions.count {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Explanation:")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(questions[currentQuestionIndex].explanation)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(12)
                }
                
                // Continue Button
                Button(action: dismissFeedback) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.0, green: 0.4, blue: 0.8))
                        .cornerRadius(12)
                }
            }
            .padding(32)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }
    
    // MARK: - Data Fetching
    
    private func fetchScenario() {
#if canImport(FirebaseFirestore)
        isLoading = true
        errorMessage = nil
        
        // Fetch a random scenario
        db.collection("scenarios")
            .getDocuments { snapshot, error in
                if let error = error {
                    isLoading = false
                    errorMessage = "Failed to load scenario: \(error.localizedDescription)"
                    print("❌ Error fetching scenarios: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    isLoading = false
                    errorMessage = "No scenarios found in database"
                    print("❌ No scenario documents found")
                    return
                }
                
                // Pick a random scenario
                let randomDocument = documents.randomElement()!
                
                if let fetchedScenario = Scenario(document: randomDocument) {
                    self.scenario = fetchedScenario
                    print("✅ Loaded scenario: \(fetchedScenario.id)")
                    
                    // Fetch linked questions
                    fetchQuestions(for: fetchedScenario.id)
                } else {
                    isLoading = false
                    errorMessage = "Failed to parse scenario"
                }
            }
#else
        isLoading = false
        errorMessage = "Firebase is not configured"
#endif
    }
    
    private func fetchQuestions(for scenarioId: String) {
#if canImport(FirebaseFirestore)
        db.collection("questions")
            .whereField("scenario_id", isEqualTo: scenarioId)
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Failed to load questions: \(error.localizedDescription)"
                    print("❌ Error fetching questions: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    errorMessage = "No questions found for this scenario"
                    print("❌ No question documents found")
                    return
                }
                
                let fetchedQuestions = documents.compactMap { Question(document: $0) }
                
                if fetchedQuestions.isEmpty {
                    print("⚠️ No questions found for scenario: \(scenarioId)")
                } else {
                    questions = fetchedQuestions
                    print("✅ Loaded \(fetchedQuestions.count) questions")
                }
            }
#endif
    }
    
    // MARK: - Game Logic
    
    private func checkAnswer(question: Question) {
        guard let selected = selectedOption else { return }
        
        isCorrect = selected == question.correctOption
        
        if isCorrect {
            score += 1
            print("✅ Correct!")
        } else {
            print("❌ Wrong! Correct answer: \(question.correctOption)")
        }
        
        answeredQuestions.insert(currentQuestionIndex)
        
        withAnimation(.spring()) {
            showFeedback = true
        }
    }
    
    private func dismissFeedback() {
        withAnimation(.spring()) {
            showFeedback = false
        }
    }
    
    private func nextQuestion() {
        guard currentQuestionIndex < questions.count - 1 else { return }
        
        withAnimation {
            currentQuestionIndex += 1
            selectedOption = nil
        }
    }
    
    private func previousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        
        withAnimation {
            currentQuestionIndex -= 1
            selectedOption = nil
        }
    }
}

// MARK: - Preview

struct ScenarioRunnerView_Previews: PreviewProvider {
    static var previews: some View {
        ScenarioRunnerView()
    }
}
