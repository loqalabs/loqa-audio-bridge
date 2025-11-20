# VoicelineDSP v0.2.0 API Specification

**Version:** 0.2.0
**Status:** Design Document
**Last Updated:** 2025-11-12
**Author:** Loqa Architecture Team

## Overview

VoicelineDSP v0.2.0 extends the voice analysis capabilities introduced in v0.1.0 with real-time audio streaming support. This API enables native audio capture from device microphones and delivers audio samples to JavaScript via event-driven architecture, enabling live voice-responsive visualizations in the Voiceline mobile app.

### Key Features

- **Real-time audio streaming** from device microphone
- **Event-driven architecture** using Expo EventEmitter pattern
- **Cross-platform consistency** (identical API on iOS and Android)
- **Type-safe TypeScript interfaces** for all events and configurations
- **Privacy-first design** (in-memory processing, no disk writes)

### Design Principles

1. **Ergonomic API**: Intuitive, minimal boilerplate, clear error messages
2. **Type Safety**: Full TypeScript coverage with JSDoc documentation
3. **Performance**: Low-latency streaming (<100ms end-to-end)
4. **Privacy**: In-memory only, audio samples discarded after processing
5. **Cross-platform**: Same API behavior on iOS and Android (within platform constraints)

---

## Type Definitions

### StreamConfig

Configuration options for initializing an audio stream.

```typescript
/**
 * Configuration for audio streaming session
 *
 * @example
 * const config: StreamConfig = {
 *   sampleRate: 16000,      // 16kHz for voice analysis
 *   bufferSize: 2048,       // 128ms buffer (optimal for YIN pitch detection)
 *   channels: 1             // Mono audio
 * };
 */
export interface StreamConfig {
  /**
   * Sample rate in Hz
   *
   * Supported values: 16000, 44100, 48000
   * - 16000 Hz: Recommended for voice analysis (optimal for YIN pitch detection)
   * - 44100 Hz: CD-quality audio
   * - 48000 Hz: Professional audio standard
   *
   * @default 16000
   */
  sampleRate: number;

  /**
   * Buffer size in samples
   *
   * Determines latency and processing window:
   * - Smaller buffers = lower latency, less frequency resolution
   * - Larger buffers = higher latency, better frequency resolution
   *
   * Valid range: 512 - 8192 samples
   * Recommended: 2048 samples at 16kHz (128ms, optimal for voice analysis)
   *
   * Latency calculation: (bufferSize / sampleRate) * 1000 ms
   * - 2048 samples @ 16kHz = 128ms
   * - 4096 samples @ 44.1kHz = 93ms
   * - 4096 samples @ 48kHz = 85ms
   *
   * @default 2048
   */
  bufferSize: number;

  /**
   * Number of audio channels
   *
   * Currently only mono (1 channel) is supported.
   * Stereo input will be automatically converted to mono by averaging channels.
   *
   * @default 1
   */
  channels: 1;
}
```

### AudioSampleEvent

Event payload containing audio samples from the microphone.

```typescript
/**
 * Audio sample data event
 *
 * Emitted continuously while streaming is active.
 * Contains raw audio samples normalized to [-1.0, 1.0] range.
 *
 * @example
 * const subscription = VoicelineDSP.addAudioSampleListener((event) => {
 *   console.log(`Received ${event.frameLength} samples at ${event.timestamp}ms`);
 *   const samples = event.samples; // Float32Array normalized to [-1.0, 1.0]
 *
 *   // Process samples (e.g., visualize waveform, analyze pitch)
 *   analyzeAudio(samples, event.sampleRate);
 * });
 */
export interface AudioSampleEvent {
  /**
   * Raw audio samples as floating-point values
   *
   * Format: Float32, normalized to [-1.0, 1.0] range
   * Length: equals bufferSize from StreamConfig
   *
   * Platform notes:
   * - iOS: Converted from AVAudioPCMBuffer Int16 format
   * - Android: Directly captured as ENCODING_PCM_FLOAT
   */
  samples: number[];

  /**
   * Sample rate of the audio data in Hz
   *
   * Should match the sampleRate from StreamConfig,
   * or the fallback rate if requested rate was unsupported.
   */
  sampleRate: number;

  /**
   * Number of samples in this frame
   *
   * Should match bufferSize from StreamConfig under normal conditions.
   * May be smaller in edge cases (e.g., stream stopping).
   */
  frameLength: number;

  /**
   * Timestamp when samples were captured (milliseconds since stream start)
   *
   * Useful for:
   * - Synchronizing audio with visual updates
   * - Measuring end-to-end latency
   * - Detecting buffer overflows (gaps in timestamp sequence)
   */
  timestamp: number;
}
```

### StreamStatusEvent

Event indicating streaming state changes.

```typescript
/**
 * Stream status change event
 *
 * Emitted when streaming state changes (started, stopped, error occurred).
 *
 * @example
 * VoicelineDSP.addStreamStatusListener((event) => {
 *   switch (event.status) {
 *     case 'streaming':
 *       console.log('Audio streaming started');
 *       break;
 *     case 'stopped':
 *       console.log('Audio streaming stopped');
 *       break;
 *     case 'error':
 *       console.log('Streaming error - check error listener');
 *       break;
 *   }
 * });
 */
export interface StreamStatusEvent {
  /**
   * Current streaming status
   *
   * - 'streaming': Audio capture is active, samples are being delivered
   * - 'stopped': Audio capture has stopped (user requested or cleanup)
   * - 'error': An error occurred (see StreamErrorEvent for details)
   */
  status: 'streaming' | 'stopped' | 'error';

  /**
   * Optional timestamp when status changed (milliseconds since epoch)
   */
  timestamp?: number;
}
```

### StreamErrorEvent

Event containing error information.

```typescript
/**
 * Stream error event
 *
 * Emitted when an error occurs during streaming setup or operation.
 * Contains error code, human-readable message, and recovery guidance.
 *
 * @example
 * VoicelineDSP.addStreamErrorListener((event) => {
 *   console.error(`[${event.error}] ${event.message}`);
 *
 *   switch (event.error) {
 *     case 'PERMISSION_DENIED':
 *       // Prompt user to grant microphone permission in settings
 *       showPermissionPrompt();
 *       break;
 *     case 'DEVICE_NOT_AVAILABLE':
 *       // Inform user microphone is unavailable
 *       showMicrophoneUnavailableMessage();
 *       break;
 *     case 'BUFFER_OVERFLOW':
 *       // Reduce processing load or increase buffer size
 *       adjustBufferSize();
 *       break;
 *   }
 * });
 */
export interface StreamErrorEvent {
  /**
   * Error code identifier
   *
   * Standardized error codes (see Error Handling section):
   * - PERMISSION_DENIED: Microphone permission not granted
   * - SESSION_CONFIG_FAILED: Audio session setup failed (iOS)
   * - ENGINE_START_FAILED: Audio engine/recorder failed to start
   * - DEVICE_NOT_AVAILABLE: Microphone hardware unavailable
   * - BUFFER_OVERFLOW: Audio frames are being dropped
   * - UNKNOWN_ERROR: Unexpected error occurred
   */
  error: string;

  /**
   * Human-readable error message
   *
   * Provides context about what went wrong and potential recovery steps.
   * Suitable for logging but may need user-friendly translation for UI display.
   */
  message: string;

  /**
   * Platform where error occurred ('ios' | 'android')
   *
   * Useful for platform-specific error handling or debugging.
   */
  platform?: string;

  /**
   * Optional additional error details (e.g., native error codes)
   */
  details?: Record<string, unknown>;
}
```

---

## Function API

### Core Streaming Functions

#### startAudioStream()

Starts audio streaming from the device microphone.

```typescript
/**
 * Start audio streaming session
 *
 * Requests microphone permission (if not granted), configures audio session,
 * and begins delivering audio samples via AudioSampleEvent.
 *
 * @param config - Stream configuration options
 * @returns Promise that resolves when streaming starts successfully
 * @throws StreamErrorEvent via error listener if startup fails
 *
 * @example
 * try {
 *   await VoicelineDSP.startAudioStream({
 *     sampleRate: 16000,
 *     bufferSize: 2048,
 *     channels: 1
 *   });
 *   console.log('Streaming started');
 * } catch (error) {
 *   console.error('Failed to start streaming:', error);
 * }
 *
 * @platform ios AVAudioEngine with input node tap
 * @platform android AudioRecord with background coroutine
 */
export function startAudioStream(config?: Partial<StreamConfig>): Promise<void>;
```

**Behavior:**

1. Validates configuration (falls back to defaults for missing values)
2. Requests microphone permission (if not already granted)
3. Configures audio session (iOS: AVAudioSession, Android: AudioRecord)
4. Starts audio engine/recorder
5. Emits `StreamStatusEvent` with status='streaming'
6. Begins emitting `AudioSampleEvent` at configured intervals

**Error Cases:**

- Permission denied → emits `PERMISSION_DENIED` error
- Audio session setup fails → emits `SESSION_CONFIG_FAILED` or `ENGINE_START_FAILED` error
- Device microphone unavailable → emits `DEVICE_NOT_AVAILABLE` error

#### stopAudioStream()

Stops audio streaming and releases resources.

```typescript
/**
 * Stop audio streaming session
 *
 * Stops audio capture, removes event listeners (native side),
 * and releases audio engine/recorder resources.
 *
 * @returns Promise that resolves when streaming stops successfully
 *
 * @example
 * await VoicelineDSP.stopAudioStream();
 * console.log('Streaming stopped');
 *
 * @platform ios Removes tap, stops AVAudioEngine, deactivates session
 * @platform android Cancels coroutine, stops and releases AudioRecord
 */
export function stopAudioStream(): Promise<void>;
```

**Behavior:**

1. Stops audio engine/recorder
2. Removes native tap/listener (iOS: removeTap, Android: coroutine cancellation)
3. Releases audio session resources
4. Emits `StreamStatusEvent` with status='stopped'
5. Stops emitting `AudioSampleEvent`

**Safe to call multiple times:** Subsequent calls are no-ops if already stopped.

#### isStreaming()

Checks if audio streaming is currently active.

```typescript
/**
 * Check if audio streaming is active
 *
 * @returns Promise resolving to true if streaming, false otherwise
 *
 * @example
 * const streaming = await VoicelineDSP.isStreaming();
 * if (streaming) {
 *   console.log('Currently streaming audio');
 * }
 */
export function isStreaming(): Promise<boolean>;
```

**Usage Notes:**

- Returns `true` between successful `startAudioStream()` and `stopAudioStream()` calls
- Returns `false` if stream was stopped due to error or interruption
- Returns `false` before first `startAudioStream()` call

---

### Event Listener Functions

All event listeners return a `Subscription` object that can be used to remove the listener.

```typescript
/**
 * Subscription object for event listeners
 */
export interface Subscription {
  /**
   * Remove this event listener
   */
  remove(): void;
}
```

#### addAudioSampleListener()

Registers a listener for audio sample events.

```typescript
/**
 * Register listener for audio sample events
 *
 * @param listener - Callback function receiving AudioSampleEvent
 * @returns Subscription object to remove listener
 *
 * @example
 * const subscription = VoicelineDSP.addAudioSampleListener((event) => {
 *   const { samples, sampleRate, frameLength, timestamp } = event;
 *   console.log(`Received ${frameLength} samples at ${timestamp}ms`);
 *
 *   // Analyze audio samples
 *   const pitch = detectPitch(samples, sampleRate);
 *   updateVisualization(pitch);
 * });
 *
 * // Later: remove listener
 * subscription.remove();
 */
export function addAudioSampleListener(listener: (event: AudioSampleEvent) => void): Subscription;
```

**Event Frequency:**

- Emitted every `bufferSize / sampleRate` seconds
- Example: 2048 samples @ 16kHz = every 128ms (~7.8 events/second)

**Performance Note:**

Listener should process samples quickly to avoid blocking native thread.
Consider offloading heavy processing to Web Worker or async queue.

#### addStreamStatusListener()

Registers a listener for stream status change events.

```typescript
/**
 * Register listener for stream status changes
 *
 * @param listener - Callback function receiving StreamStatusEvent
 * @returns Subscription object to remove listener
 *
 * @example
 * const subscription = VoicelineDSP.addStreamStatusListener((event) => {
 *   console.log(`Stream status: ${event.status}`);
 *
 *   if (event.status === 'streaming') {
 *     showRecordingIndicator();
 *   } else if (event.status === 'stopped') {
 *     hideRecordingIndicator();
 *   }
 * });
 *
 * subscription.remove();
 */
export function addStreamStatusListener(listener: (event: StreamStatusEvent) => void): Subscription;
```

**Status Transitions:**

- `startAudioStream()` → status='streaming'
- `stopAudioStream()` → status='stopped'
- Error during streaming → status='error' (see `StreamErrorEvent` for details)
- iOS interruption (phone call) → status='stopped' → status='streaming' (auto-resume)

#### addStreamErrorListener()

Registers a listener for stream error events.

```typescript
/**
 * Register listener for stream errors
 *
 * @param listener - Callback function receiving StreamErrorEvent
 * @returns Subscription object to remove listener
 *
 * @example
 * const subscription = VoicelineDSP.addStreamErrorListener((event) => {
 *   console.error(`[${event.error}] ${event.message}`);
 *
 *   // Handle specific errors
 *   switch (event.error) {
 *     case 'PERMISSION_DENIED':
 *       Alert.alert(
 *         'Microphone Permission Required',
 *         'Please enable microphone access in Settings to use voice features.',
 *         [{ text: 'Open Settings', onPress: openAppSettings }]
 *       );
 *       break;
 *
 *     case 'DEVICE_NOT_AVAILABLE':
 *       showToast('Microphone is not available on this device');
 *       break;
 *
 *     case 'BUFFER_OVERFLOW':
 *       console.warn('Audio frames dropping - consider increasing buffer size');
 *       break;
 *   }
 * });
 *
 * subscription.remove();
 */
export function addStreamErrorListener(listener: (event: StreamErrorEvent) => void): Subscription;
```

**Error Handling Strategy:**

1. Listen for errors before calling `startAudioStream()`
2. Handle permission errors by prompting user to open Settings
3. Handle device errors by disabling audio features gracefully
4. Handle transient errors (BUFFER_OVERFLOW) with automatic retry or config adjustment

---

## Usage Examples

### Basic Streaming Lifecycle

```typescript
import { VoicelineDSP } from '@loqa/voiceline-dsp';

// 1. Setup error handling first
const errorSub = VoicelineDSP.addStreamErrorListener((event) => {
  console.error(`Stream error: [${event.error}] ${event.message}`);

  if (event.error === 'PERMISSION_DENIED') {
    Alert.alert('Microphone permission required');
  }
});

// 2. Setup status listener
const statusSub = VoicelineDSP.addStreamStatusListener((event) => {
  console.log(`Stream status: ${event.status}`);
});

// 3. Setup audio sample listener
const sampleSub = VoicelineDSP.addAudioSampleListener((event) => {
  console.log(`Received ${event.frameLength} samples`);

  // Process audio samples
  processAudioSamples(event.samples, event.sampleRate);
});

// 4. Start streaming
try {
  await VoicelineDSP.startAudioStream({
    sampleRate: 16000,
    bufferSize: 2048,
    channels: 1,
  });
  console.log('Streaming started');
} catch (error) {
  console.error('Failed to start:', error);
}

// 5. Stop streaming when done
await VoicelineDSP.stopAudioStream();

// 6. Cleanup listeners
sampleSub.remove();
statusSub.remove();
errorSub.remove();
```

### React Hook Example

```typescript
import { useEffect, useState } from 'react';
import { VoicelineDSP } from '@loqa/voiceline-dsp';

function useAudioStreaming(enabled: boolean) {
  const [streaming, setStreaming] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!enabled) return;

    // Setup listeners
    const statusSub = VoicelineDSP.addStreamStatusListener((event) => {
      setStreaming(event.status === 'streaming');
    });

    const errorSub = VoicelineDSP.addStreamErrorListener((event) => {
      setError(event.message);
      setStreaming(false);
    });

    const sampleSub = VoicelineDSP.addAudioSampleListener((event) => {
      // Process samples here
      analyzeAudio(event.samples, event.sampleRate);
    });

    // Start streaming
    VoicelineDSP.startAudioStream({
      sampleRate: 16000,
      bufferSize: 2048,
      channels: 1,
    }).catch((err) => {
      setError(err.message);
    });

    // Cleanup on unmount
    return () => {
      VoicelineDSP.stopAudioStream();
      statusSub.remove();
      errorSub.remove();
      sampleSub.remove();
    };
  }, [enabled]);

  return { streaming, error };
}

// Usage in component
function VoiceRecorder() {
  const { streaming, error } = useAudioStreaming(true);

  return (
    <View>
      {streaming && <Text>Recording...</Text>}
      {error && <Text>Error: {error}</Text>}
    </View>
  );
}
```

### Real-Time Pitch Detection Example

```typescript
import { VoicelineDSP } from '@loqa/voiceline-dsp';

// Setup pitch detection
const sampleSub = VoicelineDSP.addAudioSampleListener((event) => {
  const { samples, sampleRate } = event;

  // Use VoicelineDSP v0.1.0 analysis function
  const pitch = VoicelineDSP.detectPitch(samples, sampleRate);

  if (pitch > 0) {
    console.log(`Detected pitch: ${pitch.toFixed(2)} Hz`);
    updatePitchVisualization(pitch);
  }
});

await VoicelineDSP.startAudioStream({
  sampleRate: 16000,
  bufferSize: 2048, // 128ms window optimal for YIN pitch detection
  channels: 1,
});
```

---

## Error Handling

### Error Codes

| Error Code              | Description                           | Recovery Strategy                         |
| ----------------------- | ------------------------------------- | ----------------------------------------- |
| `PERMISSION_DENIED`     | Microphone permission not granted     | Prompt user to enable in Settings         |
| `SESSION_CONFIG_FAILED` | Audio session setup failed (iOS)      | Retry with fallback config, inform user   |
| `ENGINE_START_FAILED`   | Audio engine/recorder failed to start | Check device availability, retry once     |
| `DEVICE_NOT_AVAILABLE`  | Microphone hardware unavailable       | Inform user, disable audio features       |
| `BUFFER_OVERFLOW`       | Audio frames being dropped            | Increase buffer size, reduce processing   |
| `UNKNOWN_ERROR`         | Unexpected error occurred             | Log for debugging, inform user gracefully |

### Error Handling Best Practices

1. **Always register error listener before starting stream**
2. **Handle PERMISSION_DENIED gracefully** with clear user messaging
3. **Retry transient errors** (SESSION_CONFIG_FAILED, ENGINE_START_FAILED) once with exponential backoff
4. **Degrade gracefully** for DEVICE_NOT_AVAILABLE (hide audio features)
5. **Monitor BUFFER_OVERFLOW** and adjust config if persistent

---

## Platform-Specific Notes

### iOS (AVAudioEngine)

- **Latency:** Typically 40-60ms (mic → native callback)
- **Thread Model:** Callbacks on audio thread (internally managed), events emitted on main thread
- **Interruptions:** Automatic handling of phone calls, other apps (AVAudioSession notifications)
- **Sample Format:** Converted from Int16 PCM to Float32 normalized

### Android (AudioRecord)

- **Latency:** Typically 60-100ms (mic → native callback)
- **Thread Model:** Background coroutine (Dispatchers.IO), events emitted on main thread (Dispatchers.Main)
- **Permissions:** Runtime permission request required (RECORD_AUDIO)
- **Sample Format:** Direct Float32 capture (ENCODING_PCM_FLOAT)

### Cross-Platform Consistency

✅ **Same API surface** on both platforms
✅ **Same event payloads** (AudioSampleEvent, StreamStatusEvent, StreamErrorEvent)
✅ **Same error codes** (PERMISSION_DENIED, DEVICE_NOT_AVAILABLE, etc.)
✅ **Same default config** (16kHz, 2048 samples, mono)
✅ **Same buffer size constraints** (512-8192 samples)

⚠️ **Platform Differences:**

- iOS latency ~20-40ms lower than Android
- Android requires explicit permission request in code
- iOS handles interruptions automatically (phone calls)
- Android uses background thread + main thread dispatch

---

## Performance Considerations

### Latency Budget

**Target: <100ms end-to-end (mic → visual update)**

- Mic → Native: <40ms (iOS), <60ms (Android)
- Native → JS: <10ms (event emission)
- JS Processing: <30ms (analysis + state update)
- Visual Update: <16ms (60fps render)

**Total:** 40+10+30+16 = 96ms (iOS), 116ms (Android, slightly over target)

### Buffer Size Selection

| Sample Rate | Buffer Size  | Latency | Use Case                     |
| ----------- | ------------ | ------- | ---------------------------- |
| 16kHz       | 2048 samples | 128ms   | Voice analysis (recommended) |
| 44.1kHz     | 4096 samples | 93ms    | High-quality capture         |
| 48kHz       | 4096 samples | 85ms    | Professional audio           |

**Recommendation:** 16kHz + 2048 samples for voice analysis (optimal for YIN pitch detection)

### Memory Usage

- **Target:** <10MB during streaming
- **Buffer overhead:** ~16KB per buffer (2048 samples × 4 bytes Float32 × 2 buffers)
- **Event payload:** ~8KB per AudioSampleEvent
- **Total:** Minimal impact with proper cleanup

### Battery Impact

- **Target:** <5% battery drain per 30-minute session
- **Measured:** Native audio capture is highly optimized by OS
- **Tips:** Use VAD to pause processing during silence, reduce sample rate if high quality not needed

---

## Migration from v0.1.0

VoicelineDSP v0.2.0 is **fully backward compatible** with v0.1.0 analysis functions.

### What's New in v0.2.0

✅ **New:** Real-time audio streaming API (`startAudioStream`, `stopAudioStream`, `isStreaming`)
✅ **New:** Event listeners for samples, status, errors
✅ **New:** StreamConfig, AudioSampleEvent, StreamStatusEvent, StreamErrorEvent types

### What's Unchanged

✅ **Preserved:** All v0.1.0 analysis functions (`detectPitch`, `analyzeFormants`, `computeSpectrum`, etc.)
✅ **Preserved:** VoiceProfile API, TrainingSession API
✅ **Preserved:** Existing TypeScript types and interfaces

### Migration Example

```typescript
// v0.1.0: Manual audio capture with expo-av or third-party library
const recording = await Audio.Recording.createAsync(...);
const audioData = await getAudioSamples(recording);
const pitch = VoicelineDSP.detectPitch(audioData, 16000);

// v0.2.0: Built-in streaming + analysis
VoicelineDSP.addAudioSampleListener((event) => {
  const pitch = VoicelineDSP.detectPitch(event.samples, event.sampleRate);
  updateVisualization(pitch);
});
await VoicelineDSP.startAudioStream({ sampleRate: 16000, bufferSize: 2048 });
```

---

## Next Steps

This API specification serves as the blueprint for:

- **Story 2D.2:** iOS Native Streaming Implementation
- **Story 2D.3:** Android Native Streaming Implementation
- **Story 2D.7:** TypeScript API Wrapper Implementation

Subsequent stories will implement this API design with native platform code (iOS AVAudioEngine, Android AudioRecord) and Expo module bindings.

---

## References

- [Epic 2D Technical Specification](../epics/epic-2d-tech-spec.md)
- [Audio Streaming Architecture Decision](./audio-streaming-architecture-decision.md)
- [Expo Modules API Documentation](https://docs.expo.dev/modules/overview/)
- [iOS AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Android AudioRecord Documentation](https://developer.android.com/reference/android/media/AudioRecord)
