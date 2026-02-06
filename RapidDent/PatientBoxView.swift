//
//  PatientBoxView.swift
//  RapidDent
//
//  Patient information display component
//

import SwiftUI

struct PatientBoxView: View {
    let scenario: Scenario
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with patient name and demographics
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.patientName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Label("\(scenario.age) yo", systemImage: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Label(scenario.gender, systemImage: scenario.gender.lowercased() == "male" ? "person.fill" : "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.rdBrand)
            }
            .padding(16)
            .background(Color(uiColor: .systemGray6))
            
            Divider()
            
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Clinical Image (if available)
                    if let mediaUrl = scenario.mediaUrl, !mediaUrl.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.fill")
                                    .foregroundColor(.cyan)
                                Text("Clinical Image")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            let imageUrl = convertGoogleDriveUrl(mediaUrl)
                            
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Text("Loading image...")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 200)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                case .failure(let error):
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.badge.exclamationmark")
                                            .font(.system(size: 40))
                                            .foregroundColor(.orange)
                                        Text("Failed to load image")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        Text(error.localizedDescription)
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                        Text("URL: \(imageUrl)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                            .padding(.horizontal)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 200)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal, 8)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    
                    // Chief Complaint
                    InfoSection(
                        title: "Chief Complaint",
                        content: scenario.chiefComplaint,
                        icon: "text.bubble.fill",
                        color: .red
                    )
                    
                    // Vital Signs
                    InfoSection(
                        title: "Vital Signs",
                        content: scenario.vitalSigns,
                        icon: "waveform.path.ecg",
                        color: .orange
                    )
                    
                    // Medical History
                    InfoSection(
                        title: "Medical History",
                        content: scenario.medicalHistory,
                        icon: "cross.case.fill",
                        color: .blue
                    )
                    
                    // Medications
                    InfoSection(
                        title: "Medications",
                        content: scenario.medications,
                        icon: "pills.fill",
                        color: .green
                    )
                    
                    // Allergies
                    InfoSection(
                        title: "Allergies",
                        content: scenario.allergies,
                        icon: "exclamationmark.triangle.fill",
                        color: .yellow
                    )
                    
                    // Clinical Findings
                    InfoSection(
                        title: "Clinical Findings",
                        content: scenario.clinicalFindings,
                        icon: "stethoscope",
                        color: .purple
                    )
                }
                .padding(16)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Helper Functions

func convertGoogleDriveUrl(_ url: String) -> String {
    // Convert Google Drive share URLs to direct download URLs
    if url.contains("drive.google.com") {
        // Extract file ID from various Google Drive URL formats
        if let fileId = extractGoogleDriveFileId(from: url) {
            // Use thumbnail API for reliable image loading
            return "https://drive.google.com/thumbnail?id=\(fileId)&sz=w1000"
        }
    }
    return url
}

func extractGoogleDriveFileId(from url: String) -> String? {
    // Pattern 1: /d/{fileId}/
    if let range = url.range(of: "/d/([^/]+)", options: .regularExpression) {
        let match = String(url[range])
        return match.replacingOccurrences(of: "/d/", with: "").replacingOccurrences(of: "/", with: "")
    }
    
    // Pattern 2: id={fileId} or ?id={fileId}
    if let range = url.range(of: "id=([^&]+)", options: .regularExpression) {
        let match = String(url[range])
        return match.replacingOccurrences(of: "id=", with: "")
    }
    
    return nil
}

// MARK: - Info Section Component

struct InfoSection: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

