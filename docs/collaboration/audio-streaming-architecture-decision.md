# Audio Streaming Architecture Decision

**Date:** 2025-11-11
**Status:** Needs Decision
**Teams:** Voiceline App Team → Loqa DSP Team
**Priority:** High (Blocking Story 2.3 - Real-Time Voice-to-Flower Data Binding)

## Executive Summary

The Voiceline app requires **real-time audio streaming** to power live voice-to-visual feedback. Currently, the VoicelineDSP native module provides excellent audio analysis functions (FFT, pitch detection, formants) but does not provide real-time audio capture. This blocks the voice-responsive flower visualization from working.

**We need to decide:** Should we extend the VoicelineDSP native module to include real-time audio streaming, or integrate a third-party streaming library?

---

## Current Architecture

### What Works ✅

1. **VoicelineDSP Native Module** (`modules/voiceline-dsp/`)
   - iOS: Swift wrapper around `loqa-voice-dsp` Rust FFI
   - Android: Expected to follow similar pattern
   - Provides functions:
     - `computeFFT(samples, sampleRate, fftSize)` → FFT spectrum
     - `detectPitch(samples, sampleRate, minFreq, maxFreq)` → Pitch detection (YIN algorithm)
     - `extractFormants(samples, sampleRate, lpcOrder)` → Formant extraction (LPC)
     - `analyzeSpectrum(samples, sampleRate, fftSize)` → Spectral features

2. **AudioStreamService** (`src/services/audio/AudioStreamService.ts`)
   - Manages audio processing state machine
   - Provides `processAudioSamples(samples, pitchConfidence)` method
   - Implements adaptive processing modes (battery optimization)
   - Publishes voice metrics to Zustand store for UI consumption

3. **Voice Analysis Pipeline**
   - PitchDetector → IntonationClassifier → Voice Metrics Store
   - Works perfectly when given audio samples
   - Tested and validated with synthetic data

4. **Voice-Responsive Visualization**
   - VoiceFlower component renders 8-petal flower with Skia
   - Maps pitch → height, intonation → color, amplitude → openness
   - AnimatedVoiceFlower subscribes to voice metrics store
   - Renders correctly with all visual mappings working

### What's Missing ❌

**Real-time audio capture pipeline:** There is no connection between device microphone and `AudioStreamService.processAudioSamples()`.

**Current Recording Setup (Not Working for Real-Time):**
```typescript
// PracticeScreen.tsx (simplified)
import { useAudioRecorder } from 'expo-audio';

const recorder = useAudioRecorder({ ...recordingOptions });
await recorder.record(); // ❌ Records to file, no real-time samples
```

**Problem:**
- `expo-audio` and `expo-av` recording APIs only provide audio **after** recording stops
- No access to live audio buffers during recording
- `AudioStreamService.processAudioSamples()` is never called
- Voice metrics are never published
- Flower never responds to voice

---

## Architecture Options

### Option 1: Extend VoicelineDSP Native Module ⭐ (Recommended)

**Add real-time audio streaming to the native module.**

#### iOS Implementation Approach
```swift
// VoicelineDSPModule.swift additions

import AVFoundation

public class VoicelineDSPModule: Module {
  private var audioEngine: AVAudioEngine?
  private var inputNode: AVAudioInputNode?

  public func definition() -> ModuleDefinition {
    Name("VoicelineDSP")

    // ... existing FFT, pitch, formant functions ...

    // NEW: Start real-time audio capture
    AsyncFunction("startAudioStream") { (config: StreamConfig, promise: Promise) in
      let audioEngine = AVAudioEngine()
      let inputNode = audioEngine.inputNode
      let bus = 0

      let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: Double(config.sampleRate),
        channels: 1,
        interleaved: false
      )!

      inputNode.installTap(onBus: bus, bufferSize: config.bufferSize, format: format) { buffer, time in
        // Convert AVAudioPCMBuffer to Float32Array
        guard let channelData = buffer.floatChannelData else { return }
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(buffer.frameLength)))

        // Send to JavaScript via event
        self.sendEvent("onAudioSamples", [
          "samples": samples,
          "sampleRate": config.sampleRate,
          "timestamp": time.sampleTime
        ])
      }

      try audioEngine.start()
      self.audioEngine = audioEngine
      promise.resolve(true)
    }

    // NEW: Stop audio stream
    Function("stopAudioStream") {
      self.audioEngine?.stop()
      self.inputNode?.removeTap(onBus: 0)
      self.audioEngine = nil
    }

    // NEW: Event definitions
    Events("onAudioSamples")
  }
}
```

#### Android Implementation Approach
```kotlin
// VoicelineDSPModule.kt additions

import android.media.AudioRecord
import android.media.AudioFormat
import android.media.MediaRecorder

class VoicelineDSPModule : Module() {
  private var audioRecord: AudioRecord? = null
  private var recordingThread: Thread? = null

  override fun definition() = ModuleDefinition {
    Name("VoicelineDSP")

    // ... existing FFT, pitch, formant functions ...

    // NEW: Start real-time audio capture
    AsyncFunction("startAudioStream") { config: StreamConfig, promise: Promise ->
      val bufferSize = AudioRecord.getMinBufferSize(
        config.sampleRate,
        AudioFormat.CHANNEL_IN_MONO,
        AudioFormat.ENCODING_PCM_FLOAT
      )

      audioRecord = AudioRecord(
        MediaRecorder.AudioSource.VOICE_RECOGNITION,
        config.sampleRate,
        AudioFormat.CHANNEL_IN_MONO,
        AudioFormat.ENCODING_PCM_FLOAT,
        bufferSize
      )

      recordingThread = Thread {
        val buffer = FloatArray(config.bufferSize)
        audioRecord?.startRecording()

        while (Thread.currentThread().isInterrupted.not()) {
          val samplesRead = audioRecord?.read(buffer, 0, buffer.size, AudioRecord.READ_BLOCKING)

          if (samplesRead != null && samplesRead > 0) {
            sendEvent("onAudioSamples", mapOf(
              "samples" to buffer.toList(),
              "sampleRate" to config.sampleRate,
              "timestamp" to System.currentTimeMillis()
            ))
          }
        }
      }

      recordingThread?.start()
      promise.resolve(true)
    }

    // NEW: Stop audio stream
    Function("stopAudioStream") {
      recordingThread?.interrupt()
      audioRecord?.stop()
      audioRecord?.release()
      audioRecord = null
    }

    // NEW: Event definitions
    Events("onAudioSamples")
  }
}
```

#### TypeScript Integration
```typescript
// VoicelineDSP.ts additions

import { EventEmitter } from 'expo-modules-core';

export interface StreamConfig {
  sampleRate: number;
  bufferSize: number;
  channelCount: number;
}

export interface AudioSampleEvent {
  samples: number[];
  sampleRate: number;
  timestamp: number;
}

const emitter = new EventEmitter(VoicelineDSPNative);

export function startAudioStream(config: StreamConfig): Promise<boolean> {
  return VoicelineDSPNative.startAudioStream(config);
}

export function stopAudioStream(): void {
  return VoicelineDSPNative.stopAudioStream();
}

export function addAudioSampleListener(
  listener: (event: AudioSampleEvent) => void
): Subscription {
  return emitter.addListener('onAudioSamples', listener);
}

export const VoicelineDSP = {
  computeFFT,
  detectPitch,
  extractFormants,
  analyzeSpectrum,
  startAudioStream,      // NEW
  stopAudioStream,       // NEW
  addAudioSampleListener, // NEW
};
```

#### Usage in PracticeScreen
```typescript
// PracticeScreen.tsx integration

useEffect(() => {
  if (!isStreaming) return;

  // Start native audio streaming
  VoicelineDSP.startAudioStream({
    sampleRate: 16000,
    bufferSize: 2048,
    channelCount: 1,
  });

  // Subscribe to audio samples
  const subscription = VoicelineDSP.addAudioSampleListener((event) => {
    const samples = new Float32Array(event.samples);
    AudioStreamService.processAudioSamples(samples);
  });

  return () => {
    subscription.remove();
    VoicelineDSP.stopAudioStream();
  };
}, [isStreaming]);
```

#### Pros ✅
- **Single native module** for all audio operations (capture + analysis)
- **Lower latency** - samples stay native until needed for JS processing
- **Better battery efficiency** - can optimize at native layer
- **Full control** over audio configuration and processing
- **Consistent API** - matches existing VoicelineDSP patterns
- **Type-safe** integration with existing AudioStreamService

#### Cons ⚠️
- Requires native development for iOS + Android
- More testing required (iOS + Android platforms)
- Maintenance overhead for native code
- Potential audio permission handling complexity

---

### Option 2: Use @siteed/expo-audio-studio

**Integrate third-party streaming library.**

#### Installation
```bash
npx expo install @siteed/expo-audio-studio
```

#### Usage
```typescript
// PracticeScreen.tsx

import { AudioRecording } from '@siteed/expo-audio-studio';

const recording = AudioRecording.create({
  sampleRate: 16000,
  channels: 1,
  interval: 100, // 100ms chunks
  onAudioStream: (data) => {
    const samples = new Float32Array(data.samples);
    AudioStreamService.processAudioSamples(samples);
  },
});

await recording.start();
```

#### Pros ✅
- **Immediate solution** - no native development required
- **Battle-tested** - used in production apps
- **Maintained** - active development in 2025
- **Cross-platform** - iOS + Android + Web support
- **Easy to integrate** - simple API

#### Cons ⚠️
- **External dependency** - another package to maintain
- **Potential conflicts** with VoicelineDSP if it adds streaming later
- **Less control** over audio pipeline
- **Possible overhead** - extra layer between native and JS
- **Bundle size** increase

---

### Option 3: Hybrid Approach

**Use expo-audio-studio temporarily, plan VoicelineDSP extension for future.**

This gives us immediate functionality while planning native integration.

---

## Technical Requirements

### Audio Configuration Needed

```typescript
interface AudioStreamRequirements {
  sampleRate: 16000;      // Hz (matches VoicelineDSP expectations)
  bufferSize: 2048;       // samples (128ms at 16kHz)
  format: 'float32';      // Normalized -1.0 to 1.0
  channels: 1;            // Mono
  latency: '<100ms';      // Target end-to-end latency
  updateRate: '30-60Hz';  // Visual feedback rate
}
```

### Integration Points

1. **AudioStreamService.processAudioSamples()** - Entry point for audio data
2. **Voice Metrics Store** - Publishes pitch, intonation, amplitude
3. **AnimatedVoiceFlower** - Subscribes to metrics for visual updates

### Performance Targets

- **End-to-end latency:** <100ms (microphone → visual update)
- **Frame rate:** 60fps for Skia rendering
- **Audio processing:** 30-60Hz (adaptive based on battery mode)
- **Battery impact:** <5% additional drain during 30-minute session

---

## Questions for Loqa Team

### Architecture Questions

1. **Native Module Scope:** Is real-time audio streaming within the scope of the VoicelineDSP native module, or should it remain analysis-only?

2. **Development Timeline:** If we extend VoicelineDSP, what's the estimated timeline for iOS + Android implementation?

3. **Resource Availability:** Does the Loqa team have capacity to implement audio streaming, or should Voiceline team use expo-audio-studio as interim solution?

### Technical Questions

4. **Audio Pipeline Design:** Should audio capture and analysis be tightly coupled (Option 1) or loosely coupled (Option 2)?

5. **Event System:** For Option 1, should we use Expo's EventEmitter pattern or another approach for streaming samples to JavaScript?

6. **Buffer Management:** What buffer sizes and streaming intervals do you recommend for optimal pitch detection with YIN algorithm?

7. **Native Performance:** Can we optimize by doing some processing (e.g., VAD, RMS) at native layer before sending to JS?

### Integration Questions

8. **Audio Session Management:** How should we handle iOS AVAudioSession configuration (category, mode, options)?

9. **Android Permissions:** Best practices for handling RECORD_AUDIO permission with AudioRecord?

10. **Cross-Platform Consistency:** How can we ensure consistent behavior between iOS AVAudioEngine and Android AudioRecord?

---

## Current Blockers

**Story 2.3 (Real-Time Voice-to-Flower Data Binding)** is currently **blocked** because:

1. ✅ Voice analysis pipeline is implemented and tested
2. ✅ Voice-to-flower visual mappings work correctly
3. ✅ Flower rendering with all 8 petals working
4. ❌ **No audio samples reaching the analysis pipeline**
5. ❌ Flower doesn't respond to voice input

**Impact:**
- Cannot test or validate real-time voice response
- Cannot proceed to Story 2.4 animations (depends on real-time data)
- Cannot deliver MVP experience to users

---

## Recommendation

**We recommend Option 1 (Extend VoicelineDSP)** if:
- Loqa team has capacity to implement within 1-2 weeks
- Native audio streaming is within VoicelineDSP module scope
- Long-term maintenance is acceptable

**We recommend Option 3 (Hybrid)** if:
- Loqa team is at capacity or timeline is uncertain
- Need to unblock development immediately
- Can plan native integration for future sprint

---

## Next Steps

1. **Loqa team review** of this document
2. **Architecture decision** by both teams
3. **Timeline estimate** for chosen option
4. **Implementation planning** based on decision

---

## References

### Current Implementation
- [VoicelineDSP Module](/Users/anna/code/annabarnes1138/voiceline/modules/voiceline-dsp/)
- [AudioStreamService.ts](/Users/anna/code/annabarnes1138/voiceline/src/services/audio/AudioStreamService.ts)
- [Story 2.3 Documentation](/Users/anna/code/annabarnes1138/voiceline/docs/stories/2-3-implement-real-time-voice-to-flower-data-binding.md)

### External Resources
- [expo-audio-studio on npm](https://www.npmjs.com/package/@siteed/expo-audio-studio)
- [Expo: Real-time Audio Processing Blog](https://expo.dev/blog/real-time-audio-processing-with-expo-and-native-code)
- [AVAudioEngine Documentation (iOS)](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [AudioRecord Documentation (Android)](https://developer.android.com/reference/android/media/AudioRecord)

---

## Contact

**Voiceline App Team:**
- Ready to implement either option based on decision
- Can provide code review and testing support
- Available for architecture discussions

**Awaiting Response From:**
- Loqa DSP Team

---

**Document Version:** 1.0
**Last Updated:** 2025-11-11
**Next Review:** After Loqa team response
