//
//  ScoreReportView.swift
//  RapidDent
//
//  Score report view for mock exam results
//

import SwiftUI

struct ScoreReportView: View {
    let score: Int
    let total: Int
    let wrongQuestions: [Question]
    
    @Environment(\.dismiss) var dismiss
    
    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((Double(score) / Double(total)) * 100)
    }
    
    private var passed: Bool {
        percentage >= 75
    }
    
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
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .font(.system(size: 100))
                            .foregroundColor(passed ? .green : .red)
                        
                        Text(passed ? "PASSED! 🎉" : "FAILED")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(passed ? .green : .red)
                        
                        Text("Mock Exam Results")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                    
                    // Score Card
                    VStack(spacing: 24) {
                        // Percentage
                        VStack(spacing: 8) {
                            Text("\(percentage)%")
                                .font(.system(size: 72, weight: .bold))
                                .foregroundColor(passed ? .green : .red)
                            
                            Text("Score")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        Divider()
                            .padding(.horizontal, 40)
                        
                        // Detailed stats
                        HStack(spacing: 40) {
                            VStack(spacing: 8) {
                                Text("\(score)")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.green)
                                
                                Text("Correct")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(spacing: 8) {
                                Text("\(total - score)")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.red)
                                
                                Text("Wrong")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(spacing: 8) {
                                Text("\(total)")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.8))
                                
                                Text("Total")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(32)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 32)
                    
                    // Pass/Fail message
                    VStack(spacing: 12) {
                        if passed {
                            Text("Congratulations! 🎓")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.green)
                            
                            Text("You've passed the mock exam with flying colors!")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Keep Studying! 📚")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("You need 75% or higher to pass. Review the material and try again!")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Wrong questions count
                    if !wrongQuestions.isEmpty {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                
                                Text("Review \(wrongQuestions.count) incorrect answer\(wrongQuestions.count == 1 ? "" : "s")")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    // Done button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(red: 0.0, green: 0.4, blue: 0.8))
                            .cornerRadius(16)
                            .shadow(color: Color(red: 0.0, green: 0.4, blue: 0.8).opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview

struct ScoreReportView_Previews: PreviewProvider {
    static var previews: some View {
        ScoreReportView(
            score: 24,
            total: 30,
            wrongQuestions: []
        )
    }
}

