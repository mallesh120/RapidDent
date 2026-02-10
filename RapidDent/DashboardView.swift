//
//  DashboardView.swift
//  RapidDent
//
//  Dashboard to view progress statistics and manage user data
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject private var progressManager = ProgressManager.shared
    @State private var showResetConfirmation = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.rdBrand)
                    
                    Text("Progress Dashboard")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.rdBrand)
                    
                    Text("Track your study progress")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Stats Cards
                VStack(spacing: 20) {
                    // Correct Answers – tappable to review
                    NavigationLink(destination: CorrectAnswersView()) {
                        StatCard(
                            icon: "checkmark.circle.fill",
                            title: "Correct",
                            value: "\(progressManager.questionsCorrect)",
                            color: .green,
                            accentColor: .rdSuccess,
                            showChevron: true
                        )
                    }
                    .disabled(progressManager.correctIDs.isEmpty)
                    .opacity(progressManager.correctIDs.isEmpty ? 0.5 : 1.0)
                    
                    // Questions Needing Review (wrapped in NavigationLink)
                    NavigationLink(destination: ContentView(reviewMode: true)) {
                        StatCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "Needs Review",
                            value: "\(progressManager.questionsNeedingReview)",
                            color: .orange,
                            accentColor: .rdWarning,
                            showChevron: true
                        )
                    }
                    .disabled(progressManager.wrongIDs.isEmpty)
                    .opacity(progressManager.wrongIDs.isEmpty ? 0.5 : 1.0)
                    
                    // Mock Exam Button
                    NavigationLink(destination: ExamView()) {
                        HStack(spacing: 20) {
                            // Icon
                            Image(systemName: "timer")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.rdExam)
                                .cornerRadius(16)
                            
                            // Content
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Mock Exam 📝")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("30 questions • 15 minutes")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            // Arrow
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.rdExam)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.rdExam.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Reset Progress Button
                Button(action: {
                    showResetConfirmation = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 20))
                        
                        Text("Reset Progress")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(12)
                    .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .appBackground()
        .navigationBarTitle("Dashboard", displayMode: .inline)
        .alert("Reset Progress?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                progressManager.resetProgress()
            }
        } message: {
            Text("This will clear all your progress data. This action cannot be undone.")
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let accentColor: Color
    var showChevron: Bool = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(accentColor)
                .cornerRadius(16)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(accentColor)
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accentColor.opacity(0.6))
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DashboardView()
        }
    }
}

