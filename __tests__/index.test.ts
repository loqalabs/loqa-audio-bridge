/**
 * API Contract Tests - Type Definitions
 *
 * Tests that validate TypeScript types and enums are correctly exported
 * (Note: Full module tests require native environment)
 */

import { StreamErrorCode } from '../src/types';
import type {
  AudioSampleEvent,
  StreamStatusEvent,
  StreamErrorEvent,
  StreamConfig,
} from '../src/types';

describe('API Type Contracts', () => {
  describe('StreamErrorCode Enum', () => {
    test('should export StreamErrorCode enum', () => {
      expect(StreamErrorCode).toBeDefined();
    });

    test('should have PERMISSION_DENIED error code', () => {
      expect(StreamErrorCode.PERMISSION_DENIED).toBe('PERMISSION_DENIED');
    });

    test('should have SESSION_CONFIG_FAILED error code', () => {
      expect(StreamErrorCode.SESSION_CONFIG_FAILED).toBe('SESSION_CONFIG_FAILED');
    });

    test('should have ENGINE_START_FAILED error code', () => {
      expect(StreamErrorCode.ENGINE_START_FAILED).toBe('ENGINE_START_FAILED');
    });

    test('should have DEVICE_NOT_AVAILABLE error code', () => {
      expect(StreamErrorCode.DEVICE_NOT_AVAILABLE).toBe('DEVICE_NOT_AVAILABLE');
    });

    test('should have BUFFER_OVERFLOW error code', () => {
      expect(StreamErrorCode.BUFFER_OVERFLOW).toBe('BUFFER_OVERFLOW');
    });
  });

  describe('Type Definitions', () => {
    test('should define AudioSampleEvent type', () => {
      const event: AudioSampleEvent = {
        samples: [0.1, 0.2],
        sampleRate: 16000,
        frameLength: 2048,
        timestamp: Date.now(),
        rms: 0.5,
      };
      expect(event.samples).toBeDefined();
      expect(event.sampleRate).toBe(16000);
    });

    test('should define StreamStatusEvent type', () => {
      const event: StreamStatusEvent = {
        status: 'streaming',
        timestamp: Date.now(),
      };
      expect(event.status).toBe('streaming');
    });

    test('should define StreamErrorEvent type', () => {
      const event: StreamErrorEvent = {
        error: StreamErrorCode.PERMISSION_DENIED,
        message: 'Permission denied',
        platform: 'ios',
        timestamp: Date.now(),
      };
      expect(event.error).toBe('PERMISSION_DENIED');
    });

    test('should define StreamConfig type', () => {
      const config: StreamConfig = {
        sampleRate: 16000,
        bufferSize: 2048,
        channels: 1,
        vadEnabled: true,
        adaptiveProcessing: true,
      };
      expect(config.sampleRate).toBe(16000);
      expect(config.channels).toBe(1);
    });
  });
});
