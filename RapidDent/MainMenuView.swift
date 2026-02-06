//
//  MainMenuView.swift
//  RapidDent
//
//  Main menu for selecting study mode
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationStack {
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
                
                VStack(spacing: 40) {
                    // App Title
                    VStack(spacing: 12) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.rdBrand)
                        
                        Text("RapidDent")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.rdBrand)
                        
                        Text("INBDE Study Companion")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("RapidDent, INBDE Study Companion")
                    
                    Spacer()
                    
                    // Mode Selection Cards
                    VStack(spacing: 24) {
                        // Rapid Fire Mode
                        NavigationLink(destination: ContentView()) {
                            ModeCard(
                                icon: "flame.fill",
                                title: "Rapid Fire 🔥",
                                description: "Swipe True/False questions for quick review",
                                color: .orange,
                                accentColor: Color(red: 1.0, green: 0.4, blue: 0.0)
                            )
                        }
                        .accessibilityLabel("Rapid Fire mode. Swipe True or False questions for quick review")
                        
                        // Clinical Scenarios Mode
                        NavigationLink(destination: ScenarioRunnerView()) {
                            ModeCard(
                                icon: "stethoscope",
                                title: "Clinical Scenarios 🏥",
                                description: "Patient cases with multiple choice questions",
                                color: .blue,
                                accentColor: .rdBrand
                            )
                        }
                        .accessibilityLabel("Clinical Scenarios mode. Patient cases with multiple choice questions")
                        
                        // Dashboard
                        NavigationLink(destination: DashboardView()) {
                            ModeCard(
                                icon: "chart.bar.fill",
                                title: "Dashboard 📊",
                                description: "Track your progress and review statistics",
                                color: .green,
                                accentColor: .rdSuccess
                            )
                        }
                        .accessibilityLabel("Dashboard. Track your progress and review statistics")
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    // Footer
                    Text("Choose your study mode")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.bottom, 40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Mode Card Component

struct ModeCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(
                    Circle()
                        .fill(accentColor)
                )
            
            // Text Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(accentColor)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: accentColor.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Preview

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}

