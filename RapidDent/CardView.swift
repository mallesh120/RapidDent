//
//  CardView.swift
//  Dental Rapid Fire
//
//  Swipeable card component for displaying questions
//

import SwiftUI

struct CardView: View {
    let question: Question
    let onSwipe: (Bool) -> Void  // true = right swipe (True), false = left swipe (False)
    
    @State private var offset = CGSize.zero
    @State private var color: Color = .white
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(color)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor, lineWidth: 3)
                )
            
            VStack(spacing: 24) {
                // Question number badge
                HStack {
                    Spacer()
                }
                
                Spacer()
                
                // Question text
                Text(question.questionText)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(8)
                
                Spacer()
                
                // Swipe hints
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        // False hint
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("FALSE")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.red.opacity(0.7))
                        
                        Text("|")
                            .foregroundColor(.gray.opacity(0.5))
                        
                        // True hint
                        HStack(spacing: 8) {
                            Text("TRUE")
                                .font(.system(size: 14, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.green.opacity(0.7))
                    }
                    
                    Text("Swipe to answer")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 32)
            }
            
            // Swipe overlay indicators
            if abs(offset.width) > 50 {
                VStack {
                    HStack {
                        if offset.width < 0 {
                            // FALSE indicator
                            Text("FALSE")
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .rotationEffect(.degrees(-15))
                                .padding(.leading, 40)
                            Spacer()
                        } else {
                            Spacer()
                            // TRUE indicator
                            Text("TRUE")
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.green)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .rotationEffect(.degrees(15))
                                .padding(.trailing, 40)
                        }
                    }
                    .padding(.top, 60)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    
                    // Change color based on drag direction
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if gesture.translation.width < 0 {
                            color = .red.opacity(0.1)
                        } else if gesture.translation.width > 0 {
                            color = .green.opacity(0.1)
                        } else {
                            color = .white
                        }
                    }
                }
                .onEnded { _ in
                    // Determine swipe direction
                    if offset.width > 100 {
                        // Swiped right (True)
                        swipeRight()
                    } else if offset.width < -100 {
                        // Swiped left (False)
                        swipeLeft()
                    } else {
                        // Not enough swipe - reset
                        withAnimation(.spring()) {
                            offset = .zero
                            color = .white
                        }
                    }
                }
        )
    }
    
    private var borderColor: Color {
        if offset.width > 50 {
            return .green.opacity(0.5)
        } else if offset.width < -50 {
            return .red.opacity(0.5)
        }
        return .gray.opacity(0.2)
    }
    
    private func swipeRight() {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: 500, height: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwipe(true)  // User answered True
        }
    }
    
    private func swipeLeft() {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: -500, height: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwipe(false)  // User answered False
        }
    }
}
