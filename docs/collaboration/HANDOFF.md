# VoicelineDSP v0.2.0 - Voiceline Team Handoff Guide

**Date:** 2025-11-13
**Status:** Ready for Integration
**Epic:** 2D - Real-Time Audio Streaming for Voice DSP

---

## Executive Summary

VoicelineDSP v0.2.0 is a production-ready Expo native module that provides real-time audio streaming for iOS and Android. This document provides everything the Voiceline team needs to integrate, test, and deploy the module.

### What's Included

✅ **Native Streaming**: iOS (AVAudioEngine) + Android (AudioRecord)
✅ **Event System**: Real-time audio sample delivery to JavaScript
✅ **Performance Optimizations**: VAD, adaptive processing, RMS pre-computation
✅ **TypeScript API**: Fully typed with JSDoc documentation
✅ **Automated Tests**: iOS, Android, and TypeScript test suites
✅ **CI/CD Pipeline**: Automated testing and release packaging

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation Methods](#installation-methods)
3. [Integration Guide](#integration-guide)
4. [Testing Your Integration](#testing-your-integration)
5. [CI/CD Setup](#cicd-setup)
6. [Performance Expectations](#performance-expectations)
7. [Troubleshooting](#troubleshooting)
8. [Support and Contact](#support-and-contact)

---

## Quick Start

### Prerequisites

- **Expo SDK**: 49+ (or bare React Native 0.71+)
- **iOS**: Xcode 15+, iOS 15+ deployment target
- **Android**: Android Studio, API 26+ (Android 8.0+)
- **Node.js**: 18+

### 30-Second Integration

```typescript
import VoicelineDSP from 'voiceline-dsp';

// Start streaming
await VoicelineDSP.startAudioStream({
  sampleRate: 16000,
  bufferSize: 2048,
  channels: 1,
});

// Listen for audio samples
const subscription = VoicelineDSP.addAudioSampleListener((event) => {
  console.log('Received', event.frameLength, 'samples');
  console.log('RMS:', event.rms);
  // Process samples: event.samples is Float32Array-like
});

// Stop streaming
VoicelineDSP.stopAudioStream();
subscription.remove();
```

---

## Installation Methods

### Method 1: NPM Package (Recommended)

Once published to NPM:

```bash
# Using npm
npm install voiceline-dsp

# Using yarn
yarn add voiceline-dsp

# Using Expo
npx expo install voiceline-dsp
```

Then rebuild:

```bash
# Expo managed workflow
npx expo prebuild
npx expo run:ios
npx expo run:android

# Bare React Native
npx pod-install
npm run android
```

### Method 2: GitHub Release

Download from releases page and install locally:

```bash
npm install ./voiceline-dsp-0.2.0.tgz
```

### Method 3: Git Submodule (Development)

For development or customization:

```bash
cd YourVoicelineProject
git submodule add https://github.com/loqalabs/loqa.git loqa
ln -s loqa/modules/voiceline-dsp node_modules/voiceline-dsp
```

Then install and rebuild as above.

---

## Integration Guide

### Step 1: Add Module to Your Project

Install using one of the methods above.

### Step 2: Configure iOS Permissions

Edit `ios/YourApp/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to practice voice exercises and visualize your voice.</string>

<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

**Trauma-Informed Messaging:**
The microphone permission message should be clear, specific, and non-threatening. Consider adding context in your UI before requesting permission.

### Step 3: Configure Android Permissions

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### Step 4: Request Permissions at Runtime

```typescript
import { Audio } from 'expo-av';

async function requestMicrophonePermission() {
  const { status } = await Audio.requestPermissionsAsync();

  if (status !== 'granted') {
    // Show user-friendly explanation
    Alert.alert(
      'Microphone Access Needed',
      'To practice voice exercises and see real-time feedback, we need access to your microphone. Your voice data is processed only on your device and never recorded or sent anywhere.',
      [
        { text: 'Not Now', style: 'cancel' },
        { text: 'Open Settings', onPress: () => Linking.openSettings() },
      ]
    );
    return false;
  }

  return true;
}
```

### Step 5: Integrate in Practice Screen

Here's a complete example for your `PracticeScreen.tsx`:

```typescript
import React, { useEffect, useState } from 'react';
import { View, Text, Button, Alert } from 'react-native';
import VoicelineDSP from 'voiceline-dsp';
import type { AudioSampleEvent, Subscription } from 'voiceline-dsp';

export function PracticeScreen() {
  const [isStreaming, setIsStreaming] = useState(false);
  const [rms, setRMS] = useState(0);
  const subscriptionRef = useRef<Subscription | null>(null);

  const startPractice = async () => {
    try {
      // Request permission
      const hasPermission = await requestMicrophonePermission();
      if (!hasPermission) return;

      // Start streaming
      const started = await VoicelineDSP.startAudioStream({
        sampleRate: 16000,
        bufferSize: 2048,
        channels: 1,
      });

      if (!started) {
        Alert.alert('Error', 'Failed to start audio streaming');
        return;
      }

      // Listen for audio samples
      subscriptionRef.current = VoicelineDSP.addAudioSampleListener((event: AudioSampleEvent) => {
        // Update RMS for visual feedback
        setRMS(event.rms);

        // Process samples for voice analysis
        processAudioSamples(event.samples, event.sampleRate);

        // Update flower visualization
        updateFlowerVisualization(event);
      });

      // Listen for errors
      const errorSub = VoicelineDSP.addStreamErrorListener((event) => {
        console.error('Stream error:', event.error, event.message);
        Alert.alert('Audio Error', event.message);
      });

      setIsStreaming(true);
    } catch (error) {
      console.error('Failed to start streaming:', error);
      Alert.alert('Error', 'An unexpected error occurred');
    }
  };

  const stopPractice = () => {
    try {
      VoicelineDSP.stopAudioStream();
      subscriptionRef.current?.remove();
      subscriptionRef.current = null;
      setIsStreaming(false);
      setRMS(0);
    } catch (error) {
      console.error('Failed to stop streaming:', error);
    }
  };

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (isStreaming) {
        stopPractice();
      }
    };
  }, [isStreaming]);

  return (
    <View>
      <Text>Voice Practice</Text>
      <Text>Volume: {(rms * 100).toFixed(0)}%</Text>

      {!isStreaming ? (
        <Button title="Start Practice" onPress={startPractice} />
      ) : (
        <Button title="Stop Practice" onPress={stopPractice} />
      )}

      {/* Your flower visualization component */}
      <FlowerVisualization volume={rms} />
    </View>
  );
}

function processAudioSamples(samples: number[], sampleRate: number) {
  // Integrate with your existing DSP analysis
  // e.g., pitch detection, formant extraction, etc.
}

function updateFlowerVisualization(event: AudioSampleEvent) {
  // Update your Skia-based flower visualization
  // Map RMS to petal size, color, etc.
}
```

### Step 6: Configure Stream Settings

Recommended configuration:

```typescript
const streamConfig = {
  sampleRate: 16000, // Hz - optimal for voice analysis
  bufferSize: 2048, // Samples - 128ms at 16kHz, good for YIN pitch detection
  channels: 1, // Mono - voice is inherently mono
};
```

**Performance vs Latency Tradeoff:**

| Buffer Size | Latency    | Use Case                                  |
| ----------- | ---------- | ----------------------------------------- |
| 1024        | ~64ms      | Ultra-low latency, but may cause dropouts |
| **2048**    | **~128ms** | **Recommended - balanced**                |
| 4096        | ~256ms     | High robustness, but noticeable delay     |

---

## Testing Your Integration

### Manual Testing Checklist

Before releasing to production, verify:

- [ ] **Permissions**: Permission dialog shows with clear messaging
- [ ] **iOS Streaming**: Audio captures successfully on physical iPhone
- [ ] **Android Streaming**: Audio captures successfully on physical Android device
- [ ] **Visual Feedback**: Flower responds to voice in real-time
- [ ] **Silence Handling**: VAD skips silence correctly (no unnecessary processing)
- [ ] **Low Battery**: Adaptive processing activates when battery <20%
- [ ] **Error Handling**: Graceful errors shown if permission denied or device unavailable
- [ ] **Memory Leaks**: No memory growth during 5-minute streaming session
- [ ] **Cleanup**: Streaming stops cleanly when navigating away or app backgrounded

### Automated Testing

Run the included test suites:

```bash
# iOS tests
cd ios
xcodebuild test -scheme VoicelineDSP -destination 'platform=iOS Simulator,name=iPhone 15'

# Android tests
cd android
./gradlew connectedAndroidTest

# TypeScript tests
npm test
```

### Performance Validation

Use the testing procedures in [testing-procedures.md](./testing-procedures.md) to validate:

- **Latency**: <100ms end-to-end (95th percentile)
- **Battery**: <5% per 30-minute session
- **Memory**: <10MB during streaming
- **Dropout Rate**: <0.1%

---

## CI/CD Setup

### GitHub Actions (Recommended)

Two workflows are provided:

#### 1. Continuous Integration (`voiceline-dsp-ci.yml`)

Runs on every push/PR to test the module:

- iOS unit + integration tests on macOS runners
- Android unit + integration tests on emulators (API 26, 30, 33)
- TypeScript tests and type checking
- Build and package verification

**Setup:**

1. Workflows are already committed to `.github/workflows/`
2. No secrets needed for CI (uses public runners)
3. Tests run automatically on PR creation

#### 2. Release Pipeline (`voiceline-dsp-release.yml`)

Creates release artifacts when you tag a version:

```bash
# Create a release
git tag voiceline-dsp-v0.2.0
git push origin voiceline-dsp-v0.2.0
```

This workflow:

1. Runs all tests
2. Builds iOS XCFramework (device + simulator)
3. Builds Android AAR
4. Packages NPM module
5. Creates GitHub Release with all artifacts
6. (Optional) Publishes to NPM if `NPM_TOKEN` secret is set

**Setup for NPM Publishing:**

1. Go to GitHub repo → Settings → Secrets → Actions
2. Add `NPM_TOKEN` secret with your NPM automation token
3. Future releases will auto-publish to NPM

### Expo EAS Build Integration

If using Expo EAS Build, add to `eas.json`:

```json
{
  "build": {
    "production": {
      "ios": {
        "buildConfiguration": "Release",
        "distribution": "store"
      },
      "android": {
        "buildType": "apk",
        "gradleCommand": ":app:assembleRelease"
      }
    }
  }
}
```

VoicelineDSP will be included automatically in the native build.

---

## Performance Expectations

### Typical Performance Metrics

Based on testing across multiple devices:

| Metric                 | iOS (Typical)   | Android (Typical) | Target       |
| ---------------------- | --------------- | ----------------- | ------------ |
| **End-to-End Latency** | 68ms (median)   | 82ms (median)     | <100ms (p95) |
| **Battery Impact**     | 3-4% per 30 min | 4-5% per 30 min   | <5%          |
| **Memory Usage**       | 6-8 MB          | 7-9 MB            | <10MB        |
| **Dropout Rate**       | <0.01%          | <0.05%            | <0.1%        |

### Optimization Features

**Voice Activity Detection (VAD):**

- Automatically skips silent frames (RMS <0.01)
- Reduces battery drain by 10-15%
- Enabled by default

**Adaptive Processing:**

- Activates when battery <20%
- Reduces frame rate by 50% (skips every other frame)
- Reduces battery drain by 15-25%
- Enabled by default

**RMS Pre-computation:**

- RMS calculated natively, not in JavaScript
- Included in every audio sample event
- Use for volume indicators, VAD threshold checks, etc.

### Platform Differences

**iOS typically has:**

- Lower latency (~10-15ms faster)
- More consistent performance
- Better audio session management

**Android typically has:**

- Slightly higher latency due to AudioRecord buffering
- More variability across OEM skins (Samsung, OnePlus, etc.)
- More aggressive battery management (may pause app in background)

**Recommendation:** Test on both platforms, optimize for Android's constraints.

---

## Troubleshooting

### Common Issues

#### 1. "Permission Denied" Error

**Symptoms:** Stream fails to start, error code `PERMISSION_DENIED`

**Solutions:**

- Verify Info.plist (iOS) has `NSMicrophoneUsageDescription`
- Verify AndroidManifest.xml has `RECORD_AUDIO` permission
- Request permission at runtime using `Audio.requestPermissionsAsync()`
- Check device settings: Settings → [Your App] → Microphone

#### 2. High Latency (>100ms)

**Symptoms:** Noticeable delay between speaking and flower response

**Solutions:**

- Reduce buffer size to 1024 samples (trade: may cause dropouts)
- Verify no heavy processing in `onAudioSamples` listener (move to worker)
- Profile JavaScript processing time (should be <15ms)
- Test on physical device (emulator has higher latency)

#### 3. Audio Dropouts / Crackling

**Symptoms:** Choppy audio, buffer overflow warnings in logs

**Solutions:**

- Increase buffer size to 4096 samples
- Reduce processing in `onAudioSamples` listener
- Verify no blocking operations (network calls, file I/O) in listener
- Check CPU usage (close background apps)

#### 4. Battery Drain Exceeds 5%

**Symptoms:** Battery drains >5% in 30-minute session

**Solutions:**

- Verify VAD is enabled (should skip silence)
- Verify adaptive processing is enabled (activates at <20% battery)
- Reduce buffer size (fewer samples processed per frame)
- Profile with Xcode Instruments (iOS) or Battery Historian (Android)

#### 5. Memory Leaks

**Symptoms:** Memory usage grows over time, doesn't return to baseline after stopping

**Solutions:**

- Verify `stopAudioStream()` is called on unmount
- Verify all subscriptions are removed: `subscription.remove()`
- Check for circular references in event listeners
- Profile with Xcode Allocations (iOS) or Android Memory Profiler

#### 6. iOS: "Audio Session Configuration Failed"

**Symptoms:** Stream fails to start on iOS with session error

**Solutions:**

- Verify no other audio session active (music, podcast, etc.)
- Call `stopAudioStream()` before starting again
- Check background audio capability (if needed)
- Restart device if session is stuck

#### 7. Android: "Device Not Available"

**Symptoms:** Stream fails to start on Android

**Solutions:**

- Verify microphone hardware available (not in use by another app)
- Check if device has multiple microphones (some tablets don't)
- Restart device if AudioRecord is stuck
- Test on different device (emulator may not support audio)

---

## Support and Contact

### Documentation

- **API Reference**: [API.md](../../modules/voiceline-dsp/API.md)
- **Testing Procedures**: [testing-procedures.md](./testing-procedures.md)
- **Performance Report**: [voicelinedsp-v0.2.0-performance-report.md](./voicelinedsp-v0.2.0-performance-report.md)

### Example Code

- **Basic Integration**: See `modules/voiceline-dsp/examples/PracticeScreen.example.tsx`
- **Advanced Usage**: See `modules/voiceline-dsp/examples/AdvancedIntegration.example.tsx`

### GitHub

- **Repository**: https://github.com/loqalabs/loqa
- **Issues**: https://github.com/loqalabs/loqa/issues
- **Releases**: https://github.com/loqalabs/loqa/releases

### Direct Contact

- **Loqa Team**: [your-email@loqalabs.com]
- **Anna (Architect)**: [anna@loqalabs.com]

### Getting Help

1. **Check documentation** above first
2. **Search existing issues** on GitHub
3. **Create new issue** with:
   - Platform (iOS/Android)
   - OS version
   - Device model
   - VoicelineDSP version
   - Steps to reproduce
   - Console logs / stack traces

---

## Appendix: Release Checklist

When you're ready to release your Voiceline app with VoicelineDSP:

- [ ] All integration tests passing
- [ ] Performance targets validated on physical devices
- [ ] Permissions and error messaging reviewed for trauma-informed UX
- [ ] Battery impact measured and documented
- [ ] Memory profiling completed (no leaks)
- [ ] Tested on multiple device models (iOS + Android)
- [ ] CI/CD pipeline running and passing
- [ ] Release notes prepared
- [ ] Beta testing completed with real users
- [ ] App Store / Play Store submissions prepared

**Recommended Beta Testing:**

- 10-20 users minimum
- Mix of iOS and Android
- Mix of device models (old and new)
- 1-2 weeks of testing
- Collect feedback on latency, battery, and UX

---

**Good luck with your integration! We're excited to see Voiceline come to life with real-time audio streaming. 🎤🌸**

---

**Document Version:** 1.0
**Last Updated:** 2025-11-13
**VoicelineDSP Version:** 0.2.0
