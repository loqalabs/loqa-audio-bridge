/**
 * Jest setup file for LoqaAudioBridge tests
 *
 * This file configures the test environment and mocks native modules
 */

// Mock the native LoqaAudioBridge module
jest.mock('./src/LoqaAudioBridgeModule', () => {
  return require('./__mocks__/LoqaAudioBridgeModule').default;
});

// Suppress console warnings during tests (optional)
global.console = {
  ...console,
  // Uncomment to suppress warnings:
  // warn: jest.fn(),
};
