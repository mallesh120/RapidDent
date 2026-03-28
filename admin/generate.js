#!/usr/bin/env node
/**
 * RapidDent Data Pipeline — generate.js
 *
 * Reads Scenarios and Questions from their respective TSV files,
 * generates clinical images via Gemini API (free tier),
 * uploads images to Firebase Storage, and writes everything to Firestore.
 *
 * Usage:
 *   node admin/generate.js                  # full run (all scenarios & questions)
 *   node admin/generate.js --dry-run        # preview without writing to Firestore
 *   node admin/generate.js --skip-images    # skip image generation/upload
 */
require('dotenv').config({ path: __dirname + '/.env' });

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// ─── Config ──────────────────────────────────────────────────────────────────
const SCENARIOS_TSV = path.join(__dirname, '..', 'Scenarios - Scenarios.tsv');
const QUESTIONS_TSV = path.join(__dirname, '..', 'Scenarios - Questions.tsv');
const SERVICE_ACCOUNT = path.join(__dirname, 'serviceAccountKey.json');

const DRY_RUN = process.argv.includes('--dry-run');
const SKIP_IMAGES = process.argv.includes('--skip-images');
const FIRESTORE_BATCH_SIZE = 450; // Firestore max is 500

// ─── Gemini AI Client ─────────────────────────────────────────────────────────
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// ─── Firebase Init ────────────────────────────────────────────────────────────
const serviceAccount = require(SERVICE_ACCOUNT);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: `${serviceAccount.project_id}.firebasestorage.app`,
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

// ─── Utilities ────────────────────────────────────────────────────────────────

/** Parse a TSV string into an array of objects keyed by header row */
function parseTSV(raw) {
  const lines = raw.replace(/\r/g, '').split('\n').filter(l => l.trim());
  // Find all header rows (lines that start with expected column name)
  let headerLine = null;
  const dataLines = [];

  for (const line of lines) {
    const cols = line.split('\t');
    // Detect header rows (two possible headers in the questions file)
    if (cols[0] === 'question_id' || cols[0] === 'scenario_id') {
      headerLine = cols.map(h => h.trim());
    } else if (headerLine) {
      if (cols.length >= 3 && cols[0].trim()) {
        dataLines.push(cols);
      }
    }
  }

  if (!headerLine) throw new Error('No header row found in TSV');

  return dataLines.map(cols => {
    const obj = {};
    headerLine.forEach((key, i) => {
      obj[key] = (cols[i] || '').trim();
    });
    return obj;
  });
}

/** Parse multi-section TSV where header can repeat (questions file has 2 sheets) */
function parseMultiSectionTSV(raw) {
  const lines = raw.replace(/\r/g, '').split('\n').filter(l => l.trim());
  const results = [];
  let headerLine = null;

  for (const line of lines) {
    const cols = line.split('\t');
    const firstCol = cols[0].trim();

    // Detect header row
    if (firstCol === 'question_id') {
      headerLine = cols.map(h => h.trim());
      continue;
    }

    if (!headerLine) continue;

    // Skip blank or malformed rows
    if (!firstCol || cols.length < 3) continue;

    const obj = {};
    headerLine.forEach((key, i) => {
      obj[key] = (cols[i] || '').trim();
    });
    results.push(obj);
  }

  return results;
}

/** Generate a clinical image using Gemini API and return a Buffer */
async function generateImageWithGemini(scenario) {
  const searchHint = (scenario['.'] || '').startsWith('SEARCH:')
    ? scenario['.'].replace('SEARCH:', '').trim()
    : '';

  const prompt = searchHint
    ? `Professional dental/medical clinical photograph showing: ${searchHint}. ` +
      `Educational medical image, clean background, high quality, realistic.`
    : `Professional dental clinical photograph. ` +
      `Patient: ${scenario.patient_age} year old ${scenario.patient_gender}. ` +
      `Chief complaint: ${scenario.chief_complaint}. ` +
      `Showing: ${scenario.clinical_notes.slice(0, 150)}. ` +
      `Educational medical image, clean background, high quality, realistic.`;

  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-image' });

  const result = await model.generateContent({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    generationConfig: { responseModalities: ['IMAGE', 'TEXT'] },
  });

  const parts = result.response.candidates?.[0]?.content?.parts || [];
  for (const part of parts) {
    if (part.inlineData?.mimeType?.startsWith('image/')) {
      return {
        buffer: Buffer.from(part.inlineData.data, 'base64'),
        mimeType: part.inlineData.mimeType,
      };
    }
  }
  return null;
}

/** Upload image Buffer to Firebase Storage and return public download URL */
async function uploadImageToStorage(imageBuffer, scenarioId, contentType = 'image/jpeg') {
  const ext = contentType.includes('png') ? 'png' : 'jpg';
  const filePath = `scenario_images/${scenarioId}.${ext}`;
  const file = bucket.file(filePath);

  await file.save(imageBuffer, {
    metadata: { contentType },
    public: true,
  });

  // Return public URL
  return `https://storage.googleapis.com/${bucket.name}/${filePath}`;
}

/** Generate and upload image for a scenario, return the storage URL */
async function getOrGenerateImage(scenario) {
  if (SKIP_IMAGES) return null;

  const scenarioId = scenario.scenario_id;
  console.log(`  📸 Generating image for ${scenarioId}...`);

  try {
    const result = await generateImageWithGemini(scenario);

    if (!result) {
      console.warn(`  ⚠️  No image returned for ${scenarioId}, skipping.`);
      return null;
    }

    const url = await uploadImageToStorage(result.buffer, scenarioId, result.mimeType);
    console.log(`  ✅ Image uploaded for ${scenarioId}: ${url}`);
    return url;
  } catch (err) {
    console.warn(`  ⚠️  Failed to generate/upload image for ${scenarioId}: ${err.message}`);
    return null;
  }
}

/** Commit a batch and return a new one */
async function commitBatch(batch, count) {
  console.log(`\n💾 Committing batch of ${count} documents...`);
  await batch.commit();
  console.log(`✅ Batch committed.`);
  return db.batch();
}

// ─── Main Pipeline ─────────────────────────────────────────────────────────────

async function main() {
  console.log('🦷 RapidDent Data Pipeline\n');
  console.log(`Mode: ${DRY_RUN ? 'DRY RUN (no writes)' : 'LIVE'}`);
  console.log(`Images: ${SKIP_IMAGES ? 'SKIPPED' : 'ENABLED (Pollinations.ai)'}\n`);

  // ── 1. Parse TSV files ──────────────────────────────────────────────────────
  console.log('📂 Reading TSV files...');
  const scenariosRaw = fs.readFileSync(SCENARIOS_TSV, 'utf8');
  const questionsRaw = fs.readFileSync(QUESTIONS_TSV, 'utf8');

  const scenarioRows = parseTSV(scenariosRaw);
  const questionRows = parseMultiSectionTSV(questionsRaw);

  console.log(`  Found ${scenarioRows.length} scenarios`);
  console.log(`  Found ${questionRows.length} questions\n`);

  // ── 2. Process Scenarios ────────────────────────────────────────────────────
  console.log('🏥 Processing scenarios...');

  const processedScenarios = [];
  for (const row of scenarioRows) {
    const scenarioId = row.scenario_id;
    if (!scenarioId) continue;

    let mediaUrl = null;
    if (!DRY_RUN) {
      mediaUrl = await getOrGenerateImage(row);
    }

    // Parse med_history, medications, allergies as arrays
    const toArray = (str) => {
      if (!str || str === 'None' || str === 'NKDA' || str === 'N/A' || str === '-') return [];
      return str.split(/[,;]/).map(s => s.trim()).filter(Boolean);
    };

    const scenarioDoc = {
      patient_profile: {
        age: isNaN(parseInt(row.patient_age)) ? row.patient_age : parseInt(row.patient_age),
        gender: row.patient_gender || 'Unknown',
        chief_complaint: row.chief_complaint || '',
        med_history: toArray(row.med_history),
        medications: toArray(row.medications),
        allergies: toArray(row.allergies),
        vitals: row.vitals || '',
      },
      clinical_notes: row.clinical_notes || '',
      ...(mediaUrl && { media_url: mediaUrl }),
    };

    processedScenarios.push({ id: scenarioId, data: scenarioDoc });

    if (DRY_RUN) {
      console.log(`  [DRY RUN] Would write scenario: ${scenarioId}`);
    }
  }

  // ── 3. Process Questions ────────────────────────────────────────────────────
  console.log('\n❓ Processing questions...');

  const processedQuestions = [];
  for (const row of questionRows) {
    const questionId = row.question_id;
    if (!questionId) continue;

    // Normalize correct_option: some rows use "Option_A", some use "A" or "B"
    let correctOpt = row.correct_option || '';
    // Normalize to single letter format: "Option_A" -> "A", "B" -> "B"
    correctOpt = correctOpt.replace(/^Option_/, '').toUpperCase();
    if (!['A', 'B', 'C', 'D'].includes(correctOpt)) correctOpt = 'A';

    // Build options array in the format expected by Firestore/Swift
    const options = [];
    const optLabels = ['A', 'B', 'C', 'D'];
    optLabels.forEach(label => {
      const text = row[`option_${label}`];
      if (text && text.trim()) {
        options.push({
          id: label,
          text: text.trim(),
          is_correct: label === correctOpt,
        });
      }
    });

    // Parse tags
    const tags = (row.tags || '').split(/[,;]/).map(t => t.trim()).filter(Boolean);

    const questionDoc = {
      question_text: row.question_text || '',
      type: row.type || 'RAPID_FIRE',
      category: row.category || '',
      explanation: row.explanation || '',
      correct_option: correctOpt,
      options,
      tags,
      ...(row.scenario_id && { scenario_id: row.scenario_id }),
      ...(row.image_url && row.image_url.startsWith('http') && { image_url: row.image_url }),
    };

    processedQuestions.push({ id: questionId, data: questionDoc });

    if (DRY_RUN) {
      console.log(`  [DRY RUN] Would write question: ${questionId} (${row.type})`);
    }
  }

  console.log(`\n📊 Summary:`);
  console.log(`  Scenarios ready: ${processedScenarios.length}`);
  console.log(`  Questions ready: ${processedQuestions.length}`);

  if (DRY_RUN) {
    console.log('\n⚠️  DRY RUN — no data was written to Firestore.');
    return;
  }

  // ── 4. Write to Firestore in batches ─────────────────────────────────────────
  console.log('\n🔥 Writing to Firestore...');
  let batch = db.batch();
  let batchCount = 0;
  let totalWritten = 0;

  for (const { id, data } of processedScenarios) {
    batch.set(db.collection('scenarios').doc(id), data);
    batchCount++;
    if (batchCount >= FIRESTORE_BATCH_SIZE) {
      batch = await commitBatch(batch, batchCount);
      totalWritten += batchCount;
      batchCount = 0;
    }
  }

  for (const { id, data } of processedQuestions) {
    batch.set(db.collection('questions').doc(id), data);
    batchCount++;
    if (batchCount >= FIRESTORE_BATCH_SIZE) {
      batch = await commitBatch(batch, batchCount);
      totalWritten += batchCount;
      batchCount = 0;
    }
  }

  // Commit remaining docs
  if (batchCount > 0) {
    batch = await commitBatch(batch, batchCount);
    totalWritten += batchCount;
  }

  console.log(`\n🎉 Done! ${totalWritten} documents written to Firestore.`);
  console.log(`   Scenarios collection: ${processedScenarios.length} docs`);
  console.log(`   Questions collection: ${processedQuestions.length} docs`);
}

main().catch(err => {
  console.error('\n❌ Fatal error:', err);
  process.exit(1);
});
