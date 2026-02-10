//
//  PatientBoxView.swift
//  RapidDent
//
//  Patient information display component
//

import SwiftUI

struct PatientBoxView: View {
    let scenario: Scenario
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Tappable header – always visible
            Button(action: { withAnimation(.spring(response: 0.35)) { isExpanded.toggle() } }) {
                HStack(spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.rdBrand)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scenario.patientName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(scenario.age) yo · \(scenario.gender) · \(scenario.chiefComplaint)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(uiColor: .systemGray6))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Patient info: \(scenario.patientName). Tap to \(isExpanded ? "collapse" : "expand")")
            
            // Expandable detail content (no inner scroll – parent controls scroll)
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 14) {
                    // Clinical Image (if available)
                    if let mediaUrl = scenario.mediaUrl, !mediaUrl.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.fill")
                                    .foregroundColor(.cyan)
                                    .font(.system(size: 14))
                                Text("Clinical Image")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            let imageUrl = convertGoogleDriveUrl(mediaUrl)
                            
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    HStack(spacing: 8) {
                                        ProgressView()
                                        Text("Loading image...")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 120)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity, maxHeight: 180)
                                        .cornerRadius(10)
                                case .failure:
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo.badge.exclamationmark")
                                            .foregroundColor(.orange)
                                        Text("Image unavailable")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 60)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(10)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    
                    InfoSection(title: "Chief Complaint", content: scenario.chiefComplaint, icon: "text.bubble.fill", color: .red)
                    InfoSection(title: "Vital Signs", content: scenario.vitalSigns, icon: "waveform.path.ecg", color: .orange)
                    InfoSection(title: "Medical History", content: scenario.medicalHistory, icon: "cross.case.fill", color: .blue)
                    InfoSection(title: "Medications", content: scenario.medications, icon: "pills.fill", color: .green)
                    InfoSection(title: "Allergies", content: scenario.allergies, icon: "exclamationmark.triangle.fill", color: .yellow)
                    InfoSection(title: "Clinical Findings", content: scenario.clinicalFindings, icon: "stethoscope", color: .purple)
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
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

