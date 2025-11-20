# Loqa Audio Bridge Example

This example app demonstrates how to integrate `@loqalabs/loqa-audio-bridge` into an Expo application. It shows real-time audio streaming with visual feedback and proper permission handling.

## Quick Start

1. Install dependencies:

   ```bash
   npm install
   ```

2. Run on iOS:

   ```bash
   npx expo run:ios
   ```

3. Run on Android:
   ```bash
   npx expo run:android
   ```

## Prerequisites

- Node.js 18+ installed
- macOS with Xcode 14+ (for iOS development)
- Android Studio with Android SDK (for Android development)
- iOS Simulator or physical device
- Android Emulator or physical device

## What This Example Demonstrates

### Core Features

- **Audio Streaming Setup**: How to configure and start audio streaming
- **Event Listeners**: Subscribe to audio sample events
- **Real-Time Visualization**: Display RMS (volume level) updates
- **Permission Handling**: Request and manage microphone permissions
- **Lifecycle Management**: Proper cleanup when component unmounts

### Integration Patterns

- Importing the module into React Native
- TypeScript type definitions usage
- Error handling best practices
- Cross-platform compatibility (iOS + Android)

## Code Walkthrough

### 1. Import the Module

```typescript
import {
  startAudioStream,
  stopAudioStream,
  addAudioSampleListener,
} from '@loqalabs/loqa-audio-bridge';
```

### 2. Request Microphone Permission

```typescript
import { Audio } from 'expo-av';

const { status } = await Audio.requestPermissionsAsync();
```

### 3. Start Audio Streaming

```typescript
await startAudioStream({
  sampleRate: 16000, // 16kHz sample rate
  bufferSize: 2048, // 2048 samples per buffer
  channels: 1, // Mono audio
  vadEnabled: true, // Enable Voice Activity Detection
});
```

### 4. Listen for Audio Samples

```typescript
const subscription = addAudioSampleListener((event) => {
  // event.samples: number[] of audio data
  // event.rms: Root Mean Square (volume level)
  // event.sampleRate: Current sample rate
  console.log('RMS:', event.rms);
});
```

### 5. Clean Up on Unmount

```typescript
useEffect(() => {
  return () => {
    subscription.remove(); // Remove listener
    stopAudioStream(); // Stop audio processing
  };
}, []);
```

## Development Commands

### Installation

```bash
npm install
```

### iOS Development

```bash
npx expo run:ios              # Build and run on iOS simulator
npx expo run:ios --device     # Run on physical iOS device
```

### Android Development

```bash
npx expo run:android          # Build and run on Android emulator
npx expo run:android --device # Run on physical Android device
```

### Other Commands

```bash
npx expo start                # Start Metro bundler only
npx expo prebuild             # Generate native projects
npx expo prebuild --clean     # Regenerate native projects (clean slate)
```

## Troubleshooting

### iOS Issues

**Build fails with "Pod install failed"**

- Solution: `cd ios && pod install --repo-update && cd ..`

**Microphone not working in simulator**

- Solution: Simulator uses Mac's microphone. Speak into Mac mic.

**Build fails with "Xcode version too old"**

- Solution: Update Xcode to 14.0 or newer

### Android Issues

**Build fails with "SDK not found"**

- Solution: Install Android SDK via Android Studio

**Microphone not working in emulator**

- Solution: Enable virtual audio input in AVD Manager or use physical device

**Gradle build fails**

- Solution: `cd android && ./gradlew clean && cd ..`

### General Issues

**Metro bundler errors**

- Solution: Clear cache with `npx expo start -c`

**Module not found errors**

- Solution: Delete node_modules and run `npm install` again

## Build Times

Tested on M1 MacBook Pro:

### iOS

- First build: ~3-4 minutes
- Subsequent builds: ~1-2 minutes
- Total from `npm install` to running app: ~5-6 minutes

### Android

- First build: ~4-5 minutes
- Subsequent builds: ~1-2 minutes
- Total from `npm install` to running app: ~6-7 minutes

**Total Integration Time**: <10 minutes ✅

## Learn More

- [Full API Documentation](../API.md) - Complete API reference (Story 4.3)
- [Integration Guide](../INTEGRATION_GUIDE.md) - Step-by-step integration (Story 4.2)
- [Module README](../README.md) - Quick start guide (Story 4.1)
- [Architecture](../../docs/loqa-audio-bridge/architecture.md) - Technical architecture

## About This Module

`@loqalabs/loqa-audio-bridge` is a production-grade Expo native module for real-time audio streaming with Voice Activity Detection and battery optimization.

- **GitHub**: [loqalabs/loqa](https://github.com/loqalabs/loqa)
- **npm**: [@loqalabs/loqa-audio-bridge](https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge)
- **License**: MIT
