/**
 * Buffer Management Utilities for LoqaAudioBridge
 *
 * Provides cross-platform buffer size calculation, validation, and
 * sample rate fallback logic for iOS and Android audio streaming.
 *
 * @module buffer-utils
 */

/**
 * Platform type for buffer management
 */
export type Platform = 'ios' | 'android';

/**
 * Buffer validation result
 */
export interface BufferValidationResult {
  /** Whether the buffer size is valid */
  valid: boolean;
  /** Error message if validation failed */
  error?: string;
}

/**
 * Supported sample rates for iOS (AVAudioEngine)
 */
export const IOS_SUPPORTED_RATES = [8000, 16000, 22050, 44100, 48000];

/**
 * Buffer size constraints
 */
export const BUFFER_SIZE_MIN = 512;
export const BUFFER_SIZE_MAX = 8192;

/**
 * Calculate optimal buffer size in samples
 *
 * Formula: bufferSize = (targetLatencyMs / 1000.0) * sampleRate
 *
 * - For iOS: Result is rounded to nearest power of 2
 * - For Android: Result is used directly (will be multiplied by 4 for byte count)
 *
 * @param sampleRate Sample rate in Hz (e.g., 16000, 44100, 48000)
 * @param targetLatencyMs Target latency in milliseconds (e.g., 128)
 * @param platform Target platform ('ios' or 'android')
 * @returns Buffer size in samples
 *
 * @example
 * ```typescript
 * // iOS: 16kHz, 128ms target → 2048 samples (power of 2)
 * const iosSize = calculateBufferSize(16000, 128, 'ios'); // 2048
 *
 * // Android: 16kHz, 128ms target → 2048 samples
 * const androidSize = calculateBufferSize(16000, 128, 'android'); // 2048
 *
 * // iOS: 44.1kHz, 93ms target → 4096 samples (rounded to power of 2)
 * const hiResSize = calculateBufferSize(44100, 93, 'ios'); // 4096
 * ```
 */
export function calculateBufferSize(
  sampleRate: number,
  targetLatencyMs: number,
  platform: Platform = 'ios'
): number {
  // Calculate raw buffer size from latency and sample rate
  const rawSize = Math.floor((targetLatencyMs / 1000.0) * sampleRate);

  // iOS requires power-of-2 buffer sizes for optimal AVAudioEngine performance
  if (platform === 'ios') {
    return roundToPowerOf2(rawSize);
  }

  // Android can use any buffer size
  return rawSize;
}

/**
 * Round a number up to the nearest power of 2
 *
 * Used for iOS buffer size calculation where AVAudioEngine works
 * best with power-of-2 buffer sizes.
 *
 * @param value Input value to round
 * @returns Nearest power of 2 >= value
 *
 * @example
 * ```typescript
 * roundToPowerOf2(2000); // 2048
 * roundToPowerOf2(2048); // 2048
 * roundToPowerOf2(3000); // 4096
 * ```
 */
export function roundToPowerOf2(value: number): number {
  let result = 1;
  while (result < value) {
    result *= 2;
  }
  return result;
}

/**
 * Check if a number is a power of 2
 *
 * @param value Number to check
 * @returns true if value is a power of 2
 *
 * @example
 * ```typescript
 * isPowerOf2(1024); // true
 * isPowerOf2(1023); // false
 * isPowerOf2(2048); // true
 * ```
 */
export function isPowerOf2(value: number): boolean {
  return value > 0 && (value & (value - 1)) === 0;
}

/**
 * Validate buffer size for given platform
 *
 * Checks:
 * - Minimum size: >= 512 samples (32ms at 16kHz)
 * - Maximum size: <= 8192 samples (512ms at 16kHz)
 * - iOS: Must be power of 2
 * - Android: Any size within range
 *
 * @param bufferSize Buffer size in samples
 * @param platform Target platform ('ios' or 'android')
 * @returns Validation result with error message if invalid
 *
 * @example
 * ```typescript
 * // Valid cases
 * validateBufferSize(2048, 'ios'); // { valid: true }
 * validateBufferSize(2048, 'android'); // { valid: true }
 *
 * // Invalid: too small
 * validateBufferSize(256, 'ios');
 * // { valid: false, error: "Buffer size 256 is too small..." }
 *
 * // Invalid: not power of 2 on iOS
 * validateBufferSize(2000, 'ios');
 * // { valid: false, error: "iOS requires power-of-2 buffer sizes..." }
 * ```
 */
export function validateBufferSize(
  bufferSize: number,
  platform: Platform = 'ios'
): BufferValidationResult {
  // Check minimum size
  if (bufferSize < BUFFER_SIZE_MIN) {
    return {
      valid: false,
      error: `Buffer size ${bufferSize} is too small (minimum ${BUFFER_SIZE_MIN} samples). Recommended: 2048 samples (128ms at 16kHz) for voice analysis.`,
    };
  }

  // Check maximum size
  if (bufferSize > BUFFER_SIZE_MAX) {
    return {
      valid: false,
      error: `Buffer size ${bufferSize} is too large (maximum ${BUFFER_SIZE_MAX} samples). Large buffers increase latency. Recommended: 2048-4096 samples.`,
    };
  }

  // iOS-specific: Check power of 2
  if (platform === 'ios' && !isPowerOf2(bufferSize)) {
    const rounded = roundToPowerOf2(bufferSize);
    return {
      valid: false,
      error: `iOS requires power-of-2 buffer sizes. ${bufferSize} is not a power of 2. Try ${rounded} instead.`,
    };
  }

  return { valid: true };
}

/**
 * Find the closest supported sample rate for iOS
 *
 * iOS (AVAudioEngine) supports specific sample rates:
 * 8kHz, 16kHz, 22.05kHz, 44.1kHz, 48kHz
 *
 * If the requested rate is not in this list, this function finds
 * the closest supported rate.
 *
 * @param requestedRate Requested sample rate in Hz
 * @returns Closest supported sample rate
 *
 * @example
 * ```typescript
 * findClosestSupportedRate(16000); // 16000 (exact match)
 * findClosestSupportedRate(32000); // 44100 (closest)
 * findClosestSupportedRate(11025); // 16000 (closest)
 * ```
 */
export function findClosestSupportedRate(requestedRate: number): number {
  return IOS_SUPPORTED_RATES.reduce((prev, curr) => {
    return Math.abs(curr - requestedRate) < Math.abs(prev - requestedRate) ? curr : prev;
  });
}

/**
 * Check if a sample rate is supported on iOS
 *
 * @param sampleRate Sample rate to check
 * @returns true if supported
 */
export function isRateSupported(sampleRate: number): boolean {
  return IOS_SUPPORTED_RATES.includes(sampleRate);
}

/**
 * Calculate buffer duration in milliseconds
 *
 * @param bufferSize Buffer size in samples
 * @param sampleRate Sample rate in Hz
 * @returns Buffer duration in milliseconds
 *
 * @example
 * ```typescript
 * calculateBufferDuration(2048, 16000); // 128ms
 * calculateBufferDuration(4096, 44100); // ~93ms
 * ```
 */
export function calculateBufferDuration(bufferSize: number, sampleRate: number): number {
  return (bufferSize / sampleRate) * 1000;
}

/**
 * Calculate event rate (callbacks per second)
 *
 * @param sampleRate Sample rate in Hz
 * @param bufferSize Buffer size in samples
 * @returns Event rate in Hz (callbacks per second)
 *
 * @example
 * ```typescript
 * calculateEventRate(16000, 2048); // ~7.8 Hz
 * calculateEventRate(44100, 4096); // ~10.8 Hz
 * ```
 */
export function calculateEventRate(sampleRate: number, bufferSize: number): number {
  return sampleRate / bufferSize;
}
