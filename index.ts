/**
 * LoqaAudioBridge - Expo Native Module for Real-Time Audio Streaming
 *
 * This module provides:
 * - Real-time audio capture from device microphone
 * - Event-based audio sample streaming to JavaScript
 * - Cross-platform audio streaming (iOS/Android)
 *
 * @module loqa-audio-bridge
 * @version 0.3.0
 */

import { EventEmitter, type EventSubscription } from 'expo-modules-core';
import LoqaAudioBridgeModule from './src/LoqaAudioBridgeModule';
import type {
  AudioSampleEvent,
  StreamStatusEvent,
  StreamErrorEvent,
  StreamConfig,
} from './src/types';
import { StreamErrorCode } from './src/types';

// Export types for consumers
export type {
  AudioSampleEvent,
  StreamStatusEvent,
  StreamErrorEvent,
  StreamConfig,
};
export { StreamErrorCode };

// Export buffer management utilities
export {
  calculateBufferSize,
  validateBufferSize,
  findClosestSupportedRate,
  isRateSupported,
  calculateBufferDuration,
  calculateEventRate,
  roundToPowerOf2,
  isPowerOf2,
  IOS_SUPPORTED_RATES,
  BUFFER_SIZE_MIN,
  BUFFER_SIZE_MAX,
} from './src/buffer-utils';
export type { Platform, BufferValidationResult } from './src/buffer-utils';

// Export React hooks
export { useAudioStreaming } from './hooks/useAudioStreaming';
export type { UseAudioStreamingOptions, UseAudioStreamingResult } from './hooks/useAudioStreaming';

/**
 * Event map for type-safe event listening
 * @internal
 */
type LoqaAudioBridgeEvents = {
  onAudioSamples: (event: AudioSampleEvent) => void;
  onStreamStatusChange: (event: StreamStatusEvent) => void;
  onStreamError: (event: StreamErrorEvent) => void;
};

/**
 * Event emitter for native module events
 * @internal
 */
const emitter = new EventEmitter<LoqaAudioBridgeEvents>(LoqaAudioBridgeModule as any);

// ========================================
// Streaming Functions
// ========================================

/**
 * Start audio streaming from device microphone
 *
 * Initializes the native audio engine and begins capturing audio samples.
 * Audio samples are delivered via the onAudioSamples event at ~8 Hz rate.
 *
 * Configuration is validated before passing to native code. Invalid buffer
 * sizes or sample rates will be rejected with an error.
 *
 * @param config Audio stream configuration
 * @returns Promise<boolean> - true if started successfully, false otherwise
 * @throws Error if buffer size validation fails
 *
 * @example
 * ```typescript
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
 */
export async function startAudioStream(config: StreamConfig): Promise<boolean> {
  // Validate buffer size if provided - check min/max bounds only
  // Platform-specific constraints (e.g., power-of-2 for iOS) are validated natively
  if (config.bufferSize !== undefined) {
    const { bufferSize } = config;
    const { BUFFER_SIZE_MIN, BUFFER_SIZE_MAX } = await import('./src/buffer-utils');

    if (bufferSize < BUFFER_SIZE_MIN || bufferSize > BUFFER_SIZE_MAX) {
      throw new Error(
        `Invalid buffer size: ${bufferSize}. Must be between ${BUFFER_SIZE_MIN} and ${BUFFER_SIZE_MAX} samples.`
      );
    }
  }

  return LoqaAudioBridgeModule.startAudioStream(config);
}

/**
 * Stop audio streaming and release resources
 *
 * Stops the audio engine, removes audio tap/recording, and cleans up resources.
 *
 * @returns boolean - true if stopped successfully
 *
 * @example
 * ```typescript
 * stopAudioStream();
 * ```
 */
export function stopAudioStream(): boolean {
  return LoqaAudioBridgeModule.stopAudioStream();
}

/**
 * Check if audio streaming is currently active
 *
 * @returns boolean - true if audio stream is active
 *
 * @example
 * ```typescript
 * if (isStreaming()) {
 *   console.log('Currently streaming');
 * }
 * ```
 */
export function isStreaming(): boolean {
  return LoqaAudioBridgeModule.isStreaming();
}

// ========================================
// Event Listeners
// ========================================

/**
 * Add listener for audio sample events
 *
 * The listener is called continuously while streaming (~8 Hz rate) with
 * captured audio samples in Float32 format, normalized to [-1.0, 1.0] range.
 *
 * **Important:** Always remove the subscription when done to prevent memory leaks.
 *
 * @param listener Callback function that receives audio sample events
 * @returns Subscription object - call `.remove()` to unsubscribe
 *
 * @example
 * ```typescript
 * const subscription = addAudioSampleListener((event) => {
 *   console.log(`Received ${event.samples.length} samples at ${event.sampleRate} Hz`);
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
): EventSubscription {
  return emitter.addListener('onAudioSamples', listener);
}

/**
 * Add listener for stream status change events
 *
 * The listener is called when the audio stream status changes:
 * - "streaming": Stream started successfully
 * - "stopped": Stream stopped (user-initiated or error)
 * - "paused": Stream paused due to interruption (iOS only, e.g., phone call)
 *
 * **Important:** Always remove the subscription when done to prevent memory leaks.
 *
 * @param listener Callback function that receives status change events
 * @returns Subscription object - call `.remove()` to unsubscribe
 *
 * @example
 * ```typescript
 * const subscription = addStreamStatusListener((event) => {
 *   console.log('Stream status:', event.status);
 *
 *   if (event.status === 'stopped') {
 *     // Handle stream stopped
 *   }
 * });
 *
 * // Later: cleanup
 * subscription.remove();
 * ```
 */
export function addStreamStatusListener(
  listener: (event: StreamStatusEvent) => void
): EventSubscription {
  return emitter.addListener('onStreamStatusChange', listener);
}

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
 * @param listener Callback function that receives error events
 * @returns Subscription object - call `.remove()` to unsubscribe
 *
 * @example
 * ```typescript
 * const subscription = addStreamErrorListener((event) => {
 *   console.error(`Stream error [${event.error}]:`, event.message);
 *
 *   if (event.error === 'PERMISSION_DENIED') {
 *     // Prompt user to grant microphone permission
 *     Alert.alert('Microphone Access Required', event.message);
 *   }
 * });
 *
 * // Later: cleanup
 * subscription.remove();
 * ```
 */
export function addStreamErrorListener(
  listener: (event: StreamErrorEvent) => void
): EventSubscription {
  return emitter.addListener('onStreamError', listener);
}

// ========================================
// Configuration Helpers
// ========================================

/**
 * Create a default stream configuration with sensible defaults
 *
 * Returns a StreamConfig with recommended values for most use cases:
 * - Sample rate: 16kHz (standard for speech recognition)
 * - Buffer size: 2048 samples (128ms at 16kHz, ~8 Hz event rate)
 * - Channels: 1 (mono, sufficient for voice)
 * - VAD enabled: true (reduces battery during silence)
 * - Adaptive processing: true (reduces frame rate on low battery)
 *
 * @returns StreamConfig with default values
 *
 * @example
 * ```typescript
 * const config = createDefaultStreamConfig();
 * await startAudioStream(config);
 * ```
 */
export function createDefaultStreamConfig(): StreamConfig {
  return {
    sampleRate: 16000,
    bufferSize: 2048,
    channels: 1,
    vadEnabled: true,
    adaptiveProcessing: true,
  };
}

/**
 * Validate and fill defaults for a partial stream configuration
 *
 * Takes a partial configuration (with some fields missing) and returns a complete,
 * validated StreamConfig with defaults filled in.
 *
 * Validation rules:
 * - Buffer size: 512-8192 samples (enforced by native modules)
 * - Sample rate: >0 Hz (common: 16000, 44100, 48000)
 * - Channels: 1-2 (mono or stereo)
 *
 * @param config Partial stream configuration
 * @returns Complete StreamConfig with defaults filled and validation applied
 * @throws Error if validation fails
 *
 * @example
 * ```typescript
 * // Minimal config - fills in defaults
 * const config = validateStreamConfig({
 *   bufferSize: 4096,
 * });
 * // Result: { sampleRate: 16000, bufferSize: 4096, channels: 1, vadEnabled: true, adaptiveProcessing: true }
 *
 * // Invalid config - throws error
 * try {
 *   const invalid = validateStreamConfig({ bufferSize: 100 });
 * } catch (err) {
 *   console.error('Validation failed:', err.message);
 * }
 * ```
 */
export function validateStreamConfig(config: Partial<StreamConfig>): StreamConfig {
  // Start with defaults
  const validated: StreamConfig = {
    sampleRate: config.sampleRate ?? 16000,
    bufferSize: config.bufferSize ?? 2048,
    channels: config.channels ?? 1,
    vadEnabled: config.vadEnabled ?? true,
    adaptiveProcessing: config.adaptiveProcessing ?? true,
  };

  // Validate buffer size (using already-imported constants)
  if (validated.bufferSize! < BUFFER_SIZE_MIN || validated.bufferSize! > BUFFER_SIZE_MAX) {
    throw new Error(
      `Invalid buffer size: ${validated.bufferSize}. Must be between ${BUFFER_SIZE_MIN} and ${BUFFER_SIZE_MAX} samples.`
    );
  }

  // Validate sample rate
  if (validated.sampleRate! <= 0) {
    throw new Error(`Invalid sample rate: ${validated.sampleRate}. Must be greater than 0 Hz.`);
  }

  // Validate channels
  if (validated.channels! < 1 || validated.channels! > 2) {
    throw new Error(`Invalid channels: ${validated.channels}. Must be 1 (mono) or 2 (stereo).`);
  }

  return validated;
}

// ========================================
// Namespace Export (for backward compatibility with v0.2.0 tests)
// ========================================

/**
 * LoqaAudioBridge namespace - provides all streaming functions as a single namespace export
 *
 * This namespace export maintains backward compatibility with v0.2.0 test code
 * that uses `LoqaAudioBridge.startAudioStream()` instead of named imports.
 *
 * @example
 * ```typescript
 * // Namespace style (v0.2.0 compatibility)
 * await LoqaAudioBridge.startAudioStream({ bufferSize: 2048 });
 *
 * // Named imports (preferred in v0.3.0)
 * import { startAudioStream } from '@loqalabs/loqa-audio-bridge';
 * await startAudioStream({ bufferSize: 2048 });
 * ```
 */
export const LoqaAudioBridge = {
  // Streaming functions
  startAudioStream,
  stopAudioStream,
  isStreaming,

  // Event listeners
  addAudioSampleListener,
  addStreamStatusListener,
  addStreamErrorListener,

  // Configuration helpers
  createDefaultStreamConfig,
  validateStreamConfig,
};
