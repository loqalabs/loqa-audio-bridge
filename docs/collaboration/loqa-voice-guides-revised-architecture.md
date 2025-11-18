# Loqa-Voiceline Voice Guides: Revised Hybrid Architecture

**Date:** November 7, 2025
**From:** Loqa Architecture Team (Winston)
**To:** Voiceline Team (Anna / Mary)
**Subject:** Voice Guides - Mobile-First Architecture (Revised)
**Version:** 2.0 (Replaces backend-heavy approach)

---

## 🎯 Executive Summary

**Architecture Shift:** After technical alignment discussion, we're moving from a **backend-heavy** to a **mobile-first** approach.

**Key Change:**
- ❌ **OLD:** Mobile records audio → Sends to Loqa → Waits for analysis
- ✅ **NEW:** Mobile performs all core analysis on-device → Optionally requests LLM enhancement from Loqa

**Benefits:**
- ✅ **Offline capability:** Full voice analysis works without Loqa server
- ✅ **Real-time feedback:** <100ms latency for visual feedback (voice flowers)
- ✅ **Privacy-first:** Core analysis never leaves mobile device
- ✅ **Optional enhancement:** LLM-powered narratives when user wants personalization
- ✅ **Simpler integration:** Voiceline team owns most features, minimal backend dependency

---

## 🏗️ Revised Architecture

```
┌─────────────────────────────────────────────────────────────┐
│   📱 Voiceline Mobile App (React Native)                    │
│   ─────────────────────────────────────────────────────────│
│                                                             │
│   CORE VOICE ANALYSIS (ON-DEVICE):                         │
│   ├── Audio Recording & Streaming                          │
│   ├── Pitch Detection (YIN algorithm)                      │
│   ├── Formant Extraction (LPC)                             │
│   ├── Intonation Classification (Rule-based: 4 patterns)   │
│   ├── Progress Comparison (Proximity-based)                │
│   ├── Resonance Analysis (Comparative formant distance)    │
│   ├── Voice Guide Database (JSON, local storage)           │
│   ├── Session History (SQLite, local storage)              │
│   └── Real-Time Visual Feedback (Voice Flowers)            │
│                                                             │
│   DISPLAY & UX:                                             │
│   ├── Journey Visualization (baseline → current → guide)   │
│   ├── Progress Metrics (pitch, intonation, resonance)      │
│   ├── Template-Based Narratives (offline fallback)         │
│   └── Practice Session Results                             │
│                                                             │
└──────────────┬──────────────────────────────────────────────┘
               │
               │ OPTIONAL: HTTP POST /voice/llm-enhancement
               │ (User taps "Get Personalized Coaching")
               │
┌──────────────▼──────────────────────────────────────────────┐
│   🖥️ Loqa Voice Intelligence Backend (Rust)                 │
│   ─────────────────────────────────────────────────────────│
│                                                             │
│   LLM-POWERED ENHANCEMENTS (OPTIONAL):                     │
│   ├── Trauma-Informed Narrative Generation (Llama 3.2 3B)  │
│   ├── Adaptive Coaching Suggestions (LLM-generated)        │
│   ├── Practice Prompts (Personalized)                      │
│   ├── Weekly Listening Recommendations (Guide-specific)    │
│   └── Exploration Themes (Adaptive to progress)            │
│                                                             │
│   VALIDATION & SAFETY:                                      │
│   ├── Forbidden Phrase Filter (trauma-informed)            │
│   ├── LLM Output Validation                                │
│   └── Template Fallback (if LLM fails)                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
               │
               └─→ Response: { narrative, coachingSuggestions }
```

---

## 📊 Responsibility Matrix

| Feature | Mobile (On-Device) | Loqa Backend | Rationale |
|---------|-------------------|--------------|-----------|
| **Audio Recording** | ✅ Owner | ❌ Not involved | Real-time streaming required |
| **Pitch Detection (YIN)** | ✅ Owner | ❌ Not involved | Lightweight, no ML, needed for voice flowers |
| **Formant Extraction (LPC)** | ✅ Owner | ❌ Not involved | Lightweight, no ML, <10ms processing |
| **Intonation Classification** | ✅ Owner | ❌ Not involved | Rule-based, pure logic, no ML |
| **Resonance Analysis** | ✅ Owner | ❌ Not involved | Comparative (formant distance), pure math |
| **Progress Comparison** | ✅ Owner | ❌ Not involved | Proximity-based, pure math |
| **Voice Guide Database** | ✅ Owner | ❌ Not involved | JSON files, local storage |
| **Session History** | ✅ Owner | ❌ Not involved | SQLite, local storage |
| **Visual Feedback (Voice Flowers)** | ✅ Owner | ❌ Not involved | Real-time, <100ms latency required |
| **Template-Based Narratives** | ✅ Owner (fallback) | ✅ LLM upgrade | Mobile has templates, Loqa adds variety |
| **Trauma-Informed Narratives** | ⚠️ Templates | ✅ LLM generation | LLM model too large for mobile (2GB) |
| **Coaching Suggestions** | ⚠️ Basic rules | ✅ LLM generation | LLM creates adaptive, personalized content |
| **Practice Prompts** | ⚠️ Hardcoded | ✅ LLM generation | Variety and personalization via LLM |
| **Listening Recommendations** | ⚠️ Basic selection | ✅ LLM reasoning | LLM explains why recommendation fits progress |

**Legend:**
- ✅ Owner: Responsible for implementation and maintenance
- ⚠️ Basic: Simple implementation, backend adds enhancement
- ❌ Not involved: Not responsible

---

## 🔧 Mobile Implementation Details

### **1. Pitch Detection (YIN Algorithm)**

**Implementation:** On-device, real-time

**Libraries (React Native):**
- **Option A:** Custom YIN implementation (pure JavaScript)
- **Option B:** Native module bridge (C++ YIN → React Native)
- **Option C:** `react-native-audio-toolkit` + DSP library

**Algorithm (JavaScript pseudocode):**
```javascript
// YIN pitch detection (simplified)
function detectPitch(audioBuffer, sampleRate) {
  const threshold = 0.1;
  const yinBuffer = new Array(audioBuffer.length / 2);

  // Step 1: Difference function
  for (let tau = 0; tau < yinBuffer.length; tau++) {
    yinBuffer[tau] = 0;
    for (let i = 0; i < yinBuffer.length; i++) {
      const delta = audioBuffer[i] - audioBuffer[i + tau];
      yinBuffer[tau] += delta * delta;
    }
  }

  // Step 2: Cumulative mean normalized difference
  yinBuffer[0] = 1;
  let runningSum = 0;
  for (let tau = 1; tau < yinBuffer.length; tau++) {
    runningSum += yinBuffer[tau];
    yinBuffer[tau] *= tau / runningSum;
  }

  // Step 3: Absolute threshold
  let tau;
  for (tau = 2; tau < yinBuffer.length; tau++) {
    if (yinBuffer[tau] < threshold) {
      while (tau + 1 < yinBuffer.length && yinBuffer[tau + 1] < yinBuffer[tau]) {
        tau++;
      }
      break;
    }
  }

  // Step 4: Parabolic interpolation
  const betterTau = parabolicInterpolation(yinBuffer, tau);

  // Step 5: Convert to frequency
  return sampleRate / betterTau;
}
```

**Performance Target:** <5ms per 100ms audio frame
**Accuracy Target:** ±5Hz

---

### **2. Formant Extraction (LPC)**

**Implementation:** On-device, post-session

**Algorithm (JavaScript pseudocode):**
```javascript
// LPC formant extraction (simplified)
function extractFormants(audioBuffer, sampleRate) {
  // Step 1: Pre-emphasis filter (boost high frequencies)
  const preEmphasized = preEmphasis(audioBuffer, 0.97);

  // Step 2: Apply Hamming window
  const windowed = applyHammingWindow(preEmphasized);

  // Step 3: Autocorrelation
  const autocorr = autocorrelation(windowed, 12); // 12th order LPC

  // Step 4: Levinson-Durbin algorithm → LPC coefficients
  const lpcCoeffs = levinsonDurbin(autocorr);

  // Step 5: Find formants (peaks in LPC spectrum)
  const formants = findFormantPeaks(lpcCoeffs, sampleRate);

  return {
    f1: formants[0], // First formant (vowel height)
    f2: formants[1], // Second formant (vowel frontness)
    f3: formants[2], // Third formant (optional)
  };
}
```

**Performance Target:** <10ms per analysis window
**Accuracy Target:** ±50Hz for F1/F2

**Libraries:**
- `meyda` (JavaScript audio feature extraction)
- Custom LPC implementation if needed

---

### **3. Intonation Classification (Rule-Based)**

**Implementation:** On-device, real-time or post-session

**Algorithm:**
```javascript
// Classify intonation patterns from pitch contour
function classifyIntonationPatterns(pitchContour, timestamps) {
  const windowSize = 750; // ms
  const patterns = [];

  for (let i = 0; i < pitchContour.length - windowSize; i += windowSize / 2) {
    const window = pitchContour.slice(i, i + windowSize);

    // Calculate statistics
    const slope = calculateLinearSlope(window);
    const variation = calculateStdDev(window);
    const endRising = window[window.length - 1] > window[window.length - 5];

    // Classify pattern
    let patternType;
    if (slope > 15 && variation > 10) {
      patternType = 'rising'; // Question intonation
    } else if (slope < -15 && variation > 10) {
      patternType = 'falling'; // Declarative statement
    } else if (slope > 5 && endRising) {
      patternType = 'statement-upturn'; // Uptalk
    } else {
      patternType = 'flat'; // Monotone
    }

    patterns.push({
      type: patternType,
      confidence: calculateConfidence(slope, variation),
      timestamp: timestamps[i],
    });
  }

  return patterns;
}

// Helper: Calculate confidence based on how clear the pattern is
function calculateConfidence(slope, variation) {
  const slopeStrength = Math.min(Math.abs(slope) / 30, 1.0);
  const variationStrength = Math.min(variation / 20, 1.0);
  return (slopeStrength + variationStrength) / 2;
}
```

**Performance Target:** <5ms per window
**Accuracy Target:** 85% classification accuracy

---

### **4. Progress Comparison (Proximity-Based)**

**Implementation:** On-device, instant calculation

**Algorithm:**
```javascript
// Calculate progress using proximity to guide
function calculateProximityProgress(userCurrent, userBaseline, guideTarget) {
  const baselineToGuideDistance = Math.abs(guideTarget - userBaseline);

  if (baselineToGuideDistance < 1) {
    return { progressPercent: 100, status: 'at-target' };
  }

  const currentToGuideDistance = Math.abs(userCurrent - guideTarget);
  const currentToBaselineDistance = Math.abs(userCurrent - userBaseline);

  // Proximity-based progress
  const progress = ((baselineToGuideDistance - currentToGuideDistance) / baselineToGuideDistance) * 100;

  // Determine status
  let status;
  if (progress >= 95) {
    status = 'aligned';
  } else if (progress >= 50) {
    status = 'emerging';
  } else if (progress >= 10) {
    status = 'exploring';
  } else if (progress < 0) {
    status = 'moving-away'; // User moved away from guide
  } else {
    status = 'just-started';
  }

  return {
    progressPercent: Math.max(0, Math.min(100, Math.round(progress))),
    status: status,
    distanceToGuide: currentToGuideDistance,
    movementFromBaseline: currentToBaselineDistance,
  };
}
```

**Handling Overshoot:**
```javascript
if (progress > 100) {
  return {
    progressPercent: 100,
    status: 'aligned-and-beyond',
    message: "You've reached and are exploring beyond the guide's range!",
  };
}
```

---

### **5. Resonance Analysis (Comparative)**

**Implementation:** On-device, comparative approach

**Algorithm:**
```javascript
// Comparative resonance analysis (no classification labels)
function analyzeResonanceProgress(userFormants, baselineFormants, guideFormants) {
  // Calculate distances
  const baselineToGuide = {
    f1: Math.abs(guideFormants.f1 - baselineFormants.f1),
    f2: Math.abs(guideFormants.f2 - baselineFormants.f2),
  };

  const currentToGuide = {
    f1: Math.abs(guideFormants.f1 - userFormants.f1),
    f2: Math.abs(guideFormants.f2 - userFormants.f2),
  };

  // Progress calculation (same as pitch proximity)
  const f1Progress = baselineToGuide.f1 > 0
    ? ((baselineToGuide.f1 - currentToGuide.f1) / baselineToGuide.f1) * 100
    : 100;

  const f2Progress = baselineToGuide.f2 > 0
    ? ((baselineToGuide.f2 - currentToGuide.f2) / baselineToGuide.f2) * 100
    : 100;

  const overallProgress = (f1Progress + f2Progress) / 2;

  return {
    f1Alignment: Math.max(0, Math.min(100, f1Progress)),
    f2Alignment: Math.max(0, Math.min(100, f2Progress)),
    overallResonanceProgress: Math.max(0, Math.min(100, overallProgress)),

    // Template-based narrative (mobile fallback)
    narrative: generateResonanceNarrative(f1Progress, f2Progress),
  };
}

function generateResonanceNarrative(f1Progress, f2Progress) {
  const avgProgress = (f1Progress + f2Progress) / 2;

  if (avgProgress > 80) {
    return "Your vocal resonance is aligning beautifully with the guide's characteristics";
  } else if (avgProgress > 50) {
    return "Your resonance is moving toward the guide's vocal quality—keep exploring!";
  } else if (avgProgress > 20) {
    return "You're beginning to explore resonance patterns";
  } else {
    return "Starting your resonance exploration journey";
  }
}
```

---

### **6. Voice Guide Database (Local Storage)**

**Implementation:** JSON files in mobile app storage

**Database Structure:**
```javascript
// Voice guide schema (stored locally)
const voiceGuide = {
  id: 'guide_emma_watson',
  displayName: 'Emma Watson',
  type: 'builtin', // or 'custom'

  voiceCharacteristics: {
    pitchRange: {
      mean: 210,
      min: 185,
      max: 245,
      stdev: 18,
    },
    formants: {
      f1: 730,
      f2: 2100,
      f3: 2850,
    },
    notablePatterns: [
      'statement-upturn',
      'expressive-melodic',
      'wide-pitch-range',
    ],
    tempo: 'moderate',
    style: 'expressive-conversational',
  },

  // Media content for listening recommendations
  listeningContent: [
    {
      type: 'podcast',
      title: 'Emma Watson on The High Low',
      url: 'https://...',
      focus: 'Conversational intonation patterns',
      duration: '45min',
    },
    {
      type: 'interview',
      title: 'UN Speech on Gender Equality',
      url: 'https://...',
      focus: 'Formal speech patterns, pitch control',
      duration: '12min',
    },
  ],

  metadata: {
    createdDate: '2025-11-01',
    source: 'Curated by Voiceline team',
    legalClearance: true,
  },
};
```

**Storage (React Native):**
```javascript
import AsyncStorage from '@react-native-async-storage/async-storage';

// Load voice guides
const guides = await AsyncStorage.getItem('voice_guides');
const guideDatabase = JSON.parse(guides);

// Select guide
const selectedGuide = guideDatabase.find(g => g.id === 'guide_emma_watson');
```

---

## 🖥️ Loqa Backend Implementation (LLM Enhancement)

### **Single Endpoint: `POST /voice/llm-enhancement`**

**Purpose:** Generate trauma-informed narrative + coaching suggestions using LLM

**Request:**
```json
{
  "userId": "user_abc123",
  "guideId": "guide_emma_watson",
  "sessionAnalysis": {
    "pitch": {
      "current": 195,
      "baseline": 165,
      "guide": 210,
      "progressPercent": 67,
      "status": "emerging"
    },
    "intonation": {
      "patterns": ["statement-upturn", "rising"],
      "similarity": 0.72,
      "dominantPattern": "statement-upturn"
    },
    "resonance": {
      "f1Alignment": 68,
      "f2Alignment": 71,
      "overallProgress": 69.5
    },
    "sessionNumber": 15,
    "practiceDuration": "12 minutes"
  }
}
```

**Response:**
```json
{
  "traumaInformedNarrative": "Your pitch range is moving beautifully toward the characteristics you chose—67% alignment shows such lovely progress! Statement-upturn patterns are appearing naturally in your voice, which is wonderful to hear.",

  "coachingSuggestions": {
    "practicePrompts": [
      {
        "text": "What do you think about that?",
        "focus": "Question intonation patterns",
        "guidance": "Notice how Emma uses a rising-then-falling melodic pattern on questions. Try exploring that upward lift, then gentle descent."
      },
      {
        "text": "I was thinking we could try something new",
        "focus": "Statement-upturn continuation",
        "guidance": "You're developing statement-upturns beautifully! This sentence lets you practice that gentle rise at the end."
      }
    ],

    "weeklyListening": {
      "type": "podcast",
      "title": "Emma Watson on The High Low",
      "url": "https://...",
      "platform": "Spotify",
      "duration": "45min",
      "focus": "Notice Emma's statement-upturn patterns in casual conversation",
      "reasoning": "You're showing beautiful progress with statement-upturns (appearing in 72% of your patterns). This podcast showcases them in relaxed, natural dialogue—perfect for your current stage!"
    },

    "explorationTheme": {
      "focus": "Intonation expressiveness",
      "description": "This week, explore melodic variation in your voice. You're already developing statement-upturns—now play with wider pitch ranges!",
      "exercises": [
        "Read a favorite paragraph aloud, exaggerating intonation",
        "Record yourself asking questions with varied pitch",
        "Listen to Emma's podcast and echo one sentence's melody"
      ]
    }
  },

  "generatedAt": "2025-11-07T15:30:00Z",
  "llmModel": "llama-3.2-3b-instruct",
  "validationPassed": true
}
```

**Error Response (LLM Failed Validation):**
```json
{
  "traumaInformedNarrative": "Your pitch range is moving toward the characteristics you chose. Keep exploring!",
  "coachingSuggestions": {
    "practicePrompts": [...], // Template-based fallback
    "weeklyListening": {...},
    "explorationTheme": {...}
  },
  "fallbackUsed": true,
  "fallbackReason": "LLM output contained forbidden phrase: '67% similar'",
  "generatedAt": "2025-11-07T15:30:00Z"
}
```

---

### **Backend Implementation (Rust):**

```rust
// Loqa Server - Single LLM enhancement endpoint
use axum::{Json, extract::State};
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct LLMEnhancementRequest {
    user_id: String,
    guide_id: String,
    session_analysis: SessionAnalysis,
}

#[derive(Deserialize)]
pub struct SessionAnalysis {
    pitch: PitchAnalysis,
    intonation: IntonationAnalysis,
    resonance: ResonanceAnalysis,
    session_number: u32,
    practice_duration: String,
}

#[derive(Serialize)]
pub struct LLMEnhancementResponse {
    trauma_informed_narrative: String,
    coaching_suggestions: CoachingSuggestions,
    generated_at: String,
    llm_model: String,
    validation_passed: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    fallback_used: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    fallback_reason: Option<String>,
}

pub async fn llm_enhancement_handler(
    State(llm): State<Arc<TraumaInformedLLM>>,
    Json(req): Json<LLMEnhancementRequest>,
) -> Result<Json<LLMEnhancementResponse>, ApiError> {
    // Load voice guide
    let guide = load_voice_guide(&req.guide_id)?;

    // Generate trauma-informed narrative
    let narrative_result = llm.generate_narrative(
        &req.session_analysis,
        &guide,
    );

    let (narrative, fallback_narrative) = match narrative_result {
        Ok(text) => (text, None),
        Err(e) => {
            tracing::warn!("LLM narrative generation failed: {}", e);
            (generate_fallback_narrative(&req.session_analysis), Some(e.to_string()))
        }
    };

    // Generate coaching suggestions
    let coaching = llm.generate_coaching_suggestions(
        &req.session_analysis,
        &guide,
    ).unwrap_or_else(|e| {
        tracing::warn!("LLM coaching generation failed: {}", e);
        generate_fallback_coaching(&req.session_analysis, &guide)
    });

    Ok(Json(LLMEnhancementResponse {
        trauma_informed_narrative: narrative,
        coaching_suggestions: coaching,
        generated_at: chrono::Utc::now().to_rfc3339(),
        llm_model: "llama-3.2-3b-instruct".to_string(),
        validation_passed: fallback_narrative.is_none(),
        fallback_used: fallback_narrative.as_ref().map(|_| true),
        fallback_reason: fallback_narrative,
    }))
}
```

**LLM Prompt Engineering:**

```rust
impl TraumaInformedLLM {
    fn build_narrative_prompt(&self, analysis: &SessionAnalysis, guide: &VoiceGuide) -> String {
        format!(
            r#"You are a trauma-informed voice coach. Generate an empowering progress update.

USER PROGRESS:
- Pitch: {current}Hz (baseline: {baseline}Hz, guide: {guide_pitch}Hz)
- Progress: {progress}% alignment
- Intonation patterns: {patterns}
- Resonance progress: {resonance}%
- Session #{session_num}, practiced for {duration}

GUIDE: {guide_name}
- Characteristics: {guide_characteristics}

CRITICAL RULES:
1. ALWAYS frame as exploration and growth (NOT evaluation)
2. NEVER compare user to guide ("similar to", "% match")
3. NEVER use negative language ("failed", "below", "worse")
4. ALWAYS use empowering terms ("moving toward", "exploring", "developing")
5. Maximum 2-3 sentences

FORBIDDEN PHRASES:
- "similar to {guide_name}"
- "% match"
- "below target"
- "failed to"
- "you sound like"

Generate uplifting progress narrative (2-3 sentences):"#,
            current = analysis.pitch.current,
            baseline = analysis.pitch.baseline,
            guide_pitch = analysis.pitch.guide,
            progress = analysis.pitch.progress_percent,
            patterns = analysis.intonation.patterns.join(", "),
            resonance = analysis.resonance.overall_progress,
            session_num = analysis.session_number,
            duration = analysis.practice_duration,
            guide_name = guide.display_name,
            guide_characteristics = guide.voice_characteristics.notable_patterns.join(", "),
        )
    }
}
```

---

## 📱 Mobile Integration Example

### **Complete Practice Session Flow:**

```javascript
// React Native - Complete practice session with optional LLM
import { useState, useEffect } from 'react';

function VoiceGuidePracticeSession({ selectedGuide, userBaseline }) {
  const [sessionData, setSessionData] = useState({
    pitchData: [],
    formantData: [],
    intonationPatterns: [],
  });

  const [results, setResults] = useState(null);
  const [llmEnhancement, setLLMEnhancement] = useState(null);

  // Step 1: Real-time audio analysis during recording
  const handleAudioFrame = (audioBuffer) => {
    // On-device pitch detection (real-time)
    const pitch = YINDetector.detect(audioBuffer);

    // Update voice flowers immediately (no lag)
    updateVoiceFlowers(pitch);

    // Accumulate for session analysis
    sessionData.pitchData.push(pitch);
  };

  // Step 2: Post-session analysis (all on-device)
  const analyzeSession = async () => {
    // Extract formants (on-device)
    const formants = extractFormants(sessionData.audioBuffer);

    // Classify intonation patterns (on-device)
    const patterns = classifyIntonationPatterns(sessionData.pitchData);

    // Calculate progress (on-device, instant)
    const pitchProgress = calculateProximityProgress(
      sessionData.pitchData.mean,
      userBaseline.pitch,
      selectedGuide.pitchRange.mean
    );

    const resonanceProgress = analyzeResonanceProgress(
      formants,
      userBaseline.formants,
      selectedGuide.formants
    );

    const results = {
      pitch: pitchProgress,
      intonation: {
        patterns: patterns,
        similarity: calculateIntonationSimilarity(patterns, selectedGuide.notablePatterns),
      },
      resonance: resonanceProgress,

      // Template-based narrative (offline fallback)
      narrative: generateTemplateNarrative(pitchProgress, patterns),
    };

    setResults(results);

    // Display results immediately (no backend wait)
    displayResults(results);
  };

  // Step 3: OPTIONAL - Request LLM enhancement
  const requestLLMEnhancement = async () => {
    try {
      const response = await fetch('http://loqa-server:3000/voice/llm-enhancement', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userId: user.id,
          guideId: selectedGuide.id,
          sessionAnalysis: {
            pitch: results.pitch,
            intonation: results.intonation,
            resonance: results.resonance,
            sessionNumber: user.sessionCount,
            practiceDuration: formatDuration(sessionData.duration),
          },
        }),
      });

      if (response.ok) {
        const enhancement = await response.json();
        setLLMEnhancement(enhancement);

        // Replace template narrative with LLM narrative
        displayLLMEnhancement(enhancement);
      } else {
        // Loqa server offline - keep template narrative
        console.log('LLM enhancement unavailable, using template');
      }
    } catch (error) {
      // Network error - graceful degradation
      console.log('Loqa server offline, continuing with on-device results');
    }
  };

  return (
    <View>
      <VoiceFlowersVisualization pitchData={sessionData.pitchData} />

      {results && (
        <>
          <JourneyVisualization
            baseline={userBaseline}
            current={results}
            guide={selectedGuide}
          />

          <ProgressNarrative text={llmEnhancement?.traumaInformedNarrative || results.narrative} />

          {!llmEnhancement && (
            <Button onPress={requestLLMEnhancement}>
              Get Personalized Coaching Suggestions
            </Button>
          )}

          {llmEnhancement && (
            <CoachingSuggestions suggestions={llmEnhancement.coachingSuggestions} />
          )}
        </>
      )}
    </View>
  );
}
```

---

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ USER PRACTICE SESSION                                       │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ REAL-TIME AUDIO ANALYSIS (On-Device, <100ms)               │
│ • YIN pitch detection                                       │
│ • Voice flowers visualization                               │
│ • Session data accumulation                                 │
└──────────────┬──────────────────────────────────────────────┘
               │ (Session ends)
               ▼
┌─────────────────────────────────────────────────────────────┐
│ POST-SESSION ANALYSIS (On-Device, <500ms)                  │
│ • Formant extraction (LPC)                                  │
│ • Intonation classification                                 │
│ • Progress comparison (pitch, resonance)                    │
│ • Template-based narrative generation                       │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ DISPLAY RESULTS (Offline Mode)                             │
│ • Journey visualization (baseline → current → guide)        │
│ • Progress metrics                                          │
│ • Template narrative                                        │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ USER CHOICE: Request LLM Enhancement?                       │
│ [Get Personalized Coaching] button                          │
└──────────────┬──────────────────────────────────────────────┘
               │ (User taps button)
               ▼
┌─────────────────────────────────────────────────────────────┐
│ LLM ENHANCEMENT REQUEST (Network Call, ~2-3s)              │
│ POST /voice/llm-enhancement                                 │
│ • Send session analysis (already computed)                  │
│ • Wait for LLM-generated content                            │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ DISPLAY LLM ENHANCEMENT                                     │
│ • Replace template narrative with LLM narrative             │
│ • Show personalized coaching suggestions                    │
│ • Display weekly listening recommendation                   │
└─────────────────────────────────────────────────────────────┘
```

---

## ⏱️ Performance Characteristics

### **On-Device Analysis (Mobile):**

| Operation | Latency | Notes |
|-----------|---------|-------|
| Pitch detection (YIN) | <5ms per frame | Real-time capable |
| Voice flowers update | <16ms (60 FPS) | Smooth visualization |
| Formant extraction | <10ms per analysis | Post-session |
| Intonation classification | <5ms per window | Post-session |
| Progress comparison | <1ms | Pure math |
| Template narrative generation | <5ms | String templating |
| **Total on-device analysis** | **<100ms** | User sees results instantly |

### **Backend LLM Enhancement (Optional):**

| Operation | Latency | Notes |
|-----------|---------|-------|
| Network request | ~50-100ms | Local network (WiFi) |
| LLM narrative generation | ~1-2s | Llama 3.2 3B inference |
| LLM coaching generation | ~1-2s | Llama 3.2 3B inference |
| Validation + fallback | ~50ms | If LLM output invalid |
| **Total LLM enhancement** | **~2-3s** | User-initiated, not blocking |

---

## 🔒 Privacy Model

### **Default (Offline Mode):**
- ✅ Audio never leaves mobile device
- ✅ All analysis computed on-device
- ✅ Results displayed without network call
- ✅ Voice guide database stored locally

### **Enhanced (Optional LLM):**
- ⚠️ Session analysis metadata sent to Loqa (NOT raw audio)
- ⚠️ Data sent: Pitch numbers, pattern types, progress percentages
- ⚠️ Data NOT sent: Audio files, voice recordings
- ✅ Network: Local only (mobile ↔ user's laptop, no internet)
- ✅ User choice: Must tap "Get Personalized Coaching" to trigger

**User Privacy Messaging:**
```
Default Mode (Offline):
"Your voice analysis happens entirely on your device. Nothing is sent anywhere."

Enhanced Mode (LLM):
"Tap 'Get Personalized Coaching' to send your progress numbers (not audio) to your Loqa server on your laptop for AI-powered coaching suggestions. Your voice recordings stay on your phone."
```

---

## 🚀 Implementation Timeline

### **Phase 1: Mobile Core Analysis (Voiceline Team) - 2-3 weeks**

| Task | Estimated Time | Owner |
|------|----------------|-------|
| YIN pitch detection integration | 2-3 days | Voiceline (Mobile) |
| LPC formant extraction | 2-3 days | Voiceline (Mobile) |
| Intonation classification (rule-based) | 2-3 days | Voiceline (Mobile) |
| Progress comparison algorithms | 1-2 days | Voiceline (Mobile) |
| Voice guide database (JSON) | 2 days | Voiceline (Mobile) |
| Template-based narratives | 1-2 days | Voiceline (Mobile) |
| UI integration (journey visualization) | 2-3 days | Voiceline (Mobile) |
| **Total** | **12-18 days** | |

### **Phase 2: Loqa LLM Enhancement (Loqa Team) - 1.5-2 weeks**

| Task | Estimated Time | Owner |
|------|----------------|-------|
| LLM narrative generation | 3-4 days | Loqa (Backend) |
| LLM coaching suggestions | 3-4 days | Loqa (Backend) |
| Forbidden phrase validation | 1-2 days | Loqa (Backend) |
| Fallback template system | 1 day | Loqa (Backend) |
| API endpoint implementation | 1-2 days | Loqa (Backend) |
| **Total** | **9-13 days** | |

### **Phase 3: Integration & Testing - 1 week**

| Task | Estimated Time | Owner |
|------|----------------|-------|
| Mobile ↔ Backend integration | 2-3 days | Both teams |
| E2E testing (offline mode) | 1-2 days | Voiceline |
| E2E testing (LLM enhancement) | 1-2 days | Both teams |
| User acceptance testing | 2-3 days | Voiceline |
| **Total** | **6-10 days** | |

**Grand Total:** **27-41 days (4-6 weeks)**

---

## ✅ Success Criteria

### **Mobile-First (Must Work Offline):**
- ✅ User can complete practice session without Loqa server running
- ✅ Voice flowers respond in real-time (<100ms latency)
- ✅ Post-session analysis completes in <500ms
- ✅ Journey visualization displays immediately
- ✅ Template narratives provide positive, trauma-informed feedback

### **LLM Enhancement (Optional, Must Degrade Gracefully):**
- ✅ LLM-generated narratives pass forbidden phrase validation (100% rate)
- ✅ LLM enhancement completes in <3 seconds (P95)
- ✅ Fallback to templates if LLM unavailable (graceful degradation)
- ✅ User understands LLM enhancement is optional (clear UI)

### **Trauma-Informed UX (Critical):**
- ✅ NO evaluation/comparison language in any output (template or LLM)
- ✅ ALL narratives frame progress as exploration
- ✅ Users report feeling empowered, not judged (UAT feedback)

---

## 📋 Next Steps

### **For Voiceline Team:**

1. **Technical Feasibility Check:**
   - ✅ React Native libraries available for YIN/LPC? (or custom implementation needed?)
   - ✅ Mobile team comfortable with DSP algorithms?
   - ✅ Performance testing on target devices (iPhone/Android)?

2. **Voice Guide Curation:**
   - ✅ Select builtin guides (Emma Watson, Zendaya, etc.)
   - ✅ Extract voice characteristics (pitch, formants, patterns)
   - ✅ Curate listening content (podcasts, interviews, films)
   - ✅ Legal clearance for guide usage

3. **Template Creation:**
   - ✅ Write template narratives for all progress stages (aligned, emerging, exploring)
   - ✅ Review with trauma-informed UX expert
   - ✅ Validate no forbidden phrases

4. **Mobile Prototype:**
   - ✅ Build on-device analysis first (without backend)
   - ✅ Validate UX with users
   - ✅ Ensure offline mode works perfectly

### **For Loqa Team:**

1. **LLM Setup:**
   - ✅ Ensure Llama 3.2 3B model available (already in Epic 2C architecture)
   - ✅ Test LLM generation latency on target hardware
   - ✅ Optimize prompt engineering for trauma-informed output

2. **Validation System:**
   - ✅ Implement forbidden phrase filter
   - ✅ Test with diverse inputs (various progress levels)
   - ✅ Create fallback template library

3. **API Implementation:**
   - ✅ Build single `/voice/llm-enhancement` endpoint
   - ✅ Integration testing with mock mobile data
   - ✅ Performance benchmarking (<3s P95 latency)

### **Joint Activities:**

1. **Integration Testing:**
   - Mobile team provides sample session data
   - Loqa team tests LLM generation
   - Validate E2E flow (mobile → backend → mobile)

2. **User Testing:**
   - Test offline mode first (validate core UX)
   - Add LLM enhancement in second round
   - Gather feedback on narrative quality

3. **Documentation:**
   - API contract (request/response schemas)
   - Error handling guide
   - Privacy messaging for users

---

## 🎯 Summary

**Key Architectural Wins:**
1. ✅ **Mobile-first:** Voiceline owns core features, works offline
2. ✅ **Privacy-first:** Most analysis never leaves device
3. ✅ **Optional backend:** LLM adds value without creating dependency
4. ✅ **Simpler integration:** Fewer network calls, faster iteration
5. ✅ **Real-time capable:** Voice flowers respond instantly (<100ms)

**Loqa's Role:**
- LLM-powered personalization (trauma-informed narratives + coaching)
- Validation and safety (forbidden phrase filtering)
- Fallback system (templates when LLM fails)

**Voiceline's Role:**
- Complete on-device voice analysis (pitch, formants, intonation, progress)
- Real-time visual feedback (voice flowers)
- Core UX (journey visualization, results display)
- Offline capability (works without Loqa)

---

**This hybrid architecture gives Voiceline full control over the core experience while leveraging Loqa's LLM capabilities for optional enhancement. Best of both worlds!** 🚀

---

**Contact:**
- Loqa Architect: Winston (via Anna)
- Voiceline Team: Anna (Product) / Mary (BA)

**Next Meeting:** Technical alignment + implementation kickoff (week of Nov 11, 2025)
