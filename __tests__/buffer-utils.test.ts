/**
 * Buffer Utilities Unit Tests
 *
 * Tests buffer size calculation, validation, and sample rate utilities
 */

import * as bufferUtils from '../src/buffer-utils';

describe('Buffer Utils', () => {
  describe('Buffer Size Validation', () => {
    test('BUFFER_SIZE_MIN should be 512', () => {
      expect(bufferUtils.BUFFER_SIZE_MIN).toBe(512);
    });

    test('BUFFER_SIZE_MAX should be 8192', () => {
      expect(bufferUtils.BUFFER_SIZE_MAX).toBe(8192);
    });

    test('validateBufferSize should accept valid buffer sizes', () => {
      const result = bufferUtils.validateBufferSize(2048);
      expect(result.valid).toBe(true);
    });

    test('validateBufferSize should reject buffer size below minimum', () => {
      const result = bufferUtils.validateBufferSize(256);
      expect(result.valid).toBe(false);
    });

    test('validateBufferSize should reject buffer size above maximum', () => {
      const result = bufferUtils.validateBufferSize(16384);
      expect(result.valid).toBe(false);
    });
  });

  describe('Sample Rate Utilities', () => {
    test('isRateSupported should return true for 16000 Hz', () => {
      expect(bufferUtils.isRateSupported(16000)).toBe(true);
    });

    test('findClosestSupportedRate should find nearest supported rate', () => {
      const closest = bufferUtils.findClosestSupportedRate(15000);
      expect(closest).toBe(16000);
    });
  });

  describe('Buffer Calculations', () => {
    test('calculateBufferDuration should compute correct duration', () => {
      const duration = bufferUtils.calculateBufferDuration(2048, 16000);
      expect(duration).toBe(128); // 2048 / 16000 * 1000 = 128ms
    });

    test('calculateEventRate should compute correct event rate', () => {
      const eventRate = bufferUtils.calculateEventRate(16000, 2048);
      expect(eventRate).toBeCloseTo(7.8125, 1); // 16000 / 2048 ≈ 7.8 Hz
    });

    test('isPowerOf2 should correctly identify powers of 2', () => {
      expect(bufferUtils.isPowerOf2(2048)).toBe(true);
      expect(bufferUtils.isPowerOf2(2000)).toBe(false);
    });

    test('roundToPowerOf2 should round to nearest power of 2', () => {
      expect(bufferUtils.roundToPowerOf2(2000)).toBe(2048);
      expect(bufferUtils.roundToPowerOf2(3000)).toBe(4096); // Rounds up
    });
  });
});
