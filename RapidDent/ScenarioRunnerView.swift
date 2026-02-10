//
//  ScenarioRunnerView.swift
//  DentalExamPrep
//
//  Scenario-based question runner with patient information
//

import SwiftUI
import os
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
    @State private var showScenarioComplete = false
    @State private var patientExpanded = false
    @State private var seenScenarioIDs: Set<String> = []
    
    private var allQuestionsAnswered: Bool {
        !questions.isEmpty && answeredQuestions.count == questions.count
    }
    
    private var isLastQuestionAnswered: Bool {
        !questions.isEmpty && answeredQuestions.contains(questions.count - 1)
    }
    
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
        HStack(spacing: 0) {
            Text("🏥 Clinical")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.rdBrand)
            
            Spacer()
            
            HStack(spacing: 12) {
                // Score chip
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text("\(score)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                
                // Progress chip
                if !questions.isEmpty {
                    Text("\(currentQuestionIndex + 1)/\(questions.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.rdBrand)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.rdBrand.opacity(0.12))
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.rdBrand)
            
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
                    .background(Color.rdBrand)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Scenario Content View
    
    private func scenarioContentView(scenario: Scenario) -> some View {
        VStack(spacing: 0) {
            if showScenarioComplete {
                scenarioCompleteView(scenario: scenario)
            } else {
                // Single unified scroll
                ScrollView {
                    VStack(spacing: 12) {
                        // Collapsible Patient Box
                        PatientBoxView(scenario: scenario, isExpanded: $patientExpanded)
                            .padding(.horizontal, 16)
                        
                        // Question + Options inline
                        if !questions.isEmpty && currentQuestionIndex < questions.count {
                            questionContentView(question: questions[currentQuestionIndex])
                                .padding(.horizontal, 16)
                        } else if questions.isEmpty {
                            emptyQuestionsView
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                // Fixed navigation bar at bottom (never scrolls)
                if !questions.isEmpty && currentQuestionIndex < questions.count {
                    VStack(spacing: 8) {
                        navigationButtons
                        
                        if isLastQuestionAnswered {
                            scenarioEndButtons
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Color(uiColor: .systemBackground)
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: -2)
                    )
                }
            }
        }
    }
    
    // MARK: - Question Content (no inner scroll)
    
    private func questionContentView(question: Question) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question Text
            Text(question.questionText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .lineSpacing(5)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
            
            // Options
            ForEach(question.options, id: \.id) { option in
                optionButton(option: option, question: question)
            }
        }
    }
    
    private func optionButton(option: QuestionOption, question: Question) -> some View {
        Button(action: {
            if !answeredQuestions.contains(currentQuestionIndex) {
                selectedOption = option.id
                checkAnswer(question: question)
            }
        }) {
            HStack(spacing: 10) {
                // Option Letter
                Text(option.id)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(getOptionColor(optionId: option.id))
                    .clipShape(Circle())
                
                // Option Text
                Text(option.text)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Checkmark if selected and answered
                if answeredQuestions.contains(currentQuestionIndex) && selectedOption == option.id {
                    Image(systemName: option.id == question.correctOption ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(option.id == question.correctOption ? .green : .red)
                        .font(.system(size: 18))
                }
            }
            .padding(12)
            .background(getOptionBackground(optionId: option.id, question: question))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(getOptionBorder(optionId: option.id, question: question), lineWidth: 2)
            )
        }
        .disabled(answeredQuestions.contains(currentQuestionIndex))
    }
    
    private func getOptionColor(optionId: String) -> Color {
        if answeredQuestions.contains(currentQuestionIndex) && selectedOption == optionId {
            return questions[currentQuestionIndex].correctOption == optionId ? .green : .red
        }
        return Color.rdBrand
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
        HStack(spacing: 12) {
            Button(action: previousQuestion) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Prev")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(currentQuestionIndex > 0 ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(currentQuestionIndex > 0 ? Color.rdBrand : Color.gray.opacity(0.3))
                .cornerRadius(10)
            }
            .disabled(currentQuestionIndex == 0)
            
            Button(action: nextQuestion) {
                HStack(spacing: 4) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(currentQuestionIndex < questions.count - 1 ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(currentQuestionIndex < questions.count - 1 ? Color.rdBrand : Color.gray.opacity(0.3))
                .cornerRadius(10)
            }
            .disabled(currentQuestionIndex >= questions.count - 1)
        }
    }
    
    // MARK: - Scenario End Buttons
    
    private var scenarioEndButtons: some View {
        HStack(spacing: 10) {
            Button(action: retryScenario) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Retry")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.rdBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.rdBrand.opacity(0.12))
                .cornerRadius(10)
            }
            
            Button(action: loadNextScenario) {
                HStack(spacing: 4) {
                    Text("Next Scenario")
                    Image(systemName: "arrow.right.circle.fill")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.rdSuccess)
                .cornerRadius(10)
            }
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
                
                // Continue / See Results Button
                if currentQuestionIndex >= questions.count - 1 {
                    Button(action: {
                        withAnimation(.spring()) {
                            showFeedback = false
                            showScenarioComplete = true
                        }
                    }) {
                        HStack {
                            Text("See Results")
                            Image(systemName: "chart.bar.fill")
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.rdBrand)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: dismissFeedback) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.rdBrand)
                            .cornerRadius(12)
                    }
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
    
    // MARK: - Scenario Complete View
    
    private func scenarioCompleteView(scenario: Scenario) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)
                
                // Trophy / Badge
                Image(systemName: "trophy.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 5)
                
                Text("Scenario Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                // Score Card
                VStack(spacing: 16) {
                    Text("Your Score")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(score) / \(questions.count)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)
                    
                    // Percentage
                    let pct = questions.isEmpty ? 0 : Int((Double(score) / Double(questions.count)) * 100)
                    Text("\(pct)%")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(scoreColor)
                                .frame(width: geo.size.width * CGFloat(score) / CGFloat(max(questions.count, 1)), height: 12)
                        }
                    }
                    .frame(height: 12)
                    .padding(.horizontal, 20)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 16)
                
                // Patient Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Patient Summary")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("\(scenario.age)-year-old \(scenario.gender) — \(scenario.chiefComplaint)")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: loadNextScenario) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Next Scenario")
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.rdBrand)
                        .cornerRadius(14)
                    }
                    .accessibilityLabel("Load next clinical scenario")
                    
                    Button(action: retryScenario) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Retry Scenario")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.rdExam)
                        .cornerRadius(14)
                    }
                    .accessibilityLabel("Retry the same scenario from the beginning")
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            showScenarioComplete = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Review Answers")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.rdBrand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.rdBrand.opacity(0.1))
                        .cornerRadius(14)
                    }
                    .accessibilityLabel("Go back and review your answers")
                }
                .padding(.horizontal, 16)
                
                Spacer().frame(height: 20)
            }
        }
    }
    
    private var scoreColor: Color {
        let pct = questions.isEmpty ? 0.0 : Double(score) / Double(questions.count)
        if pct >= 0.8 { return .rdSuccess }
        if pct >= 0.5 { return .rdWarning }
        return .rdError
    }
    
    private func loadNextScenario() {
        // Reset all state
        scenario = nil
        questions = []
        currentQuestionIndex = 0
        selectedOption = nil
        showFeedback = false
        isCorrect = false
        score = 0
        answeredQuestions = []
        showScenarioComplete = false
        isLoading = true
        errorMessage = nil
        
        // Fetch a fresh scenario
        fetchScenario()
    }
    
    private func retryScenario() {
        // Keep the same scenario & questions, just reset answers
        withAnimation(.spring()) {
            currentQuestionIndex = 0
            selectedOption = nil
            showFeedback = false
            isCorrect = false
            score = 0
            answeredQuestions = []
            showScenarioComplete = false
        }
        // Shuffle question order for variety
        questions.shuffle()
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
                    AppLogger.data.error("Error fetching scenarios: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    isLoading = false
                    errorMessage = "No scenarios found in database"
                    AppLogger.data.warning("No scenario documents found")
                    return
                }
                
                // Filter out already-seen scenarios
                var unseen = documents.filter { !self.seenScenarioIDs.contains($0.documentID) }
                
                // If all have been seen, reset and allow all again
                if unseen.isEmpty {
                    self.seenScenarioIDs.removeAll()
                    unseen = documents
                    AppLogger.data.info("All scenarios seen – resetting cycle")
                }
                
                // Pick a random unseen scenario
                let randomDocument = unseen.randomElement()!
                
                if let fetchedScenario = Scenario(document: randomDocument) {
                    self.seenScenarioIDs.insert(fetchedScenario.id)
                    self.scenario = fetchedScenario
                    AppLogger.data.info("Loaded scenario: \(fetchedScenario.id) (seen \(self.seenScenarioIDs.count)/\(documents.count))")
                    
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
                    AppLogger.data.error("Error fetching scenario questions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    errorMessage = "No questions found for this scenario"
                    AppLogger.data.warning("No question documents for scenario")
                    return
                }
                
                let fetchedQuestions = documents.compactMap { Question(document: $0) }
                
                if fetchedQuestions.isEmpty {
                    AppLogger.data.warning("No questions parsed for scenario: \(scenarioId)")
                } else {
                    questions = fetchedQuestions
                    AppLogger.data.info("Loaded \(fetchedQuestions.count) scenario questions")
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
            HapticManager.notification(.success)
        } else {
            HapticManager.notification(.error)
        }
        
        answeredQuestions.insert(currentQuestionIndex)
        
        // Auto-collapse patient info to keep focus on feedback
        if patientExpanded {
            withAnimation(.spring(response: 0.3)) {
                patientExpanded = false
            }
        }
        
        withAnimation(.spring()) {
            showFeedback = true
        }
    }
    
    private func dismissFeedback() {
        withAnimation(.spring()) {
            showFeedback = false
        }
        
        // Auto-advance to the next question after dismissing feedback
        if !isLastQuestionAnswered && currentQuestionIndex < questions.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    currentQuestionIndex += 1
                    selectedOption = nil
                }
            }
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
