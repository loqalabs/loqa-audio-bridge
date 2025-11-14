/**
 * React Hook for Audio Streaming Lifecycle Management
 *
 * This hook provides a simple, declarative API for managing audio streaming
 * in React components. It handles:
 * - Start/stop streaming lifecycle
 * - Event listener subscription and cleanup
 * - Error handling
 * - Streaming state tracking
 *
 * @module useAudioStreaming
 */

import { useEffect, useState, useCallback, useRef } from 'react';
import {
  startAudioStream,
  stopAudioStream,
  addAudioSampleListener,
  addStreamStatusListener,
  addStreamErrorListener,
} from '../index';
import type { AudioSampleEvent, StreamConfig, StreamStatusEvent, StreamErrorEvent } from '../src/types';

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
 * Provides a declarative API for starting/stopping audio streaming and
 * subscribing to audio events. Automatically handles cleanup on unmount.
 *
 * @param options Hook configuration options
 * @returns Audio streaming controls and state
 *
 * @example Basic Usage
 * ```typescript
 * function AudioRecorder() {
 *   const handleSamples = useCallback((event: AudioSampleEvent) => {
 *     console.log('Received samples:', event.samples.length);
 *     // Process audio samples
 *   }, []);
 *
 *   const { isStreaming, error, start, stop } = useAudioStreaming({
 *     config: { sampleRate: 16000, bufferSize: 2048, channels: 1 },
 *     onSamples: handleSamples,
 *   });
 *
 *   return (
 *     <View>
 *       <Button onPress={isStreaming ? stop : start}>
 *         {isStreaming ? 'Stop' : 'Start'} Recording
 *       </Button>
 *       {error && <Text style={{ color: 'red' }}>{error}</Text>}
 *     </View>
 *   );
 * }
 * ```
 *
 * @example With Auto-Start and Status Tracking
 * ```typescript
 * function VoicePractice() {
 *   const [practiceActive, setPracticeActive] = useState(false);
 *
 *   const handleSamples = useCallback((event: AudioSampleEvent) => {
 *     processAudioSamples(new Float32Array(event.samples));
 *   }, []);
 *
 *   const handleStatus = useCallback((event: StreamStatusEvent) => {
 *     console.log('Stream status:', event.status);
 *     if (event.status === 'stopped') {
 *       setPracticeActive(false);
 *     }
 *   }, []);
 *
 *   const { isStreaming, error, start, stop } = useAudioStreaming({
 *     config: createDefaultStreamConfig(),
 *     onSamples: handleSamples,
 *     onStatusChange: handleStatus,
 *     autoStart: practiceActive,
 *   });
 *
 *   useEffect(() => {
 *     if (practiceActive) {
 *       start();
 *     } else {
 *       stop();
 *     }
 *   }, [practiceActive, start, stop]);
 *
 *   return (
 *     <View>
 *       <Switch value={practiceActive} onValueChange={setPracticeActive} />
 *       {error && <Text>{error}</Text>}
 *     </View>
 *   );
 * }
 * ```
 *
 * @example With Error Handling
 * ```typescript
 * function StreamingExample() {
 *   const handleError = useCallback((event: StreamErrorEvent) => {
 *     if (event.error === StreamErrorCode.PERMISSION_DENIED) {
 *       Alert.alert('Microphone Permission Required', event.message);
 *     }
 *   }, []);
 *
 *   const { isStreaming, error, start, clearError } = useAudioStreaming({
 *     config: { sampleRate: 16000, bufferSize: 2048, channels: 1 },
 *     onSamples: (event) => console.log('Samples:', event.samples.length),
 *     onError: handleError,
 *   });
 *
 *   return (
 *     <View>
 *       <Button onPress={start} disabled={isStreaming}>Start</Button>
 *       {error && (
 *         <View>
 *           <Text style={{ color: 'red' }}>{error}</Text>
 *           <Button onPress={clearError}>Dismiss</Button>
 *         </View>
 *       )}
 *     </View>
 *   );
 * }
 * ```
 */
export function useAudioStreaming(options: UseAudioStreamingOptions): UseAudioStreamingResult {
  const { config, onSamples, onStatusChange, onError, autoStart = false } = options;

  const [isStreaming, setIsStreaming] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Use refs to ensure callbacks always use latest values without triggering re-subscriptions
  const onSamplesRef = useRef(onSamples);
  const onStatusChangeRef = useRef(onStatusChange);
  const onErrorRef = useRef(onError);

  // Update refs when callbacks change
  useEffect(() => {
    onSamplesRef.current = onSamples;
  }, [onSamples]);

  useEffect(() => {
    onStatusChangeRef.current = onStatusChange;
  }, [onStatusChange]);

  useEffect(() => {
    onErrorRef.current = onError;
  }, [onError]);

  /**
   * Start audio streaming
   */
  const start = useCallback(async () => {
    try {
      const started = await startAudioStream(config);
      setIsStreaming(started);
      if (!started) {
        setError('Failed to start audio stream');
      } else {
        setError(null);
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      setError(errorMessage);
      setIsStreaming(false);
    }
  }, [config]);

  /**
   * Stop audio streaming
   */
  const stop = useCallback(() => {
    stopAudioStream();
    setIsStreaming(false);
  }, []);

  /**
   * Clear current error
   */
  const clearError = useCallback(() => {
    setError(null);
  }, []);

  /**
   * Subscribe to events when streaming is active
   */
  useEffect(() => {
    if (!isStreaming) return;

    // Subscribe to audio samples
    const audioSub = addAudioSampleListener((event) => {
      onSamplesRef.current(event);
    });

    // Subscribe to status changes (if callback provided)
    const statusSub = onStatusChangeRef.current
      ? addStreamStatusListener((event) => {
          onStatusChangeRef.current?.(event);
        })
      : null;

    // Subscribe to errors
    const errorSub = addStreamErrorListener((event) => {
      setError(event.message);
      setIsStreaming(false);
      onErrorRef.current?.(event);
    });

    // Cleanup subscriptions on unmount or when streaming stops
    return () => {
      audioSub.remove();
      statusSub?.remove();
      errorSub.remove();
    };
  }, [isStreaming]);

  /**
   * Auto-start if enabled
   */
  useEffect(() => {
    if (autoStart) {
      start();
    }
    // Only run on mount if autoStart is true
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /**
   * Cleanup on unmount
   */
  useEffect(() => {
    return () => {
      if (isStreaming) {
        stopAudioStream();
      }
    };
  }, [isStreaming]);

  return {
    isStreaming,
    error,
    start,
    stop,
    clearError,
  };
}
