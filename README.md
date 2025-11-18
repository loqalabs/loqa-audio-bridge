# @loqalabs/loqa-audio-bridge

Production-grade Expo native module for real-time audio streaming with Voice Activity Detection and battery optimization

[![npm version](https://badge.fury.io/js/%40loqalabs%2Floqa-audio-bridge.svg)](https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Features

- **Real-time Audio Streaming** - Capture audio at 8kHz-48kHz with configurable buffer sizes
- **Voice Activity Detection (VAD)** - Automatic silence detection for battery optimization
- **Cross-Platform** - Unified API for iOS (AVAudioEngine) and Android (AudioRecord)
- **TypeScript Support** - Full type definitions with strict typing
- **Zero Configuration** - Autolinking works out-of-the-box with Expo

## Installation

```bash
npx expo install @loqalabs/loqa-audio-bridge
```

That's it! Autolinking handles the rest.

## Quick Start

```typescript
import { startAudioStream, addAudioSampleListener } from '@loqalabs/loqa-audio-bridge';

// Start streaming
await startAudioStream({ sampleRate: 16000, bufferSize: 2048 });

// Listen for audio samples
const subscription = addAudioSampleListener((event) => {
  console.log('RMS:', event.rms);  // Volume level
  // Access audio samples: event.samples (number[])
});

// Clean up when done
subscription.remove();
```

## Documentation

- [Integration Guide](./INTEGRATION_GUIDE.md) - Step-by-step integration instructions
- [API Reference](./API.md) - Complete API documentation
- [Example App](./example) - Working Expo app demonstrating usage

## Platform Requirements

- **iOS** 13.4+
- **Android** API 24+
- **Expo** 52+
- **React Native** 0.72+

## Key Capabilities

### Audio Configuration

Configure sample rate, buffer size, channels, and enable VAD for your use case:

```typescript
await startAudioStream({
  sampleRate: 16000,      // 8000, 16000, 32000, 44100, 48000
  bufferSize: 2048,       // 512-8192 samples
  channels: 1,            // 1 (mono) or 2 (stereo)
  vadEnabled: true,       // Voice Activity Detection
});
```

### Event-Driven Architecture

Subscribe to audio samples, status changes, and errors:

```typescript
import {
  addAudioSampleListener,
  addStreamStatusListener,
  addStreamErrorListener
} from '@loqalabs/loqa-audio-bridge';

// Audio samples (~8 Hz at 16kHz/2048 buffer)
const audioSub = addAudioSampleListener((event) => {
  const samples = event.samples;  // number[] of audio data
  const rms = event.rms;          // Volume level (0.0-1.0)
});

// Stream status changes
const statusSub = addStreamStatusListener((event) => {
  console.log('Status:', event.status);  // "streaming" | "stopped" | "paused"
});

// Stream errors
const errorSub = addStreamErrorListener((event) => {
  console.error('Error:', event.error, event.message);
});
```

### React Hook

Use the `useAudioStreaming` hook for automatic lifecycle management:

```typescript
import { useAudioStreaming } from '@loqalabs/loqa-audio-bridge';

function MyComponent() {
  const { startStream, stopStream, isStreaming, rmsLevel } = useAudioStreaming({
    sampleRate: 16000,
    bufferSize: 2048,
  });

  return (
    <View>
      <Button title="Start" onPress={startStream} />
      <Button title="Stop" onPress={stopStream} />
      <Text>RMS: {rmsLevel}</Text>
    </View>
  );
}
```

## Permissions

### iOS

Add microphone permission to your `app.json`:

```json
{
  "expo": {
    "ios": {
      "infoPlist": {
        "NSMicrophoneUsageDescription": "This app needs microphone access for audio recording."
      }
    }
  }
}
```

### Android

Add microphone permission to your `app.json`:

```json
{
  "expo": {
    "android": {
      "permissions": ["RECORD_AUDIO"]
    }
  }
}
```

Request permission at runtime using `expo-av` or similar:

```typescript
import { Audio } from 'expo-av';

const { status } = await Audio.requestPermissionsAsync();
if (status === 'granted') {
  // Start streaming
}
```

## Performance

- **CPU Usage**: 2-5% during active streaming
- **Battery Impact**: 3-8% per hour with VAD enabled (30-50% reduction vs. continuous)
- **Event Rate**: ~8 Hz at 16kHz/2048 buffer (configurable via buffer size)

## Common Use Cases

- **Speech Recognition**: 16kHz sample rate for optimal accuracy
- **Voice Communication**: 8kHz-16kHz with VAD for battery efficiency
- **Audio Analysis**: 44.1kHz-48kHz for high-fidelity capture
- **Environmental Monitoring**: VAD-enabled streaming with low sample rates

## License

MIT

## Contributing

This package is part of the [Loqa monorepo](https://github.com/loqalabs/loqa). See the repository for contribution guidelines.

## Support

- [GitHub Issues](https://github.com/loqalabs/loqa/issues)
- [Example App](./example) - Working reference implementation
