//
//  FeedbackView.swift
//  DentalExamPrep
//
//  Instant feedback view for incorrect answers
//

import SwiftUI

struct FeedbackView: View {
    let question: Question
    let isCorrect: Bool
    let onDismiss: () -> Void
    
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
            
            ScrollView {
                VStack(spacing: 32) {
                    // Large Icon and Result text
                    VStack(spacing: 20) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(isCorrect ? .green : .red)
                        
                        Text(isCorrect ? "Correct! 🎉" : "Incorrect")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    .padding(.top, 40)
                    
                    // Question Text
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Question:")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ScrollView {
                            Text(question.questionText)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 150)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 32)
                    
                    // Explanation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Explanation:")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ScrollView {
                            Text(question.explanation)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 32)
                    
                    // Got it Button
                    Button(action: onDismiss) {
                        Text("Got it")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.0, green: 0.4, blue: 0.8))
                            .cornerRadius(12)
                            .shadow(color: Color(red: 0.0, green: 0.4, blue: 0.8).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Preview

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock question for preview
        let mockQuestion = Question(
            id: "preview-1",
            questionText: "Is the mandibular first molar a three-rooted tooth?",
            type: "RAPID_FIRE",
            correctOption: "A",
            explanation: "The mandibular first molar typically has two roots: one mesial and one distal. The maxillary first molar has three roots.",
            scenarioId: nil,
            options: []
        )
        
        FeedbackView(question: mockQuestion, isCorrect: false) {
            print("Dismissed")
        }
    }
}
