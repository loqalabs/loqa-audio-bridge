# LoqaAudioBridge API Reference

**Package:** `@loqalabs/loqa-audio-bridge`
**Version:** 0.3.0
**Module:** LoqaAudioBridgeModule
**Last Updated:** 2025-11-18

## Overview

LoqaAudioBridge is an Expo native module that provides real-time audio streaming from device microphones. It enables capturing live audio samples from iOS and Android devices and delivers them to JavaScript via event-driven architecture, perfect for voice-responsive visualizations, voice training applications, and real-time audio analysis.

### Key Features

- **Real-time audio streaming** from device microphone
- **Event-driven architecture** using Expo EventEmitter pattern
- **Cross-platform consistency** (identical API on iOS and Android)
- **Type-safe TypeScript interfaces** for all events and configurations
- **Privacy-first design** (in-memory processing, no disk writes)
- **Battery optimization** with VAD and adaptive processing
- **React Hook integration** for declarative component patterns

### Design Principles

1. **Ergonomic API**: Intuitive, minimal boilerplate, clear error messages
2. **Type Safety**: Full TypeScript coverage with JSDoc documentation
3. **Performance**: Low-latency streaming (<100ms end-to-end on iOS, <120ms on Android)
4. **Privacy**: In-memory only, audio samples discarded after processing
5. **Cross-platform**: Same API behavior on iOS and Android (within platform constraints)

---

## TypeScript Interfaces

### StreamConfig

Configuration options for audio streaming sessions.

```typescript
/**
 * Audio stream configuration
 *
 * Specifies parameters for audio capture including sample rate, buffer size,
 * and power optimization features.
 */
export interface StreamConfig {
  /**
   * Sample rate in Hz
   *
   * Supported values: 8000, 16000, 32000, 44100, 48000
   * - 16000 Hz: Recommended for voice analysis (optimal for pitch detection)
   * - 44100 Hz: CD-quality audio
   * - 48000 Hz: Professional audio standard
   *
   * @default 16000
   */
  sampleRate?: number;

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
   * iOS constraint: Must be power of 2 (512, 1024, 2048, 4096, 8192)
   * Android: Any value in range is supported
   *
   * Latency calculation: (bufferSize / sampleRate) * 1000 ms
   * - 2048 samples @ 16kHz = 128ms (~8 events/second)
   * - 4096 samples @ 44.1kHz = 93ms
   * - 4096 samples @ 48kHz = 85ms
   *
   * @default 2048
   */
  bufferSize?: number;

  /**
   * Number of audio channels
   *
   * Currently only mono (1 channel) is fully supported.
   * Stereo input (2 channels) will be automatically converted to mono by averaging channels.
   *
   * @default 1
   */
  channels?: number;

  /**
   * Enable Voice Activity Detection (VAD) to skip silent frames
   *
   * When enabled, audio samples with RMS < 0.01 are not emitted as events,
   * reducing battery consumption during silence periods.
   *
   * Typical power savings: 10-15% during silent periods
   *
   * @default true
   */
  vadEnabled?: boolean;

  /**
   * Enable adaptive processing to reduce frame rate during low battery
   *
   * When enabled and battery < 20%, skips every 2nd audio frame to reduce power consumption.
   * Reduces event rate from ~8Hz to ~4Hz for 20-30% power savings.
   *
   * @default true
   */
  adaptiveProcessing?: boolean;
}
```

### AudioSampleEvent

Event payload containing audio samples from the microphone.

```typescript
/**
 * Audio sample event payload
 *
 * Emitted continuously during audio streaming with captured audio data.
 * Event rate: ~8 Hz at default config (2048 samples at 16kHz = 128ms per buffer)
 */
export interface AudioSampleEvent {
  /**
   * Raw audio samples as floating-point values
   *
   * Format: Float32, normalized to [-1.0, 1.0] range
   * Length: equals bufferSize from StreamConfig
   *
   * Platform notes:
   * - iOS: Converted from AVAudioPCMBuffer Float32 format (downsampled from hardware rate)
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
   * Platform-specific timestamp
   *
   * - iOS: Milliseconds since stream start
   * - Android: System.currentTimeMillis() (milliseconds since epoch)
   *
   * Useful for:
   * - Synchronizing audio with visual updates
   * - Measuring end-to-end latency
   * - Detecting buffer overflows (gaps in timestamp sequence)
   */
  timestamp: number;

  /**
   * Pre-computed RMS (Root Mean Square) amplitude
   *
   * Range: [0.0, 1.0]
   * Represents average loudness of the audio frame.
   *
   * Useful for:
   * - Real-time volume visualization
   * - Voice Activity Detection (VAD threshold: 0.01)
   * - Audio level metering
   */
  rms: number;
}
```

### StreamStatusEvent

Event indicating streaming state changes.

```typescript
/**
 * Stream status change event payload
 *
 * Emitted when the audio stream status changes (started, stopped, paused).
 */
export interface StreamStatusEvent {
  /**
   * Current streaming status
   *
   * - 'streaming': Audio capture is active, samples are being delivered
   * - 'stopped': Audio capture has stopped (user requested or cleanup)
   * - 'paused': Audio capture paused due to interruption (iOS only, e.g., phone call)
   * - 'battery_optimized': Adaptive processing active (battery < 20%, frame rate reduced)
   */
  status: 'streaming' | 'stopped' | 'paused' | 'battery_optimized';

  /**
   * Timestamp when status changed (milliseconds since epoch)
   * Platform-independent Unix timestamp
   */
  timestamp: number;

  /**
   * Optional platform identifier for debugging
   * Indicates which platform emitted the event
   */
  platform?: 'ios' | 'android';
}
```

### StreamErrorEvent

Event containing error information when streaming fails.

```typescript
/**
 * Stream error event payload
 *
 * Emitted when an error occurs during streaming setup or operation.
 * Contains error code, human-readable message, and recovery guidance.
 */
export interface StreamErrorEvent {
  /**
   * Standardized error code
   *
   * Error codes:
   * - PERMISSION_DENIED: Microphone permission not granted (Android only)
   * - SESSION_CONFIG_FAILED: Audio session configuration failed (iOS only)
   * - ENGINE_START_FAILED: Failed to start audio engine/recording
   * - DEVICE_NOT_AVAILABLE: Microphone hardware unavailable
   * - BUFFER_OVERFLOW: Audio processing overloaded (rare)
   */
  error: StreamErrorCode | 'PERMISSION_DENIED' | 'SESSION_CONFIG_FAILED' | 'ENGINE_START_FAILED' | 'DEVICE_NOT_AVAILABLE' | 'BUFFER_OVERFLOW';

  /**
   * User-friendly error message with actionable guidance
   *
   * Provides context about what went wrong and potential recovery steps.
   * Suitable for logging but may need user-friendly translation for UI display.
   */
  message: string;

  /**
   * Platform where error occurred
   * Useful for platform-specific error handling or debugging
   */
  platform?: 'ios' | 'android';

  /**
   * Timestamp when error occurred (milliseconds since epoch)
   * Platform-independent Unix timestamp
   */
  timestamp: number;
}
```

### StreamErrorCode

Enumeration of standardized error codes.

```typescript
/**
 * Stream error codes enumeration
 *
 * Standardized error codes emitted during audio streaming operations.
 */
export enum StreamErrorCode {
  /** Microphone permission not granted (Android only) */
  PERMISSION_DENIED = 'PERMISSION_DENIED',

  /** Audio session configuration failed (iOS only) */
  SESSION_CONFIG_FAILED = 'SESSION_CONFIG_FAILED',

  /** Failed to start audio engine/recording */
  ENGINE_START_FAILED = 'ENGINE_START_FAILED',

  /** Microphone hardware unavailable */
  DEVICE_NOT_AVAILABLE = 'DEVICE_NOT_AVAILABLE',

  /** Audio processing overloaded (rare) */
  BUFFER_OVERFLOW = 'BUFFER_OVERFLOW',
}
```

---

## Configuration Reference

All configuration parameters for `StreamConfig`:

| Parameter | Type | Default | Description | Valid Values | Platform Notes |
|-----------|------|---------|-------------|--------------|----------------|
| `sampleRate` | `number` | `16000` | Audio sample rate in Hz | `8000`, `16000`, `32000`, `44100`, `48000` | iOS: Hardware rate detected, downsampled to requested rate |
| `bufferSize` | `number` | `2048` | Buffer size in samples | `512` - `8192` | **iOS: Must be power of 2** (512, 1024, 2048, 4096, 8192)<br>Android: Any value in range |
| `channels` | `number` | `1` | Mono (1) or Stereo (2) | `1`, `2` | Stereo automatically converted to mono |
| `vadEnabled` | `boolean` | `true` | Voice Activity Detection | `true`, `false` | Skips frames with RMS < 0.01 |
| `adaptiveProcessing` | `boolean` | `true` | Battery-aware frame skipping | `true`, `false` | Reduces frame rate to ~4Hz when battery < 20% |

---

## Module Methods

### startAudioStream()

Starts audio streaming from the device microphone.

```typescript
/**
 * Start audio streaming session
 *
 * Initializes the native audio engine and begins capturing audio samples.
 * Audio samples are delivered via AudioSampleEvent at ~8 Hz rate (default config).
 *
 * Configuration is validated before passing to native code. Invalid buffer
 * sizes or sample rates will be rejected with an error.
 *
 * @param config - Stream configuration options (all fields optional, defaults used)
 * @returns Promise<boolean> - true if started successfully, false otherwise
 * @throws Error if buffer size validation fails (out of range 512-8192)
 *
 * @example Basic Usage
 * ```typescript
 * import { startAudioStream } from '@loqalabs/loqa-audio-bridge';
 *
 * const success = await startAudioStream({
 *   sampleRate: 16000,
 *   bufferSize: 2048,
 *   channels: 1,
 * });
 *
 * if (success) {
 *   console.log('Streaming started');
 * }
 * ```
 *
 * @example Using Defaults
 * ```typescript
 * // All parameters optional - uses sensible defaults
 * await startAudioStream({});
 * // Equivalent to: { sampleRate: 16000, bufferSize: 2048, channels: 1, vadEnabled: true, adaptiveProcessing: true }
 * ```
 *
 * @platform ios Uses AVAudioEngine with input node tap, audio format conversion for 16kHz
 * @platform android Uses AudioRecord with ENCODING_PCM_FLOAT
 */
export async function startAudioStream(config: StreamConfig): Promise<boolean>;
```

**Behavior:**

1. Validates configuration (buffer size 512-8192, sample rate > 0)
2. Requests microphone permission (if not already granted, Android only)
3. Configures audio session (iOS: AVAudioSession, Android: AudioRecord)
4. Starts audio engine/recorder
5. Emits `StreamStatusEvent` with status='streaming'
6. Begins emitting `AudioSampleEvent` at configured intervals

**Error Cases:**

- Permission denied → emits `PERMISSION_DENIED` error (Android)
- Audio session setup fails → emits `SESSION_CONFIG_FAILED` error (iOS)
- Audio engine fails to start → emits `ENGINE_START_FAILED` error
- Device microphone unavailable → emits `DEVICE_NOT_AVAILABLE` error
- Invalid buffer size → throws Error immediately

**Platform Differences:**

- **iOS**: Hardware audio format (typically 48kHz) is automatically downsampled to requested rate (e.g., 16kHz) using AVAudioConverter
- **Android**: Permission must be granted before calling (use `expo-av` or `expo-permissions`)

### stopAudioStream()

Stops audio streaming and releases resources.

```typescript
/**
 * Stop audio streaming session
 *
 * Stops audio capture, removes event listeners (native side),
 * and releases audio engine/recorder resources.
 *
 * @returns boolean - true if stopped successfully
 *
 * @example
 * ```typescript
 * import { stopAudioStream } from '@loqalabs/loqa-audio-bridge';
 *
 * stopAudioStream();
 * console.log('Streaming stopped');
 * ```
 *
 * @platform ios Removes tap, stops AVAudioEngine, deactivates session
 * @platform android Cancels coroutine, stops and releases AudioRecord
 */
export function stopAudioStream(): boolean;
```

**Behavior:**

1. Stops audio engine/recorder
2. Removes native tap/listener (iOS: removeTap, Android: coroutine cancellation)
3. Releases audio session resources
4. Emits `StreamStatusEvent` with status='stopped'
5. Stops emitting `AudioSampleEvent`

**Safe to call multiple times:** Subsequent calls are no-ops if already stopped.

### isStreaming()

Checks if audio streaming is currently active.

```typescript
/**
 * Check if audio streaming is active
 *
 * @returns boolean - true if audio stream is active, false otherwise
 *
 * @example
 * ```typescript
 * import { isStreaming } from '@loqalabs/loqa-audio-bridge';
 *
 * if (isStreaming()) {
 *   console.log('Currently streaming audio');
 * }
 * ```
 */
export function isStreaming(): boolean;
```

**Usage Notes:**

- Returns `true` between successful `startAudioStream()` and `stopAudioStream()` calls
- Returns `false` if stream was stopped due to error or interruption
- Returns `false` before first `startAudioStream()` call

---

## Event Listeners

All event listeners return an `EventSubscription` object that can be used to remove the listener.

```typescript
/**
 * Event subscription object (from expo-modules-core)
 */
export interface EventSubscription {
  /**
   * Remove this event listener
   */
  remove(): void;
}
```

### addAudioSampleListener()

Registers a listener for audio sample events.

```typescript
/**
 * Add listener for audio sample events
 *
 * The listener is called continuously while streaming (~8 Hz rate at default config)
 * with captured audio samples in Float32 format, normalized to [-1.0, 1.0] range.
 *
 * **Important:** Always remove the subscription when done to prevent memory leaks.
 *
 * @param listener - Callback function that receives audio sample events
 * @returns EventSubscription - call `.remove()` to unsubscribe
 *
 * @example Basic Usage
 * ```typescript
 * import { addAudioSampleListener } from '@loqalabs/loqa-audio-bridge';
 *
 * const subscription = addAudioSampleListener((event) => {
 *   console.log(`Received ${event.samples.length} samples at ${event.sampleRate} Hz`);
 *   console.log(`RMS level: ${event.rms.toFixed(4)}`);
 *
 *   // Process audio samples
 *   processAudio(new Float32Array(event.samples));
 * });
 *
 * // Later: cleanup
 * subscription.remove();
 * ```
 *
 * @example React Hook Pattern
 * ```typescript
 * useEffect(() => {
 *   if (!isRecording) return;
 *
 *   const subscription = addAudioSampleListener((event) => {
 *     processAudioSamples(new Float32Array(event.samples));
 *   });
 *
 *   return () => subscription.remove(); // Cleanup on unmount
 * }, [isRecording]);
 * ```
 */
export function addAudioSampleListener(
  listener: (event: AudioSampleEvent) => void
): EventSubscription;
```

**Event Frequency:**

- Emitted every `bufferSize / sampleRate` seconds
- Example: 2048 samples @ 16kHz = every 128ms (~7.8 events/second)

**Performance Note:**

Listener should process samples quickly to avoid blocking native thread.
Consider offloading heavy processing to Web Worker or async queue.

### addStreamStatusListener()

Registers a listener for stream status change events.

```typescript
/**
 * Add listener for stream status change events
 *
 * The listener is called when the audio stream status changes:
 * - "streaming": Stream started successfully
 * - "stopped": Stream stopped (user-initiated or error)
 * - "paused": Stream paused due to interruption (iOS only, e.g., phone call)
 * - "battery_optimized": Adaptive processing active (battery < 20%)
 *
 * **Important:** Always remove the subscription when done to prevent memory leaks.
 *
 * @param listener - Callback function that receives status change events
 * @returns EventSubscription - call `.remove()` to unsubscribe
 *
 * @example
 * ```typescript
 * import { addStreamStatusListener } from '@loqalabs/loqa-audio-bridge';
 *
 * const subscription = addStreamStatusListener((event) => {
 *   console.log('Stream status:', event.status, 'on', event.platform);
 *
 *   if (event.status === 'streaming') {
 *     showRecordingIndicator();
 *   } else if (event.status === 'stopped') {
 *     hideRecordingIndicator();
 *   } else if (event.status === 'battery_optimized') {
 *     console.log('Adaptive processing enabled - frame rate reduced to save battery');
 *   }
 * });
 *
 * // Later: cleanup
 * subscription.remove();
 * ```
 */
export function addStreamStatusListener(
  listener: (event: StreamStatusEvent) => void
): EventSubscription;
```

**Status Transitions:**

- `startAudioStream()` → status='streaming'
- `stopAudioStream()` → status='stopped'
- Error during streaming → status='stopped' (see `StreamErrorEvent` for details)
- iOS interruption (phone call) → status='paused' → status='streaming' (auto-resume)
- Battery < 20% + adaptive processing enabled → status='battery_optimized'

### addStreamErrorListener()

Registers a listener for stream error events.

```typescript
/**
 * Add listener for stream error events
 *
 * The listener is called when an error occurs during audio streaming.
 * Common errors:
 * - PERMISSION_DENIED: Microphone permission not granted (Android)
 * - SESSION_CONFIG_FAILED: Audio session configuration failed (iOS)
 * - ENGINE_START_FAILED: Failed to start audio engine
 * - DEVICE_NOT_AVAILABLE: Microphone hardware unavailable
 * - BUFFER_OVERFLOW: Audio processing overloaded
 *
 * **Important:** Always remove the subscription when done to prevent memory leaks.
 *
 * @param listener - Callback function that receives error events
 * @returns EventSubscription - call `.remove()` to unsubscribe
 *
 * @example
 * ```typescript
 * import { addStreamErrorListener, StreamErrorCode } from '@loqalabs/loqa-audio-bridge';
 * import { Alert } from 'react-native';
 *
 * const subscription = addStreamErrorListener((event) => {
 *   console.error(`Stream error [${event.error}]:`, event.message, 'on', event.platform);
 *
 *   // Handle specific errors
 *   if (event.error === StreamErrorCode.PERMISSION_DENIED) {
 *     Alert.alert(
 *       'Microphone Permission Required',
 *       'Please enable microphone access in Settings to use voice features.',
 *       [{ text: 'OK' }]
 *     );
 *   } else if (event.error === StreamErrorCode.DEVICE_NOT_AVAILABLE) {
 *     Alert.alert('Microphone Unavailable', 'Microphone is not available on this device');
 *   } else if (event.error === StreamErrorCode.BUFFER_OVERFLOW) {
 *     console.warn('Audio frames dropping - consider increasing buffer size');
 *   }
 * });
 *
 * // Later: cleanup
 * subscription.remove();
 * ```
 */
export function addStreamErrorListener(
  listener: (event: StreamErrorEvent) => void
): EventSubscription;
```

**Error Handling Strategy:**

1. Listen for errors before calling `startAudioStream()`
2. Handle permission errors by prompting user to grant permission
3. Handle device errors by disabling audio features gracefully
4. Handle transient errors (BUFFER_OVERFLOW) with automatic retry or config adjustment

---

## React Hook

### useAudioStreaming()

React hook for managing audio streaming lifecycle.

Provides a declarative API for starting/stopping audio streaming and subscribing to audio events. Automatically handles cleanup on unmount.

```typescript
/**
 * Options for useAudioStreaming hook
 */
export interface UseAudioStreamingOptions {
  /** Stream configuration */
  config: StreamConfig;

  /** Callback when audio samples are received */
  onSamples: (event: AudioSampleEvent) => void;

  /** Optional callback when stream status changes */
  onStatusChange?: (event: StreamStatusEvent) => void;

  /** Optional callback when stream error occurs */
  onError?: (event: StreamErrorEvent) => void;

  /** Auto-start streaming when component mounts (default: false) */
  autoStart?: boolean;
}

/**
 * Return type for useAudioStreaming hook
 */
export interface UseAudioStreamingResult {
  /** Whether audio streaming is currently active */
  isStreaming: boolean;

  /** Last error that occurred, if any */
  error: string | null;

  /** Start audio streaming */
  start: () => Promise<void>;

  /** Stop audio streaming */
  stop: () => void;

  /** Clear the current error */
  clearError: () => void;
}

/**
 * React hook for managing audio streaming lifecycle
 *
 * @param options - Hook configuration options
 * @returns Audio streaming controls and state
 */
export function useAudioStreaming(options: UseAudioStreamingOptions): UseAudioStreamingResult;
```

**Lifecycle Behavior:**

- Automatically subscribes to events when streaming starts
- Automatically unsubscribes when streaming stops or component unmounts
- Stops streaming automatically on component unmount if still active
- Updates callbacks without re-subscribing (uses refs internally)

**Example - Basic Usage:**

```typescript
import { useAudioStreaming } from '@loqalabs/loqa-audio-bridge';
import { View, Button, Text } from 'react-native';
import { useCallback } from 'react';

function AudioRecorder() {
  const handleSamples = useCallback((event: AudioSampleEvent) => {
    console.log('Received samples:', event.samples.length);
    // Process audio samples
  }, []);

  const { isStreaming, error, start, stop } = useAudioStreaming({
    config: { sampleRate: 16000, bufferSize: 2048, channels: 1 },
    onSamples: handleSamples,
  });

  return (
    <View>
      <Button onPress={isStreaming ? stop : start}>
        {isStreaming ? 'Stop' : 'Start'} Recording
      </Button>
      {error && <Text style={{ color: 'red' }}>{error}</Text>}
    </View>
  );
}
```

**Example - With Error Handling:**

```typescript
import { useAudioStreaming, StreamErrorCode } from '@loqalabs/loqa-audio-bridge';
import { Alert } from 'react-native';

function StreamingExample() {
  const handleError = useCallback((event: StreamErrorEvent) => {
    if (event.error === StreamErrorCode.PERMISSION_DENIED) {
      Alert.alert('Microphone Permission Required', event.message);
    }
  }, []);

  const { isStreaming, error, start, clearError } = useAudioStreaming({
    config: { sampleRate: 16000, bufferSize: 2048, channels: 1 },
    onSamples: (event) => console.log('Samples:', event.samples.length),
    onError: handleError,
  });

  return (
    <View>
      <Button onPress={start} disabled={isStreaming}>Start</Button>
      {error && (
        <View>
          <Text style={{ color: 'red' }}>{error}</Text>
          <Button onPress={clearError}>Dismiss</Button>
        </View>
      )}
    </View>
  );
}
```

---

## Code Examples

### Basic Streaming Lifecycle

```typescript
import {
  startAudioStream,
  stopAudioStream,
  addAudioSampleListener,
  addStreamStatusListener,
  addStreamErrorListener,
  StreamErrorCode,
} from '@loqalabs/loqa-audio-bridge';
import { Alert } from 'react-native';

// 1. Setup error handling first
const errorSub = addStreamErrorListener((event) => {
  console.error(`Stream error: [${event.error}] ${event.message}`);

  if (event.error === StreamErrorCode.PERMISSION_DENIED) {
    Alert.alert('Microphone Permission Required', event.message);
  }
});

// 2. Setup status listener
const statusSub = addStreamStatusListener((event) => {
  console.log(`Stream status: ${event.status}`);
});

// 3. Setup audio sample listener
const sampleSub = addAudioSampleListener((event) => {
  console.log(`Received ${event.frameLength} samples, RMS: ${event.rms.toFixed(4)}`);

  // Process audio samples
  processAudioSamples(event.samples, event.sampleRate);
});

// 4. Start streaming
try {
  const started = await startAudioStream({
    sampleRate: 16000,
    bufferSize: 2048,
    channels: 1,
    vadEnabled: true,
  });

  if (started) {
    console.log('Streaming started successfully');
  }
} catch (error) {
  console.error('Failed to start:', error);
}

// 5. Stop streaming when done
stopAudioStream();

// 6. Cleanup listeners
sampleSub.remove();
statusSub.remove();
errorSub.remove();
```

### VAD Configuration Example

```typescript
import { startAudioStream, addAudioSampleListener } from '@loqalabs/loqa-audio-bridge';

// Setup listener
const subscription = addAudioSampleListener((event) => {
  // With VAD enabled, this callback is only called when RMS >= 0.01
  console.log(`Voice detected! RMS: ${event.rms.toFixed(4)}`);
  processVoiceActivity(event.samples);
});

// Start with VAD enabled (default)
await startAudioStream({
  sampleRate: 16000,
  bufferSize: 2048,
  vadEnabled: true,  // Skip silent frames (RMS < 0.01)
});

// Later: cleanup
subscription.remove();
stopAudioStream();
```

### Error Handling Example

```typescript
import {
  startAudioStream,
  addStreamErrorListener,
  StreamErrorCode,
} from '@loqalabs/loqa-audio-bridge';
import { Alert, Linking } from 'react-native';

const errorSub = addStreamErrorListener((event) => {
  console.error(`[${event.platform}] ${event.error}: ${event.message}`);

  switch (event.error) {
    case StreamErrorCode.PERMISSION_DENIED:
      Alert.alert(
        'Microphone Permission Required',
        'Please enable microphone access in Settings.',
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'Open Settings', onPress: () => Linking.openSettings() },
        ]
      );
      break;

    case StreamErrorCode.DEVICE_NOT_AVAILABLE:
      Alert.alert('Microphone Unavailable', 'Microphone is not available on this device.');
      break;

    case StreamErrorCode.BUFFER_OVERFLOW:
      console.warn('Audio processing overloaded - consider increasing buffer size or reducing processing');
      break;

    case StreamErrorCode.ENGINE_START_FAILED:
      Alert.alert('Streaming Failed', 'Could not start audio streaming. Please try again.');
      break;
  }
});

// Start streaming
await startAudioStream({ sampleRate: 16000, bufferSize: 2048 });

// Cleanup
errorSub.remove();
```

### Battery-Aware Configuration Example

```typescript
import { startAudioStream, addStreamStatusListener } from '@loqalabs/loqa-audio-bridge';

// Monitor status changes
const statusSub = addStreamStatusListener((event) => {
  if (event.status === 'battery_optimized') {
    console.log('Battery < 20% - frame rate reduced to ~4Hz for power savings');
  } else if (event.status === 'streaming') {
    console.log('Normal streaming - frame rate ~8Hz');
  }
});

// Start with adaptive processing enabled (default)
await startAudioStream({
  sampleRate: 16000,
  bufferSize: 2048,
  adaptiveProcessing: true,  // Auto-reduce frame rate when battery < 20%
  vadEnabled: true,           // Skip silent frames for additional battery savings
});

// Cleanup
statusSub.remove();
```

### React Component Integration Example

```typescript
import React, { useState, useCallback } from 'react';
import { View, Button, Text, StyleSheet } from 'react-native';
import { useAudioStreaming } from '@loqalabs/loqa-audio-bridge';
import type { AudioSampleEvent } from '@loqalabs/loqa-audio-bridge';

function VoicePracticeScreen() {
  const [rmsLevel, setRmsLevel] = useState(0);

  const handleSamples = useCallback((event: AudioSampleEvent) => {
    setRmsLevel(event.rms);
    // Process samples for voice analysis
    analyzeVoiceQuality(event.samples, event.sampleRate);
  }, []);

  const { isStreaming, error, start, stop } = useAudioStreaming({
    config: {
      sampleRate: 16000,
      bufferSize: 2048,
      channels: 1,
      vadEnabled: true,
      adaptiveProcessing: true,
    },
    onSamples: handleSamples,
  });

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Voice Practice Session</Text>

      {/* Status Display */}
      <View style={styles.statusContainer}>
        <Text>Status: {isStreaming ? '● Recording' : '○ Stopped'}</Text>
        <Text>Volume: {(rmsLevel * 100).toFixed(0)}%</Text>
      </View>

      {/* Volume Visualization */}
      <View style={styles.barContainer}>
        <View style={[styles.bar, { width: `${rmsLevel * 100}%` }]} />
      </View>

      {/* Controls */}
      <Button
        title={isStreaming ? 'Stop' : 'Start'}
        onPress={isStreaming ? stop : start}
        color={isStreaming ? '#F44336' : '#4CAF50'}
      />

      {/* Error Display */}
      {error && <Text style={styles.error}>{error}</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, justifyContent: 'center' },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 20, textAlign: 'center' },
  statusContainer: { marginVertical: 20 },
  barContainer: { height: 30, backgroundColor: '#e0e0e0', borderRadius: 15, overflow: 'hidden', marginVertical: 20 },
  bar: { height: '100%', backgroundColor: '#4CAF50' },
  error: { color: '#F44336', marginTop: 10, textAlign: 'center' },
});

export default VoicePracticeScreen;
```

---

## Error Handling

### Error Codes

| Error Code | Description | Recovery Strategy | Platform |
|------------|-------------|-------------------|----------|
| `PERMISSION_DENIED` | Microphone permission not granted | Prompt user to enable in Settings | Android |
| `SESSION_CONFIG_FAILED` | Audio session setup failed | Retry with fallback config, inform user | iOS |
| `ENGINE_START_FAILED` | Audio engine/recorder failed to start | Check device availability, retry once | Both |
| `DEVICE_NOT_AVAILABLE` | Microphone hardware unavailable | Inform user, disable audio features | Both |
| `BUFFER_OVERFLOW` | Audio frames being dropped | Increase buffer size, reduce processing load | Both |

### Error Handling Best Practices

1. **Always register error listener before starting stream**
   ```typescript
   const errorSub = addStreamErrorListener((event) => {
     console.error('Stream error:', event.error);
   });
   await startAudioStream({ ... });
   ```

2. **Handle PERMISSION_DENIED gracefully** with clear user messaging
   ```typescript
   if (event.error === StreamErrorCode.PERMISSION_DENIED) {
     Alert.alert('Microphone Access Required', event.message);
   }
   ```

3. **Retry transient errors** (ENGINE_START_FAILED) once with exponential backoff
   ```typescript
   let retryCount = 0;
   const maxRetries = 1;

   const errorSub = addStreamErrorListener(async (event) => {
     if (event.error === StreamErrorCode.ENGINE_START_FAILED && retryCount < maxRetries) {
       retryCount++;
       console.log(`Retrying... (${retryCount}/${maxRetries})`);
       await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1s
       await startAudioStream(config);
     }
   });
   ```

4. **Degrade gracefully** for DEVICE_NOT_AVAILABLE (hide audio features)
   ```typescript
   if (event.error === StreamErrorCode.DEVICE_NOT_AVAILABLE) {
     setAudioFeaturesAvailable(false);
   }
   ```

5. **Monitor BUFFER_OVERFLOW** and adjust config if persistent
   ```typescript
   if (event.error === StreamErrorCode.BUFFER_OVERFLOW) {
     console.warn('Increasing buffer size to reduce overflow');
     await startAudioStream({ bufferSize: 4096 }); // Double buffer size
   }
   ```

---

## Platform-Specific Notes

### iOS (AVAudioEngine)

- **Audio Format Handling:** iOS captures audio at hardware sample rate (typically 48kHz). When a lower rate is requested (e.g., 16kHz), the module uses AVAudioConverter to downsample in real-time.
- **Latency:** Typically 40-60ms (mic → native callback)
- **Thread Model:** Callbacks on audio thread (internally managed), events emitted on main thread
- **Interruptions:** Automatic handling of phone calls, other apps (AVAudioSession notifications, status='paused')
- **Sample Format:** Converted from Float32 PCM (hardware) to Float32 normalized [-1.0, 1.0]
- **Buffer Size Constraint:** **Must be power of 2** (512, 1024, 2048, 4096, 8192)

### Android (AudioRecord)

- **Latency:** Typically 60-100ms (mic → native callback)
- **Thread Model:** Background coroutine (Dispatchers.IO), events emitted on main thread (Dispatchers.Main)
- **Permissions:** Runtime permission request required (RECORD_AUDIO) - use `expo-av` or `expo-permissions` before calling `startAudioStream()`
- **Sample Format:** Direct Float32 capture (ENCODING_PCM_FLOAT)
- **Buffer Size:** Any value 512-8192 supported (no power-of-2 constraint)

### Cross-Platform Consistency

✅ **Same API surface** on both platforms
✅ **Same event payloads** (AudioSampleEvent, StreamStatusEvent, StreamErrorEvent)
✅ **Same error codes** (PERMISSION_DENIED, DEVICE_NOT_AVAILABLE, etc.)
✅ **Same default config** (16kHz, 2048 samples, mono)
✅ **Same buffer size range** (512-8192 samples)

⚠️ **Platform Differences:**

- **iOS latency ~20-40ms lower** than Android
- **Android requires explicit permission** request before calling API
- **iOS handles interruptions automatically** (phone calls → status='paused')
- **Android uses background coroutine** + main thread dispatch
- **iOS buffer size must be power of 2**, Android supports any value in range
- **iOS performs hardware-rate downsampling** when lower sample rate requested

---

## Performance Considerations

### Latency Budget

**Target: <100ms end-to-end (mic → visual update)**

- Mic → Native: <40ms (iOS), <60ms (Android)
- Native → JS: <10ms (event emission)
- JS Processing: <30ms (analysis + state update)
- Visual Update: <16ms (60fps render)

**Total:** 40+10+30+16 = 96ms (iOS), 116ms (Android, slightly over target but acceptable)

### Buffer Size Selection

| Sample Rate | Buffer Size | Latency | Event Rate | Use Case |
|-------------|-------------|---------|------------|----------|
| 16kHz | 2048 samples | 128ms | ~8 Hz | Voice analysis (recommended) |
| 16kHz | 4096 samples | 256ms | ~4 Hz | Lower event rate, better frequency resolution |
| 44.1kHz | 4096 samples | 93ms | ~11 Hz | High-quality capture |
| 48kHz | 4096 samples | 85ms | ~12 Hz | Professional audio |

**Recommendation:** 16kHz + 2048 samples for voice analysis (optimal balance of latency and frequency resolution)

### Memory Usage

- **Target:** <10MB during streaming
- **Buffer overhead:** ~16KB per buffer (2048 samples × 4 bytes Float32 × 2 buffers)
- **Event payload:** ~8KB per AudioSampleEvent
- **Total:** Minimal impact with proper cleanup

### Battery Impact

- **Target:** <5% battery drain per 30-minute session
- **Measured:** Native audio capture is highly optimized by OS
- **Power Optimization Tips:**
  - Use VAD to skip silent frames (`vadEnabled: true`) → 10-15% savings during silence
  - Enable adaptive processing (`adaptiveProcessing: true`) → 20-30% savings when battery < 20%
  - Use lower sample rate if high quality not needed (16kHz vs 48kHz) → ~30% savings
  - Reduce buffer size if low latency not critical (4096 vs 2048) → ~15% savings

---

## Additional Resources

- [README.md](./README.md) - Quick start guide and installation
- [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md) - Step-by-step integration instructions
- [Example App](./example/App.tsx) - Complete working example
- [Expo Modules Documentation](https://docs.expo.dev/modules/overview/)
- [iOS AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Android AudioRecord Documentation](https://developer.android.com/reference/android/media/AudioRecord)
