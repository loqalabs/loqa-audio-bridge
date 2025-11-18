# Loqa Backend API Specification - Voice Guides System

**Document Type:** Backend API Contract
**Target Audience:** Loqa Backend Development Team
**Author:** Anna (Voiceline) / Mary (Business Analyst)
**Date:** 2025-11-07
**Version:** 1.0

**Related Documents:**
- [Voice Guides Specification](./voice-guides-specification.md) - Full feature context
- [Voiceline PRD](./PRD.md) - Product requirements
- [Epic 5: Loqa Backend Integration](./epics.md) - Implementation stories

---

## Executive Summary

The Voice Guides system enables Voiceline users to select celebrity or custom voice models as learning references. The Loqa backend provides ML-powered voice analysis to:

1. **Analyze user progress toward selected voice guide characteristics** (Story 5.3)
2. **Extract voice characteristics from custom user-uploaded audio** (Story 5.8)
3. **Generate adaptive coaching suggestions** based on guide alignment

**Key Principles:**
- Privacy-first: All communication via localhost (user's personal Loqa server)
- Optional enhancement: Voiceline works offline; Loqa adds advanced ML features
- Trauma-informed: Progress framed as exploration, not evaluation/comparison

---

## Architecture Overview

```
┌─────────────────────────────────────┐
│   Voiceline Mobile App              │
│   (React Native)                    │
│                                     │
│   • Real-time audio capture         │
│   • On-device FFT analysis          │
│   • Visual feedback (voice flowers) │
│   • Voice guides gallery            │
│   • User progress tracking          │
└──────────────┬──────────────────────┘
               │ HTTP (localhost only)
               │ 192.168.1.x:3000
               │
┌──────────────▼──────────────────────┐
│   Loqa Voice Intelligence Backend   │
│   (Rust + Node.js)                  │
│                                     │
│   NEW ENDPOINTS FOR VOICE GUIDES:   │
│   • POST /voice/analyze-progress    │
│   • POST /voice/analyze-guide       │
│   • GET  /voice/guide-suggestions   │
│                                     │
│   EXISTING ENDPOINTS (already impl):│
│   • POST /voice/session             │
│   • GET  /voice/profile/:user_id    │
│   • POST /voice/breakthrough        │
└─────────────────────────────────────┘
               │
               ▼
        ~/.loqa/voice-intelligence/
        ├── user_profiles/
        ├── sessions/
        ├── custom_guides/  ← NEW
        └── progress_analytics/
```

---

## New API Endpoints

### 1. Analyze User Progress Toward Voice Guide

**Endpoint:** `POST /voice/analyze-progress-toward-guide`

**Purpose:** Compare user's current voice characteristics against selected voice guide to show progress journey and generate coaching suggestions.

**Request:**

```typescript
POST /voice/analyze-progress-toward-guide
Content-Type: application/json

{
  // User identification
  userId: string;              // User's UUID
  sessionId: string;           // Current practice session ID

  // Voice guide selection
  selectedGuideId: string;     // e.g., "guide_emma_watson" or custom guide ID

  // User voice features (current session)
  userVoiceFeatures: {
    pitch: {
      mean: number;            // Mean F0 in Hz (e.g., 195)
      min: number;             // Minimum F0 in session
      max: number;             // Maximum F0 in session
      stdev: number;           // Pitch variation
    };
    formants: {
      f1: number;              // First formant (Hz)
      f2: number;              // Second formant (Hz)
      f3?: number;             // Optional third formant
    };
    intonation: {
      patterns: Array<{
        type: 'rising' | 'falling' | 'upturn' | 'flat';
        confidence: number;    // 0-1
        timestamp: number;     // When detected in session
      }>;
      melodicVariation: number; // Standard deviation of F0 contour
    };
    quality: {
      hnr?: number;            // Harmonics-to-noise ratio
      cpp?: number;            // Cepstral peak prominence
      breathiness?: number;    // 0-1 scale
    };
    tempo: {
      syllablesPerSecond?: number;
      speakingRate?: 'slow' | 'moderate' | 'fast';
    };
  };

  // User's baseline (first recorded session)
  baselineFeatures: {
    // Same structure as userVoiceFeatures
    pitch: { mean: number; min: number; max: number; stdev: number; };
    formants: { f1: number; f2: number; };
    intonation: { patterns: Array<any>; melodicVariation: number; };
  };

  // Guide characteristics (for reference)
  guideCharacteristics: {
    pitchRange: { mean: number; min: number; max: number; };
    resonance: string;
    intonationStyle: string;
    tempo: string;
    notablePatterns: string[];
  };
}
```

**Response:**

```typescript
{
  // Success indicator
  success: true,

  // Journey visualization data
  journeyVisualization: {
    baseline: {
      pitch: number;           // Baseline mean F0
      pitchRange: string;      // Human-readable: "165-180Hz"
      intonationStyle: string; // "Flat patterns, minimal variation"
      dominantPatterns: string[]; // ["declarative-falling"]
    };
    current: {
      pitch: number;           // Current mean F0
      pitchRange: string;      // "190-210Hz"
      intonationStyle: string; // "Rising patterns emerging"
      dominantPatterns: string[]; // ["statement-upturn", "rising"]
    };
    guide: {
      pitch: number;           // Guide mean F0
      pitchRange: string;      // "185-245Hz"
      intonationStyle: string; // "Expressive melodic intonation"
      targetPatterns: string[]; // ["statement-upturn", "question-melodic"]
    };

    // Progress metrics (always framed positively)
    progressSummary: string;   // "Your pitch range is moving toward the characteristics you chose"
    pitchProgressPercent: number; // 0-100 (baseline → guide as 0 → 100)

    // Areas of alignment
    alignmentAreas: Array<{
      characteristic: string;  // "intonation_patterns"
      status: 'aligned' | 'emerging' | 'exploring';
      description: string;     // "Statement-upturn patterns appearing naturally"
    }>;

    // Areas for continued exploration
    explorationAreas: Array<{
      characteristic: string;  // "pitch_range"
      currentState: string;    // "Moving upward, approaching guide range"
      suggestion: string;      // "Continue exploring upward pitch patterns"
    }>;
  };

  // Coaching suggestions
  coachingSuggestions: {
    // Practice recommendations
    practicePrompts: Array<{
      text: string;            // "Try asking 'What do you think about that?'"
      focus: string;           // "Question intonation patterns"
      guideExample: string;    // Description of how guide uses this pattern
    }>;

    // Listening recommendations from guide profile
    listeningRecommendation: {
      type: 'interview' | 'podcast' | 'film' | 'speech';
      title: string;
      url?: string;
      focus: string;           // What to listen for
      reasoning: string;       // Why this is suggested now
    };

    // Adaptive feedback
    nextSteps: string[];       // ["Continue exploring question patterns", "Listen to [interview]"]
  };

  // Trend data (for charts)
  progressTrends: {
    pitchEvolution: Array<{
      date: string;            // ISO timestamp
      meanPitch: number;
      sessionId: string;
    }>;
    intonationPatternFrequency: Array<{
      pattern: string;
      frequency: number;       // How often pattern appears
      change: 'increasing' | 'stable' | 'decreasing';
    }>;
  };

  // Metadata
  analysisTimestamp: string;   // ISO timestamp
  confidenceScore: number;     // 0-1 (confidence in analysis quality)
}
```

**Error Responses:**

```typescript
// User not found
{
  success: false,
  error: "USER_NOT_FOUND",
  message: "No profile found for userId: xyz"
}

// Guide not found
{
  success: false,
  error: "GUIDE_NOT_FOUND",
  message: "Voice guide 'guide_xyz' not found in database"
}

// Insufficient data
{
  success: false,
  error: "INSUFFICIENT_DATA",
  message: "Baseline features required but not found. User needs at least 1 session for comparison."
}
```

---

### 2. Analyze Custom Voice Guide Audio

**Endpoint:** `POST /voice/analyze-guide`

**Purpose:** Extract voice characteristics from user-uploaded audio to create a custom voice guide profile.

**Request:**

```typescript
POST /voice/analyze-guide
Content-Type: multipart/form-data

{
  // File upload
  audioFile: File;             // WAV, MP3, or M4A (30-60 seconds recommended)

  // Metadata
  userId: string;              // User creating the guide
  displayName: string;         // User-chosen name: "My Speech Therapist"
  description?: string;        // Optional user description
  sourceAttribution?: string;  // Where audio came from (personal records)
}
```

**Response:**

```typescript
{
  success: true,

  // Generated guide profile
  guideProfile: {
    id: string;                // Generated ID: "custom_guide_abc123"
    displayName: string;       // From request
    isCustom: true,

    // Extracted characteristics
    voiceCharacteristics: {
      pitchRange: {
        mean: number;          // Mean F0 extracted
        min: number;
        max: number;
        stdev: number;
      };

      // Classified resonance
      resonance: 'dark' | 'neutral' | 'bright' | 'dark-warm' | 'bright-forward';
      resonanceConfidence: number; // 0-1

      // Classified intonation style
      intonationStyle: 'subtle' | 'moderate' | 'expressive' | 'expressive-melodic';
      intonationConfidence: number;

      // Speaking rate
      tempo: 'slow' | 'slow-moderate' | 'moderate' | 'moderate-fast' | 'fast';
      tempoConfidence: number;
      syllablesPerSecond?: number;

      // Detected patterns
      notablePatterns: string[]; // Auto-generated: ["Wide pitch range", "Frequent rising patterns"]

      // Detailed metrics
      formants: { f1: number; f2: number; f3?: number; };
      quality: {
        hnr?: number;
        cpp?: number;
        breathiness?: number;
      };
    };

    // Analysis metadata
    audioQuality: {
      snr?: number;            // Signal-to-noise ratio
      quality: 'excellent' | 'good' | 'fair' | 'poor';
      warnings?: string[];     // e.g., ["Background noise detected", "Short sample duration"]
    };

    createdDate: string;       // ISO timestamp
  };

  // Confidence assessment
  confidence: {
    overall: number;           // 0-1 overall confidence
    pitch: number;
    formants: number;
    intonation: number;
    quality: number;
  };

  // Recommendations for user
  recommendations: {
    manualAdjustment: boolean; // True if low confidence, suggest manual sliders
    recordMoreAudio: boolean;  // True if sample too short
    improveSample: string[];   // Tips: ["Reduce background noise", "Record longer sample"]
  };
}
```

**Error Responses:**

```typescript
// Invalid audio format
{
  success: false,
  error: "INVALID_AUDIO_FORMAT",
  message: "Supported formats: WAV, MP3, M4A. Received: .ogg"
}

// Audio too short
{
  success: false,
  error: "AUDIO_TOO_SHORT",
  message: "Audio duration: 5 seconds. Minimum 15 seconds required for analysis."
}

// Analysis failed
{
  success: false,
  error: "ANALYSIS_FAILED",
  message: "Unable to extract pitch from audio. Background noise may be too high.",
  details: {
    audioQuality: "poor",
    suggestedAction: "Record in quieter environment with clear speech"
  }
}
```

---

### 3. Get Guide-Aligned Coaching Suggestions

**Endpoint:** `GET /voice/guide-suggestions`

**Purpose:** Generate weekly listening recommendations and adaptive practice prompts based on user's current progress and selected guides.

**Request:**

```typescript
GET /voice/guide-suggestions?userId={userId}&guideId={guideId}
```

**Response:**

```typescript
{
  success: true,

  // Weekly listening recommendation
  weeklyListening: {
    type: 'interview' | 'podcast' | 'film' | 'speech';
    title: string;
    url?: string;
    platform?: string;
    duration?: string;
    focus: string;             // What to listen for this week
    reasoning: string;         // Why this recommendation now based on progress
  };

  // Adaptive practice prompts
  practicePrompts: Array<{
    text: string;
    intonationTarget: string;
    guidanceText: string;      // How guide uses this pattern
    difficulty: 'easy' | 'moderate' | 'challenging';
  }>;

  // Exploration theme
  weeklyTheme: {
    focus: string;             // "Question intonation patterns"
    description: string;
    exercises: string[];
  };
}
```

---

## Data Models

### VoiceGuide Database Schema

**Storage Location:** `~/.loqa/voice-intelligence/voice_guides/`

```typescript
// Built-in guides (bundled with Loqa)
interface VoiceGuide {
  id: string;                  // "guide_emma_watson"
  displayName: string;
  type: 'builtin' | 'custom';

  voiceCharacteristics: {
    pitchRange: { mean: number; min: number; max: number; stdev: number; };
    formants: { f1: number; f2: number; f3?: number; };
    resonance: string;
    intonationStyle: string;
    tempo: string;
    notablePatterns: string[];

    // Detailed acoustic features
    spectral?: {
      centroid: number;
      tilt: number;
    };
    quality?: {
      hnr: number;
      cpp: number;
      breathiness: number;
    };
  };

  // Optional speaker embeddings (if legally cleared)
  speakerEmbedding?: number[]; // ECAPA-TDNN or x-vector

  metadata: {
    createdDate: string;
    source: string;            // "Licensed from [agency]" or "User upload"
    analysisVersion: string;   // Version of analysis algorithm used
  };
}

// Custom guides (user-contributed)
interface CustomVoiceGuide extends VoiceGuide {
  userId: string;              // Owner
  customMetadata: {
    sourceAttribution: string;
    consentConfirmed: boolean;
    manuallyDefined: boolean;  // True if characteristics set via sliders vs. ML
    originalFileName: string;
  };
}
```

### User Voice Profile Extension

**Extend existing user profile schema:**

```typescript
interface UserVoiceProfile {
  // Existing fields (already implemented)
  userId: string;
  baselineFeatures: VoiceFeatures;
  sessionHistory: Session[];

  // NEW: Voice guide preferences
  selectedGuides: Array<{
    guideId: string;
    selectedDate: string;
    isPrimary: boolean;        // Primary guide for progress tracking
  }>;

  // NEW: Guide-based progress tracking
  guideProgress: {
    [guideId: string]: {
      firstComparisonDate: string;
      latestAlignment: {
        pitchAlignment: number; // 0-1 (how close to guide pitch range)
        intonationSimilarity: number;
        overallProgress: number;
      };
      coachingHistory: Array<{
        date: string;
        suggestion: string;
        completed: boolean;
      }>;
    };
  };
}
```

---

## ML Analysis Implementation Requirements

### Required Algorithms

**1. Pitch Analysis:**
- **Algorithm:** CREPE, pYIN, or YIN for robust F0 estimation
- **Output:** Mean, min, max, stdev of F0 over session
- **Accuracy requirement:** ±5Hz
- **Latency:** <100ms per analysis window (for real-time if needed)

**2. Formant Extraction:**
- **Algorithm:** LPC (Linear Predictive Coding) or Praat backend
- **Output:** F1, F2, F3 frequencies
- **Use case:** Resonance classification (dark vs. bright)

**3. Intonation Pattern Classification:**
- **Algorithm:** Pitch contour analysis over 500-1000ms windows
- **Output:** Pattern type (rising, falling, upturn, flat) + confidence
- **Patterns to detect:**
  - Rising (question intonation)
  - Falling (declarative statements)
  - Statement-upturn (rising pitch at end of statement)
  - Flat (monotone)

**4. Voice Quality Metrics:**
- **HNR (Harmonics-to-Noise Ratio):** Measure of breathiness
- **CPP (Cepstral Peak Prominence):** Voice quality indicator
- **Spectral tilt:** Dark vs. bright resonance classification

**5. Resonance Classification:**
- **Input:** Formant frequencies (F1, F2) + spectral centroid
- **Algorithm:** Rule-based classifier or trained model
- **Output:** 'dark' | 'neutral' | 'bright' | 'dark-warm' | 'bright-forward'

**6. Intonation Style Classification:**
- **Input:** Pitch variation statistics (stdev, range) + pattern frequency
- **Algorithm:** Threshold-based or ML classifier
- **Output:** 'subtle' | 'moderate' | 'expressive' | 'expressive-melodic'

**7. Tempo/Speaking Rate:**
- **Input:** Audio duration + speech activity detection
- **Algorithm:** Syllable counting or speech rate estimation
- **Output:** Syllables per second + classification ('slow', 'moderate', 'fast')

---

## Progress Comparison Algorithm

### High-Level Approach

```python
def analyze_progress_toward_guide(
    user_features: VoiceFeatures,
    baseline_features: VoiceFeatures,
    guide_characteristics: VoiceGuide
) -> ProgressAnalysis:
    """
    Compare user's current voice to baseline and guide target.
    Frame results as exploration journey, not evaluation.
    """

    # 1. Calculate pitch progress
    pitch_progress = calculate_pitch_alignment(
        user_current=user_features.pitch.mean,
        user_baseline=baseline_features.pitch.mean,
        guide_target=guide_characteristics.pitchRange.mean
    )
    # Returns: 0-100 where 0 = baseline, 100 = guide target
    # E.g., baseline 165Hz → current 195Hz → guide 210Hz = ~70% progress

    # 2. Compare intonation patterns
    intonation_similarity = calculate_pattern_similarity(
        user_patterns=user_features.intonation.patterns,
        guide_patterns=guide_characteristics.notablePatterns
    )
    # Returns: 0-1 similarity based on pattern overlap

    # 3. Classify progress stage
    alignment_areas = classify_alignment(
        pitch_progress=pitch_progress,
        intonation_similarity=intonation_similarity,
        formant_distance=calculate_formant_distance(user, guide)
    )
    # Returns: ['aligned', 'emerging', 'exploring'] per characteristic

    # 4. Generate trauma-informed progress text
    progress_summary = generate_positive_framing(
        pitch_progress=pitch_progress,
        alignment_areas=alignment_areas,
        guide_name=guide_characteristics.displayName
    )
    # Returns: "Your pitch range is moving toward the characteristics you chose"
    # NEVER: "You're 65% similar to Emma Watson"

    # 5. Suggest adaptive coaching
    coaching = generate_adaptive_suggestions(
        current_state=user_features,
        guide_target=guide_characteristics,
        progress=pitch_progress
    )

    return ProgressAnalysis(
        journey_viz=...,
        coaching=coaching,
        trends=...
    )
```

### Pitch Alignment Calculation

```python
def calculate_pitch_alignment(
    user_current: float,
    user_baseline: float,
    guide_target: float
) -> float:
    """
    Calculate progress from baseline toward guide as percentage.
    Handles both upward and downward pitch movement.
    """

    # Total distance from baseline to guide
    total_distance = abs(guide_target - user_baseline)

    # Distance user has moved
    user_movement = abs(user_current - user_baseline)

    # Progress percentage (0-100)
    if total_distance == 0:
        return 100  # Already at target

    progress = (user_movement / total_distance) * 100

    # Cap at 100% (user may overshoot target)
    return min(progress, 100)
```

### Intonation Pattern Similarity

```python
def calculate_pattern_similarity(
    user_patterns: List[IntonationPattern],
    guide_patterns: List[str]
) -> float:
    """
    Calculate overlap between user's intonation patterns and guide's notable patterns.
    Returns 0-1 similarity score.
    """

    # Extract pattern types from user session
    user_pattern_types = [p.type for p in user_patterns]

    # Count pattern type frequency
    user_pattern_freq = Counter(user_pattern_types)

    # Notable patterns from guide
    # E.g., ["statement-upturn", "question-melodic", "wide-range"]
    guide_pattern_keywords = extract_keywords(guide_patterns)

    # Calculate overlap
    overlap_score = 0
    for keyword in guide_pattern_keywords:
        if keyword in user_pattern_freq:
            overlap_score += 1

    # Normalize 0-1
    return overlap_score / len(guide_pattern_keywords) if guide_pattern_keywords else 0
```

---

## Trauma-Informed Language Generation

### Critical Requirement: Positive Framing

**DO:**
- ✅ "Your pitch range is moving toward the characteristics you chose"
- ✅ "Intonation expressiveness is increasing—aligning with [Guide]'s melodic style"
- ✅ "Statement-upturn patterns appearing naturally"
- ✅ "Continue exploring upward pitch patterns"

**DON'T:**
- ❌ "You're 65% similar to Emma Watson"
- ❌ "Your pitch is still 15Hz below target"
- ❌ "You failed to match the guide's intonation"
- ❌ "Emma Watson's voice is better than yours"

### Language Templates

```typescript
// Progress summary templates
const progressTemplates = {
  pitch: {
    moving: "Your pitch range is moving toward the characteristics you chose",
    aligned: "Your pitch range aligns beautifully with your selected guide",
    exploring: "You're exploring pitch patterns in the range you chose"
  },
  intonation: {
    emerging: "Intonation expressiveness is increasing—aligning with {guide}'s {style} style",
    aligned: "Your intonation patterns beautifully reflect the {style} style you chose",
    exploring: "You're discovering new intonation patterns"
  }
};

// Coaching suggestion templates
const coachingTemplates = {
  practice: "Try practicing {pattern}—listen to {guide}'s {example}",
  listening: "This week, try watching {content}—notice {focus}",
  exploration: "Continue exploring {characteristic} patterns"
};
```

---

## Performance Requirements

### Latency Targets

| Operation | Target Latency | Max Acceptable |
|-----------|----------------|----------------|
| POST /voice/analyze-progress | <500ms | 1000ms |
| POST /voice/analyze-guide | <3s (30s audio) | 5s |
| GET /voice/guide-suggestions | <200ms | 500ms |

### Accuracy Requirements

| Metric | Minimum Accuracy |
|--------|------------------|
| Pitch (F0) detection | ±5Hz or 95% confidence |
| Formant extraction | ±50Hz for F1/F2 |
| Intonation pattern classification | 85% accuracy (validated against human labelers) |
| Resonance classification | 80% accuracy |

### Storage Requirements

| Data Type | Storage per User |
|-----------|------------------|
| User voice profile | ~10KB JSON |
| Session features | ~5KB per session |
| Custom guide audio | ~1-2MB per guide (compressed) |
| Custom guide profile | ~5KB JSON |

**Total estimate:** 50-100MB per active user over 6 months

---

## Security & Privacy

### Data Handling Requirements

**1. Local-Only Storage:**
- All voice data stored in `~/.loqa/voice-intelligence/` with `chmod 700` (user-only access)
- No external API calls or cloud transmission
- No telemetry or analytics collection

**2. Audio File Handling:**
- Custom guide audio: Store original file locally, never transmit
- Derived metrics only transmitted between Loqa backend and Voiceline app
- Audio automatically deleted after analysis if user chooses

**3. User Consent:**
- Custom guide upload requires explicit consent confirmation
- Warning against non-consensual recordings
- Clear privacy statement in UI

**4. Data Deletion:**
- User can delete custom guides anytime
- DELETE endpoint: `DELETE /voice/guide/:guideId`
- Permanently removes audio and derived metrics

---

## Testing Requirements

### Unit Tests

**1. Pitch Analysis:**
- Test with synthetic sine waves at known frequencies
- Verify ±5Hz accuracy
- Edge cases: Very low pitch (80Hz), very high (400Hz), pitch jumps

**2. Intonation Classification:**
- Test with labeled audio samples (rising, falling, upturn, flat)
- Target 85% classification accuracy

**3. Progress Calculation:**
- Test pitch alignment formula with known baseline/current/guide values
- Verify 0-100 range output
- Edge cases: User already at target, user beyond target

### Integration Tests

**1. Full Analysis Pipeline:**
- Upload 30s audio → extract features → generate guide profile
- Verify all characteristics populated
- Measure end-to-end latency

**2. Progress Tracking:**
- Simulate user progression over multiple sessions
- Verify progress metrics increase appropriately
- Validate trauma-informed language generation

### User Acceptance Testing

**Critical Test Scenario:**
- User selects Emma Watson as guide
- Practices for 4 weeks (20 sessions)
- Pitch moves from 165Hz → 195Hz (guide: 210Hz)
- System should show:
  - ✅ Positive progress narrative
  - ✅ Coaching suggestions aligned with Emma's patterns
  - ✅ NO language like "you're failing to match Emma"

---

## Deployment

### Phase 1: Story 5.3 (Guide-Aware Progress)
**Endpoints Required:**
- `POST /voice/analyze-progress-toward-guide`
- `GET /voice/guide-suggestions`

**Timeline:** After Epic 5 Stories 5.1-5.2 complete

### Phase 2: Story 5.8 (Custom Guides)
**Endpoints Required:**
- `POST /voice/analyze-guide`
- `DELETE /voice/guide/:guideId`

**Timeline:** Future enhancement (post-MVP)

### Loqa Version Requirements

**Minimum Loqa Version:** TBD (coordinate with Loqa team)

**Feature Flag:** `voice_guides_enabled: true`

---

## Questions for Loqa Team

**Technical Implementation:**
1. Which pitch detection algorithm do you prefer? (CREPE, pYIN, YIN)
2. Do you have existing formant extraction? (LPC vs. Praat backend)
3. Current speaker embedding model? (ECAPA-TDNN, x-vector)
4. Preferred audio format for upload? (WAV preferred for analysis quality)

**Scope Clarification:**
5. Is intonation pattern classification already implemented or new work?
6. Do you have a resonance classification model or should we use rule-based?
7. Any existing trauma-informed language generation patterns to follow?

**Timeline & Capacity:**
8. Estimated development time for Story 5.3 endpoints?
9. Estimated development time for Story 5.8 custom guide analysis?
10. Any dependencies or blockers we should know about?

---

## Appendix: Example Request/Response Flow

### Complete User Journey: Progress Analysis

**Step 1: User completes practice session**

Voiceline extracts on-device features:
```json
{
  "pitch": { "mean": 195, "min": 175, "max": 215, "stdev": 12 },
  "intonation": {
    "patterns": [
      { "type": "statement-upturn", "confidence": 0.85, "timestamp": 1234 },
      { "type": "rising", "confidence": 0.78, "timestamp": 5678 }
    ],
    "melodicVariation": 14.2
  }
}
```

**Step 2: Voiceline requests Loqa analysis**

```bash
curl -X POST http://localhost:3000/voice/analyze-progress-toward-guide \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user_abc123",
    "sessionId": "session_xyz789",
    "selectedGuideId": "guide_emma_watson",
    "userVoiceFeatures": { ... },
    "baselineFeatures": { ... },
    "guideCharacteristics": { ... }
  }'
```

**Step 3: Loqa responds with journey visualization**

```json
{
  "success": true,
  "journeyVisualization": {
    "baseline": {
      "pitch": 165,
      "pitchRange": "155-180Hz",
      "intonationStyle": "Flat patterns, minimal variation"
    },
    "current": {
      "pitch": 195,
      "pitchRange": "175-215Hz",
      "intonationStyle": "Rising patterns emerging, statement-upturns appearing"
    },
    "guide": {
      "pitch": 210,
      "pitchRange": "185-245Hz",
      "intonationStyle": "Expressive melodic intonation, wide range"
    },
    "progressSummary": "Your pitch range is moving toward the characteristics you chose. Statement-upturn patterns are appearing naturally—beautiful alignment with Emma's expressive style!",
    "pitchProgressPercent": 67
  },
  "coachingSuggestions": {
    "listeningRecommendation": {
      "type": "podcast",
      "title": "Emma Watson on The High Low",
      "url": "https://...",
      "focus": "Notice how Emma uses statement-upturns in conversational dialogue",
      "reasoning": "You're developing statement-upturn patterns—this podcast showcases them beautifully in casual conversation"
    },
    "practicePrompts": [
      {
        "text": "What do you think about that?",
        "focus": "Question melodic variation",
        "guidanceText": "Emma uses wide pitch range on questions—try exploring upward then downward motion"
      }
    ]
  }
}
```

**Step 4: Voiceline displays "Your Voice Journey" to user**

User sees:
- Journey visualization (baseline → current → guide)
- Positive progress narrative
- Listening suggestion for this week
- Practice prompts for next session

---

**End of Specification**

**Next Steps:**
1. Loqa team reviews specification
2. Schedule technical clarification meeting
3. Estimate development timeline
4. Define API versioning and feature flag strategy
5. Establish testing/validation protocol

**Contact:**
- Voiceline: Anna (Product) / Mary (BA)
- Loqa: [Your backend team contact]
