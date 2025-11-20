# Loqa Architecture Response: Voice Guides System

**Date:** November 7, 2025
**From:** Winston (Loqa Architect Agent)
**To:** Voiceline Team (Anna / Mary)
**Subject:** Voice Guides API Architecture Analysis & Implementation Roadmap
**Reference:** [loqa-backend-voice-guides-api-spec.md](./loqa-backend-voice-guides-api-spec.md)

---

## 🎯 Executive Summary

Thank you for the detailed Voice Guides API specification! This is an excellent extension of the Loqa-Voiceline collaboration that builds naturally on Epic 2C's voice intelligence foundation.

**Key Findings:**

✅ **High Architectural Alignment:** Voice Guides specification aligns well with Loqa's existing Epic 2C infrastructure (voice profiles, session analysis, file-based storage, privacy-first architecture)

⚠️ **Medium Implementation Complexity:** Requires 4 new capabilities beyond Epic 2C:

1. Intonation pattern classification (upgrade from basic to multi-pattern)
2. Resonance classification model (new)
3. Progress comparison algorithm (new)
4. Trauma-informed language generation (new, critical)

**Recommended Approach:** Phased implementation as **Epic 2D: Voice Guides Intelligence** (separate epic building on Epic 2C)

**Estimated Timeline:** 3-4 weeks development + 1 week testing (5 weeks total)

---

## 📋 Architecture Alignment Analysis

### Existing Epic 2C Capabilities (Reusable)

| Capability                      | Epic 2C Status                                    | Reusability for Voice Guides                            |
| ------------------------------- | ------------------------------------------------- | ------------------------------------------------------- |
| **Pitch Detection (F0)**        | ✅ Implemented (YIN algorithm, ±5Hz accuracy)     | **Direct reuse** for pitch analysis                     |
| **Formant Extraction (F1, F2)** | ✅ Implemented (LPC-based)                        | **Direct reuse** for resonance input                    |
| **Voice Profile Storage**       | ✅ Implemented (JSON files, atomic writes)        | **Extend schema** for `selectedGuides`, `guideProgress` |
| **Session Recording**           | ✅ Implemented (`POST /voice/session`)            | **Reuse** for session data                              |
| **Breakthrough Tagging**        | ✅ Implemented (`POST /voice/breakthrough`)       | **Reuse** for milestone tracking                        |
| **Voice Quality Metrics**       | ⚠️ **Stub implementation** (breathiness, tension) | **Upgrade required** for HNR, CPP                       |
| **Intonation Detection**        | ⚠️ **Basic implementation** (single pattern type) | **Upgrade required** for multi-pattern classification   |

### New Capabilities Required

| Capability                              | Complexity | Implementation Notes                                                             |
| --------------------------------------- | ---------- | -------------------------------------------------------------------------------- |
| **Intonation Pattern Classification**   | Medium     | Upgrade from basic to 4-pattern classifier (rising, falling, upturn, flat)       |
| **Resonance Classification**            | Medium     | New rule-based classifier (formants + spectral centroid → dark/neutral/bright)   |
| **Tempo/Speaking Rate Analysis**        | Low        | Syllable counting or VAD-based speech rate estimation                            |
| **Progress Comparison Algorithm**       | Medium     | Baseline → Current → Guide delta calculation with 0-100% progress                |
| **Trauma-Informed Language Generation** | High       | Template-based generation with positive framing rules (critical UX requirement)  |
| **Guide-Aligned Coaching Suggestions**  | Medium     | Logic to generate practice prompts + listening recommendations based on progress |

---

## 🏗️ Proposed Architecture: Epic 2D (Voice Guides Intelligence)

### Module Structure

```
crates/loqa-voice-intelligence/
├── src/
│   ├── api/
│   │   ├── analysis.rs           [EXISTING - Epic 2C]
│   │   ├── profile.rs            [EXISTING - Epic 2C]
│   │   ├── session.rs            [EXISTING - Epic 2C]
│   │   ├── breakthrough.rs       [EXISTING - Epic 2C]
│   │   ├── progress.rs           [EXISTING - Epic 2C]
│   │   ├── guide_progress.rs     [NEW - Story 2D.1] POST /voice/analyze-progress-toward-guide
│   │   ├── guide_analysis.rs     [NEW - Story 2D.2] POST /voice/analyze-guide
│   │   └── guide_suggestions.rs  [NEW - Story 2D.3] GET /voice/guide-suggestions
│   │
│   ├── analysis/
│   │   ├── pitch.rs              [EXISTING - reuse]
│   │   ├── formants.rs           [EXISTING - reuse]
│   │   ├── intonation.rs         [UPGRADE - Story 2D.4] Multi-pattern classifier
│   │   ├── resonance.rs          [NEW - Story 2D.5] Resonance classification
│   │   ├── tempo.rs              [NEW - Story 2D.6] Speaking rate analysis
│   │   └── quality.rs            [UPGRADE - Story 2D.7] HNR, CPP implementation
│   │
│   ├── voice_guides/
│   │   ├── mod.rs
│   │   ├── comparison.rs         [NEW - Story 2D.8] Progress comparison algorithm
│   │   ├── coaching.rs           [NEW - Story 2D.9] Adaptive coaching suggestions
│   │   ├── language_gen.rs       [NEW - Story 2D.10] Trauma-informed language templates
│   │   └── guide_store.rs        [NEW - Story 2D.11] Voice guide database management
│   │
│   └── storage/
│       ├── profiles.rs           [EXTEND - Story 2D.12] Add selectedGuides, guideProgress fields
│       └── guides.rs             [NEW - Story 2D.13] Custom guide storage
```

### Data Storage Architecture

```
~/.loqa/voice-intelligence/
├── profiles/
│   ├── {user-id}.json           [EXTEND] Add selectedGuides, guideProgress
│   └── {user-id}/
│       └── breakthroughs.json   [EXISTING]
│
├── sessions/                     [EXISTING]
│   ├── YYYY-MM-DD-HH-MM-SS-{uuid}.wav
│   └── YYYY-MM-DD-HH-MM-SS-{uuid}.json
│
├── voice_guides/                 [NEW]
│   ├── builtin/
│   │   ├── guide_emma_watson.json
│   │   ├── guide_zendaya.json
│   │   └── guide_shohreh_aghdashloo.json
│   │
│   └── custom/
│       ├── {user-id}/
│       │   ├── {guide-id}.json  [Guide metadata + characteristics]
│       │   └── {guide-id}.wav   [Original audio, optional retention]
│       └── index.json           [Custom guide index]
```

---

## 🔧 Technical Implementation Answers

### Q1: Which pitch detection algorithm do you prefer? (CREPE, pYIN, YIN)

**Answer:** **YIN algorithm** (already implemented in Epic 2C)

**Rationale:**

- ✅ Already implemented in Epic 2C (`loqa-core/audio/analysis.rs`)
- ✅ Meets accuracy requirement (±5Hz)
- ✅ Fast enough for real-time (<100ms per window)
- ✅ Handles voice pitch range (80-400Hz) well

**Performance (validated in Epic 2C):**

- Accuracy: ±5Hz on clean speech
- Latency: ~5ms per 100ms audio frame
- Works well for 5-second clips (target: <500ms total analysis)

**Alternative (Future):** pYIN or CREPE for higher accuracy if needed post-MVP, but YIN is sufficient for Voice Guides use case.

---

### Q2: Do you have existing formant extraction? (LPC vs. Praat backend)

**Answer:** ✅ **Yes, LPC-based formant extraction** (implemented in Epic 2C)

**Details:**

- Implementation: `loqa-core/audio/analysis::formant_extraction()`
- Algorithm: Linear Predictive Coding (LPC)
- Output: F1, F2 frequencies (F3 optional)
- Accuracy: ±50Hz for F1/F2 (meets Voice Guides requirement)

**Reusability:** Direct reuse for resonance classification input. No changes needed.

---

### Q3: Current speaker embedding model? (ECAPA-TDNN, x-vector)

**Answer:** ❌ **Not implemented** in Epic 2C

**Epic 2C Speaker Diarization:**

- Uses pyannote-based ML diarization (Story 2.10-2.11)
- Speaker embeddings generated by pyannote-rs library (ECAPA-TDNN internally)
- **Not exposed** as API feature

**For Voice Guides:**

- **Recommendation:** Do not use speaker embeddings for MVP
- **Rationale:** Voice characteristic comparison (pitch, formants, intonation) is sufficient for "alignment" without requiring embedding similarity
- **Future enhancement:** If needed post-MVP, can expose pyannote embeddings for cosine similarity comparison

**Storage Impact:** Without embeddings, voice guide profiles remain ~5-10KB JSON (vs. ~500KB with embeddings)

---

### Q4: Preferred audio format for upload? (WAV preferred for analysis quality)

**Answer:** **WAV (16kHz mono) preferred**, but support WAV, MP3, M4A (auto-convert)

**Existing Epic 2C Support:**

- Accepts: WAV, M4A, MP3, AAC (via symphonia audio decoder)
- Auto-converts to: 16kHz mono WAV for analysis
- Validated in: Story 2C.5 (session recording)

**Voice Guides Recommendation:**

- **Custom guide upload:** Request 30-60 seconds of WAV (16kHz mono) for best quality
- **Fallback:** Accept M4A/MP3 and auto-convert (warn user about potential quality degradation)
- **Validation:** Min 15 seconds, max 120 seconds audio duration

---

### Q5: Is intonation pattern classification already implemented or new work?

**Answer:** ⚠️ **Partially implemented** - requires **upgrade** from basic to multi-pattern

**Epic 2C Current State:**

- Basic intonation detection exists (`loqa-voice-intelligence/analysis/intonation.rs`)
- Current output: Single pattern type + melodic variation score
- **Gap:** Does not classify into 4 pattern types (rising, falling, upturn, flat)

**Voice Guides Requirement:**

- Detect 4 pattern types over 500-1000ms windows
- Output: `Array<{ type, confidence, timestamp }>`
- Target accuracy: 85%

**Implementation Plan (Story 2D.4):**

**Algorithm Upgrade:**

```rust
// EXISTING (Epic 2C)
pub struct IntonationPattern {
    pub pattern_type: IntonationType,  // Single enum value
    pub melodic_variation: f32,
}

// NEW (Epic 2D - Voice Guides)
pub struct IntonationAnalysis {
    pub patterns: Vec<PatternDetection>,  // Multiple patterns detected
    pub melodic_variation: f32,
    pub dominant_pattern: IntonationType,
}

pub struct PatternDetection {
    pub pattern_type: IntonationType,  // rising | falling | upturn | flat
    pub confidence: f32,               // 0-1
    pub timestamp_ms: u64,             // When detected in audio
    pub pitch_delta: f32,              // Hz change during pattern
}

pub enum IntonationType {
    Rising,          // Question intonation (upward F0 contour)
    Falling,         // Declarative statement (downward F0 contour)
    StatementUpturn, // Uptalk (statement with rising end)
    Flat,            // Monotone (minimal F0 variation)
}
```

**Pattern Detection Logic:**

```rust
fn classify_intonation_patterns(
    pitch_contour: &[f32],  // F0 values over time
    sample_rate: f32,
) -> Vec<PatternDetection> {
    let window_size_ms = 750; // 500-1000ms window
    let windows = segment_into_windows(pitch_contour, window_size_ms, sample_rate);

    let mut patterns = Vec::new();

    for (window, timestamp) in windows {
        // Calculate pitch slope (linear regression)
        let slope = calculate_pitch_slope(&window);
        let variation = window_pitch_stdev(&window);

        // Classify pattern based on slope and variation
        let pattern_type = match (slope, variation) {
            (s, v) if s > 15.0 && v > 10.0 => IntonationType::Rising,
            (s, v) if s < -15.0 && v > 10.0 => IntonationType::Falling,
            (s, v) if s > 5.0 && is_end_rising(&window) => IntonationType::StatementUpturn,
            (_, v) if v < 5.0 => IntonationType::Flat,
            _ => IntonationType::Flat, // Default
        };

        let confidence = calculate_confidence(slope, variation, &window);

        patterns.push(PatternDetection {
            pattern_type,
            confidence,
            timestamp_ms: timestamp,
            pitch_delta: window.last() - window.first(),
        });
    }

    patterns
}
```

**Estimated Effort:** 3-4 days (Story 2D.4)

---

### Q6: Do you have a resonance classification model or should we use rule-based?

**Answer:** ❌ **Not implemented** - recommend **rule-based classifier** for MVP

**Rationale:**

- Rule-based classification sufficient for 5 categories (dark, neutral, bright, dark-warm, bright-forward)
- Avoids ML model training overhead
- Explainable rules (users can understand why classification was made)

**Proposed Rule-Based Algorithm (Story 2D.5):**

```rust
pub enum ResonanceType {
    Dark,           // Low F2, deep chest resonance
    Neutral,        // Balanced formants
    Bright,         // High F2, head/nasal resonance
    DarkWarm,       // Low F2 with moderate F1
    BrightForward,  // High F2 with high F1
}

fn classify_resonance(
    f1_mean: f32,
    f2_mean: f32,
    spectral_centroid: f32,  // From FFT
) -> (ResonanceType, f32) {
    // Rule-based thresholds (typical adult voice ranges)
    let f2_dark_threshold = 1800.0;    // Hz
    let f2_bright_threshold = 2200.0;  // Hz
    let f1_low_threshold = 650.0;      // Hz
    let f1_high_threshold = 850.0;     // Hz
    let centroid_bright_threshold = 3000.0; // Hz

    let resonance_type = match (f1_mean, f2_mean, spectral_centroid) {
        // Dark resonance: Low F2, any F1
        (_, f2, _) if f2 < f2_dark_threshold => {
            if f1_mean < f1_low_threshold {
                ResonanceType::Dark
            } else {
                ResonanceType::DarkWarm
            }
        },

        // Bright resonance: High F2
        (_, f2, sc) if f2 > f2_bright_threshold => {
            if f1_mean > f1_high_threshold && sc > centroid_bright_threshold {
                ResonanceType::BrightForward
            } else {
                ResonanceType::Bright
            }
        },

        // Neutral: Mid-range formants
        _ => ResonanceType::Neutral,
    };

    // Calculate confidence based on distance from thresholds
    let confidence = calculate_resonance_confidence(f1_mean, f2_mean, &resonance_type);

    (resonance_type, confidence)
}

fn calculate_resonance_confidence(
    f1: f32,
    f2: f32,
    resonance_type: &ResonanceType,
) -> f32 {
    // Higher confidence when formants are far from threshold boundaries
    match resonance_type {
        ResonanceType::Dark => {
            let distance_from_threshold = 1800.0 - f2;
            (distance_from_threshold / 200.0).min(1.0) // 0-1 confidence
        },
        ResonanceType::Bright => {
            let distance_from_threshold = f2 - 2200.0;
            (distance_from_threshold / 200.0).min(1.0)
        },
        _ => 0.75, // Default moderate confidence for neutral/compound types
    }
}
```

**Validation Plan:**

- Test with known voice samples (annotated by speech therapist)
- Target: 80% classification accuracy (meets Voice Guides requirement)

**Future Enhancement:** ML-based classifier (train on labeled dataset) if rule-based accuracy insufficient

**Estimated Effort:** 2-3 days (Story 2D.5)

---

### Q7: Any existing trauma-informed language generation patterns to follow?

**Answer:** ❌ **Not implemented** in Loqa - this is **new work** (critical for Voice Guides UX)

**Recommendation:** Template-based generation with positive framing rules

**Implementation Plan (Story 2D.10):**

**Core Principle:** Always frame progress as exploration, never as evaluation/comparison

**Language Templates (Rust):**

```rust
pub struct TraumaInformedLanguage {
    progress_templates: HashMap<(CharacteristicType, ProgressStage), Vec<String>>,
    coaching_templates: HashMap<CoachingType, Vec<String>>,
    forbidden_phrases: Vec<String>,
}

#[derive(Hash, Eq, PartialEq)]
pub enum CharacteristicType {
    Pitch,
    Intonation,
    Resonance,
    Tempo,
}

#[derive(Hash, Eq, PartialEq)]
pub enum ProgressStage {
    Aligned,     // User already matches guide
    Emerging,    // User showing progress toward guide
    Exploring,   // User just starting journey
}

impl TraumaInformedLanguage {
    pub fn new() -> Self {
        let mut progress_templates = HashMap::new();

        // Pitch progress templates
        progress_templates.insert(
            (CharacteristicType::Pitch, ProgressStage::Moving),
            vec![
                "Your pitch range is moving toward the characteristics you chose".to_string(),
                "You're exploring pitch patterns in the range you selected".to_string(),
            ],
        );

        progress_templates.insert(
            (CharacteristicType::Pitch, ProgressStage::Aligned),
            vec![
                "Your pitch range aligns beautifully with your selected guide".to_string(),
                "You've developed the pitch characteristics you chose—lovely alignment!".to_string(),
            ],
        );

        // Intonation progress templates
        progress_templates.insert(
            (CharacteristicType::Intonation, ProgressStage::Emerging),
            vec![
                "Intonation expressiveness is increasing—aligning with {guide}'s {style} style".to_string(),
                "{pattern} patterns are appearing naturally in your voice".to_string(),
            ],
        );

        // ... more templates ...

        // Forbidden phrases (validation)
        let forbidden_phrases = vec![
            "similar to".to_string(),
            "% match".to_string(),
            "failed to".to_string(),
            "below target".to_string(),
            "better than".to_string(),
            "worse than".to_string(),
        ];

        TraumaInformedLanguage {
            progress_templates,
            coaching_templates: Self::init_coaching_templates(),
            forbidden_phrases,
        }
    }

    pub fn generate_progress_summary(
        &self,
        characteristic: CharacteristicType,
        progress_stage: ProgressStage,
        context: &ProgressContext,
    ) -> String {
        let templates = self.progress_templates
            .get(&(characteristic, progress_stage))
            .expect("Template not found");

        // Select template (round-robin or random)
        let template = &templates[context.session_count % templates.len()];

        // Fill in placeholders
        template
            .replace("{guide}", &context.guide_name)
            .replace("{style}", &context.guide_style)
            .replace("{pattern}", &context.dominant_pattern)
    }

    pub fn validate_output(&self, text: &str) -> Result<(), Vec<String>> {
        let mut violations = Vec::new();

        for forbidden in &self.forbidden_phrases {
            if text.to_lowercase().contains(&forbidden.to_lowercase()) {
                violations.push(format!("Forbidden phrase detected: '{}'", forbidden));
            }
        }

        if violations.is_empty() {
            Ok(())
        } else {
            Err(violations)
        }
    }
}

pub struct ProgressContext {
    pub guide_name: String,
    pub guide_style: String,
    pub dominant_pattern: String,
    pub session_count: usize,
}
```

**Unit Tests (Critical):**

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_trauma_informed_language_no_forbidden_phrases() {
        let lang = TraumaInformedLanguage::new();

        let context = ProgressContext {
            guide_name: "Emma Watson".to_string(),
            guide_style: "expressive melodic".to_string(),
            dominant_pattern: "statement-upturn".to_string(),
            session_count: 5,
        };

        let summary = lang.generate_progress_summary(
            CharacteristicType::Intonation,
            ProgressStage::Emerging,
            &context,
        );

        // Validate no forbidden phrases
        assert!(lang.validate_output(&summary).is_ok());

        // Validate positive framing
        assert!(!summary.contains("failed"));
        assert!(!summary.contains("below"));
        assert!(!summary.contains("% similar"));
    }

    #[test]
    fn test_validation_catches_forbidden_phrases() {
        let lang = TraumaInformedLanguage::new();

        let bad_text = "You're 65% similar to Emma Watson but still below target.";
        let result = lang.validate_output(bad_text);

        assert!(result.is_err());
        let errors = result.unwrap_err();
        assert!(errors.iter().any(|e| e.contains("similar to")));
        assert!(errors.iter().any(|e| e.contains("below target")));
    }
}
```

**Estimated Effort:** 4-5 days (Story 2D.10) - critical UX requirement

---

## 📊 Progress Comparison Algorithm Design

### Story 2D.8: Progress Comparison Algorithm

**Requirement:** Calculate progress from baseline → current → guide as 0-100%

**Implementation:**

```rust
pub struct ProgressComparison {
    pub pitch_alignment: f32,           // 0-100 percentage
    pub intonation_similarity: f32,     // 0-1 similarity score
    pub resonance_alignment: f32,       // 0-1 alignment score
    pub overall_progress: f32,          // 0-100 weighted average
}

pub fn analyze_progress_toward_guide(
    user_features: &VoiceFeatures,
    baseline_features: &VoiceFeatures,
    guide_characteristics: &VoiceGuide,
) -> ProgressComparison {
    // 1. Pitch alignment
    let pitch_alignment = calculate_pitch_alignment(
        user_features.pitch.mean,
        baseline_features.pitch.mean,
        guide_characteristics.pitch_range.mean,
    );

    // 2. Intonation similarity
    let intonation_similarity = calculate_pattern_similarity(
        &user_features.intonation.patterns,
        &guide_characteristics.notable_patterns,
    );

    // 3. Resonance alignment
    let resonance_alignment = calculate_resonance_similarity(
        &user_features.formants,
        &guide_characteristics.formants,
    );

    // 4. Overall progress (weighted average)
    let overall_progress = (
        pitch_alignment * 0.4 +
        intonation_similarity * 100.0 * 0.4 +
        resonance_alignment * 100.0 * 0.2
    );

    ProgressComparison {
        pitch_alignment,
        intonation_similarity,
        resonance_alignment,
        overall_progress,
    }
}

fn calculate_pitch_alignment(
    user_current: f32,
    user_baseline: f32,
    guide_target: f32,
) -> f32 {
    // Distance from baseline to guide
    let total_distance = (guide_target - user_baseline).abs();

    if total_distance < 1.0 {
        return 100.0; // Already at target (within 1Hz)
    }

    // Distance user has moved
    let user_movement = (user_current - user_baseline).abs();

    // Check if moving in correct direction
    let moving_toward_guide = if guide_target > user_baseline {
        user_current > user_baseline
    } else {
        user_current < user_baseline
    };

    if !moving_toward_guide {
        return 0.0; // Moving away from guide
    }

    // Progress percentage (0-100)
    let progress = (user_movement / total_distance) * 100.0;

    progress.min(100.0) // Cap at 100%
}

fn calculate_pattern_similarity(
    user_patterns: &[PatternDetection],
    guide_patterns: &[String],
) -> f32 {
    // Extract pattern types from user session
    let user_pattern_types: Vec<String> = user_patterns
        .iter()
        .map(|p| format!("{:?}", p.pattern_type).to_lowercase())
        .collect();

    // Count pattern frequency
    let user_pattern_freq: HashMap<String, usize> =
        user_pattern_types.iter().fold(HashMap::new(), |mut acc, p| {
            *acc.entry(p.clone()).or_insert(0) += 1;
            acc
        });

    // Calculate overlap with guide patterns
    let mut overlap_count = 0;
    for guide_pattern in guide_patterns {
        let pattern_key = guide_pattern.to_lowercase();
        if user_pattern_freq.contains_key(&pattern_key) {
            overlap_count += 1;
        }
    }

    // Normalize to 0-1
    if guide_patterns.is_empty() {
        0.5 // Default neutral similarity
    } else {
        overlap_count as f32 / guide_patterns.len() as f32
    }
}

fn calculate_resonance_similarity(
    user_formants: &FormantData,
    guide_formants: &FormantData,
) -> f32 {
    // Euclidean distance in formant space (normalized)
    let f1_distance = (user_formants.f1_mean - guide_formants.f1_mean).abs();
    let f2_distance = (user_formants.f2_mean - guide_formants.f2_mean).abs();

    // Normalize distances (typical F1 range: 300-1000Hz, F2: 800-3000Hz)
    let f1_norm = (f1_distance / 700.0).min(1.0);
    let f2_norm = (f2_distance / 2200.0).min(1.0);

    // Similarity score (1.0 = identical, 0.0 = very different)
    let similarity = 1.0 - ((f1_norm + f2_norm) / 2.0);

    similarity.max(0.0)
}
```

**Unit Tests:**

```rust
#[cfg(test)]
mod tests {
    #[test]
    fn test_pitch_alignment_moving_upward() {
        // Baseline: 165Hz, Current: 195Hz, Guide: 210Hz
        let alignment = calculate_pitch_alignment(195.0, 165.0, 210.0);

        // Expected: (195 - 165) / (210 - 165) * 100 = 66.7%
        assert!((alignment - 66.7).abs() < 1.0);
    }

    #[test]
    fn test_pitch_alignment_already_at_target() {
        let alignment = calculate_pitch_alignment(210.0, 165.0, 210.0);
        assert_eq!(alignment, 100.0);
    }

    #[test]
    fn test_pitch_alignment_moving_away() {
        // Baseline: 165Hz, Current: 150Hz, Guide: 210Hz (moving down instead of up)
        let alignment = calculate_pitch_alignment(150.0, 165.0, 210.0);
        assert_eq!(alignment, 0.0);
    }
}
```

**Estimated Effort:** 3-4 days (Story 2D.8)

---

## 📅 Implementation Roadmap: Epic 2D (Voice Guides Intelligence)

### Phase 1: Foundation (Week 1-2)

**Story 2D.1: Extend User Profile Schema** (2 days)

- Add `selectedGuides`, `guideProgress` fields to user profile
- Update profile storage with atomic writes
- Migration script for existing profiles

**Story 2D.2: Voice Guide Database** (2 days)

- Create voice guide storage (`~/.loqa/voice-intelligence/voice_guides/`)
- Implement guide loading (builtin + custom)
- Add guide CRUD operations

**Story 2D.3: Upgrade Intonation Classification** (3-4 days)

- Implement multi-pattern classifier (rising, falling, upturn, flat)
- Confidence scoring per pattern
- Unit tests with labeled audio samples

**Story 2D.4: Resonance Classification** (2-3 days)

- Rule-based classifier (formants + spectral centroid)
- 5-category output (dark, neutral, bright, dark-warm, bright-forward)
- Confidence scoring

**Story 2D.5: Tempo/Speaking Rate Analysis** (1-2 days)

- Syllable counting or VAD-based speech rate estimation
- Classification (slow, moderate, fast)

---

### Phase 2: Progress Analysis (Week 3)

**Story 2D.6: Progress Comparison Algorithm** (3-4 days)

- Implement pitch alignment calculation
- Intonation pattern similarity
- Resonance alignment
- Overall progress weighting

**Story 2D.7: Trauma-Informed Language Generation** (4-5 days)

- Template-based generation system
- Positive framing rules
- Forbidden phrase validation
- Unit tests for all templates

**Story 2D.8: Journey Visualization Data** (2 days)

- Generate baseline → current → guide visualization data
- Alignment areas classification (aligned, emerging, exploring)
- Exploration areas suggestions

---

### Phase 3: API Endpoints (Week 4)

**Story 2D.9: `POST /voice/analyze-progress-toward-guide`** (3-4 days)

- Endpoint implementation
- Integrate progress comparison algorithm
- Trauma-informed language generation
- Journey visualization output
- Error handling

**Story 2D.10: `POST /voice/analyze-guide`** (2-3 days)

- Custom guide analysis endpoint
- Extract voice characteristics from audio
- Resonance, intonation, tempo classification
- Confidence assessment
- Recommendations for manual adjustment

**Story 2D.11: `GET /voice/guide-suggestions`** (2-3 days)

- Coaching suggestions generation
- Practice prompts based on progress
- Weekly listening recommendations
- Exploration theme generation

---

### Phase 4: Testing & Validation (Week 5)

**Story 2D.12: Integration Testing** (3 days)

- End-to-end journey testing (baseline → progress → suggestions)
- Trauma-informed language validation
- Performance benchmarks (<500ms for progress analysis)

**Story 2D.13: Voice Guide Database Seeding** (2 days)

- Create builtin guide profiles (Emma Watson, Zendaya, etc.)
- Validate guide characteristics accuracy
- Documentation

---

## ⏱️ Timeline Estimate

| Phase                          | Duration                       | Stories     | Dependencies     |
| ------------------------------ | ------------------------------ | ----------- | ---------------- |
| **Phase 1: Foundation**        | 10-12 days                     | 2D.1-2D.5   | Epic 2C complete |
| **Phase 2: Progress Analysis** | 9-11 days                      | 2D.6-2D.8   | Phase 1 complete |
| **Phase 3: API Endpoints**     | 7-10 days                      | 2D.9-2D.11  | Phase 2 complete |
| **Phase 4: Testing**           | 5 days                         | 2D.12-2D.13 | Phase 3 complete |
| **Total**                      | **31-38 days** (4.5-5.5 weeks) | 13 stories  | Epic 2C          |

**Recommended Buffer:** Add 1 week for unforeseen challenges

**Total Estimated Timeline:** **5-6 weeks** development + testing

---

## 🎯 Performance & Accuracy Targets

### Latency Targets (Aligned with Spec)

| Endpoint                                | Target (P50) | Max Acceptable (P95) | Epic 2C Baseline                 |
| --------------------------------------- | ------------ | -------------------- | -------------------------------- |
| `POST /voice/analyze-progress`          | <500ms       | 1000ms               | N/A (new)                        |
| `POST /voice/analyze-guide` (30s audio) | <3s          | 5s                   | ~2.8s (Epic 2C `/voice/analyze`) |
| `GET /voice/guide-suggestions`          | <200ms       | 500ms                | N/A (new)                        |

**Optimization Strategy:**

- Pre-compute progress trends on session save (cache)
- Lazy-load guide characteristics (in-memory cache)
- Async processing for guide analysis

### Accuracy Requirements (Aligned with Spec)

| Metric                            | Minimum Accuracy       | Validation Method                                   |
| --------------------------------- | ---------------------- | --------------------------------------------------- |
| Pitch (F0) detection              | ±5Hz or 95% confidence | ✅ Already validated (Epic 2C)                      |
| Formant extraction                | ±50Hz for F1/F2        | ✅ Already validated (Epic 2C)                      |
| Intonation pattern classification | 85% accuracy           | **New:** Validate with human-labeled dataset        |
| Resonance classification          | 80% accuracy           | **New:** Validate with speech therapist annotations |
| Progress alignment calculation    | ±5% error              | **New:** Unit tests with known values               |

---

## 🔒 Security & Privacy Validation

✅ **All requirements aligned with Epic 2C privacy guarantees:**

1. **Local-Only Storage:** Voice guides stored in `~/.loqa/voice-intelligence/voice_guides/` (chmod 700)
2. **No External APIs:** All ML processing local
3. **User Consent:** Custom guide upload requires explicit consent confirmation (UI responsibility)
4. **Data Deletion:** `DELETE /voice/guide/:guideId` permanently removes audio + metadata
5. **Audio Retention:** Optional (user chooses whether to keep custom guide audio post-analysis)

**Additional Privacy Consideration:**

- **Builtin Voice Guides:** Ensure legal clearance for celebrity voice characteristics (licensing requirement)

---

## 🧪 Testing Strategy

### Unit Tests (Per Story)

**Story 2D.3 (Intonation Classification):**

- Test with synthetic pitch contours (rising, falling, upturn, flat)
- Validate confidence scoring
- Edge cases: Very short audio, noisy pitch detection

**Story 2D.4 (Resonance Classification):**

- Test with known formant values (annotated by speech therapist)
- Target 80% accuracy on validation set

**Story 2D.6 (Progress Comparison):**

- Test pitch alignment formula with known baseline/current/guide values
- Verify 0-100 range output
- Edge cases: User already at target, user beyond target, moving away from guide

**Story 2D.7 (Trauma-Informed Language):**

- **Critical:** Validate no forbidden phrases in generated text
- Test all template variations
- Edge cases: Missing context fields, empty guide names

### Integration Tests (Epic-Level)

**E2E User Journey Test:**

1. User selects Emma Watson as guide (baseline: 165Hz, guide: 210Hz)
2. Practice session 1: User pitch = 175Hz → Progress analysis shows 22% alignment
3. Practice session 5: User pitch = 195Hz → Progress shows 67% alignment
4. Validate coaching suggestions adapt to progress

**Expected Outputs:**

- ✅ Positive progress narrative ("moving toward")
- ✅ NO forbidden language ("65% similar")
- ✅ Adaptive coaching (practice prompts change based on alignment)

### User Acceptance Testing

**Trauma-Informed Language Validation:**

- Review all generated text with trauma-informed UX expert
- Validate no evaluation/comparison language
- Ensure positive framing in all edge cases (no progress, regression, overshoot)

---

## 🚀 Deployment Plan

### Feature Flag Strategy

```toml
# ~/.loqa/config.toml
[features]
voice_intelligence = true       # Epic 2C (existing)
voice_guides = true             # Epic 2D (new)
```

**Rollout Phases:**

**Phase 1:** Internal testing (Voiceline team + Loqa team)

- Feature flag: `voice_guides = false` (default)
- Manual enable for testing

**Phase 2:** Beta testing (select Voiceline users)

- Feature flag: `voice_guides = true` for beta cohort
- Collect feedback on trauma-informed language quality

**Phase 3:** General availability

- Feature flag: `voice_guides = true` (default)
- Bundled with Loqa release (version TBD)

---

## 📋 Open Questions & Decisions Needed

### Technical Decisions

**Q1: Builtin Voice Guide Curation**

- **Question:** Which celebrity voices should be included in builtin guides?
- **Decision Needed:** Legal clearance, licensing, diversity representation
- **Owner:** Voiceline team (Anna / Mary)

**Q2: Custom Guide Audio Retention**

- **Question:** Should custom guide audio be kept after analysis or deleted?
- **Options:**
  - Delete immediately (privacy-first)
  - Keep with user consent (allows re-analysis if algorithm improves)
  - User choice (settings toggle)
- **Recommendation:** User choice (default: delete after 30 days)

**Q3: Progress Metric Weighting**

- **Question:** Should overall progress be weighted equally (pitch 40%, intonation 40%, resonance 20%) or user-customizable?
- **Current:** Fixed weighting (simpler)
- **Future:** User can set priorities ("I care more about intonation than pitch")

### Integration Questions

**Q4: Voiceline On-Device Feature Extraction**

- **Question:** How much voice analysis happens on-device (Voiceline mobile) vs. server (Loqa)?
- **Current Understanding:** Voiceline extracts basic pitch + intonation, sends to Loqa for advanced analysis
- **Clarification Needed:** Exact division of responsibilities (performance trade-off)

**Q5: Real-Time Feedback Latency**

- **Question:** Does Voiceline need <100ms real-time feedback during recording, or is post-session analysis (<500ms) acceptable?
- **Current Spec:** Post-session analysis (easier to implement)
- **Future Enhancement:** Real-time analysis (requires streaming endpoint)

---

## 🎯 Success Criteria

### Technical Success

- ✅ All 3 new endpoints implemented and tested
- ✅ Intonation classification achieves 85% accuracy
- ✅ Resonance classification achieves 80% accuracy
- ✅ Progress analysis latency <500ms (P50)
- ✅ All trauma-informed language validates (no forbidden phrases)

### User Experience Success

- ✅ Users report progress narratives feel **empowering, not evaluative**
- ✅ Coaching suggestions perceived as **helpful and adaptive**
- ✅ NO users report feeling **compared to celebrity guides** (critical)
- ✅ Custom guide creation works smoothly with clear privacy messaging

### Privacy Success

- ✅ Zero external API calls (validated via network monitoring)
- ✅ All voice data stored locally with user-only permissions
- ✅ Users understand data ownership (custom guides are theirs to delete)

---

## 📬 Next Steps

### For Loqa Team (Anna):

1. **Review this architectural response** and validate approach
2. **Decide on Epic 2D prioritization** (after Epic 2C? Parallel track?)
3. **Answer open questions** (Q1-Q5 above)
4. **Provide builtin voice guide data** (celebrity voice characteristics for seeding)
5. **Schedule technical sync** with Voiceline team (week of Nov 11?)

### For Voiceline Team:

1. **Review technical answers** (Q1-Q7) and confirm alignment
2. **Provide builtin guide profiles** (Emma Watson, Zendaya, etc. characteristics)
3. **Clarify on-device vs. server processing split** (Q4)
4. **Provide labeled audio samples** for intonation/resonance validation
5. **Define trauma-informed language review process** (UX expert involvement)

### Joint Activities:

1. **Technical alignment meeting** (discuss Epic 2D roadmap)
2. **Builtin guide curation** (legal, licensing, diversity)
3. **Integration testing plan** (Voiceline mobile + Loqa server E2E)
4. **Trauma-informed language validation** (review all templates together)

---

## 📚 Appendix: Architecture Diagrams

### Voice Guides Data Flow

```
┌─────────────────────────────────────┐
│   Voiceline Mobile App              │
│                                     │
│   1. User selects Emma Watson      │
│   2. Completes practice session    │
│   3. Extracts on-device features:  │
│      • Pitch: 195Hz mean           │
│      • Intonation: [upturn, rising]│
└──────────────┬──────────────────────┘
               │ HTTP POST /voice/analyze-progress-toward-guide
               │ {
               │   userVoiceFeatures: {...},
               │   baselineFeatures: {...},
               │   guideCharacteristics: {...}
               │ }
               ▼
┌──────────────────────────────────────┐
│   Loqa Voice Intelligence Backend    │
│                                      │
│   4. Load Emma Watson guide profile  │
│   5. Calculate progress:             │
│      • Pitch alignment: 67%          │
│      • Intonation similarity: 0.72   │
│      • Resonance alignment: 0.68     │
│   6. Generate trauma-informed text:  │
│      "Your pitch range is moving     │
│       toward the characteristics     │
│       you chose"                     │
│   7. Suggest adaptive coaching:      │
│      • Listen to Emma on podcast X   │
│      • Practice question patterns    │
└──────────────┬───────────────────────┘
               │ Response (JSON)
               ▼
┌─────────────────────────────────────┐
│   Voiceline Mobile App              │
│                                     │
│   8. Display "Your Voice Journey":  │
│      • Baseline → Current → Guide   │
│      • Progress narrative           │
│      • Weekly listening suggestion  │
│      • Practice prompts             │
└─────────────────────────────────────┘
```

---

**Thank you for the detailed Voice Guides specification! This is an exciting extension of our collaboration. I look forward to discussing the implementation roadmap and ensuring the trauma-informed UX requirements are met with excellence.** 🚀

---

**Contact:**

- **Loqa Architect:** Winston (via Anna)
- **Voiceline Team:** Anna (Product) / Mary (BA)

**Recommended Next Meeting:** Technical alignment sync (week of November 11, 2025)
