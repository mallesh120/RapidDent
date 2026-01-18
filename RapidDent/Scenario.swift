//
//  Scenario.swift
//  DentalExamPrep
//
//  Data model for clinical scenarios from Firestore
//

import Foundation
import FirebaseFirestore

struct Scenario: Identifiable {
    let id: String
    let patientName: String
    let age: Int
    let gender: String
    let chiefComplaint: String
    let medicalHistory: String
    let medications: String
    let allergies: String
    let clinicalFindings: String
    let vitalSigns: String
    let mediaUrl: String?
    
    // Custom initializer to parse Firestore document
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        // Parse patient_profile map
        guard let patientProfile = data["patient_profile"] as? [String: Any] else {
            print("❌ Missing patient_profile in scenario document: \(document.documentID)")
            return nil
        }
        
        // Extract fields from patient_profile
        guard let age = patientProfile["age"] as? Int,
              let gender = patientProfile["gender"] as? String,
              let chiefComplaint = patientProfile["chief_complaint"] as? String else {
            print("❌ Missing required fields in patient_profile: \(document.documentID)")
            return nil
        }
        
        // Extract clinical notes
        guard let clinicalNotes = data["clinical_notes"] as? String else {
            print("❌ Missing clinical_notes in scenario document: \(document.documentID)")
            return nil
        }
        
        // Extract vitals - check both patient_profile and root level
        var vitals: String?
        if let vitalsInProfile = patientProfile["vitals"] as? String {
            vitals = vitalsInProfile
        } else if let vitalsInRoot = data["vitals"] as? String {
            vitals = vitalsInRoot
        }
        
        guard let finalVitals = vitals else {
            print("❌ Missing vitals in scenario document: \(document.documentID)")
            return nil
        }
        
        // Parse optional and array fields
        let medHistoryArray = patientProfile["med_history"] as? [String] ?? []
        let medicationsArray = patientProfile["medications"] as? [String] ?? []
        let allergiesArray = patientProfile["allergies"] as? [String] ?? []
        
        self.id = document.documentID
        self.patientName = "Patient" // Default since not in Firestore
        self.age = age
        self.gender = gender
        self.chiefComplaint = chiefComplaint
        self.medicalHistory = medHistoryArray.isEmpty ? "None" : medHistoryArray.joined(separator: "\n")
        self.medications = medicationsArray.isEmpty ? "None" : medicationsArray.joined(separator: ", ")
        self.allergies = allergiesArray.isEmpty ? "None" : allergiesArray.joined(separator: ", ")
        self.clinicalFindings = clinicalNotes
        self.vitalSigns = finalVitals
        self.mediaUrl = data["media_url"] as? String
        
        print("✅ Successfully parsed scenario: \(self.id)")
    }
}
