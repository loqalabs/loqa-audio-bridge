# VoicelineDSP v0.2.0 Audio Streaming Architecture

**Version:** 0.2.0
**Status:** Design Document
**Last Updated:** 2025-11-12
**Epic:** Epic 2D - Real-Time Audio Streaming for Voice DSP

## Table of Contents

1. [System Overview](#system-overview)
2. [Buffer Management Strategy](#buffer-management-strategy)
3. [Error Handling Patterns](#error-handling-patterns)
4. [Performance Targets and Measurement](#performance-targets-and-measurement)
5. [Cross-Platform Consistency](#cross-platform-consistency)
6. [Architecture Diagrams](#architecture-diagrams)
7. [References](#references)

---

## System Overview

VoicelineDSP v0.2.0 extends the voice analysis capabilities with real-time audio streaming from device microphones. The architecture uses native platform APIs (iOS AVAudioEngine, Android AudioRecord) with event-driven delivery to JavaScript via Expo modules.

### Core Architecture Principles

1. **Native-First:** Direct platform audio APIs (no hybrid solutions)
2. **Event-Driven:** Push-based sample delivery (no polling)
3. **Privacy-First:** In-memory processing only (no disk writes)
4. **Type-Safe:** Full TypeScript coverage with compile-time validation
5. **Cross-Platform:** Consistent API surface on iOS and Android

### Technology Stack

| Layer                | iOS                     | Android               | Shared                 |
| -------------------- | ----------------------- | --------------------- | ---------------------- |
| **Audio Capture**    | AVAudioEngine           | AudioRecord           | -                      |
| **Audio Format**     | Float32 PCM             | Float32 PCM           | [-1.0, 1.0] normalized |
| **Threading**        | Audio I/O thread → Main | Dispatchers.IO → Main | Expo EventEmitter      |
| **Language**         | Swift 5.0+              | Kotlin 1.9+           | TypeScript 5.0+        |
| **Module Framework** | Expo Modules            | Expo Modules          | expo-modules-core      |

---

## Buffer Management Strategy

### Buffer Size Fundamentals

Audio buffers balance three competing requirements:

1. **Latency:** Smaller buffers = lower latency
2. **Frequency Resolution:** Larger buffers = better frequency analysis
3. **Reliability:** Adequate size prevents buffer overruns

**Calculation Formula:**

```
latency_ms = (buffer_size_samples / sample_rate_hz) × 1000
```

**Examples:**

| Sample Rate | Buffer Size      | Latency    | Use Case                              |
| ----------- | ---------------- | ---------- | ------------------------------------- |
| 16 kHz      | 512 samples      | 32 ms      | Ultra-low latency (limited analysis)  |
| 16 kHz      | 1024 samples     | 64 ms      | Low latency, basic analysis           |
| 16 kHz      | **2048 samples** | **128 ms** | **Recommended: Voice analysis (YIN)** |
| 16 kHz      | 4096 samples     | 256 ms     | High-resolution analysis              |
| 44.1 kHz    | 2048 samples     | 46 ms      | Low-latency music                     |
| 44.1 kHz    | **4096 samples** | **93 ms**  | **High-quality capture**              |
| 48 kHz      | 4096 samples     | 85 ms      | Professional audio                    |

### Recommended Configurations

#### Voice Analysis (Default)

**Optimal for Voiceline use case:**

```typescript
{
  sampleRate: 16000,     // 16 kHz sufficient for voice (0-8 kHz)
  bufferSize: 2048,      // 128 ms optimal for YIN pitch detection
  channels: 1            // Mono
}
```

**Rationale:**

- **YIN pitch detection** requires 100-200ms analysis windows
- **128ms buffer** (2048 @ 16kHz) fits this requirement perfectly
- **16 kHz** covers full voice spectrum (fundamental + harmonics to 8 kHz)
- **Low computational cost** enables real-time processing on mobile

#### High-Quality Capture

**For music or high-fidelity recording:**

```typescript
{
  sampleRate: 44100,     // CD-quality sample rate
  bufferSize: 4096,      // 93 ms latency
  channels: 1            // Mono (or 2 for stereo)
}
```

#### Low-Latency Mode

**For immediate feedback (<50ms):**

```typescript
{
  sampleRate: 16000,
  bufferSize: 512,       // 32 ms latency
  channels: 1
}
```

⚠️ **Trade-off:** Limited frequency resolution, may not work well with pitch detection

### Buffer Size Validation

**Constraints:**

- **Minimum:** 512 samples (prevents excessive overhead)
- **Maximum:** 8192 samples (prevents excessive latency)
- **Recommended Range:** 1024-4096 samples

**Validation Logic:**

```typescript
function validateBufferSize(bufferSize: number): void {
  if (bufferSize < 512) {
    throw new Error('Buffer size too small (min: 512 samples)');
  }
  if (bufferSize > 8192) {
    throw new Error('Buffer size too large (max: 8192 samples)');
  }
  if (!Number.isInteger(bufferSize) || bufferSize <= 0) {
    throw new Error('Buffer size must be a positive integer');
  }

  // Recommend power-of-2 for FFT efficiency
  const isPowerOf2 = (bufferSize & (bufferSize - 1)) === 0;
  if (!isPowerOf2) {
    console.warn(`Buffer size ${bufferSize} is not power-of-2 (FFT may be slower)`);
  }
}
```

### Buffer Overflow Detection

**Symptoms:**

- Dropped audio frames (gaps in timestamp sequence)
- Increased latency (timestamps lagging behind expected)
- Audio glitches or stuttering

**Detection Strategy:**

```typescript
let lastTimestamp = 0;
const expectedInterval = (bufferSize / sampleRate) * 1000; // ms

VoicelineDSP.addAudioSampleListener((event) => {
  const actualInterval = event.timestamp - lastTimestamp;
  const delta = Math.abs(actualInterval - expectedInterval);

  if (delta > expectedInterval * 0.5) {
    // 50% tolerance
    console.warn(
      `Buffer overflow detected: expected ${expectedInterval}ms, got ${actualInterval}ms`
    );
    // Mitigation: increase buffer size or reduce processing load
  }

  lastTimestamp = event.timestamp;
});
```

**Mitigation Strategies:**

1. **Increase buffer size** (e.g., 2048 → 4096 samples)
2. **Reduce processing load** (offload to Web Worker, simplify analysis)
3. **Lower sample rate** (e.g., 44.1kHz → 16kHz if acceptable)
4. **Check device performance** (close background apps, ensure not throttling)

### Sample Rate Fallback Logic

Not all devices support all sample rates. Implement graceful fallback:

**iOS (AVAudioEngine):**

```swift
let requestedSampleRate: Double = 16000
let hardwareSampleRate = AVAudioSession.sharedInstance().sampleRate

if requestedSampleRate != hardwareSampleRate {
    print("⚠️ Requested \(requestedSampleRate)Hz, hardware uses \(hardwareSampleRate)Hz")
    print("   AVAudioEngine will automatically resample")
}

// AVAudioEngine handles resampling transparently
let format = AVAudioFormat(
    commonFormat: .pcmFormatFloat32,
    sampleRate: requestedSampleRate,  // Use requested rate
    channels: 1,
    interleaved: false
)
```

**Android (AudioRecord):**

```kotlin
val requestedSampleRate = 16000
val minBufferSize = AudioRecord.getMinBufferSize(
    requestedSampleRate,
    AudioFormat.CHANNEL_IN_MONO,
    AudioFormat.ENCODING_PCM_FLOAT
)

if (minBufferSize <= 0) {
    // Requested sample rate not supported, try fallback
    val fallbackRates = listOf(44100, 48000, 22050, 8000)

    for (fallbackRate in fallbackRates) {
        val fallbackBufferSize = AudioRecord.getMinBufferSize(
            fallbackRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_FLOAT
        )

        if (fallbackBufferSize > 0) {
            println("✅ Using fallback sample rate: ${fallbackRate}Hz")
            // Use fallbackRate instead
            break
        }
    }
}
```

**Common Fallback Sequence:**

1. **Requested rate** (e.g., 16000 Hz)
2. **44100 Hz** (CD-quality, widely supported)
3. **48000 Hz** (professional audio standard)
4. **22050 Hz** (half of CD-quality)
5. **8000 Hz** (telephone quality, last resort)

### Float32 Normalization

Both platforms deliver samples normalized to [-1.0, 1.0] range.

**iOS:**

```swift
// AVAudioPCMBuffer with .pcmFormatFloat32 is already normalized
let samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: frameLength))
// samples are in [-1.0, 1.0] range, no conversion needed
```

**Android:**

```kotlin
// AudioRecord with ENCODING_PCM_FLOAT is already normalized
val samples = FloatArray(bufferSize)
audioRecord.read(samples, 0, bufferSize, AudioRecord.READ_BLOCKING)
// samples are in [-1.0, 1.0] range, no conversion needed
```

**Verification:**

```typescript
VoicelineDSP.addAudioSampleListener((event) => {
  const maxSample = Math.max(...event.samples.map(Math.abs));

  if (maxSample > 1.0) {
    console.error(`Sample out of range: ${maxSample} (expected <= 1.0)`);
  }
});
```

### Buffer Sizing Decision Tree

```
Start
  │
  ├─ Voice analysis (pitch, formants)?
  │   └─ Yes → 16 kHz, 2048 samples (128 ms)
  │
  ├─ Music or high-fidelity capture?
  │   └─ Yes → 44.1 kHz, 4096 samples (93 ms)
  │
  ├─ Real-time visual feedback (<50ms)?
  │   ├─ Yes → 16 kHz, 512 samples (32 ms)
  │   └─ No → Use default (16 kHz, 2048 samples)
  │
  └─ Buffer overflows occurring?
      ├─ Yes → Increase buffer size (2048 → 4096)
      └─ No → Keep current config
```

---

## Error Handling Patterns

### Error Code Taxonomy

All errors follow a consistent structure across platforms:

```typescript
interface StreamErrorEvent {
  error: string; // Error code (uppercase, underscore-separated)
  message: string; // Human-readable description
  platform?: string; // 'ios' | 'android'
  details?: any; // Optional platform-specific details
}
```

### Standard Error Codes

| Error Code              | Description                           | Severity   | Recovery Strategy                         |
| ----------------------- | ------------------------------------- | ---------- | ----------------------------------------- |
| `PERMISSION_DENIED`     | Microphone permission not granted     | **High**   | Prompt user to enable in Settings         |
| `SESSION_CONFIG_FAILED` | Audio session setup failed (iOS)      | **High**   | Retry with fallback config                |
| `ENGINE_START_FAILED`   | Audio engine/recorder failed to start | **High**   | Check device availability, retry once     |
| `DEVICE_NOT_AVAILABLE`  | Microphone hardware unavailable       | **High**   | Inform user, disable audio features       |
| `BUFFER_OVERFLOW`       | Audio frames being dropped            | **Medium** | Increase buffer size, reduce processing   |
| `UNKNOWN_ERROR`         | Unexpected error occurred             | **Medium** | Log for debugging, inform user gracefully |

### Error Recovery Matrix

| Error                     | Retry?   | Fallback         | User Action Required | Auto-Recover        |
| ------------------------- | -------- | ---------------- | -------------------- | ------------------- |
| **PERMISSION_DENIED**     | No       | N/A              | Yes (open Settings)  | No                  |
| **SESSION_CONFIG_FAILED** | Yes (1x) | Different config | No                   | Possible            |
| **ENGINE_START_FAILED**   | Yes (1x) | Check device     | Maybe                | Possible            |
| **DEVICE_NOT_AVAILABLE**  | No       | Disable features | Yes (external mic)   | No                  |
| **BUFFER_OVERFLOW**       | No       | Larger buffer    | No                   | Yes (adjust config) |
| **UNKNOWN_ERROR**         | No       | N/A              | Maybe                | No                  |

### Platform-Specific Error Mapping

#### iOS Errors

```swift
do {
    try audioSession.setCategory(.record, mode: .measurement, options: [.allowBluetooth])
} catch let error as NSError {
    let errorCode: String
    let errorMessage: String

    switch error.code {
    case 561015905:  // '!cat'
        errorCode = "SESSION_CONFIG_FAILED"
        errorMessage = "Audio category not supported: \(error.localizedDescription)"

    case 560030580:  // '!act'
        errorCode = "SESSION_CONFIG_FAILED"
        errorMessage = "Failed to activate audio session: \(error.localizedDescription)"

    case 561017449:  // '!pla'
        errorCode = "ENGINE_START_FAILED"
        errorMessage = "Audio engine failed to start: \(error.localizedDescription)"

    default:
        errorCode = "UNKNOWN_ERROR"
        errorMessage = "iOS audio error \(error.code): \(error.localizedDescription)"
    }

    sendEvent("onStreamError", [
        "error": errorCode,
        "message": errorMessage,
        "platform": "ios",
        "details": ["nativeCode": error.code]
    ])
}
```

#### Android Errors

```kotlin
val samplesRead = audioRecord.read(buffer, 0, bufferSize, AudioRecord.READ_BLOCKING)

when (samplesRead) {
    AudioRecord.ERROR_INVALID_OPERATION -> {
        sendEvent("onStreamError", mapOf(
            "error" to "ENGINE_START_FAILED",
            "message" to "AudioRecord not properly initialized",
            "platform" to "android",
            "details" to mapOf("nativeCode" to AudioRecord.ERROR_INVALID_OPERATION)
        ))
    }

    AudioRecord.ERROR_BAD_VALUE -> {
        sendEvent("onStreamError", mapOf(
            "error" to "BUFFER_OVERFLOW",
            "message" to "Invalid buffer size or read parameters",
            "platform" to "android",
            "details" to mapOf("nativeCode" to AudioRecord.ERROR_BAD_VALUE)
        ))
    }

    AudioRecord.ERROR_DEAD_OBJECT -> {
        sendEvent("onStreamError", mapOf(
            "error" to "DEVICE_NOT_AVAILABLE",
            "message" to "AudioRecord object is no longer valid",
            "platform" to "android",
            "details" to mapOf("nativeCode" to AudioRecord.ERROR_DEAD_OBJECT)
        ))
    }
}
```

### Error Handling Best Practices

#### 1. Always Register Error Listener First

```typescript
// ✅ Correct order
const errorSub = VoicelineDSP.addStreamErrorListener(handleError);
const statusSub = VoicelineDSP.addStreamStatusListener(handleStatus);
const sampleSub = VoicelineDSP.addAudioSampleListener(handleSamples);

await VoicelineDSP.startAudioStream(config);
```

```typescript
// ❌ Incorrect (may miss errors during startup)
await VoicelineDSP.startAudioStream(config);
const errorSub = VoicelineDSP.addStreamErrorListener(handleError);
```

#### 2. Implement Graceful Degradation

```typescript
function handleStreamError(event: StreamErrorEvent) {
  switch (event.error) {
    case 'PERMISSION_DENIED':
      // Critical: cannot proceed without permission
      showPermissionPrompt();
      disableAudioFeatures();
      break;

    case 'DEVICE_NOT_AVAILABLE':
      // Critical: no microphone available
      showDeviceUnavailableMessage();
      disableAudioFeatures();
      break;

    case 'BUFFER_OVERFLOW':
      // Recoverable: adjust configuration
      console.warn('Buffer overflow detected, increasing buffer size');
      restartWithLargerBuffer();
      break;

    case 'SESSION_CONFIG_FAILED':
    case 'ENGINE_START_FAILED':
      // Transient: retry once
      if (!hasRetried) {
        console.warn('Retrying stream startup...');
        setTimeout(() => retryStartStream(), 1000);
        hasRetried = true;
      } else {
        showErrorMessage('Unable to start audio capture');
        disableAudioFeatures();
      }
      break;

    default:
      // Unknown: log and inform user
      console.error('Unknown audio error:', event);
      showErrorMessage('An audio error occurred');
  }
}
```

#### 3. Trauma-Informed Error Messaging

**Principles:**

- **Non-demanding:** Don't force or guilt users
- **Explanatory:** Clarify why permission is needed
- **Empowering:** Give users control and choice
- **Reassuring:** Address privacy concerns

**Examples:**

```typescript
// ❌ Aggressive messaging
"Grant microphone permission now or the app won't work!";
'Error: Permission denied. Fix this immediately.';

// ✅ Trauma-informed messaging
'Voice features require microphone access to analyze your voice in real-time.';
'Your audio is processed locally and never leaves your device.';
'You can enable microphone access in Settings anytime.';

// ❌ Technical jargon
'AudioRecord initialization failed (error -1)';
'AVAudioSession category configuration error 561015905';

// ✅ User-friendly explanation
"We're having trouble connecting to your microphone.";
'This might be resolved by restarting the app.';
"If the issue persists, please check your device's microphone settings.";
```

#### 4. Retry Logic with Exponential Backoff

```typescript
async function startStreamWithRetry(config: StreamConfig, maxRetries = 2) {
  let attempt = 0;
  let delay = 1000; // Start with 1 second

  while (attempt < maxRetries) {
    try {
      await VoicelineDSP.startAudioStream(config);
      return; // Success
    } catch (error) {
      attempt++;

      if (attempt >= maxRetries) {
        throw error; // Give up
      }

      console.warn(
        `Stream start failed (attempt ${attempt}/${maxRetries}), retrying in ${delay}ms...`
      );
      await new Promise((resolve) => setTimeout(resolve, delay));
      delay *= 2; // Exponential backoff
    }
  }
}
```

### Error Handling Flowchart

```
Start Stream Request
        │
        ▼
  Check Permission
        │
        ├─ Granted ─────────────────────┐
        │                               │
        └─ Not Granted ──> Request ─────┤
                               │        │
                          ┌────┴────┐   │
                     Denied      Granted│
                       │            │   │
                       ▼            │   │
             PERMISSION_DENIED      │   │
             Show Settings Prompt   │   │
             Disable Features       │   │
                                    ▼   ▼
                          Configure Audio Session
                                    │
                    ┌───────────────┼───────────────┐
               Success         Failure              │
                  │               │                 │
                  │      SESSION_CONFIG_FAILED      │
                  │      Retry with fallback?       │
                  │          │           │          │
                  │         Yes         No          │
                  │          │           │          │
                  │       Retry      Show Error     │
                  │          │       Disable        │
                  │          └─────────────┐        │
                  ▼                        │        │
          Initialize Engine/Recorder       │        │
                  │                        │        │
          ┌───────┼────────┐               │        │
     Success   Failure     │               │        │
        │          │        │               │        │
        │   ENGINE_START_   │               │        │
        │      FAILED       │               │        │
        │   Retry once?     │               │        │
        │      │      │     │               │        │
        │    Yes    No      │               │        │
        │      │      │     │               │        │
        │   Retry  Error    │               │        │
        │      │      │     │               │        │
        ▼      └──────┴─────┴───────────────┘        │
  Start Capture                                      │
        │                                            │
        ├─ Running ───────> Emit Samples            │
        │                                            │
        └─ Error ──> BUFFER_OVERFLOW/               │
                     DEVICE_NOT_AVAILABLE            │
                     Handle gracefully               │
```

---

## Performance Targets and Measurement

### End-to-End Latency Budget

**Target: <100ms (microphone → visual update)**

| Component         | iOS Target    | Android Target | Measurement Method                   |
| ----------------- | ------------- | -------------- | ------------------------------------ |
| **Mic → Native**  | <40 ms        | <60 ms         | Hardware + OS latency                |
| **Native → JS**   | <10 ms        | <10 ms         | Timestamp tracking (native→JS event) |
| **JS Processing** | <30 ms        | <30 ms         | Performance.now() before/after       |
| **Visual Update** | <16 ms        | <16 ms         | 60fps render frame time              |
| **Total**         | **<96 ms** ✅ | **<116 ms** ⚠️ | End-to-end timestamp tracking        |

**Note:** Android latency ~20-40ms higher than iOS due to platform differences. This is acceptable for Voiceline use case (voice training doesn't require <50ms latency).

### Component Latency Breakdown

#### 1. Microphone → Native Callback

**iOS (AVAudioEngine):**

- **Typical:** 40-60ms
- **Best case:** 30ms (optimal hardware + config)
- **Worst case:** 100ms (Bluetooth mic, suboptimal config)

**Android (AudioRecord):**

- **Typical:** 60-100ms
- **Best case:** 50ms (optimal hardware + config)
- **Worst case:** 150ms (Bluetooth mic, suboptimal config)

**Measurement:**

```swift
// iOS: Compare AVAudioTime to system time
inputNode.installTap(...) { buffer, time in
    let systemTime = Date().timeIntervalSince1970 * 1000
    let audioTime = Double(time.sampleTime) / time.sampleRate * 1000
    let latency = systemTime - audioTime
    print("Mic→Native latency: \(latency)ms")
}
```

```kotlin
// Android: Compare AudioRecord timestamp to system time
val startTime = System.currentTimeMillis()
audioRecord.startRecording()

while (isActive) {
    val samplesRead = audioRecord.read(buffer, 0, bufferSize, AudioRecord.READ_BLOCKING)
    val readTime = System.currentTimeMillis()
    val latency = readTime - startTime
    println("Mic→Native latency: ${latency}ms")
}
```

#### 2. Native → JavaScript Event

**Target:** <10ms (event dispatch overhead)

**Measurement:**

```swift
// iOS: Timestamp native event emission
let nativeTime = Date().timeIntervalSince1970 * 1000
sendEvent("onAudioSample", [
    "samples": samples,
    "nativeTimestamp": nativeTime,
    ...
])
```

```typescript
// JS: Calculate delta from native timestamp
VoicelineDSP.addAudioSampleListener((event) => {
  const jsTime = Date.now();
  const delta = jsTime - event.nativeTimestamp;
  console.log(`Native→JS latency: ${delta}ms`);
});
```

#### 3. JavaScript Processing

**Target:** <30ms (audio analysis + state updates)

**Measurement:**

```typescript
VoicelineDSP.addAudioSampleListener((event) => {
  const startTime = performance.now();

  // Perform analysis
  const pitch = VoicelineDSP.detectPitch(event.samples, event.sampleRate);
  const formants = VoicelineDSP.analyzeFormants(event.samples, event.sampleRate);

  // Update state
  setAudioState({ pitch, formants });

  const endTime = performance.now();
  const processingTime = endTime - startTime;

  if (processingTime > 30) {
    console.warn(`JS processing slow: ${processingTime.toFixed(2)}ms`);
  }
});
```

**Optimization Tips:**

- Offload heavy processing to Web Worker
- Use memoization for expensive calculations
- Batch state updates (React: `unstable_batchedUpdates`)
- Profile with React DevTools Profiler

#### 4. Visual Update (Render)

**Target:** <16ms (60fps frame time)

**Measurement:**

```typescript
function useAnimationFrame(callback: () => void) {
  const requestRef = useRef<number>();
  const previousTimeRef = useRef<number>();

  useEffect(() => {
    const animate = (time: number) => {
      if (previousTimeRef.current !== undefined) {
        const deltaTime = time - previousTimeRef.current;

        if (deltaTime > 16) {
          console.warn(`Frame time exceeded: ${deltaTime.toFixed(2)}ms`);
        }
      }

      callback();
      previousTimeRef.current = time;
      requestRef.current = requestAnimationFrame(animate);
    };

    requestRef.current = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(requestRef.current!);
  }, [callback]);
}
```

### Battery Impact

**Target: <5% battery drain per 30-minute session**

**Measurement Methodology:**

#### iOS: Instruments Energy Log

1. Open Xcode Instruments
2. Select "Energy Log" template
3. Run Voiceline app with audio streaming
4. Record 30-minute session
5. Analyze energy usage:
   - **CPU:** Audio processing load
   - **Networking:** Should be minimal (no network I/O during streaming)
   - **Location:** Should be zero (not used)
   - **Display:** User interaction overhead

**Acceptable Energy Impact:** Medium or lower (not "Very High")

#### Android: Battery Historian

1. Enable battery stats: `adb shell dumpsys batterystats --enable full-wake-history`
2. Reset stats: `adb shell dumpsys batterystats --reset`
3. Run 30-minute streaming session
4. Capture stats: `adb bugreport bugreport.zip`
5. Upload to [Battery Historian](https://bathist.ef.lc/)
6. Analyze:
   - **App battery usage:** Should be <5% of total battery per 30min
   - **Wakelock usage:** Should be minimal (only during active streaming)
   - **CPU usage:** Should be moderate (not constantly high)

**Test Protocol:**

```
1. Fully charge device to 100%
2. Close all background apps
3. Start Voiceline app
4. Begin audio streaming
5. Keep screen on (consistent display drain)
6. Let run for exactly 30 minutes
7. Stop streaming
8. Check battery level (should be >95%)
```

### Memory Usage

**Target: <10MB during streaming**

**Measurement:**

#### iOS: Instruments Allocations

1. Open Xcode Instruments
2. Select "Allocations" template
3. Run Voiceline app with audio streaming
4. Record 1-hour session (test for memory leaks)
5. Check:
   - **Persistent allocations:** Should not continuously grow
   - **Peak memory:** Should stay under 10MB for audio streaming module
   - **Leaked memory:** Should be zero

#### Android: Memory Profiler

1. Open Android Studio
2. Run app on device
3. Open Memory Profiler
4. Start audio streaming
5. Record 1-hour session
6. Check:
   - **Java Heap:** Should stabilize, not continuously grow
   - **Native Heap:** Should stabilize (AudioRecord buffers)
   - **Graphics:** Should be minimal (audio module doesn't use GPU)

**Memory Leak Detection:**

```kotlin
// Ensure proper cleanup
override fun onDestroy() {
    super.onDestroy()
    audioStreamManager?.cleanup()  // Cancel coroutines, release AudioRecord
    audioStreamManager = null
}
```

```swift
deinit {
    // Swift ARC should handle this, but verify
    audioEngine?.stop()
    inputNode?.removeTap(onBus: 0)
    NotificationCenter.default.removeObserver(self)
}
```

### Audio Dropout Rate

**Target: <0.1% (less than 1 dropout per 1000 samples)**

**Detection:**

```typescript
let totalSamples = 0;
let dropoutCount = 0;
let lastTimestamp = 0;

VoicelineDSP.addAudioSampleListener((event) => {
  totalSamples++;

  const expectedInterval = (bufferSize / sampleRate) * 1000;
  const actualInterval = event.timestamp - lastTimestamp;

  if (lastTimestamp > 0 && actualInterval > expectedInterval * 1.5) {
    // Dropout detected (50% tolerance)
    dropoutCount++;
    console.warn(`Dropout #${dropoutCount} detected at sample ${totalSamples}`);
  }

  lastTimestamp = event.timestamp;

  // Report dropout rate every 1000 samples
  if (totalSamples % 1000 === 0) {
    const dropoutRate = (dropoutCount / totalSamples) * 100;
    console.log(`Dropout rate: ${dropoutRate.toFixed(3)}% (${dropoutCount}/${totalSamples})`);

    if (dropoutRate > 0.1) {
      console.error('⚠️ Dropout rate exceeds target (0.1%)');
    }
  }
});
```

### Performance Test Plan

#### Test 1: Latency Measurement

**Objective:** Measure end-to-end latency (mic → visual update)

**Setup:**

1. Use synthetic audio source (known timing)
   - iOS: Play known audio file to AVAudioEngine input
   - Android: Use loopback audio (if supported) or external speaker→mic
2. Inject timestamp at audio source
3. Track timestamp through pipeline
4. Measure at each stage

**Acceptance Criteria:**

- iOS: <100ms (95th percentile)
- Android: <120ms (95th percentile)

#### Test 2: Battery Impact

**Objective:** Measure battery drain during 30-minute streaming session

**Setup:**

1. Fully charge device
2. Close all background apps
3. Run 30-minute streaming session
4. Monitor battery level

**Acceptance Criteria:**

- Battery drain <5% for 30-minute session
- No excessive heat generation
- No thermal throttling warnings

#### Test 3: Memory Stability

**Objective:** Verify no memory leaks during long-running session

**Setup:**

1. Start audio streaming
2. Run for 1 hour
3. Profile memory usage

**Acceptance Criteria:**

- Memory usage stabilizes (not continuously growing)
- No memory leak warnings in profiler
- Peak memory <10MB for audio streaming module

#### Test 4: Dropout Detection

**Objective:** Measure audio dropout rate under normal conditions

**Setup:**

1. Stream audio for 10 minutes
2. Monitor timestamp gaps
3. Calculate dropout rate

**Acceptance Criteria:**

- Dropout rate <0.1%
- No dropouts under light CPU load
- Graceful handling under heavy CPU load (increase buffer, emit warning)

---

## Cross-Platform Consistency

### API Surface Parity

**Guarantee: Identical API on iOS and Android**

| Feature                     | iOS         | Android     | Consistent? |
| --------------------------- | ----------- | ----------- | ----------- |
| **TypeScript API**          | ✅ Same     | ✅ Same     | ✅ Yes      |
| **Function signatures**     | ✅ Same     | ✅ Same     | ✅ Yes      |
| **Event payloads**          | ✅ Same     | ✅ Same     | ✅ Yes      |
| **Error codes**             | ✅ Same     | ✅ Same     | ✅ Yes      |
| **Default config**          | ✅ Same     | ✅ Same     | ✅ Yes      |
| **Buffer size constraints** | ✅ 512-8192 | ✅ 512-8192 | ✅ Yes      |

### Event Payload Consistency

**AudioSampleEvent:**

```typescript
// Identical payload structure on both platforms
{
  samples: number[];      // Float32 array, [-1.0, 1.0]
  sampleRate: number;     // Hz (e.g., 16000)
  frameLength: number;    // Sample count (e.g., 2048)
  timestamp: number;      // Milliseconds since stream start
}
```

**StreamStatusEvent:**

```typescript
{
  status: 'streaming' | 'stopped' | 'error';
  timestamp?: number;     // Optional, milliseconds since epoch
}
```

**StreamErrorEvent:**

```typescript
{
  error: string;          // Error code (e.g., 'PERMISSION_DENIED')
  message: string;        // Human-readable description
  platform?: 'ios' | 'android';
  details?: any;          // Optional platform-specific details
}
```

### Error Code Mapping

**Identical error codes across platforms:**

| Error Code              | iOS | Android   | Message Format                          |
| ----------------------- | --- | --------- | --------------------------------------- |
| `PERMISSION_DENIED`     | ✅  | ✅        | "Microphone permission not granted"     |
| `SESSION_CONFIG_FAILED` | ✅  | ⚠️ (rare) | "Audio session setup failed"            |
| `ENGINE_START_FAILED`   | ✅  | ✅        | "Audio engine/recorder failed to start" |
| `DEVICE_NOT_AVAILABLE`  | ✅  | ✅        | "Microphone hardware unavailable"       |
| `BUFFER_OVERFLOW`       | ✅  | ✅        | "Audio frames are being dropped"        |
| `UNKNOWN_ERROR`         | ✅  | ✅        | "Unexpected error occurred"             |

### Platform-Specific Behavior Documentation

**Differences to document and handle:**

| Aspect                    | iOS                        | Android                    | Mitigation                                |
| ------------------------- | -------------------------- | -------------------------- | ----------------------------------------- |
| **Latency**               | 40-60ms                    | 60-100ms                   | Document difference, adjust expectations  |
| **Permission Flow**       | System prompt (automatic)  | Runtime request (explicit) | Handle in app code (Android)              |
| **Interruption Handling** | Automatic (AVAudioSession) | Manual (focus management)  | Implement interruption handling (Android) |
| **Sample Format**         | Int16 → Float32 conversion | Native Float32 (API 23+)   | Transparent to JS layer                   |
| **Threading Model**       | Audio thread → Main        | Dispatchers.IO → Main      | Same event delivery model                 |

**Example: Document Platform Differences**

````markdown
### Platform-Specific Notes

#### Latency

- **iOS:** Typically 40-60ms (mic → native callback)
- **Android:** Typically 60-100ms (mic → native callback)
- **Reason:** Android audio stack has additional buffering layers

**Impact:** Android users may experience slightly higher latency (~20-40ms).
This is acceptable for voice training use case (not latency-critical).

#### Permission Handling

- **iOS:** System automatically prompts user on first `startAudioStream()` call
- **Android:** App must explicitly request permission via `ActivityCompat.requestPermissions()`

**Impact:** Android requires explicit permission handling in JavaScript layer.

```typescript
// Android: Check permission before starting
const hasPermission = await PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.RECORD_AUDIO);

if (!hasPermission) {
  await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.RECORD_AUDIO, {
    title: 'Microphone Permission',
    message: 'Voice features require microphone access for real-time analysis.',
    buttonPositive: 'Allow',
  });
}

// iOS: No explicit check needed, system handles automatically
await VoicelineDSP.startAudioStream(config);
```
````

#### Interruption Handling

- **iOS:** Automatic handling via AVAudioSession notifications (phone calls, Siri)
- **Android:** Manual handling via AudioFocusRequest (phone calls, other apps)

**Impact:** iOS resumes automatically, Android may require manual resume.

````

### Testing Strategy for Cross-Platform Parity

#### 1. API Contract Tests

**Objective:** Verify identical API surface on both platforms

```typescript
describe('VoicelineDSP API', () => {
  it('should have identical function signatures on iOS and Android', () => {
    expect(typeof VoicelineDSP.startAudioStream).toBe('function');
    expect(typeof VoicelineDSP.stopAudioStream).toBe('function');
    expect(typeof VoicelineDSP.isStreaming).toBe('function');
    expect(typeof VoicelineDSP.addAudioSampleListener).toBe('function');
    expect(typeof VoicelineDSP.addStreamStatusListener).toBe('function');
    expect(typeof VoicelineDSP.addStreamErrorListener).toBe('function');
  });

  it('should emit events with identical payload structures', async () => {
    const sampleEvents: AudioSampleEvent[] = [];

    const sub = VoicelineDSP.addAudioSampleListener((event) => {
      sampleEvents.push(event);
    });

    await VoicelineDSP.startAudioStream({ sampleRate: 16000, bufferSize: 2048 });
    await new Promise(resolve => setTimeout(resolve, 500));  // Capture some samples
    await VoicelineDSP.stopAudioStream();
    sub.remove();

    // Verify payload structure
    expect(sampleEvents.length).toBeGreaterThan(0);
    const event = sampleEvents[0];

    expect(event).toHaveProperty('samples');
    expect(event).toHaveProperty('sampleRate');
    expect(event).toHaveProperty('frameLength');
    expect(event).toHaveProperty('timestamp');

    expect(Array.isArray(event.samples)).toBe(true);
    expect(typeof event.sampleRate).toBe('number');
    expect(typeof event.frameLength).toBe('number');
    expect(typeof event.timestamp).toBe('number');
  });
});
````

#### 2. Error Code Consistency Tests

```typescript
describe('Error Handling', () => {
  it('should emit identical error codes on iOS and Android', async () => {
    const errors: StreamErrorEvent[] = [];

    const sub = VoicelineDSP.addStreamErrorListener((event) => {
      errors.push(event);
    });

    // Trigger various error conditions
    // ... (platform-specific test setup)

    // Verify error codes match across platforms
    errors.forEach((error) => {
      expect(error).toHaveProperty('error');
      expect(error).toHaveProperty('message');
      expect(error).toHaveProperty('platform');

      expect([
        'PERMISSION_DENIED',
        'SESSION_CONFIG_FAILED',
        'ENGINE_START_FAILED',
        'DEVICE_NOT_AVAILABLE',
        'BUFFER_OVERFLOW',
        'UNKNOWN_ERROR',
      ]).toContain(error.error);
    });

    sub.remove();
  });
});
```

#### 3. Configuration Validation Tests

```typescript
describe('Configuration', () => {
  it('should accept same valid configs on iOS and Android', async () => {
    const validConfigs = [
      { sampleRate: 16000, bufferSize: 2048, channels: 1 },
      { sampleRate: 44100, bufferSize: 4096, channels: 1 },
      { sampleRate: 48000, bufferSize: 4096, channels: 1 },
    ];

    for (const config of validConfigs) {
      await expect(VoicelineDSP.startAudioStream(config)).resolves.not.toThrow();
      await VoicelineDSP.stopAudioStream();
    }
  });

  it('should reject same invalid configs on iOS and Android', async () => {
    const invalidConfigs = [
      { sampleRate: 16000, bufferSize: 100, channels: 1 }, // Too small
      { sampleRate: 16000, bufferSize: 10000, channels: 1 }, // Too large
      { sampleRate: -1, bufferSize: 2048, channels: 1 }, // Negative
    ];

    for (const config of invalidConfigs) {
      await expect(VoicelineDSP.startAudioStream(config)).rejects.toThrow();
    }
  });
});
```

### API Compatibility Checklist

Use this checklist when implementing platform-specific code:

**TypeScript API:**

- [ ] All functions have identical signatures (parameters, return types)
- [ ] All event listener functions return `Subscription` object
- [ ] All async functions return `Promise<T>` with same `T`
- [ ] All interfaces exported from index.ts

**Event Payloads:**

- [ ] `AudioSampleEvent` has identical fields (samples, sampleRate, frameLength, timestamp)
- [ ] `StreamStatusEvent` has identical fields (status, timestamp?)
- [ ] `StreamErrorEvent` has identical fields (error, message, platform?, details?)
- [ ] Field types match exactly (number, string, boolean, array)

**Error Codes:**

- [ ] Same error codes used on both platforms
- [ ] Error messages have consistent format
- [ ] Platform-specific details in optional `details` field

**Configuration:**

- [ ] Same default values (16000 Hz, 2048 samples, mono)
- [ ] Same validation rules (512-8192 samples)
- [ ] Same buffer size calculation logic

**Behavior:**

- [ ] Same lifecycle (start → streaming → stop)
- [ ] Same event emission sequence (status → samples → status)
- [ ] Same cleanup behavior (remove listeners, release resources)

---

## Architecture Diagrams

### System Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Voiceline App                           │
│                      (React Native + TS)                        │
└────────────────┬────────────────────────────────────────────────┘
                 │ TypeScript API
                 │ (startAudioStream, addAudioSampleListener, ...)
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    VoicelineDSP Module                          │
│                    (Expo Module Layer)                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  JavaScript Bindings (TypeScript)                        │  │
│  │  - Type definitions (StreamConfig, AudioSampleEvent)     │  │
│  │  - Event emitter wrappers (Subscription management)      │  │
│  └────────────┬─────────────────────────────────────────────┘  │
│               │                                                 │
│               ▼                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Native Module (Swift on iOS, Kotlin on Android)         │  │
│  │  - Audio session management                              │  │
│  │  - Audio engine/recorder lifecycle                       │  │
│  │  - Event emission to JavaScript                          │  │
│  └────────────┬─────────────────────────────────────────────┘  │
└───────────────┼─────────────────────────────────────────────────┘
                │
      ┌─────────┴─────────┐
      ▼                   ▼
┌─────────────┐     ┌─────────────┐
│     iOS     │     │   Android   │
│ Platform    │     │ Platform    │
│             │     │             │
│ AVAudio-    │     │ AudioRecord │
│ Engine      │     │             │
│ AVAudio-    │     │ Kotlin      │
│ Session     │     │ Coroutines  │
└──────┬──────┘     └──────┬──────┘
       │                   │
       │                   │
       ▼                   ▼
┌─────────────────────────────────┐
│     Device Microphone           │
└─────────────────────────────────┘
```

### Audio Streaming Sequence Diagram

```
User App          VoicelineDSP       Native Module      Audio Engine      Microphone
   │                   │                   │                  │               │
   │ startAudio()      │                   │                  │               │
   ├──────────────────>│                   │                  │               │
   │                   │ Initialize        │                  │               │
   │                   ├──────────────────>│                  │               │
   │                   │                   │ Configure        │               │
   │                   │                   ├─────────────────>│               │
   │                   │                   │                  │ Request Access│
   │                   │                   │                  ├──────────────>│
   │                   │                   │                  │ Permission OK │
   │                   │                   │                  │<──────────────│
   │                   │                   │ Start Engine     │               │
   │                   │                   ├─────────────────>│               │
   │                   │                   │ Engine Started   │               │
   │                   │                   │<─────────────────│               │
   │                   │ Emit Status       │                  │               │
   │<──────────────────┼───────────────────┤ (streaming)      │               │
   │                   │                   │                  │               │
   │                   │                   │                  │ Capture Audio │
   │                   │                   │                  │<──────────────│
   │                   │                   │ Audio Buffer     │               │
   │                   │                   │<─────────────────│               │
   │                   │ Emit Samples      │                  │               │
   │<──────────────────┼───────────────────┤                  │               │
   │ (AudioSampleEvent)│                   │                  │               │
   │                   │                   │                  │               │
   │                   │                   │  [Repeat ~7.8x/sec for 2048@16kHz]
   │                   │                   │                  │               │
   │ stopAudio()       │                   │                  │               │
   ├──────────────────>│                   │                  │               │
   │                   │ Stop              │                  │               │
   │                   ├──────────────────>│                  │               │
   │                   │                   │ Stop Engine      │               │
   │                   │                   ├─────────────────>│               │
   │                   │                   │ Cleanup          │               │
   │                   │                   │<─────────────────│               │
   │                   │ Emit Status       │                  │               │
   │<──────────────────┼───────────────────┤ (stopped)        │               │
   │                   │                   │                  │               │
```

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Audio Sample Pipeline                       │
└─────────────────────────────────────────────────────────────────────┘

 Microphone
     │
     │ Analog Audio (Pressure Waves)
     │
     ▼
 ADC (Analog-to-Digital Converter)
     │
     │ PCM Audio (Int16 or Float32)
     │
     ▼
 ┌────────────────────────┐
 │  Platform Audio API    │
 │  iOS: AVAudioEngine    │──┐
 │  Android: AudioRecord  │  │ Sample Rate: 16 kHz
 └────────────────────────┘  │ Buffer Size: 2048 samples
     │                       │ Format: Float32 PCM
     │ Audio Buffer          │ Channels: Mono
     │                       │ Latency: 128 ms
     ▼                       │
 ┌────────────────────────┐  │
 │  Native Module         │  │
 │  - Buffer conversion   │──┘
 │  - Normalization       │
 │  - Timestamp injection │
 └────────────────────────┘
     │
     │ FloatArray (native)
     │ [-1.0, 1.0] normalized
     │
     ▼
 ┌────────────────────────┐
 │  Expo EventEmitter     │
 │  - Main thread dispatch│
 │  - JSON serialization  │
 └────────────────────────┘
     │
     │ AudioSampleEvent (JS)
     │ { samples, sampleRate, frameLength, timestamp }
     │
     ▼
 ┌────────────────────────┐
 │  JavaScript Handler    │
 │  - Pitch detection     │
 │  - Formant analysis    │
 │  - Spectral features   │
 └────────────────────────┘
     │
     │ Analysis Results
     │ { pitch, formants, spectrum, ... }
     │
     ▼
 ┌────────────────────────┐
 │  React State Update    │
 │  - setState()          │
 │  - Render trigger      │
 └────────────────────────┘
     │
     │ UI Updates
     │
     ▼
 ┌────────────────────────┐
 │  Visual Components     │
 │  - Waveform display    │
 │  - Pitch graph         │
 │  - Formant chart       │
 └────────────────────────┘
```

---

## References

### API Specifications

- [VoicelineDSP v0.2.0 API Spec](./voicelinedsp-v0.2.0-api-spec.md)
- [iOS Implementation Design](./ios-audio-streaming-design.md)
- [Android Implementation Design](./android-audio-streaming-design.md)

### Epic Documentation

- [Epic 2D Technical Specification](../epics/epic-2d-tech-spec.md)
- [Audio Streaming Architecture Decision](./audio-streaming-architecture-decision.md)

### Platform Documentation

**iOS:**

- [AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [AVAudioSession Documentation](https://developer.apple.com/documentation/avfoundation/avaudiosession)
- [installTap Reference](https://developer.apple.com/documentation/avfaudio/avaudionode/1387122-installtap)
- [Accelerate Framework (vDSP)](https://developer.apple.com/documentation/accelerate/vdsp)

**Android:**

- [AudioRecord Documentation](https://developer.android.com/reference/android/media/AudioRecord)
- [AudioFormat Documentation](https://developer.android.com/reference/android/media/AudioFormat)
- [Runtime Permissions Guide](https://developer.android.com/training/permissions/requesting)
- [Kotlin Coroutines Guide](https://kotlinlang.org/docs/coroutines-guide.html)

**Expo:**

- [Expo Modules API](https://docs.expo.dev/modules/overview/)
- [EventEmitter Pattern](https://docs.expo.dev/modules/module-api/#events)

### Research Papers

- [YIN Pitch Detection Algorithm](http://audition.ens.fr/adc/pdf/2002_JASA_YIN.pdf) - De Cheveigné & Kawahara, 2002

### Testing Tools

- [iOS Instruments](https://developer.apple.com/instruments/)
- [Android Profiler](https://developer.android.com/studio/profile/android-profiler)
- [Battery Historian](https://github.com/google/battery-historian)

---

## Document History

| Version | Date       | Author                 | Changes                             |
| ------- | ---------- | ---------------------- | ----------------------------------- |
| 0.2.0   | 2025-11-12 | Loqa Architecture Team | Initial design document for Epic 2D |

---

**Next Steps:**

1. **Review this architecture** with stakeholders (Anna, development team)
2. **Validate design assumptions** with platform experts (iOS, Android)
3. **Create detailed diagrams** (Mermaid, Draw.io, or similar)
4. **Begin implementation** of Story 2D.2 (iOS), 2D.3 (Android)
5. **Update this document** as implementation uncovers issues or optimizations
