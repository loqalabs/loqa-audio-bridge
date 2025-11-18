# Loqa Voice DSP - Hybrid Implementation Specification

**Date:** 2025-11-07
**Project:** Voiceline Mobile App
**Implementation Approach:** Option 3 - Hybrid (Core DSP in Rust, Business Logic in JavaScript)
**Target Timeline:** 7-10 days development

---

## Executive Summary

This specification defines a **shared Rust crate (`loqa-voice-dsp`)** that provides core DSP functionality for both the Voiceline mobile app and the Loqa backend. The hybrid approach balances performance (Rust for computationally intensive operations) with development velocity (JavaScript for business logic and UI transformations).

**Key Decision:** Computationally intensive DSP operations in Rust, pattern recognition and business logic in JavaScript.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Voiceline Mobile App                     │
│                                                             │
│  ┌──────────────────────┐      ┌──────────────────────┐   │
│  │  JavaScript Layer    │      │   Rust DSP Crate     │   │
│  │                      │      │  (loqa-voice-dsp)    │   │
│  │ • Intonation class.  │◄────►│                      │   │
│  │ • Progress calc.     │ FFI  │ • Formant extract.   │   │
│  │ • UI transforms      │      │ • Pitch detection    │   │
│  │ • Voice Guides logic │      │ • FFT utilities      │   │
│  │                      │      │ • Spectral analysis  │   │
│  └──────────────────────┘      └──────────────────────┘   │
│                                          │                  │
└──────────────────────────────────────────┼──────────────────┘
                                           │
                                           │ (Same crate)
                                           │
┌──────────────────────────────────────────┼──────────────────┐
│                    Loqa Backend          │                  │
│                                          ▼                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          Rust DSP Crate (loqa-voice-dsp)             │  │
│  │  • Formant extraction • Pitch detection • FFT        │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                 │
│                           ▼                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          Python/Backend Business Logic               │  │
│  │  • LLM enhancement • Voice Guide suggestions         │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Rust Crate API Specification

### Crate Name
`loqa-voice-dsp`

### Core Modules

#### 1. Formant Extraction (`formants.rs`)

```rust
pub struct FormantResult {
    pub f1: f32,  // First formant (Hz)
    pub f2: f32,  // Second formant (Hz)
    pub f3: f32,  // Third formant (Hz)
    pub confidence: f32,  // 0.0-1.0 quality metric
}

/// Extract formants using Linear Predictive Coding (LPC)
///
/// # Arguments
/// * `audio_samples` - Audio samples (normalized -1.0 to 1.0)
/// * `sample_rate` - Sample rate in Hz (typically 44100)
/// * `lpc_order` - LPC order (typically 12-16 for speech)
///
/// # Returns
/// FormantResult or error if extraction fails
pub fn extract_formants(
    audio_samples: &[f32],
    sample_rate: u32,
    lpc_order: usize,
) -> Result<FormantResult, String>;
```

**Implementation Details:**
- Pre-emphasis filter (α = 0.97)
- Hamming window application
- Autocorrelation calculation
- Levinson-Durbin recursion for LPC coefficients
- Polynomial root finding for formant frequencies
- Confidence scoring based on spectral envelope fit

---

#### 2. Pitch Detection (`pitch.rs`)

```rust
pub struct PitchResult {
    pub frequency: f32,  // Fundamental frequency in Hz (0.0 if unvoiced)
    pub confidence: f32, // 0.0-1.0 quality metric
    pub is_voiced: bool, // True if voiced sound detected
}

/// Detect pitch using YIN algorithm
///
/// # Arguments
/// * `audio_samples` - Audio samples (normalized -1.0 to 1.0)
/// * `sample_rate` - Sample rate in Hz (typically 44100)
/// * `min_frequency` - Minimum expected pitch (e.g., 80 Hz)
/// * `max_frequency` - Maximum expected pitch (e.g., 400 Hz)
///
/// # Returns
/// PitchResult or error if detection fails
pub fn detect_pitch(
    audio_samples: &[f32],
    sample_rate: u32,
    min_frequency: f32,
    max_frequency: f32,
) -> Result<PitchResult, String>;
```

**Implementation Details:**
- YIN algorithm (Difference function + Cumulative Mean Normalized Difference)
- Absolute threshold (typically 0.1)
- Parabolic interpolation for sub-sample accuracy
- Voiced/unvoiced detection

---

#### 3. FFT Utilities (`fft.rs`)

```rust
pub struct FFTResult {
    pub magnitudes: Vec<f32>,  // Magnitude spectrum
    pub frequencies: Vec<f32>, // Frequency bins (Hz)
    pub sample_rate: u32,
}

/// Compute FFT magnitude spectrum
///
/// # Arguments
/// * `audio_samples` - Audio samples (normalized -1.0 to 1.0)
/// * `sample_rate` - Sample rate in Hz
/// * `fft_size` - FFT size (power of 2, e.g., 2048)
///
/// # Returns
/// FFTResult containing magnitude spectrum and frequency bins
pub fn compute_fft(
    audio_samples: &[f32],
    sample_rate: u32,
    fft_size: usize,
) -> Result<FFTResult, String>;
```

**Implementation Details:**
- Use `rustfft` crate for FFT computation
- Hamming window application
- Magnitude calculation (sqrt(re² + im²))
- Frequency bin calculation

---

#### 4. Spectral Analysis (`spectral.rs`)

```rust
pub struct SpectralFeatures {
    pub centroid: f32,      // Spectral centroid (Hz) - "brightness"
    pub tilt: f32,          // Spectral tilt (dB/octave) - "resonance"
    pub rolloff_95: f32,    // 95% rolloff frequency (Hz)
}

/// Calculate spectral features from FFT result
///
/// # Arguments
/// * `fft_result` - FFT result from compute_fft()
///
/// # Returns
/// SpectralFeatures
pub fn analyze_spectrum(
    fft_result: &FFTResult,
) -> Result<SpectralFeatures, String>;
```

**Implementation Details:**
- Spectral centroid: weighted mean of frequencies
- Spectral tilt: slope of log-magnitude spectrum
- Rolloff: frequency below which 95% of energy resides

---

## FFI Bridge Specification

### iOS Bridge (Swift)

**File:** `ios/VoicelineDSP.swift`

```swift
import Foundation

struct FormantResult {
    let f1: Float
    let f2: Float
    let f3: Float
    let confidence: Float
}

class VoicelineDSP {
    static func extractFormants(
        audioSamples: [Float],
        sampleRate: UInt32,
        lpcOrder: UInt32 = 12
    ) -> FormantResult? {
        // Call C-compatible Rust function via FFI
        let result = loqa_extract_formants(
            audioSamples,
            audioSamples.count,
            sampleRate,
            lpcOrder
        )

        guard result.success else { return nil }

        return FormantResult(
            f1: result.f1,
            f2: result.f2,
            f3: result.f3,
            confidence: result.confidence
        )
    }
}
```

**Rust FFI Function:**

```rust
#[repr(C)]
pub struct FormantResultFFI {
    pub f1: f32,
    pub f2: f32,
    pub f3: f32,
    pub confidence: f32,
    pub success: bool,
}

#[no_mangle]
pub extern "C" fn loqa_extract_formants(
    audio_ptr: *const f32,
    audio_len: usize,
    sample_rate: u32,
    lpc_order: u32,
) -> FormantResultFFI {
    if audio_ptr.is_null() {
        return FormantResultFFI {
            f1: 0.0, f2: 0.0, f3: 0.0,
            confidence: 0.0,
            success: false,
        };
    }

    let audio_samples = unsafe {
        std::slice::from_raw_parts(audio_ptr, audio_len)
    };

    match extract_formants(audio_samples, sample_rate, lpc_order as usize) {
        Ok(result) => FormantResultFFI {
            f1: result.f1,
            f2: result.f2,
            f3: result.f3,
            confidence: result.confidence,
            success: true,
        },
        Err(_) => FormantResultFFI {
            f1: 0.0, f2: 0.0, f3: 0.0,
            confidence: 0.0,
            success: false,
        },
    }
}
```

---

### Android Bridge (JNI)

**File:** `android/app/src/main/java/com/voiceline/VoicelineDSP.java`

```java
package com.voiceline;

public class VoicelineDSP {
    static {
        System.loadLibrary("loqa_voice_dsp");
    }

    public static class FormantResult {
        public float f1;
        public float f2;
        public float f3;
        public float confidence;
        public boolean success;
    }

    public native static FormantResult extractFormants(
        float[] audioSamples,
        int sampleRate,
        int lpcOrder
    );
}
```

**Rust JNI Function:**

```rust
use jni::JNIEnv;
use jni::objects::{JClass, JObject};
use jni::sys::{jfloatArray, jint, jobject};

#[no_mangle]
pub extern "system" fn Java_com_voiceline_VoicelineDSP_extractFormants(
    env: JNIEnv,
    _class: JClass,
    audio_array: jfloatArray,
    sample_rate: jint,
    lpc_order: jint,
) -> jobject {
    // Convert jfloatArray to Rust slice
    let audio_samples = env.get_float_array_elements(audio_array, jni::objects::ReleaseMode::NoCopyBack)
        .expect("Failed to get audio array");

    let audio_slice = unsafe {
        std::slice::from_raw_parts(
            audio_samples.as_ptr(),
            audio_samples.size().unwrap() as usize
        )
    };

    // Call Rust function
    let result = extract_formants(audio_slice, sample_rate as u32, lpc_order as usize);

    // Create Java object and return
    // (Full JNI object creation code omitted for brevity)
    // Returns FormantResult Java object
    std::ptr::null_mut() // Placeholder
}
```

---

## JavaScript Integration Layer

### Responsibility Boundaries

**Rust handles:**
- ✅ Formant extraction (LPC algorithm)
- ✅ Pitch detection (YIN algorithm)
- ✅ FFT computation (spectral analysis)
- ✅ Spectral features (centroid, tilt, rolloff)

**JavaScript handles:**
- ✅ Intonation pattern classification (rising, falling, upturn, flat)
- ✅ Progress comparison (baseline → current → guide)
- ✅ UI data transformations
- ✅ Voice Guides selection logic
- ✅ Session history aggregation

### Example JavaScript Integration

```javascript
import { VoicelineDSP } from './native-modules/VoicelineDSP';

// 1. Extract formants using Rust
const formantResult = await VoicelineDSP.extractFormants(
  audioSamples,
  44100,  // sample rate
  12      // LPC order
);

// 2. Classify intonation in JavaScript (pure logic)
function classifyIntonation(pitchContour, timestamps) {
  const slopes = [];

  for (let i = 1; i < pitchContour.length; i++) {
    const deltaF = pitchContour[i] - pitchContour[i - 1];
    const deltaT = timestamps[i] - timestamps[i - 1];
    slopes.push((deltaF / deltaT) * 1000); // Hz/sec
  }

  const avgSlope = slopes.reduce((a, b) => a + b, 0) / slopes.length;
  const finalSlope = slopes[slopes.length - 1];

  if (avgSlope > 15) return 'rising';
  if (avgSlope < -15) return 'falling';
  if (finalSlope > 20) return 'upturn';
  return 'flat';
}

// 3. Calculate progress in JavaScript (pure math)
function calculateProximityProgress(userCurrent, userBaseline, guideTarget) {
  const baselineToGuideDistance = Math.abs(guideTarget - userBaseline);
  const currentToGuideDistance = Math.abs(guideTarget - userCurrent);

  const progressPercent =
    ((baselineToGuideDistance - currentToGuideDistance) / baselineToGuideDistance) * 100;

  return {
    progressPercent: Math.max(0, Math.min(100, progressPercent)),
    status: progressPercent > 60 ? 'approaching' : 'exploring'
  };
}
```

---

## Implementation Timeline

### Week 1 (Days 1-5): Core Rust Crate Development

**Day 1-2: Project Setup**
- Initialize Rust crate with Cargo
- Set up CI/CD for testing
- Configure `rustfft` and `ndarray` dependencies
- Create module structure (formants, pitch, fft, spectral)

**Day 3-4: Core DSP Implementation**
- Implement formant extraction (LPC, Levinson-Durbin)
- Implement pitch detection (YIN algorithm)
- Implement FFT utilities
- Implement spectral analysis (centroid, tilt)

**Day 5: Unit Testing**
- Write comprehensive unit tests
- Test with synthetic audio signals
- Validate against known reference implementations

### Week 2 (Days 6-10): FFI Bridges & Integration

**Day 6-7: iOS FFI Bridge**
- Create C-compatible FFI functions
- Build Swift wrapper classes
- Test on iOS simulator
- Profile performance

**Day 8-9: Android JNI Bridge**
- Create JNI bindings
- Build Java wrapper classes
- Test on Android emulator
- Profile performance

**Day 10: Integration Testing & Documentation**
- End-to-end testing with real audio
- Performance benchmarking
- API documentation
- Integration examples for Voiceline team

---

## Testing Strategy

### Unit Tests (Rust)

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_formant_extraction_vowel_a() {
        // Generate synthetic /a/ vowel at 100 Hz
        let audio = generate_vowel_a(100.0, 44100, 0.5);
        let result = extract_formants(&audio, 44100, 12).unwrap();

        // Expected formants for /a/: F1 ≈ 700 Hz, F2 ≈ 1200 Hz
        assert!((result.f1 - 700.0).abs() < 50.0);
        assert!((result.f2 - 1200.0).abs() < 100.0);
        assert!(result.confidence > 0.7);
    }

    #[test]
    fn test_pitch_detection_pure_tone() {
        // Generate 200 Hz pure tone
        let audio = generate_sine_wave(200.0, 44100, 0.5);
        let result = detect_pitch(&audio, 44100, 80.0, 400.0).unwrap();

        assert!((result.frequency - 200.0).abs() < 1.0);
        assert!(result.is_voiced);
        assert!(result.confidence > 0.9);
    }
}
```

### Integration Tests (JavaScript)

```javascript
describe('VoicelineDSP Integration', () => {
  it('should extract formants from real audio', async () => {
    const audioBuffer = await loadTestAudio('vowel_a.wav');
    const formants = await VoicelineDSP.extractFormants(
      audioBuffer,
      44100,
      12
    );

    expect(formants.f1).toBeGreaterThan(600);
    expect(formants.f1).toBeLessThan(800);
    expect(formants.confidence).toBeGreaterThan(0.7);
  });
});
```

---

## Performance Requirements

| Operation | Target Latency | Notes |
|-----------|---------------|-------|
| Formant extraction | < 50ms | For 500ms audio window |
| Pitch detection | < 20ms | For 100ms audio window |
| FFT computation | < 10ms | For 2048-point FFT |
| Spectral analysis | < 5ms | Post-FFT processing |

**Memory:** Maximum 10MB allocated during processing

**Battery Impact:** Minimal (DSP runs on-demand, not continuously)

---

## Dependencies

### Rust Crate Dependencies

```toml
[package]
name = "loqa-voice-dsp"
version = "0.1.0"
edition = "2021"

[dependencies]
rustfft = "6.1"
ndarray = "0.15"
realfft = "3.3"

[lib]
crate-type = ["cdylib", "staticlib"]  # For FFI

[dev-dependencies]
approx = "0.5"  # For float comparisons in tests
```

### React Native Dependencies

```json
{
  "dependencies": {
    "react-native-fs": "^2.20.0"  // For loading audio files in tests
  }
}
```

---

## Code Sharing Between Mobile and Backend

The Rust crate can be used identically in both contexts:

**Mobile (via FFI):**
```javascript
// React Native
import { VoicelineDSP } from './native-modules/VoicelineDSP';
const formants = await VoicelineDSP.extractFormants(audioSamples, 44100, 12);
```

**Backend (native Rust):**
```python
# Python backend using PyO3 bindings
import loqa_voice_dsp

formants = loqa_voice_dsp.extract_formants(audio_samples, 44100, 12)
```

This ensures:
- ✅ **Consistency**: Identical DSP algorithms across platforms
- ✅ **Maintainability**: Single source of truth for core logic
- ✅ **Testing**: Shared test suite for both mobile and backend

---

## Open Questions for Loqa Team

1. **Backend Integration Preference:**
   - Would you prefer PyO3 (Python bindings) or direct Rust server integration?
   - Any existing Rust infrastructure we should align with?

2. **Formant Validation:**
   - Do you have reference audio samples with known formant values for validation?
   - Any specific edge cases we should test (accents, voice conditions)?

3. **Delivery Format:**
   - Preferred delivery method for Rust crate (Git repo, Cargo registry)?
   - Documentation format preferences (rustdoc, separate markdown)?

4. **Timeline Constraints:**
   - Any hard deadlines for Loqa backend integration?
   - Preferred sprint schedule for collaboration?

---

## Next Steps

1. **Loqa Team Review** (2-3 days)
   - Review this specification
   - Provide feedback on API design
   - Answer open questions

2. **Kickoff Meeting** (1 day)
   - Align on implementation details
   - Establish communication channels
   - Set up shared Git repository

3. **Development Sprints** (7-10 days)
   - Week 1: Core Rust crate development
   - Week 2: FFI bridges and integration testing

4. **Handoff & Documentation** (2 days)
   - API documentation
   - Integration guides
   - Performance benchmarks

---

## Contact

**Voiceline Team:**
- Anna (Developer)

**Loqa Team:**
- [To be filled in]

**Collaboration Channel:**
- [To be determined - Slack, GitHub Discussions, etc.]

---

**Document Version:** 1.0
**Last Updated:** 2025-11-07
**Status:** Awaiting Loqa Team Review
