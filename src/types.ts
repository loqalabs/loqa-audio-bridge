/**
 * Event payload types for LoqaAudioBridge module
 *
 * These interfaces define the structure of events emitted by the native
 * iOS and Android modules during audio streaming operations.
 */

/**
 * Audio sample event payload
 *
 * Emitted continuously during audio streaming with captured audio data.
 * Event rate: ~8 Hz (2048 samples at 16kHz = 128ms per buffer)
 */
export interface AudioSampleEvent {
  /** Audio samples as Float32 array, normalized to [-1.0, 1.0] range */
  samples: number[];

  /** Sample rate in Hz (typically 16000) */
  sampleRate: number;

  /** Number of samples in the samples array */
  frameLength: number;

  /**
   * Platform-specific timestamp
   * - iOS: Milliseconds since stream start
   * - Android: System.currentTimeMillis() (milliseconds since epoch)
   */
  timestamp: number;

  /** Pre-computed RMS (Root Mean Square) amplitude in range [0.0, 1.0] */
  rms: number;
}

/**
 * Stream status change event payload
 *
 * Emitted when the audio stream status changes (start, stop, pause).
 */
export interface StreamStatusEvent {
  /** Current stream status */
  status: 'streaming' | 'stopped' | 'paused' | 'battery_optimized';

  /**
   * Timestamp when status changed (milliseconds since epoch)
   * Platform-independent Unix timestamp
   */
  timestamp: number;

  /** Optional platform identifier for debugging */
  platform?: 'ios' | 'android';
}

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

/**
 * Stream error event payload
 *
 * Emitted when an error occurs during audio streaming setup or operation.
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

  /** User-friendly error message with actionable guidance */
  message: string;

  /** Platform identifier for debugging */
  platform?: 'ios' | 'android';

  /**
   * Timestamp when error occurred (milliseconds since epoch)
   * Platform-independent Unix timestamp
   */
  timestamp: number;
}

/**
 * Audio stream configuration
 *
 * Used when starting audio streaming to specify capture parameters.
 */
export interface StreamConfig {
  /** Sample rate in Hz (default: 16000) */
  sampleRate?: number;

  /** Buffer size in samples (default: 2048) */
  bufferSize?: number;

  /** Number of channels (default: 1 for mono) */
  channels?: number;

  /**
   * Enable Voice Activity Detection (VAD) to skip silent frames
   * Reduces battery consumption during silence (default: true)
   * Silence threshold: RMS < 0.01
   */
  vadEnabled?: boolean;

  /**
   * Enable adaptive processing to reduce frame rate during low battery
   * Skips every 2nd frame when battery < 20% (default: true)
   * Reduces event rate from ~8Hz to ~4Hz for 20-30% power savings
   */
  adaptiveProcessing?: boolean;
}
