# Loqa Audio Streaming Architecture Response

**Date:** November 11, 2025
**From:** Winston (Loqa Architect Agent)
**To:** Voiceline App Team
**Subject:** Audio Streaming Architecture Decision & Implementation Guidance
**Reference:** [audio-streaming-architecture-decision.md](./audio-streaming-architecture-decision.md)

---

## 🎯 Executive Summary

Thank you for the detailed architectural analysis! After reviewing your options and considering resource allocation (same developer for both teams), **the decision is to adopt Option 1 (Native VoicelineDSP Streaming)** without the hybrid approach.

**Decision:** Extend VoicelineDSP native module with audio streaming capabilities. Do NOT use third-party streaming library (expo-audio-studio).

**Development Sequence:**
1. **Priority 1:** Complete Loqa Epic 2C (voice intelligence backend) - 2-3 weeks
2. **Priority 2:** Implement VoicelineDSP native audio streaming - 3-4 weeks

**Impact:** Voiceline Story 2.3 remains blocked until VoicelineDSP audio streaming is complete (~5-7 weeks total)

**Rationale:**
- ✅ Single cohesive native module for capture + analysis (optimal architecture)
- ✅ Best performance and battery efficiency from the start
- ✅ No temporary dependencies to add and remove later
- ✅ Clean implementation without technical debt
- ✅ Allows focused development on Loqa Epic 2C without context-switching
- ✅ Voiceline gets production-quality streaming when development resumes

---

## 📋 Detailed Recommendation

### Development Approach: Native-Only (No Hybrid Solution)

**Implement native audio streaming in VoicelineDSP module directly.**

**Status:** Implementation begins after Loqa Epic 2C completion (2-3 weeks)

### Native Streaming Integration

**Extend VoicelineDSP with native audio streaming capabilities.**

#### Architecture Design

##### 1. Native Module Scope

**Answer to Q1:** Yes, real-time audio streaming is **within scope** for VoicelineDSP.

**Rationale:**
- loqa-voice-dsp is designed as a **shared DSP library** for voice analysis
- Audio capture + analysis are tightly coupled for optimal performance
- Having both in one module reduces latency and improves battery efficiency
- Consistent API across capture and analysis operations

##### 2. Module Architecture

```
VoicelineDSP Module
├── Audio Analysis (EXISTING)
│   ├── FFT computation
│   ├── Pitch detection (YIN)
│   ├── Formant extraction (LPC)
│   └── Spectral analysis
│
└── Audio Streaming (NEW - Phase 2)
    ├── Real-time capture (AVAudioEngine / AudioRecord)
    ├── Buffer management
    ├── Sample rate conversion
    └── Event emission to JS
```

##### 3. Implementation Strategy

**iOS Implementation (AVAudioEngine)**

```swift
// modules/voiceline-dsp/ios/VoicelineDSPModule.swift

import AVFoundation
import ExpoModulesCore

public class VoicelineDSPModule: Module {
  private var audioEngine: AVAudioEngine?
  private var inputNode: AVAudioInputNode?
  private var audioSession: AVAudioSession?

  public func definition() -> ModuleDefinition {
    Name("VoicelineDSP")

    // EXISTING: Analysis functions
    Function("computeFFT") { /* ... existing implementation ... */ }
    Function("detectPitch") { /* ... existing implementation ... */ }
    Function("extractFormants") { /* ... existing implementation ... */ }
    Function("analyzeSpectrum") { /* ... existing implementation ... */ }

    // NEW: Streaming functions
    AsyncFunction("startAudioStream") { (config: StreamConfig) -> Bool in
      return try await self.startAudioCapture(config: config)
    }

    Function("stopAudioStream") { () -> Bool in
      return self.stopAudioCapture()
    }

    Function("isStreaming") { () -> Bool in
      return self.audioEngine?.isRunning ?? false
    }

    // NEW: Event for audio samples
    Events("onAudioSamples", "onStreamError", "onStreamStatusChange")
  }

  // MARK: - Audio Capture Implementation

  private func startAudioCapture(config: StreamConfig) async throws -> Bool {
    // Configure audio session
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: [.allowBluetooth])
    try session.setActive(true)
    self.audioSession = session

    // Create audio engine
    let engine = AVAudioEngine()
    let inputNode = engine.inputNode

    // Configure format (16kHz mono float32)
    guard let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: Double(config.sampleRate),
      channels: 1,
      interleaved: false
    ) else {
      throw AudioStreamError.invalidFormat
    }

    // Install tap for real-time processing
    inputNode.installTap(
      onBus: 0,
      bufferSize: AVAudioFrameCount(config.bufferSize),
      format: format
    ) { [weak self] buffer, audioTime in
      guard let self = self,
            let channelData = buffer.floatChannelData else { return }

      // Convert to Swift array
      let samples = Array(UnsafeBufferPointer(
        start: channelData[0],
        count: Int(buffer.frameLength)
      ))

      // Emit to JavaScript
      self.sendEvent("onAudioSamples", [
        "samples": samples,
        "sampleRate": config.sampleRate,
        "frameLength": buffer.frameLength,
        "timestamp": audioTime.sampleTime,
      ])
    }

    // Start engine
    try engine.start()

    self.audioEngine = engine
    self.inputNode = inputNode

    sendEvent("onStreamStatusChange", ["status": "streaming"])

    return true
  }

  private func stopAudioCapture() -> Bool {
    guard let engine = audioEngine,
          let inputNode = inputNode else {
      return false
    }

    inputNode.removeTap(onBus: 0)
    engine.stop()

    try? audioSession?.setActive(false)

    self.audioEngine = nil
    self.inputNode = nil
    self.audioSession = nil

    sendEvent("onStreamStatusChange", ["status": "stopped"])

    return true
  }
}

// MARK: - Configuration Types

struct StreamConfig: Record {
  @Field var sampleRate: Int = 16000
  @Field var bufferSize: Int = 2048
  @Field var channels: Int = 1
}

enum AudioStreamError: Error {
  case invalidFormat
  case sessionConfigFailed
  case engineStartFailed
}
```

**Android Implementation (AudioRecord)**

```kotlin
// modules/voiceline-dsp/android/src/main/java/expo/modules/voicelinedsp/VoicelineDSPModule.kt

package expo.modules.voicelinedsp

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import androidx.core.content.ContextCompat
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.*

class VoicelineDSPModule : Module() {
  private var audioRecord: AudioRecord? = null
  private var recordingJob: Job? = null
  private var isRecording = false

  override fun definition() = ModuleDefinition {
    Name("VoicelineDSP")

    // EXISTING: Analysis functions
    Function("computeFFT") { /* ... existing implementation ... */ }
    Function("detectPitch") { /* ... existing implementation ... */ }
    Function("extractFormants") { /* ... existing implementation ... */ }
    Function("analyzeSpectrum") { /* ... existing implementation ... */ }

    // NEW: Streaming functions
    AsyncFunction("startAudioStream") { config: StreamConfig ->
      startAudioCapture(config)
    }

    Function("stopAudioStream") {
      stopAudioCapture()
    }

    Function("isStreaming") {
      isRecording
    }

    // NEW: Events
    Events("onAudioSamples", "onStreamError", "onStreamStatusChange")
  }

  private fun startAudioCapture(config: StreamConfig): Boolean {
    // Check permission
    val permission = ContextCompat.checkSelfPermission(
      appContext.reactContext!!,
      Manifest.permission.RECORD_AUDIO
    )

    if (permission != PackageManager.PERMISSION_GRANTED) {
      sendEvent("onStreamError", mapOf("error" to "RECORD_AUDIO permission not granted"))
      return false
    }

    // Configure AudioRecord
    val bufferSize = AudioRecord.getMinBufferSize(
      config.sampleRate,
      AudioFormat.CHANNEL_IN_MONO,
      AudioFormat.ENCODING_PCM_FLOAT
    ).coerceAtLeast(config.bufferSize * 4) // Float32 = 4 bytes per sample

    audioRecord = AudioRecord(
      MediaRecorder.AudioSource.VOICE_RECOGNITION,
      config.sampleRate,
      AudioFormat.CHANNEL_IN_MONO,
      AudioFormat.ENCODING_PCM_FLOAT,
      bufferSize
    )

    if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
      sendEvent("onStreamError", mapOf("error" to "AudioRecord initialization failed"))
      return false
    }

    // Start recording on background thread
    audioRecord?.startRecording()
    isRecording = true

    recordingJob = CoroutineScope(Dispatchers.IO).launch {
      val buffer = FloatArray(config.bufferSize)

      while (isActive && isRecording) {
        val samplesRead = audioRecord?.read(
          buffer,
          0,
          buffer.size,
          AudioRecord.READ_BLOCKING
        ) ?: 0

        if (samplesRead > 0) {
          // Emit to JavaScript (on main thread)
          withContext(Dispatchers.Main) {
            sendEvent("onAudioSamples", mapOf(
              "samples" to buffer.take(samplesRead),
              "sampleRate" to config.sampleRate,
              "frameLength" to samplesRead,
              "timestamp" to System.currentTimeMillis()
            ))
          }
        }
      }
    }

    sendEvent("onStreamStatusChange", mapOf("status" to "streaming"))

    return true
  }

  private fun stopAudioCapture(): Boolean {
    isRecording = false
    recordingJob?.cancel()

    audioRecord?.apply {
      stop()
      release()
    }
    audioRecord = null

    sendEvent("onStreamStatusChange", mapOf("status" to "stopped"))

    return true
  }
}

data class StreamConfig(
  val sampleRate: Int = 16000,
  val bufferSize: Int = 2048,
  val channels: Int = 1
)
```

**TypeScript API Wrapper**

```typescript
// modules/voiceline-dsp/index.ts

import { EventEmitter, Subscription } from 'expo-modules-core';
import VoicelineDSPModule from './src/VoicelineDSPModule';

// EXISTING: Analysis functions
export * from './src/analysis';

// NEW: Streaming types
export interface StreamConfig {
  sampleRate: number;
  bufferSize: number;
  channels: number;
}

export interface AudioSampleEvent {
  samples: number[];
  sampleRate: number;
  frameLength: number;
  timestamp: number;
}

export interface StreamStatusEvent {
  status: 'streaming' | 'stopped' | 'error';
}

export interface StreamErrorEvent {
  error: string;
}

// NEW: Streaming API
const emitter = new EventEmitter(VoicelineDSPModule);

export async function startAudioStream(config: StreamConfig): Promise<boolean> {
  return await VoicelineDSPModule.startAudioStream(config);
}

export function stopAudioStream(): boolean {
  return VoicelineDSPModule.stopAudioStream();
}

export function isStreaming(): boolean {
  return VoicelineDSPModule.isStreaming();
}

export function addAudioSampleListener(
  listener: (event: AudioSampleEvent) => void
): Subscription {
  return emitter.addListener<AudioSampleEvent>('onAudioSamples', listener);
}

export function addStreamStatusListener(
  listener: (event: StreamStatusEvent) => void
): Subscription {
  return emitter.addListener<StreamStatusEvent>('onStreamStatusChange', listener);
}

export function addStreamErrorListener(
  listener: (event: StreamErrorEvent) => void
): Subscription {
  return emitter.addListener<StreamErrorEvent>('onStreamError', listener);
}

// Convenience: All-in-one VoicelineDSP namespace
export const VoicelineDSP = {
  // Analysis (existing)
  computeFFT,
  detectPitch,
  extractFormants,
  analyzeSpectrum,

  // Streaming (new)
  startAudioStream,
  stopAudioStream,
  isStreaming,
  addAudioSampleListener,
  addStreamStatusListener,
  addStreamErrorListener,
};
```

**Estimated Development Timeline:**

| Task | iOS | Android | Testing | Total |
|------|-----|---------|---------|-------|
| Audio capture implementation | 2 days | 3 days | - | 5 days |
| Event system integration | 1 day | 1 day | - | 2 days |
| Permission handling | 0.5 day | 1 day | - | 1.5 days |
| Error handling & recovery | 1 day | 1 day | - | 2 days |
| TypeScript API wrapper | 0.5 day | 0.5 day | - | 1 day |
| Unit tests | 1 day | 1 day | - | 2 days |
| Integration testing | - | - | 3 days | 3 days |
| Documentation | 1 day | 1 day | - | 2 days |
| **Total** | **7 days** | **8.5 days** | **3 days** | **18.5 days** |

**Buffer:** Add 4-5 days for unforeseen issues

**Total Estimated Timeline:** **3-4 weeks** (assuming sequential development iOS → Android → Testing)

---

## 🔧 Technical Answers to Your Questions

### Q1: Native Module Scope
**Answer:** ✅ **Yes, real-time audio streaming is within VoicelineDSP scope.**

Loqa-voice-dsp is designed as a shared DSP library for voice analysis. Audio capture and analysis are tightly coupled for performance and battery efficiency. Having both in one module creates a cohesive API and reduces integration complexity.

### Q2: Development Timeline
**Answer:** **3-4 weeks** for native streaming implementation (iOS + Android + testing).

See detailed timeline breakdown above. This assumes:
- Sequential development (iOS first, then Android)
- One developer working full-time
- Parallel testing as features complete

### Q3: Resource Availability
**Answer:** **Loqa team is currently focused on Epic 2C completion** (voice intelligence features).

**Recommendation:** Voiceline team should use expo-audio-studio immediately (Phase 1) while Loqa team:
1. Completes Epic 2C (estimated completion: mid-November 2025)
2. Plans VoicelineDSP v0.2.0 streaming integration (December 2025)
3. Collaborates on native streaming design (shared responsibility)

### Q4: Audio Pipeline Design
**Answer:** **Loosely coupled for MVP (Option 2/3), tightly coupled for production (Option 1).**

Phase 1 (Hybrid) provides loose coupling:
```
expo-audio-studio → AudioStreamService → VoicelineDSP.computeFFT()
```

Phase 2 (Native) provides tight coupling:
```
VoicelineDSP (capture + analysis) → AudioStreamService
```

Both architectures support the same AudioStreamService API, making migration seamless.

### Q5: Event System
**Answer:** **Use Expo EventEmitter pattern** (standard for Expo modules).

Benefits:
- ✅ Standard Expo module convention
- ✅ Type-safe event subscriptions
- ✅ Automatic cleanup on component unmount
- ✅ Works consistently on iOS + Android

Example:
```typescript
const subscription = VoicelineDSP.addAudioSampleListener((event) => {
  // Process samples
});

// Cleanup
subscription.remove();
```

### Q6: Buffer Management
**Answer:** **Recommended: 2048 samples at 16kHz (128ms buffers)**

Rationale:
- YIN pitch detection requires 100-200ms windows for accuracy
- 2048 samples = 128ms at 16kHz (optimal for YIN)
- Provides good balance between latency and analysis quality
- Matches FFT size for efficient processing

Configuration:
```typescript
const streamConfig: StreamConfig = {
  sampleRate: 16000,  // Hz (standard for voice analysis)
  bufferSize: 2048,   // samples (128ms at 16kHz)
  channels: 1,        // mono
};
```

### Q7: Native Performance Optimization
**Answer:** ✅ **Yes, consider native-side optimizations for battery efficiency.**

**Recommended Native Optimizations:**

1. **Voice Activity Detection (VAD)**
   ```swift
   // Skip analysis when silence detected
   let rms = calculateRMS(buffer)
   if rms < silenceThreshold {
     return // Don't emit to JS
   }
   ```

2. **Adaptive Processing Rate**
   ```swift
   // Reduce frame rate during low battery
   if isBatteryOptimizationMode {
     frameSkipCounter += 1
     if frameSkipCounter % 2 != 0 { return } // Process every 2nd frame
   }
   ```

3. **Pre-computation at Native Layer**
   ```swift
   // Compute RMS amplitude at native layer
   let rms = calculateRMS(buffer)

   sendEvent("onAudioSamples", [
     "samples": samples,
     "rms": rms,  // Pre-computed
     "timestamp": audioTime.sampleTime,
   ])
   ```

These optimizations reduce JS bridge crossings and CPU usage.

### Q8: Audio Session Management (iOS)
**Answer:** **Use `.record` category with `.measurement` mode for optimal voice capture.**

```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(
  .record,                    // Recording category
  mode: .measurement,         // High-quality measurement mode
  options: [
    .allowBluetooth,          // Support Bluetooth headsets
    .defaultToSpeaker         // Use speaker if no headset
  ]
)
try session.setActive(true)
```

**Rationale:**
- `.measurement` mode provides highest quality audio (no processing)
- `.record` category enables microphone access
- `.allowBluetooth` supports AirPods and other Bluetooth audio

### Q9: Android Permissions
**Answer:** **Request RECORD_AUDIO at runtime with clear privacy explanation.**

```kotlin
// Check permission before starting stream
if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO)
    != PackageManager.PERMISSION_GRANTED) {

  // Explain why permission is needed (trauma-informed messaging)
  showPermissionRationale()

  // Request permission
  ActivityCompat.requestPermissions(
    activity,
    arrayOf(Manifest.permission.RECORD_AUDIO),
    RECORD_AUDIO_REQUEST_CODE
  )
}
```

**Best Practices:**
1. Request permission only when user initiates practice session (not on app launch)
2. Provide clear explanation: "Voiceline needs microphone access to analyze your voice during practice"
3. Handle permission denial gracefully (disable practice mode, show help text)
4. Respect user's privacy choice (never re-prompt aggressively)

### Q10: Cross-Platform Consistency
**Answer:** **Abstract platform differences behind unified TypeScript API.**

**Strategy:**

1. **Consistent Event Format**
   ```typescript
   // Same event structure on iOS + Android
   interface AudioSampleEvent {
     samples: number[];      // Float32 array (-1.0 to 1.0)
     sampleRate: number;     // Always 16000
     frameLength: number;    // Number of samples
     timestamp: number;      // Platform-specific timestamp
   }
   ```

2. **Unified Error Handling**
   ```typescript
   // Consistent error codes across platforms
   enum AudioStreamError {
     PERMISSION_DENIED = "PERMISSION_DENIED",
     SESSION_CONFIG_FAILED = "SESSION_CONFIG_FAILED",
     ENGINE_START_FAILED = "ENGINE_START_FAILED",
     DEVICE_NOT_AVAILABLE = "DEVICE_NOT_AVAILABLE",
   }
   ```

3. **Platform-Specific Behavior Documentation**
   ```typescript
   /**
    * Note: iOS uses AVAudioEngine (40-60ms latency typical)
    * Android uses AudioRecord (60-100ms latency typical)
    * Both target <100ms end-to-end latency for real-time feedback.
    */
   ```

4. **Comprehensive Testing**
   - Test on both iOS simulator (Intel + Apple Silicon Macs)
   - Test on physical iOS devices (iPhone 12+, iPad)
   - Test on Android emulator (x86 + ARM)
   - Test on physical Android devices (various manufacturers)

---

## 🎯 Performance Targets & Validation

### Latency Targets

| Component | Target | Measurement Method |
|-----------|--------|--------------------|
| **Microphone → Native Buffer** | <40ms | Platform-specific (AVAudioEngine / AudioRecord) |
| **Native → JS Bridge** | <10ms | Event emission timestamp tracking |
| **JS Processing (AudioStreamService)** | <30ms | Performance.now() markers |
| **Visual Update (Skia Rendering)** | <16ms | 60fps frame budget |
| **Total End-to-End Latency** | **<100ms** | User-perceived voice → visual lag |

### Battery Impact Targets

| Scenario | Target | Mitigation Strategy |
|----------|--------|---------------------|
| **30-minute practice session** | <5% battery drain | Adaptive processing rate, VAD |
| **Real-time analysis (continuous)** | <10% per hour | Native optimizations, frame skipping |

### Validation Plan

**Phase 1 (expo-audio-studio):**
1. Measure end-to-end latency with synthetic audio input
2. Profile battery usage during 30-minute test session
3. Validate visual responsiveness (60fps flower rendering)

**Phase 2 (Native VoicelineDSP):**
1. Compare latency: native vs expo-audio-studio
2. Measure battery improvement from native optimizations
3. Validate cross-platform consistency (iOS vs Android latency)

---

## 🔒 Privacy & Security Validation

### Audio Data Handling

**Principle:** Voice data never leaves device except when explicitly sent to Loqa server for advanced analysis.

**Implementation Guarantees:**

1. **Real-Time Streaming:** Audio samples processed in-memory, never saved to disk
2. **Session Recording:** Only saved when user explicitly starts "Save Session" mode
3. **No Cloud Upload:** All processing local (mobile device or user's Loqa server)
4. **Microphone Indicator:** iOS shows orange dot when microphone active (user awareness)

**Code-Level Validation:**

```typescript
// AudioStreamService processes samples in-memory only
class AudioStreamService {
  processAudioSamples(samples: Float32Array): void {
    // 1. Analyze samples (pitch, FFT, formants)
    const metrics = this.analyzer.analyze(samples);

    // 2. Update voice metrics store (in-memory)
    this.voiceStore.update(metrics);

    // 3. Samples are discarded after processing
    // NO disk writes, NO network calls
  }
}
```

**User Communication (Trauma-Informed):**

```
✅ Accurate Privacy Claims:
- "Voice analysis happens on your device in real-time"
- "Audio is processed in memory and never saved unless you choose to record a session"
- "No voice data leaves your device during live practice"

❌ Claims to Remove:
- Any ambiguity about data retention
```

---

## 🚀 Recommended Implementation Plan

### Week 1-3: Loqa Epic 2C (Priority 1)

**Status:** 🚀 **ACTIVE**

**Tasks:**
1. Story 2C.2: Create loqa-voice-intelligence crate (1-2 days)
2. Story 2C.3: Implement voice analysis API (2-3 days)
3. Story 2C.4: Build voice profile API (2 days)
4. Story 2C.5: Implement training session recording (2 days)
5. Story 2C.6: Add progress analytics API (2 days)
6. Story 2C.7: Add breakthrough moment tagging (1 day)
7. Story 2C.8: API documentation and testing (2 days)

**Deliverable:** Complete voice intelligence backend for Voiceline integration

### Week 4: VoicelineDSP Streaming Planning

**Status:** ⏳ **PENDING** (after Epic 2C)

**Tasks:**
1. Detailed VoicelineDSP streaming API design
2. Native module architecture review
3. iOS AVAudioEngine design
4. Android AudioRecord design
5. Event system specification

**Deliverable:** VoicelineDSP v0.2.0 design specification

### Week 5-6: iOS Native Streaming Implementation

**Status:** ⏳ **PENDING**

**Tasks:**
1. Implement AVAudioEngine audio capture
2. Add event system for sample streaming
3. Handle audio session management
4. Implement permission handling
5. Unit tests and integration tests

**Deliverable:** iOS native streaming complete

### Week 7-8: Android Native Streaming Implementation

**Status:** ⏳ **PENDING**

**Tasks:**
1. Implement AudioRecord audio capture
2. Add event system for sample streaming
3. Handle permission handling
4. Thread management and buffer handling
5. Unit tests and integration tests

**Deliverable:** Android native streaming complete

### Week 9-10: Integration & Testing

**Status:** ⏳ **PENDING**

**Tasks:**
1. Cross-platform testing (iOS + Android)
2. Performance validation (latency, battery)
3. TypeScript API wrapper finalization
4. Documentation and examples
5. Voiceline integration support

**Deliverable:** VoicelineDSP v0.2.0 released, Voiceline Story 2.3 unblocked

---

## 📋 Open Questions & Decisions

### Technical Decisions Needed

**Q1: Should VoicelineDSP v0.2.0 be backwards compatible with v0.1.x?**
- **Option A:** Additive API (v0.2.0 adds streaming, keeps existing analysis functions)
- **Option B:** Breaking changes (refactor analysis functions to work with streaming)
- **Recommendation:** Option A (additive) - easier migration, no breaking changes

**Q2: Should native streaming support recording to file simultaneously?**
- **Option A:** Streaming-only (in-memory processing)
- **Option B:** Dual-mode (streaming + optional recording)
- **Recommendation:** Option B (future-proof for session recording feature)

**Q3: Should VoicelineDSP provide high-level streaming abstractions?**
- **Option A:** Low-level (raw samples only, no analysis)
- **Option B:** High-level (pre-computed RMS, VAD, pitch)
- **Recommendation:** Option B for battery efficiency (reduce JS bridge crossings)

### Collaboration Decisions

**Q4: Who owns VoicelineDSP native streaming implementation?**
- **Option A:** Loqa team (Rust + native expertise)
- **Option B:** Voiceline team (immediate need, app context)
- **Option C:** Shared (Loqa designs, Voiceline implements)
- **Recommendation:** Option C (collaborative approach)

**Q5: When should Phase 2 begin?**
- **Option A:** Immediately (parallel with Phase 1)
- **Option B:** After Epic 2C complete (December 2025)
- **Option C:** After MVP launch (Q1 2026)
- **Recommendation:** Option B (after Epic 2C, allows focused effort)

---

## 🎯 Success Criteria

### Phase 1 Success (Hybrid Solution)

- ✅ Story 2.3 unblocked within 1 week
- ✅ Voice-to-flower visualization working with real voice input
- ✅ End-to-end latency <100ms
- ✅ Battery impact <5% per 30-minute session
- ✅ Cross-platform working (iOS + Android)

### Phase 2 Success (Native Streaming)

- ✅ VoicelineDSP v0.2.0 released with streaming API
- ✅ Native streaming 10-20% lower latency than hybrid
- ✅ Battery efficiency improved 15-25%
- ✅ API migration seamless (no breaking changes to AudioStreamService)
- ✅ Cross-platform parity (iOS + Android consistent behavior)

---

## 📬 Next Steps

### Immediate Actions (Current)

**For Voiceline Team:**
- 🛑 **BLOCKED** - Wait for Loqa Epic 2C completion (2-3 weeks)
- 🛑 **BLOCKED** - Wait for VoicelineDSP audio streaming (3-4 weeks after Epic 2C)
- ⏳ **Story 2.3 unblock date:** Estimated 5-7 weeks from now

**For Loqa Team:**
1. ✅ Review this architectural response
2. 🚀 **Active:** Complete Epic 2C stories 2C.2 through 2C.8 (current priority)
3. ⏳ Plan VoicelineDSP v0.2.0 design (after Epic 2C complete)
4. ⏳ Implement native audio streaming (after Epic 2C complete)

### Joint Activities (After Epic 2C)

1. **API Design Review:** Collaborate on VoicelineDSP streaming API design
2. **Implementation Planning:** Finalize iOS + Android implementation approach
3. **Integration Support:** Loqa team helps Voiceline integrate native streaming

---

## 📚 References

### Loqa Architecture
- [Loqa Architecture Document](/Users/anna/code/loqalabs/loqa/docs/architecture.md)
- [loqa-voice-dsp README](/Users/anna/code/loqalabs/loqa/crates/loqa-voice-dsp/README.md)
- [loqa-voice-dsp Performance Benchmarks](/Users/anna/code/loqalabs/loqa/crates/loqa-voice-dsp/README.md#performance-benchmarks)

### Voiceline Implementation
- [AudioStreamService Implementation](/Users/anna/code/annabarnes1138/voiceline/src/services/audio/AudioStreamService.ts)
- [Story 2.3: Real-Time Voice-to-Flower Binding](/Users/anna/code/annabarnes1138/voiceline/docs/stories/2-3-implement-real-time-voice-to-flower-data-binding.md)

### External Resources
- [expo-audio-studio Documentation](https://www.npmjs.com/package/@siteed/expo-audio-studio)
- [AVAudioEngine Documentation (iOS)](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [AudioRecord Documentation (Android)](https://developer.android.com/reference/android/media/AudioRecord)
- [Expo Modules API](https://docs.expo.dev/modules/overview/)

---

## 🤝 Contact & Collaboration

**Loqa Team:**
- Winston (Architect) - Available for API design review and architecture questions
- Ready to collaborate on VoicelineDSP v0.2.0 design

**Voiceline Team:**
- Ready to implement Phase 1 (hybrid solution) immediately
- Available for performance testing and feedback

**Preferred Communication:**
- Technical questions: GitHub issues or collaboration docs
- Design review: Joint architecture meeting (Zoom/Slack)
- Timeline coordination: Async updates via docs

---

**Thank you for the detailed architectural analysis! This hybrid approach balances immediate delivery with long-term architectural quality. I'm excited to see the voice-responsive flower visualization come to life.** 🎤🌸

---

**Document Version:** 1.0
**Last Updated:** November 11, 2025
**Next Review:** After Phase 1 implementation complete (Week 2)
