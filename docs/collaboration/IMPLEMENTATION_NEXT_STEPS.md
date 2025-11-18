# Loqa Voice DSP - Next Implementation Steps

**Status:** ✅ Crate structure created
**Next:** Extract DSP code from loqa-core

---

## ✅ Completed (Today)

1. Created `loqa-voice-dsp` crate structure
2. Set up Cargo.toml with dependencies (rustfft, realfft, ndarray)
3. Created module structure (pitch, formants, fft, spectral, ffi)
4. Created README with API examples

---

## 🚀 Next Steps (Priority Order)

### **Step 2: Extract Pitch Detection (Next - ~2 hours)**

**Source:** `crates/loqa-core/src/audio/analysis.rs` (YIN implementation)
**Destination:** `crates/loqa-voice-dsp/src/pitch.rs`

**Action:**
1. Find YIN algorithm implementation in loqa-core
2. Copy to pitch.rs with new API signature:
   ```rust
   pub struct PitchResult {
       pub frequency: f32,
       pub confidence: f32,
       pub is_voiced: bool,
   }

   pub fn detect_pitch(
       audio_samples: &[f32],
       sample_rate: u32,
       min_frequency: f32,
       max_frequency: f32,
   ) -> Result<PitchResult, String>
   ```
3. Test with: `cargo test -p loqa-voice-dsp`

**How to find the code:**
```bash
# Search for YIN implementation
cd /Users/anna/code/loqalabs/loqa
rg "yin" crates/loqa-core/src/ --type rust
```

---

### **Step 3: Extract Formant Extraction (~2 hours)**

**Source:** `crates/loqa-core/src/audio/analysis.rs` (LPC implementation)
**Destination:** `crates/loqa-voice-dsp/src/formants.rs`

**Action:**
1. Find LPC formant extraction in loqa-core
2. Copy to formants.rs with new API signature:
   ```rust
   pub struct FormantResult {
       pub f1: f32,
       pub f2: f32,
       pub f3: f32,
       pub confidence: f32,
   }

   pub fn extract_formants(
       audio_samples: &[f32],
       sample_rate: u32,
       lpc_order: usize,
   ) -> Result<FormantResult, String>
   ```
3. Test with: `cargo test -p loqa-voice-dsp`

---

### **Step 4: Extract FFT Utilities (~1 hour)**

**Source:** `crates/loqa-core/src/audio/analysis.rs` (rustfft usage)
**Destination:** `crates/loqa-voice-dsp/src/fft.rs`

**Action:**
1. Find FFT implementation in loqa-core
2. Copy to fft.rs with new API signature:
   ```rust
   pub struct FFTResult {
       pub magnitudes: Vec<f32>,
       pub frequencies: Vec<f32>,
       pub sample_rate: u32,
   }

   pub fn compute_fft(
       audio_samples: &[f32],
       sample_rate: u32,
       fft_size: usize,
   ) -> Result<FFTResult, String>
   ```
3. Test with: `cargo test -p loqa-voice-dsp`

---

### **Step 5: Add Spectral Analysis (~2 hours)**

**Source:** `crates/loqa-core/src/audio/features.rs` (partial) + NEW code
**Destination:** `crates/loqa-voice-dsp/src/spectral.rs`

**Action:**
1. Create new spectral analysis module
2. Implement:
   - Spectral centroid (weighted mean frequency)
   - Spectral tilt (slope of log-magnitude spectrum)
   - Spectral rolloff (95% energy threshold)
3. Test with: `cargo test -p loqa-voice-dsp`

**Reference implementation:** See implementation plan document for code examples

---

### **Step 6: Update loqa-core Dependencies (~30 minutes)**

**Action:**
1. Edit `crates/loqa-core/Cargo.toml`:
   ```toml
   [dependencies]
   loqa-voice-dsp = { path = "../loqa-voice-dsp" }
   ```

2. Update `crates/loqa-core/src/audio/mod.rs`:
   ```rust
   // Re-export from loqa-voice-dsp
   pub use loqa_voice_dsp::{
       detect_pitch, extract_formants, compute_fft,
       PitchResult, FormantResult, FFTResult,
   };
   ```

3. **Critical:** Run all Epic 2C tests to ensure no regression:
   ```bash
   cargo test -p loqa-core
   cargo test -p loqa-meetings
   cargo test -p loqa-voice-intelligence
   ```

---

### **Step 7: Add FFI Layer (~4 hours)**

**Destination:** `crates/loqa-voice-dsp/src/ffi/`

**Action:**
1. Add `ffi` feature to Cargo.toml
2. Create `src/ffi/mod.rs`, `src/ffi/ios.rs`, `src/ffi/android.rs`
3. Implement C-compatible exports for iOS
4. Implement JNI exports for Android
5. Test FFI safety (null pointers, bounds checking)

**Reference implementation:** See implementation plan document for FFI code examples

---

## 📋 Validation Checklist

After each step, validate:

- [ ] `cargo check -p loqa-voice-dsp` passes
- [ ] `cargo test -p loqa-voice-dsp` passes (add tests as you extract)
- [ ] `cargo clippy -p loqa-voice-dsp` has no warnings
- [ ] Existing Epic 2C tests still pass (no regression)

---

## 🤝 Handoff to Voiceline Team

**When Steps 1-7 are complete:**

1. Share `loqa-voice-dsp` crate with Voiceline team
2. Provide FFI header files (C exports for iOS, JNI signatures for Android)
3. Share test audio samples for validation
4. Schedule integration meeting to answer questions

**Voiceline team will then:**
- Create Swift bridge for iOS
- Create Java bridge for Android
- Build React Native module
- Integration testing with Voiceline app

---

## ⏱️ Estimated Timeline

| Step | Duration | Who | Dependencies |
|------|----------|-----|--------------|
| ✅ Step 1: Crate structure | 0.5 hours | ✅ Done | None |
| Step 2: Pitch detection | 2 hours | Loqa | Step 1 |
| Step 3: Formant extraction | 2 hours | Loqa | Step 1 |
| Step 4: FFT utilities | 1 hour | Loqa | Step 1 |
| Step 5: Spectral analysis | 2 hours | Loqa | Step 4 |
| Step 6: Update loqa-core | 0.5 hours | Loqa | Steps 2-5 |
| Step 7: FFI layer | 4 hours | Loqa | Steps 2-6 |
| **Total Loqa work** | **12 hours (1.5-2 days)** | | |
| Voiceline integration | 5-7 days | Voiceline | Step 7 complete |

---

## 📞 Questions or Blockers?

Contact:
- **Technical:** Winston (Loqa Architect, via Anna)
- **Voiceline:** Anna (via collaboration docs)

**Communication:** Update implementation progress in this document or via team sync

---

**Current Status:** ✅ Phase 1 started - Ready for DSP extraction!
