const admin = require('firebase-admin');
const fs = require('fs');
const yaml = require('js-yaml');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadData() {
  try {
    // Read and parse YAML
    const fileContents = fs.readFileSync(path.join(__dirname, 'data.yaml'), 'utf8');
    const data = yaml.load(fileContents);

    const batch = db.batch();
    let count = 0;

    // Process Scenarios
    if (data.scenarios && Array.isArray(data.scenarios)) {
      data.scenarios.forEach(scenario => {
        const docRef = db.collection('scenarios').doc(scenario.id);
        
        // Construct the Firestore document format expected by Scenario.swift
        const docData = {
          patient_profile: {
            age: scenario.patient_profile.age || 0,
            gender: scenario.patient_profile.gender || "Unknown",
            chief_complaint: scenario.patient_profile.chief_complaint || "",
            med_history: scenario.patient_profile.med_history || [],
            medications: scenario.patient_profile.medications || [],
            allergies: scenario.patient_profile.allergies || [],
            vitals: scenario.patient_profile.vitals || scenario.vitals || ""
          },
          clinical_notes: scenario.clinical_notes || "",
          media_url: scenario.media_url || null
        };

        batch.set(docRef, docData);
        count++;
        console.log(`Prepared scenario: ${scenario.id}`);
      });
    }

    // Process Questions
    if (data.questions && Array.isArray(data.questions)) {
      data.questions.forEach(question => {
        const docRef = db.collection('questions').doc(question.id);
        
        // Find correct option from options array if not explicitly set
        let correctOpt = question.correct_option;
        if (!correctOpt && question.options) {
            const correctObj = question.options.find(opt => opt.is_correct);
            if (correctObj) correctOpt = correctObj.id;
        }

        const docData = {
          question_text: question.question_text || "",
          type: question.type || "RAPID_FIRE",
          explanation: question.explanation || "",
          scenario_id: question.scenario_id || null,
          image_url: question.image_url || null,
          options: question.options || [],
          correct_option: correctOpt || "A"
        };

        // Remove null fields
        if (docData.scenario_id === null) delete docData.scenario_id;
        if (docData.image_url === null) delete docData.image_url;

        batch.set(docRef, docData);
        count++;
        console.log(`Prepared question: ${question.id}`);
      });
    }

    if (count > 0) {
      console.log(`\nCommiting ${count} documents to Firestore...`);
      await batch.commit();
      console.log('✅ Successfully uploaded everything!');
    } else {
      console.log('No scenarios or questions found in data.yaml.');
    }

  } catch (error) {
    console.error('Error uploading data:', error);
  }
}

// Run the script
uploadData();
