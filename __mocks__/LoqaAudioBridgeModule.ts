/**
 * Mock implementation of LoqaAudioBridgeModule for Jest testing
 *
 * This mock provides a test double for the native module, allowing
 * tests to run without requiring actual iOS/Android native code.
 */

import { EventEmitter } from 'expo-modules-core';

// Create mock event emitter
const mockEmitter = new EventEmitter({} as any);

// Mock state
let isCurrentlyStreaming = false;
// eslint-disable-next-line @typescript-eslint/no-unused-vars
let _currentConfig: any = null; // Stored but not read in mock - kept for potential future test assertions

// Mock native module
const LoqaAudioBridgeModule = {
  /**
   * Mock startAudioStream - simulates starting audio capture
   */
  async startAudioStream(config: any): Promise<boolean> {
    if (isCurrentlyStreaming) {
      throw new Error('ALREADY_STREAMING');
    }

    _currentConfig = config;
    isCurrentlyStreaming = true;

    // Simulate async native initialization
    await new Promise(resolve => setTimeout(resolve, 10));

    // Emit initial status event
    setTimeout(() => {
      mockEmitter.emit('onStreamStatusChange', {
        status: 'streaming',
      });

      // Simulate audio sample events
      const emitSamples = () => {
        if (isCurrentlyStreaming) {
          mockEmitter.emit('onAudioSamples', {
            samples: new Array(config.bufferSize || 2048).fill(0).map(() => Math.random() * 0.02 - 0.01),
            sampleRate: config.sampleRate || 16000,
            frameLength: config.bufferSize || 2048,
            timestamp: Date.now(),
            rms: 0.005 + Math.random() * 0.01,
          });

          if (isCurrentlyStreaming) {
            setTimeout(emitSamples, 125); // ~8 Hz
          }
        }
      };

      emitSamples();
    }, 50);

    return true;
  },

  /**
   * Mock stopAudioStream - simulates stopping audio capture
   */
  stopAudioStream(): boolean {
    if (!isCurrentlyStreaming) {
      return false;
    }

    isCurrentlyStreaming = false;
    _currentConfig = null;

    // Emit stopped status
    setTimeout(() => {
      mockEmitter.emit('onStreamStatusChange', {
        status: 'stopped',
      });
    }, 10);

    return true;
  },

  /**
   * Mock isStreaming - returns current streaming state
   */
  isStreaming(): boolean {
    return isCurrentlyStreaming;
  },

  /**
   * Mock addListener - delegates to EventEmitter
   */
  addListener(eventName: string, listener: (...args: any[]) => void) {
    return mockEmitter.addListener(eventName, listener);
  },

  /**
   * Mock removeListeners - delegates to EventEmitter
   */
  removeListeners(count: number) {
    // EventEmitter handles this internally
  },
};

export default LoqaAudioBridgeModule;
