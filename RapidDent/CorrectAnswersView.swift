//
//  CorrectAnswersView.swift
//  RapidDent
//
//  Shows all correctly answered questions with their explanations
//

import SwiftUI

struct CorrectAnswersView: View {
    @ObservedObject private var progressManager = ProgressManager.shared
    @State private var questions: [Question] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var expandedID: String?
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.97, blue: 0.99)
                .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(.rdBrand)
                    Text("Loading questions…")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Retry") { fetchCorrectQuestions() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(Color.rdBrand)
                        .cornerRadius(20)
                }
            } else if questions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No correct answers yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("Start answering questions to see your mastered topics here.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Summary chip
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.rdSuccess)
                            Text("\(questions.count) question\(questions.count == 1 ? "" : "s") mastered")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.rdSuccess)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.rdSuccess.opacity(0.1))
                        .cornerRadius(20)
                        .padding(.top, 8)
                        
                        ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                            CorrectQuestionCard(
                                question: question,
                                index: index + 1,
                                isExpanded: expandedID == question.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        expandedID = expandedID == question.id ? nil : question.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitle("Correct Answers", displayMode: .inline)
        .onAppear { fetchCorrectQuestions() }
    }
    
    private func fetchCorrectQuestions() {
        let ids = progressManager.correctIDs
        guard !ids.isEmpty else {
            isLoading = false
            questions = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        QuestionService.shared.fetchQuestionsByIDs(ids) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetched):
                    questions = fetched.sorted { $0.questionText < $1.questionText }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Question Card

private struct CorrectQuestionCard: View {
    let question: Question
    let index: Int
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row – always visible
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 12) {
                    // Number badge
                    Text("\(index)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.rdSuccess)
                        .clipShape(Circle())
                    
                    Text(question.questionText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    Spacer(minLength: 4)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .padding(.top, 4)
                }
                .padding(14)
            }
            .buttonStyle(.plain)
            
            // Expanded detail
            if isExpanded {
                Divider()
                    .padding(.horizontal, 14)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Correct answer
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.rdSuccess)
                            .font(.system(size: 16))
                        
                        if let correctOpt = question.options.first(where: { $0.id == question.correctOption }) {
                            Text("\(correctOpt.id). \(correctOpt.text)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.rdSuccess)
                        } else {
                            Text("Answer: \(question.correctOption)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.rdSuccess)
                        }
                    }
                    
                    // Explanation
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Explanation")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(question.explanation)
                            .font(.system(size: 14))
                            .foregroundColor(.primary.opacity(0.85))
                            .lineSpacing(4)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.rdSuccess.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
