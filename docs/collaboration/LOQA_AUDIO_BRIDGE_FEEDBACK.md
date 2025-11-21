# @loqalabs/loqa-audio-bridge@0.3.0 - Integration Feedback

## Date
November 20, 2025

## Summary
We successfully integrated `@loqalabs/loqa-audio-bridge@0.3.0` into our Voiceline app! The autolinking works perfectly without any manual Podfile configuration or ExpoModulesProvider edits. This is a huge improvement over v0.2.0. 🎉

However, we discovered two critical issues that need to be addressed before this package can be used in production.

---

## ✅ What Works Great

### 1. **Autolinking is Perfect!**
- No manual Podfile entries needed
- No manual ExpoModulesProvider.swift edits needed
- Simply `npm install @loqalabs/loqa-audio-bridge@0.3.0` and `npx expo prebuild` works flawlessly
- Native module properly discovered and linked

### 2. **Clean API Design**
The new API with named exports is much cleaner:
```typescript
import {
  startAudioStream,
  stopAudioStream,
  addAudioSampleListener,
  addStreamErrorListener,
} from '@loqalabs/loqa-audio-bridge';
```

This is much better than the old object-based API.

### 3. **iOS Build Success**
- Native code compiles without errors
- LoqaAudioBridge module loads correctly
- No linking or compilation issues

---

## ❌ Critical Issues Found

### Issue #1: Missing Build Files (BLOCKING)

**Problem:**
The published npm package has `package.json` pointing to:
```json
{
  "main": "build/index.js",
  "types": "build/index.d.ts"
}
```

But these files **do not exist** in the published package. The `build/` directory only contains `hooks/` and `src/` subdirectories, but no `index.js` or `index.d.ts` files.

**Impact:**
- Metro bundler cannot resolve the module
- App fails with: `Unable to resolve "@loqalabs/loqa-audio-bridge"`
- Package is unusable without manual patching

**Our Workaround:**
We had to manually patch `node_modules/@loqalabs/loqa-audio-bridge/package.json`:
```json
{
  "main": "src/index.ts",
  "types": "src/index.ts"
}
```

This works, but the fix is lost whenever we reinstall node_modules.

**Recommended Fix:**
Choose one of these approaches:

**Option A: Build Before Publishing (Recommended)**
```bash
# In your package
npm run build  # This should compile TS to JS in build/
npm publish
```

Make sure your `build/` directory is included in the published package with an `index.js` file.

**Option B: Point to Source Files**
Update `package.json` to:
```json
{
  "main": "src/index.ts",
  "types": "src/index.ts"
}
```

This works fine with Metro's TypeScript support, but Option A is more standard.

---

### Issue #2: Missing DSP Analysis Functions (FEATURE GAP)

**Problem:**
The new `@loqalabs/loqa-audio-bridge@0.3.0` module only provides **audio streaming** functions:
- ✅ `startAudioStream()`
- ✅ `stopAudioStream()`
- ✅ `addAudioSampleListener()`
- ✅ `addStreamErrorListener()`

But it's missing the **DSP analysis** functions that existed in the original VoicelineDSP v0.2.0 module:
- ❌ `computeFFT()` - FFT magnitude spectrum
- ❌ `detectPitch()` - YIN pitch detection algorithm
- ❌ `extractFormants()` - LPC formant extraction (F1, F2, F3)
- ❌ `analyzeSpectrum()` - Spectral features (centroid, tilt, rolloff)

**Impact:**
Our app currently has a wrapper file `src/services/audio/VoicelineDSP.ts` that calls:
```typescript
const VoicelineDSPNative = requireNativeModule('VoicelineDSP');
```

This fails at runtime with:
```
Error: Cannot find native module 'VoicelineDSP'
```

**Our Current Usage:**
We use these DSP functions extensively:
- **PitchDetector.ts** - Uses `detectPitch()` for real-time pitch tracking
- **FFTAnalyzer.ts** - Uses `computeFFT()` and `analyzeSpectrum()` for spectral analysis
- **SafeVoicelineDSP.ts** - Safe wrapper with error handling for all DSP functions
- **DSPTestScreen.tsx** - Testing/debugging screen for DSP functions

**Recommended Solution:**

**Option A: Include DSP in loqa-audio-bridge (Preferred)**
Add the DSP functions to the same module:
```typescript
// @loqalabs/loqa-audio-bridge
export {
  // Streaming functions (already exist)
  startAudioStream,
  stopAudioStream,
  addAudioSampleListener,

  // DSP functions (need to be added)
  computeFFT,
  detectPitch,
  extractFormants,
  analyzeSpectrum,
};
```

**Option B: Separate Package**
Publish DSP functions as a separate package:
```typescript
// @loqalabs/loqa-audio-dsp
export {
  computeFFT,
  detectPitch,
  extractFormants,
  analyzeSpectrum,
};
```

This would keep streaming and DSP concerns separated, which might be cleaner architecturally.

**Either way**, we need these DSP functions to be available in the new module ecosystem!

---

## 📊 Integration Stats

- **Time to integrate streaming API**: ~30 minutes
- **Native build time**: 2-3 minutes (unchanged)
- **Metro bundle time**: ~10 seconds (unchanged)
- **Code changes required**: Minimal (just import statements)
- **Manual configuration**: None needed (autolinking works!)

---

## 🎯 Recommendations for v0.4.0

### Priority 1: Fix Build Files
This is blocking - the package doesn't work without manual patching.

### Priority 2: Add DSP Functions
Our app needs these, and they were in v0.2.0. Please include them or provide guidance on migration path.

### Priority 3: Consider Adding
- Type definitions for `EventSubscription` (currently importing from expo-modules-core)
- Documentation on migrating from v0.2.0 to v0.3.0
- Example showing how to use streaming + DSP functions together

---

## 💬 Questions

1. **Are the DSP functions planned for a future release?**
   - If yes, what's the timeline?
   - If no, what's the recommended migration path?

2. **Should we expect the build files issue to be fixed in v0.3.1?**
   - If yes, we can use a patch-package workaround temporarily
   - If no, should we expect a breaking change in v0.4.0?

3. **Is there a reason the DSP functions were removed?**
   - Performance concerns?
   - Maintenance burden?
   - Architectural decision?

---

## 📝 Technical Details

### Environment
- Expo SDK: 54.0.23
- React Native: 0.81.5
- iOS Deployment Target: 15.1
- Node: Latest LTS
- Platform: macOS (iOS simulator testing)

### Files Modified
- [package.json](package.json) - Added `@loqalabs/loqa-audio-bridge@0.3.0`
- [AudioStreamService.ts](src/services/audio/AudioStreamService.ts) - Updated to use new API
- Locally patched: `node_modules/@loqalabs/loqa-audio-bridge/package.json`

### Build Output
```
✅ iOS build succeeded with 0 errors
✅ Native module LoqaAudioBridge compiled successfully
✅ Autolinking detected module without manual configuration
✅ Metro bundle succeeded (with workaround)
❌ Runtime error: Cannot find native module 'VoicelineDSP'
```

---

## 🙏 Thank You!

Despite these issues, this is a HUGE improvement over v0.2.0. The autolinking alone saves us significant development time and maintenance burden. We're excited to see this mature and look forward to v0.4.0!

If you need any additional information, testing, or have questions about our integration, please let us know.

**Contact**: anna@voiceline.app (or via GitHub issues)
