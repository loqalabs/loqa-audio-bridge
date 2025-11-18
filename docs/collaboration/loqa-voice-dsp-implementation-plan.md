# Loqa Voice DSP - Implementation Plan

**Date:** November 7, 2025
**From:** Loqa Architecture Team (Winston)
**To:** Voiceline Team (Anna) & Loqa Team
**Subject:** Shared Rust DSP Crate - Implementation Roadmap
**Reference:** [loqa-voice-dsp-hybrid-spec.md](./loqa-voice-dsp-hybrid-spec.md)

---

## 🎯 Executive Summary

The Voiceline team's hybrid specification is **excellent** and aligns perfectly with Loqa's existing architecture. **Key insight:** Loqa already has most of the DSP code in `loqa-core/audio` - we should extract it into the shared `loqa-voice-dsp` crate rather than rebuild from scratch.

**Timeline:** 10-15 days total (parallel work opportunities)

**Approach:** Extract existing Loqa DSP → Add FFI bridges → Integration testing

---

## ✅ What Loqa Already Has (Epic 2C)

From [architecture.md](../architecture.md) and Epic 2C implementation:

| Component | Status | Location | Reusable? |
|-----------|--------|----------|-----------|
| **YIN Pitch Detection** | ✅ Implemented | `loqa-core/src/audio/analysis.rs` | **YES** |
| **LPC Formant Extraction** | ✅ Implemented | `loqa-core/src/audio/analysis.rs` | **YES** |
| **FFT Utilities** | ✅ Implemented | `loqa-core/src/audio/analysis.rs` | **YES** (uses rustfft) |
| **Spectral Analysis** | ⚠️ Partial | `loqa-core/src/audio/features.rs` | **YES** (needs spectral tilt) |

**Good news:** We have 90% of the DSP code already! Just need to:
1. Extract into standalone crate
2. Add FFI layer for mobile
3. Add missing spectral tilt calculation

---

## 🏗️ Recommended Architecture

### **Shared Crate: `loqa-voice-dsp`**

```
loqa/
├── crates/
│   ├── loqa-voice-dsp/          ← NEW shared crate (extracted from loqa-core)
│   │   ├── src/
│   │   │   ├── lib.rs           ← Public API
│   │   │   ├── pitch.rs         ← YIN algorithm (from loqa-core)
│   │   │   ├── formants.rs      ← LPC formants (from loqa-core)
│   │   │   ├── fft.rs           ← FFT utilities (from loqa-core)
│   │   │   ├── spectral.rs      ← Spectral analysis (from loqa-core + new)
│   │   │   └── ffi/             ← FFI exports for mobile
│   │   │       ├── mod.rs
│   │   │       ├── ios.rs       ← C-compatible exports
│   │   │       └── android.rs   ← JNI exports
│   │   ├── benches/
│   │   │   └── dsp_benchmarks.rs
│   │   ├── tests/
│   │   │   └── integration_tests.rs
│   │   ├── Cargo.toml
│   │   ├── build.rs             ← iOS/Android build script
│   │   └── README.md
│   │
│   ├── loqa-core/               ← NOW depends on loqa-voice-dsp
│   │   ├── Cargo.toml           ← [dependencies] loqa-voice-dsp = { path = "../loqa-voice-dsp" }
│   │   └── src/
│   │       └── audio/           ← Import from loqa-voice-dsp
│   │
│   └── loqa-voice-intelligence/ ← Uses loqa-voice-dsp directly
       └── Cargo.toml            ← [dependencies] loqa-voice-dsp = { path = "../loqa-voice-dsp" }
```

---

## 📅 Implementation Timeline

### **Phase 1: Extract DSP Crate (Loqa Team - 2-3 days)**

**Task 1.1: Create New Crate (Day 1 morning)**
```bash
cd loqa/crates
cargo new loqa-voice-dsp --lib
```

**Cargo.toml:**
```toml
[package]
name = "loqa-voice-dsp"
version = "0.1.0"
edition = "2021"
authors = ["Loqa Labs"]
description = "Shared DSP library for voice analysis (pitch, formants, spectral features)"
license = "MIT"

[dependencies]
rustfft = "6.1"
realfft = "3.3"
ndarray = "0.15"

[lib]
crate-type = ["cdylib", "staticlib", "rlib"]  # cdylib/staticlib for FFI, rlib for Rust

[dev-dependencies]
approx = "0.5"
criterion = "0.5"

[[bench]]
name = "dsp_benchmarks"
harness = false
```

**Task 1.2: Extract Pitch Detection (Day 1 afternoon)**

Copy from `loqa-core/src/audio/analysis.rs` → `loqa-voice-dsp/src/pitch.rs`

**New API (matches Voiceline spec):**
```rust
// loqa-voice-dsp/src/pitch.rs

pub struct PitchResult {
    pub frequency: f32,
    pub confidence: f32,
    pub is_voiced: bool,
}

/// Detect pitch using YIN algorithm
pub fn detect_pitch(
    audio_samples: &[f32],
    sample_rate: u32,
    min_frequency: f32,
    max_frequency: f32,
) -> Result<PitchResult, String> {
    // Existing YIN implementation from loqa-core
    // (Already tested and validated in Epic 2C)

    let threshold = 0.1;
    let yin_buffer = compute_yin_difference_function(audio_samples);
    let tau = find_absolute_threshold(&yin_buffer, threshold);

    if tau == 0 {
        return Ok(PitchResult {
            frequency: 0.0,
            confidence: 0.0,
            is_voiced: false,
        });
    }

    let better_tau = parabolic_interpolation(&yin_buffer, tau);
    let frequency = sample_rate as f32 / better_tau;

    // Confidence from YIN buffer value
    let confidence = 1.0 - yin_buffer[tau];

    Ok(PitchResult {
        frequency,
        confidence,
        is_voiced: frequency >= min_frequency && frequency <= max_frequency,
    })
}
```

**Task 1.3: Extract Formant Extraction (Day 2 morning)**

Copy from `loqa-core/src/audio/analysis.rs` → `loqa-voice-dsp/src/formants.rs`

**New API (matches Voiceline spec):**
```rust
// loqa-voice-dsp/src/formants.rs

pub struct FormantResult {
    pub f1: f32,
    pub f2: f32,
    pub f3: f32,
    pub confidence: f32,
}

/// Extract formants using Linear Predictive Coding (LPC)
pub fn extract_formants(
    audio_samples: &[f32],
    sample_rate: u32,
    lpc_order: usize,
) -> Result<FormantResult, String> {
    // Existing LPC implementation from loqa-core

    // 1. Pre-emphasis filter
    let pre_emphasized = apply_pre_emphasis(audio_samples, 0.97);

    // 2. Hamming window
    let windowed = apply_hamming_window(&pre_emphasized);

    // 3. Autocorrelation
    let autocorr = compute_autocorrelation(&windowed, lpc_order);

    // 4. Levinson-Durbin algorithm
    let lpc_coeffs = levinson_durbin(&autocorr)?;

    // 5. Find formant peaks
    let formants = find_formant_peaks(&lpc_coeffs, sample_rate)?;

    // 6. Calculate confidence
    let confidence = calculate_formant_confidence(&formants, &lpc_coeffs);

    Ok(FormantResult {
        f1: formants[0],
        f2: formants[1],
        f3: formants.get(2).copied().unwrap_or(0.0),
        confidence,
    })
}
```

**Task 1.4: Extract FFT Utilities (Day 2 afternoon)**

```rust
// loqa-voice-dsp/src/fft.rs

use rustfft::{FftPlanner, num_complex::Complex};

pub struct FFTResult {
    pub magnitudes: Vec<f32>,
    pub frequencies: Vec<f32>,
    pub sample_rate: u32,
}

/// Compute FFT magnitude spectrum
pub fn compute_fft(
    audio_samples: &[f32],
    sample_rate: u32,
    fft_size: usize,
) -> Result<FFTResult, String> {
    if audio_samples.len() < fft_size {
        return Err("Audio buffer too short for FFT size".to_string());
    }

    // Apply Hamming window
    let windowed = apply_hamming_window(&audio_samples[..fft_size]);

    // Convert to complex
    let mut buffer: Vec<Complex<f32>> = windowed
        .iter()
        .map(|&x| Complex::new(x, 0.0))
        .collect();

    // Perform FFT
    let mut planner = FftPlanner::new();
    let fft = planner.plan_fft_forward(fft_size);
    fft.process(&mut buffer);

    // Calculate magnitudes
    let magnitudes: Vec<f32> = buffer
        .iter()
        .take(fft_size / 2)
        .map(|c| (c.re * c.re + c.im * c.im).sqrt())
        .collect();

    // Calculate frequency bins
    let frequencies: Vec<f32> = (0..fft_size / 2)
        .map(|i| i as f32 * sample_rate as f32 / fft_size as f32)
        .collect();

    Ok(FFTResult {
        magnitudes,
        frequencies,
        sample_rate,
    })
}
```

**Task 1.5: Add Spectral Analysis (Day 3 morning)**

```rust
// loqa-voice-dsp/src/spectral.rs

pub struct SpectralFeatures {
    pub centroid: f32,
    pub tilt: f32,
    pub rolloff_95: f32,
}

/// Calculate spectral features from FFT result
pub fn analyze_spectrum(fft_result: &FFTResult) -> Result<SpectralFeatures, String> {
    let magnitudes = &fft_result.magnitudes;
    let frequencies = &fft_result.frequencies;

    // Spectral centroid (weighted mean frequency)
    let total_energy: f32 = magnitudes.iter().sum();
    let weighted_sum: f32 = magnitudes
        .iter()
        .zip(frequencies.iter())
        .map(|(mag, freq)| mag * freq)
        .sum();
    let centroid = weighted_sum / total_energy;

    // Spectral tilt (slope of log-magnitude spectrum)
    let tilt = calculate_spectral_tilt(magnitudes, frequencies);

    // Rolloff (frequency below which 95% of energy resides)
    let rolloff_95 = calculate_rolloff(magnitudes, frequencies, 0.95);

    Ok(SpectralFeatures {
        centroid,
        tilt,
        rolloff_95,
    })
}

fn calculate_spectral_tilt(magnitudes: &[f32], frequencies: &[f32]) -> f32 {
    // Linear regression on log-magnitude spectrum
    let log_mags: Vec<f32> = magnitudes.iter().map(|m| m.ln()).collect();

    let n = log_mags.len() as f32;
    let sum_x: f32 = frequencies.iter().sum();
    let sum_y: f32 = log_mags.iter().sum();
    let sum_xy: f32 = frequencies.iter().zip(log_mags.iter()).map(|(x, y)| x * y).sum();
    let sum_x2: f32 = frequencies.iter().map(|x| x * x).sum();

    // Slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
    (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
}

fn calculate_rolloff(magnitudes: &[f32], frequencies: &[f32], threshold: f32) -> f32 {
    let total_energy: f32 = magnitudes.iter().sum();
    let target_energy = total_energy * threshold;

    let mut cumulative_energy = 0.0;
    for (i, mag) in magnitudes.iter().enumerate() {
        cumulative_energy += mag;
        if cumulative_energy >= target_energy {
            return frequencies[i];
        }
    }

    frequencies.last().copied().unwrap_or(0.0)
}
```

**Task 1.6: Update loqa-core to Use New Crate (Day 3 afternoon)**

```toml
# loqa-core/Cargo.toml
[dependencies]
loqa-voice-dsp = { path = "../loqa-voice-dsp" }
```

```rust
// loqa-core/src/audio/mod.rs
pub use loqa_voice_dsp::{
    detect_pitch, extract_formants, compute_fft, analyze_spectrum,
    PitchResult, FormantResult, FFTResult, SpectralFeatures,
};
```

---

### **Phase 2: Add FFI Bridges (Loqa Team - 2-3 days)**

**Task 2.1: iOS FFI Layer (Day 4-5)**

```rust
// loqa-voice-dsp/src/ffi/ios.rs

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

    match crate::extract_formants(audio_samples, sample_rate, lpc_order as usize) {
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

#[repr(C)]
pub struct PitchResultFFI {
    pub frequency: f32,
    pub confidence: f32,
    pub is_voiced: bool,
    pub success: bool,
}

#[no_mangle]
pub extern "C" fn loqa_detect_pitch(
    audio_ptr: *const f32,
    audio_len: usize,
    sample_rate: u32,
    min_frequency: f32,
    max_frequency: f32,
) -> PitchResultFFI {
    if audio_ptr.is_null() {
        return PitchResultFFI {
            frequency: 0.0,
            confidence: 0.0,
            is_voiced: false,
            success: false,
        };
    }

    let audio_samples = unsafe {
        std::slice::from_raw_parts(audio_ptr, audio_len)
    };

    match crate::detect_pitch(audio_samples, sample_rate, min_frequency, max_frequency) {
        Ok(result) => PitchResultFFI {
            frequency: result.frequency,
            confidence: result.confidence,
            is_voiced: result.is_voiced,
            success: true,
        },
        Err(_) => PitchResultFFI {
            frequency: 0.0,
            confidence: 0.0,
            is_voiced: false,
            success: false,
        },
    }
}
```

**Build Script for iOS:**
```rust
// loqa-voice-dsp/build.rs
fn main() {
    // iOS build configuration
    if std::env::var("TARGET").unwrap().contains("ios") {
        println!("cargo:rustc-link-lib=framework=Foundation");
    }
}
```

**Task 2.2: Android JNI Layer (Day 6)**

```rust
// loqa-voice-dsp/src/ffi/android.rs
use jni::JNIEnv;
use jni::objects::{JClass, JObject};
use jni::sys::{jfloatArray, jint, jfloat, jboolean};

#[no_mangle]
pub extern "system" fn Java_com_voiceline_VoicelineDSP_extractFormants(
    env: JNIEnv,
    _class: JClass,
    audio_array: jfloatArray,
    sample_rate: jint,
    lpc_order: jint,
) -> JObject {
    // JNI boilerplate to convert Java arrays to Rust slices
    let audio_elements = env.get_float_array_elements(audio_array, jni::objects::ReleaseMode::NoCopyBack)
        .expect("Failed to get audio array");

    let audio_slice = unsafe {
        std::slice::from_raw_parts(
            audio_elements.as_ptr(),
            audio_elements.size().unwrap() as usize
        )
    };

    // Call Rust function
    let result = match crate::extract_formants(audio_slice, sample_rate as u32, lpc_order as usize) {
        Ok(r) => r,
        Err(_) => {
            // Return error object
            return JObject::null();
        }
    };

    // Create Java FormantResult object
    let class = env.find_class("com/voiceline/VoicelineDSP$FormantResult")
        .expect("FormantResult class not found");

    let obj = env.alloc_object(class).expect("Failed to allocate object");

    // Set fields
    env.set_field(obj, "f1", "F", result.f1.into()).unwrap();
    env.set_field(obj, "f2", "F", result.f2.into()).unwrap();
    env.set_field(obj, "f3", "F", result.f3.into()).unwrap();
    env.set_field(obj, "confidence", "F", result.confidence.into()).unwrap();
    env.set_field(obj, "success", "Z", true.into()).unwrap();

    obj
}
```

---

### **Phase 3: Voiceline Integration (Voiceline Team - 5-7 days)**

**Task 3.1: iOS Swift Bridge (Voiceline - Day 7-8)**

```swift
// ios/VoicelineDSP.swift
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

    static func detectPitch(
        audioSamples: [Float],
        sampleRate: UInt32,
        minFrequency: Float = 80.0,
        maxFrequency: Float = 400.0
    ) -> PitchResult? {
        let result = loqa_detect_pitch(
            audioSamples,
            audioSamples.count,
            sampleRate,
            minFrequency,
            maxFrequency
        )

        guard result.success else { return nil }

        return PitchResult(
            frequency: result.frequency,
            confidence: result.confidence,
            isVoiced: result.is_voiced
        )
    }
}
```

**Task 3.2: Android Java Bridge (Voiceline - Day 9)**

```java
// android/app/src/main/java/com/voiceline/VoicelineDSP.java
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

    public static class PitchResult {
        public float frequency;
        public float confidence;
        public boolean isVoiced;
        public boolean success;
    }

    public native static PitchResult detectPitch(
        float[] audioSamples,
        int sampleRate,
        float minFrequency,
        float maxFrequency
    );
}
```

**Task 3.3: React Native Module (Voiceline - Day 10-11)**

```javascript
// src/modules/VoicelineDSP.js
import { NativeModules } from 'react-native';

const { VoicelineDSP } = NativeModules;

export async function extractFormants(audioSamples, sampleRate = 44100, lpcOrder = 12) {
  const result = await VoicelineDSP.extractFormants(audioSamples, sampleRate, lpcOrder);

  if (!result || !result.success) {
    throw new Error('Formant extraction failed');
  }

  return {
    f1: result.f1,
    f2: result.f2,
    f3: result.f3,
    confidence: result.confidence,
  };
}

export async function detectPitch(audioSamples, sampleRate = 44100, minFreq = 80, maxFreq = 400) {
  const result = await VoicelineDSP.detectPitch(audioSamples, sampleRate, minFreq, maxFreq);

  if (!result || !result.success) {
    throw new Error('Pitch detection failed');
  }

  return {
    frequency: result.frequency,
    confidence: result.confidence,
    isVoiced: result.isVoiced,
  };
}
```

---

### **Phase 4: Integration Testing (Both Teams - 3-5 days)**

**Task 4.1: Unit Tests (Loqa - Day 12)**

```rust
// loqa-voice-dsp/tests/integration_tests.rs
#[test]
fn test_pitch_detection_pure_tone() {
    let sample_rate = 44100;
    let duration = 0.5; // seconds
    let frequency = 200.0; // Hz

    let audio = generate_sine_wave(frequency, sample_rate, duration);
    let result = detect_pitch(&audio, sample_rate, 80.0, 400.0).unwrap();

    assert!((result.frequency - frequency).abs() < 1.0);
    assert!(result.is_voiced);
    assert!(result.confidence > 0.9);
}

#[test]
fn test_formant_extraction_vowel_a() {
    let audio = generate_vowel_a(100.0, 44100, 0.5);
    let result = extract_formants(&audio, 44100, 12).unwrap();

    // Expected formants for /a/: F1 ≈ 700 Hz, F2 ≈ 1200 Hz
    assert!((result.f1 - 700.0).abs() < 50.0);
    assert!((result.f2 - 1200.0).abs() < 100.0);
}
```

**Task 4.2: Mobile E2E Tests (Voiceline - Day 13)**

```javascript
describe('VoicelineDSP E2E', () => {
  it('should analyze real voice recording', async () => {
    const audioBuffer = await loadTestAudio('voice_sample.wav');

    // Test pitch detection
    const pitch = await detectPitch(audioBuffer, 44100);
    expect(pitch.frequency).toBeGreaterThan(80);
    expect(pitch.frequency).toBeLessThan(400);
    expect(pitch.isVoiced).toBe(true);

    // Test formant extraction
    const formants = await extractFormants(audioBuffer, 44100);
    expect(formants.f1).toBeGreaterThan(200);
    expect(formants.f2).toBeGreaterThan(800);
    expect(formants.confidence).toBeGreaterThan(0.5);
  });
});
```

**Task 4.3: Performance Benchmarking (Both - Day 14)**

```rust
// loqa-voice-dsp/benches/dsp_benchmarks.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use loqa_voice_dsp::*;

fn benchmark_pitch_detection(c: &mut Criterion) {
    let audio = generate_sine_wave(200.0, 44100, 0.1); // 100ms

    c.bench_function("pitch_detection_100ms", |b| {
        b.iter(|| {
            detect_pitch(black_box(&audio), 44100, 80.0, 400.0)
        });
    });
}

fn benchmark_formant_extraction(c: &mut Criterion) {
    let audio = generate_vowel_a(100.0, 44100, 0.5); // 500ms

    c.bench_function("formant_extraction_500ms", |b| {
        b.iter(|| {
            extract_formants(black_box(&audio), 44100, 12)
        });
    });
}

criterion_group!(benches, benchmark_pitch_detection, benchmark_formant_extraction);
criterion_main!(benches);
```

**Run benchmarks:**
```bash
cargo bench
```

**Expected Results:**
- Pitch detection (100ms audio): <20ms
- Formant extraction (500ms audio): <50ms

---

## 📊 Timeline Summary

| Phase | Tasks | Duration | Owner | Dependencies |
|-------|-------|----------|-------|--------------|
| **1. Extract DSP Crate** | Create crate, extract pitch/formants/FFT/spectral, update loqa-core | 2-3 days | Loqa | None |
| **2. Add FFI Bridges** | iOS FFI, Android JNI, build scripts | 2-3 days | Loqa | Phase 1 complete |
| **3. Voiceline Integration** | Swift/Java bridges, React Native module | 5-7 days | Voiceline | Phase 2 complete |
| **4. Integration Testing** | Unit tests, E2E tests, benchmarks | 3-5 days | Both | Phase 3 complete |
| **Total** | | **12-18 days** | | |

**Parallel Work Opportunities:**
- Voiceline can start Swift/Java bridge design during Phase 1-2
- Testing can begin as soon as FFI exports available (end of Phase 2)

---

## ✅ Success Criteria

### **Performance (Must Meet):**
- ✅ Pitch detection: <20ms for 100ms audio
- ✅ Formant extraction: <50ms for 500ms audio
- ✅ FFT computation: <10ms for 2048-point FFT
- ✅ Memory usage: <10MB during processing

### **Accuracy (Must Meet):**
- ✅ Pitch detection: ±5Hz or 95% confidence
- ✅ Formant extraction: ±50Hz for F1/F2
- ✅ Spectral centroid: ±100Hz

### **Integration (Must Work):**
- ✅ iOS: Swift can call Rust DSP functions
- ✅ Android: Java can call Rust DSP functions
- ✅ Loqa backend: Direct Rust imports work
- ✅ All unit tests pass (100% success rate)
- ✅ E2E tests pass on real audio samples

---

## 🚀 Deliverables

### **For Voiceline Team:**
1. **Rust crate:** `loqa-voice-dsp` with source code
2. **iOS FFI headers:** C-compatible function signatures
3. **Android JNI library:** `.so` files for ARM/x86
4. **Documentation:**
   - rustdoc API documentation
   - Integration guide (Swift/Java examples)
   - Performance benchmarks
5. **Test suite:** Shared validation audio samples

### **For Loqa Backend:**
1. **Updated loqa-core:** Imports from `loqa-voice-dsp`
2. **Validated compatibility:** Existing Epic 2C functionality unchanged
3. **Performance:** No regression in analysis speed

---

## 📋 Open Action Items

### **For Anna (Loqa Team Lead):**
- [ ] Approve extraction of loqa-core/audio → loqa-voice-dsp
- [ ] Assign engineer for Phase 1-2 (DSP extraction + FFI)
- [ ] Schedule kickoff meeting with Voiceline team (week of Nov 11)
- [ ] Share Epic 2C test audio samples with Voiceline for validation

### **For Voiceline Team:**
- [ ] Review extracted Rust API (Phase 1 complete)
- [ ] Test iOS/Android FFI bridges (Phase 2)
- [ ] Implement React Native integration (Phase 3)
- [ ] Provide mobile-specific test cases (edge cases, device diversity)

### **Joint Activities:**
- [ ] Kickoff meeting: Align on timeline, communication channels, repo access
- [ ] Weekly sync: Review progress, address blockers
- [ ] Integration testing: E2E validation with real Voiceline app

---

## 🤝 Communication & Collaboration

**Recommended Channels:**
- **GitHub:** Shared repository or loqa monorepo with Voiceline access
- **Slack/Discord:** Real-time Q&A and coordination
- **Weekly sync:** 30-minute call to review progress (Tuesdays 2pm?)

**Code Reviews:**
- Loqa team reviews FFI layer (safety, performance)
- Voiceline team reviews API ergonomics (ease of use from Swift/Java)

---

## 🎯 Summary

**Key Wins:**
1. ✅ **Reuse existing code:** 90% of DSP already implemented in Epic 2C
2. ✅ **Single source of truth:** Shared Rust crate for consistency
3. ✅ **Fast timeline:** 12-18 days vs. rebuild from scratch (7-10 days Voiceline spec + 5-8 days duplicated work)
4. ✅ **Validated quality:** Epic 2C DSP already tested and production-ready

**This is the optimal path forward!** We leverage existing Loqa investment, share code across platforms, and deliver faster than building separately.

---

**Next Step:** Loqa team approval to proceed with Phase 1 (DSP extraction) this week.

**Contact:**
- **Loqa:** Anna (Team Lead)
- **Voiceline:** Anna (Developer)
- **Architect:** Winston (via Anna)

**Document Status:** Ready for implementation approval
**Last Updated:** November 7, 2025
