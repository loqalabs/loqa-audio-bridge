# Integration Guide: @loqalabs/loqa-audio-bridge

Complete step-by-step guide for integrating real-time audio streaming into your Expo/React Native application.

**Target Integration Time**: < 30 minutes from installation to working audio stream

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Installation](#step-1-installation)
3. [Step 2: iOS Configuration](#step-2-ios-configuration)
4. [Step 3: Android Configuration](#step-3-android-configuration)
5. [Step 4: Basic Usage](#step-4-basic-usage)
6. [Step 5: Testing](#step-5-testing)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Topics](#advanced-topics)
   - [8.6 EAS Build (Cloud Builds)](#86-eas-build-cloud-builds)

---

## Prerequisites

Before integrating @loqalabs/loqa-audio-bridge, ensure your development environment meets these requirements:

### Required Software Versions

- **Expo SDK**: 52.0.0 or higher
- **React Native**: 0.72.0 or higher
- **Node.js**: 18.0.0 or higher
- **npm** or **yarn**: Latest stable version

### Platform-Specific Requirements

#### For iOS Development

- **macOS**: Required for iOS development
- **Xcode**: 14.0 or higher
- **CocoaPods**: 1.11.0 or higher (usually installed with Xcode)
- **iOS Deployment Target**: 13.4 or higher

#### For Android Development

- **Android Studio**: Latest stable version (Flamingo or higher recommended)
- **Android SDK**: API Level 24 (Android 7.0) or higher
- **JDK**: 17 or higher

### Verify Your Setup

Run these commands to verify prerequisites:

```bash
# Check Expo version
npx expo --version
# Should show: 52.0.0 or higher

# Check Node version
node --version
# Should show: v18.0.0 or higher

# Check if CocoaPods is installed (macOS only)
pod --version
# Should show: 1.11.0 or higher
```

**Expected Result**: All version checks pass with compatible versions.

---

## Step 1: Installation

### 1.1 Install the Package

From your Expo project root directory, run:

```bash
npx expo install @loqalabs/loqa-audio-bridge
```

**Why `npx expo install`?** This command ensures version compatibility with your Expo SDK version. It's preferred over `npm install` for Expo projects.

**Expected Output**:

```
✔ Added dependencies
```

### 1.2 Rebuild Native Code

Since this is a native module, you need to rebuild the native projects:

```bash
npx expo prebuild --clean
```

**What this does**:

- Generates iOS and Android native projects from your Expo configuration
- Links the native module to both platforms automatically (autolinking)
- The `--clean` flag ensures a fresh rebuild without cached artifacts

**Expected Output**:

```
✔ Config synced
✔ Created native directories
✔ Updated native directories
```

**⚠️ Important**: Run `npx expo prebuild --clean` after every package update.

### 1.3 Verify Installation

Run Expo Doctor to check for any integration issues:

```bash
npx expo-doctor
```

**Expected Output**:

```
✔ Check Expo config for common issues
✔ Check package.json for common issues
✔ Check dependencies for packages that should not be installed directly
✔ Check for common project setup issues
```

**If you see warnings**: Review the output carefully. Common warnings about peer dependencies are usually safe to ignore if versions are compatible.

**Expected Result**: No critical errors. Package should be listed in your `package.json` dependencies.

---

## Step 2: iOS Configuration

### 2.1 Add Microphone Permission

iOS requires you to declare why your app needs microphone access. Add this to your `app.json`:

```json
{
  "expo": {
    "name": "YourAppName",
    "ios": {
      "infoPlist": {
        "NSMicrophoneUsageDescription": "This app needs microphone access to record and analyze audio."
      }
    }
  }
}
```

**Customize the message**: Replace the description with text that explains your specific use case. This message will be shown to users when requesting permission.

**Examples of good permission messages**:

- "Record audio for speech-to-text transcription"
- "Capture audio for voice analysis and feedback"
- "Record audio during coaching sessions"

### 2.2 Why This is Required

**App Store Rejection Risk**: Apps that access the microphone without declaring `NSMicrophoneUsageDescription` will be **automatically rejected** by App Store review.

**User Trust**: Clear, honest permission messages build trust with your users.

### 2.3 Rebuild After Configuration

After modifying `app.json`, rebuild:

```bash
npx expo prebuild --clean
```

**Expected Result**: The `ios/YourApp/Info.plist` file will contain your microphone usage description.

---

## Step 3: Android Configuration

### 3.1 Add Microphone Permission

Add microphone permission to your `app.json`:

```json
{
  "expo": {
    "name": "YourAppName",
    "android": {
      "permissions": ["RECORD_AUDIO"]
    }
  }
}
```

**Note**: If you already have other permissions in the array, just add `"RECORD_AUDIO"` to the existing list.

### 3.2 Runtime Permission Handling (Android 6.0+)

On Android 6.0 (API 23) and higher, microphone permission **must be requested at runtime** before starting audio streaming.

#### Install expo-av for Permission Requests

```bash
npx expo install expo-av
```

#### Request Permission in Your Code

```typescript
import { Audio } from 'expo-av';

async function requestMicrophonePermission() {
  try {
    const { status } = await Audio.requestPermissionsAsync();

    if (status === 'granted') {
      console.log('Microphone permission granted');
      return true;
    } else {
      console.log('Microphone permission denied');
      return false;
    }
  } catch (error) {
    console.error('Permission request failed:', error);
    return false;
  }
}

// Use before starting audio stream
const hasPermission = await requestMicrophonePermission();
if (hasPermission) {
  // Safe to start audio streaming
}
```

### 3.3 Handling Permission Denial

If the user denies permission, guide them to enable it manually:

```typescript
import { Linking, Platform } from 'react-native';

function openAppSettings() {
  if (Platform.OS === 'android') {
    Linking.openSettings();
  } else if (Platform.OS === 'ios') {
    Linking.openURL('app-settings:');
  }
}

// Show user-friendly message
Alert.alert(
  'Microphone Permission Required',
  'Please enable microphone access in Settings to use audio features.',
  [
    { text: 'Cancel', style: 'cancel' },
    { text: 'Open Settings', onPress: openAppSettings },
  ]
);
```

### 3.4 Rebuild After Configuration

```bash
npx expo prebuild --clean
```

**Expected Result**: The `android/app/src/main/AndroidManifest.xml` file will contain the `RECORD_AUDIO` permission.

---

## Step 4: Basic Usage

### 4.1 Complete Working Example

Here's a full component demonstrating audio streaming with proper error handling and permission requests:

```typescript
import {
  startAudioStream,
  stopAudioStream,
  addAudioSampleListener,
} from '@loqalabs/loqa-audio-bridge';
import { useState, useEffect } from 'react';
import { View, Button, Text, Alert } from 'react-native';
import { Audio } from 'expo-av';

export default function AudioStreamingComponent() {
  const [isStreaming, setIsStreaming] = useState(false);
  const [rmsLevel, setRmsLevel] = useState(0);
  const [permissionGranted, setPermissionGranted] = useState(false);

  // Step 1: Request permission on mount
  useEffect(() => {
    async function requestPermission() {
      const { status } = await Audio.requestPermissionsAsync();
      setPermissionGranted(status === 'granted');
    }
    requestPermission();
  }, []);

  // Step 2: Listen for audio samples
  useEffect(() => {
    const subscription = addAudioSampleListener((event) => {
      // event.samples: number[] - raw audio data
      // event.rms: number - volume level (0.0 to 1.0)
      // event.sampleRate: number - configured sample rate
      // event.timestamp: number - platform timestamp

      setRmsLevel(event.rms);

      // Process audio samples here
      // Example: Send to speech recognition, analyze audio, etc.
    });

    // Cleanup: remove listener when component unmounts
    return () => {
      subscription.remove();
    };
  }, []);

  // Step 3: Start streaming
  async function handleStartStreaming() {
    try {
      // Verify permission first
      if (!permissionGranted) {
        Alert.alert('Permission Required', 'Microphone permission is required');
        return;
      }

      // Start audio stream with configuration
      await startAudioStream({
        sampleRate: 16000, // 16kHz (optimal for speech recognition)
        bufferSize: 2048, // ~8 Hz event rate (2048/16000 = 0.128s per event)
        channels: 1, // Mono audio
        vadEnabled: true, // Enable Voice Activity Detection for battery savings
        adaptiveProcessing: true, // Reduce frame rate on low battery
      });

      setIsStreaming(true);
    } catch (error) {
      console.error('Failed to start streaming:', error);
      Alert.alert('Error', 'Failed to start audio streaming');
    }
  }

  // Step 4: Stop streaming
  function handleStopStreaming() {
    try {
      stopAudioStream();
      setIsStreaming(false);
      setRmsLevel(0);
    } catch (error) {
      console.error('Failed to stop streaming:', error);
    }
  }

  // Step 5: Cleanup on unmount
  useEffect(() => {
    return () => {
      if (isStreaming) {
        stopAudioStream();
      }
    };
  }, [isStreaming]);

  return (
    <View style={{ padding: 20 }}>
      <Text>Microphone: {permissionGranted ? '✓ Granted' : '✗ Denied'}</Text>
      <Text>Status: {isStreaming ? 'Streaming' : 'Stopped'}</Text>
      <Text>Volume (RMS): {rmsLevel.toFixed(4)}</Text>

      <Button
        title="Start Streaming"
        onPress={handleStartStreaming}
        disabled={isStreaming || !permissionGranted}
      />

      <Button title="Stop Streaming" onPress={handleStopStreaming} disabled={!isStreaming} />
    </View>
  );
}
```

### 4.2 Configuration Options Explained

#### Sample Rate

```typescript
sampleRate: 16000; // Options: 8000, 16000, 32000, 44100, 48000
```

**Recommended values**:

- **8000 Hz**: Voice communication, minimal bandwidth
- **16000 Hz**: Speech recognition (optimal quality/performance balance)
- **44100 Hz**: Music recording, high fidelity audio
- **48000 Hz**: Professional audio applications

**Trade-offs**: Higher sample rates provide better quality but increase CPU usage, battery consumption, and data size.

#### Buffer Size

```typescript
bufferSize: 2048; // Options: 512, 1024, 2048, 4096, 8192
```

**Event rate calculation**: `bufferSize / sampleRate = seconds per event`

- 2048 @ 16kHz = 0.128s = ~8 Hz event rate
- 4096 @ 16kHz = 0.256s = ~4 Hz event rate

**Trade-offs**:

- **Smaller buffers** (512-1024): Lower latency, higher CPU usage, more events per second
- **Larger buffers** (4096-8192): Lower CPU usage, higher latency, fewer events per second

**Recommended**: 2048 (good balance for most applications)

#### Voice Activity Detection (VAD)

```typescript
vadEnabled: true; // Default: true
```

**What it does**: Skips processing silent audio frames (RMS < 0.01) to save battery.

**Battery savings**: 30-50% reduction during silence (e.g., pauses between speech)

**When to disable**: Real-time audio visualization or when you need continuous samples

#### Adaptive Processing

```typescript
adaptiveProcessing: true; // Default: true
```

**What it does**: Automatically reduces frame rate by 50% when battery < 20%

**Power savings**: Additional 20-30% battery savings during low battery conditions

**User experience**: Minimal impact on most use cases (4 Hz still responsive)

### 4.3 Expected Outcome

After implementing the code above:

1. **On mount**: App requests microphone permission
2. **User grants permission**: "Microphone: ✓ Granted" appears
3. **Press "Start Streaming"**:
   - Status changes to "Streaming"
   - RMS value updates ~8 times per second
   - Audio samples are captured and delivered via listener
4. **Speak into microphone**: RMS value increases (0.01-0.5 typical for speech)
5. **Press "Stop Streaming"**: Status returns to "Stopped", RMS resets to 0

**Verification**: RMS value should change when you speak and drop during silence.

---

## Step 5: Testing

### 5.1 iOS Testing

#### iOS Simulator Limitations

**⚠️ CRITICAL**: iOS Simulator **does not have microphone support**. Audio streaming will fail with error `DEVICE_NOT_AVAILABLE`.

**You must test on a physical iOS device.**

#### Testing on Physical iOS Device

1. **Connect device** via USB or Wi-Fi debugging
2. **Run**:
   ```bash
   npx expo run:ios --device
   ```
3. **Grant permission** when prompted
4. **Expected behavior**:
   - Microphone permission dialog appears on first launch
   - After granting, audio streaming starts successfully
   - RMS level updates when speaking
   - No crashes or console errors

#### Common iOS Issues

**"Module not found" error**: Run `npx expo prebuild --clean && cd ios && pod install && cd ..`

**Permission denied**: Check `ios/YourApp/Info.plist` contains `NSMicrophoneUsageDescription`

### 5.2 Android Testing

#### Android Emulator Setup

Android Emulator has virtual microphone support:

1. **Start emulator** from Android Studio
2. **Enable virtual microphone**:
   - Click "..." (More) in emulator toolbar
   - Go to "Microphone" tab
   - Select "Virtual microphone uses host audio input"
3. **Allow host microphone**: Grant permission if prompted by OS

#### Testing on Physical Android Device

1. **Enable USB debugging** on device
2. **Connect** via USB
3. **Run**:
   ```bash
   npx expo run:android --device
   ```
4. **Grant permission** when prompted

#### Common Android Issues

**"Duplicate class" error**: Run `cd android && ./gradlew clean && cd ..` then rebuild

**Permission denied**: Verify `android/app/src/main/AndroidManifest.xml` contains `RECORD_AUDIO`

### 5.3 Expected Behavior Checklist

Use this checklist to verify successful integration:

- [ ] App launches without crashes
- [ ] Permission request appears on first launch
- [ ] After granting permission, "Start Streaming" button is enabled
- [ ] Pressing "Start Streaming" changes status to "Streaming"
- [ ] RMS value updates continuously (~8 times per second)
- [ ] Speaking into microphone increases RMS value (0.01-0.5 range)
- [ ] Silence decreases RMS value (< 0.01)
- [ ] Pressing "Stop Streaming" changes status to "Stopped"
- [ ] RMS value stops updating after stopping
- [ ] No console errors or warnings
- [ ] Works on both iOS device and Android device/emulator

**If all checkboxes pass**: Integration successful! ✅

---

## Troubleshooting

This section covers 90% of common integration issues based on v0.2.0 user feedback and real-world integrations.

### Issue 1: "Cannot find native module 'LoqaAudioBridge'"

**Symptom**: App crashes with error:

```
Error: Cannot find native module 'LoqaAudioBridge'
```

**Root Cause**: Autolinking failed to register the native module.

**Solution**:

1. **Clean rebuild**:

   ```bash
   npx expo prebuild --clean
   ```

2. **For iOS, install CocoaPods**:

   ```bash
   cd ios
   pod install
   cd ..
   ```

3. **Verify autolinking** by checking:

   - iOS: `ios/Pods/Pods.xcodeproj` should contain `LoqaAudioBridge` target
   - Android: `android/app/build.gradle` should reference the module

4. **Rebuild**:
   ```bash
   npx expo run:ios --device  # or
   npx expo run:android --device
   ```

**Validation**: App should launch without "Cannot find module" error.

---

### Issue 2: iOS CocoaPods Errors

**Symptom**: Pod install fails with errors like:

```
[!] Unable to find a specification for 'LoqaAudioBridge'
```

**Solution**:

1. **Clear CocoaPods cache**:

   ```bash
   cd ios
   pod cache clean --all
   pod deintegrate
   pod install
   cd ..
   ```

2. **Update CocoaPods**:

   ```bash
   sudo gem install cocoapods
   ```

3. **Clean Expo cache**:
   ```bash
   npx expo prebuild --clean
   ```

**Validation**: `pod install` completes without errors.

---

### Issue 3: Android Gradle "Duplicate class" Errors

**Symptom**: Android build fails with:

```
Duplicate class expo.modules.loqaaudiobridge.LoqaAudioBridgeModule found in modules
```

**Root Cause**: Stale build artifacts or multiple versions of the module.

**Solution**:

1. **Clean Gradle cache**:

   ```bash
   cd android
   ./gradlew clean
   cd ..
   ```

2. **Delete build directories**:

   ```bash
   rm -rf android/app/build
   rm -rf android/build
   ```

3. **Rebuild**:
   ```bash
   npx expo prebuild --clean
   npx expo run:android --device
   ```

**Validation**: Android build completes without duplicate class errors.

---

### Issue 4: Microphone Permission Denied (Runtime)

**Symptom**: Audio streaming fails with error `PERMISSION_DENIED`.

**iOS Solution**:

1. **Check Info.plist**:

   - Open `ios/YourApp/Info.plist`
   - Verify `NSMicrophoneUsageDescription` key exists

2. **Reset permissions** (if testing repeatedly):

   - Settings → Privacy & Security → Microphone → YourApp → Toggle off/on

3. **Rebuild** after changing `app.json`:
   ```bash
   npx expo prebuild --clean
   ```

**Android Solution**:

1. **Verify manifest**:

   - Open `android/app/src/main/AndroidManifest.xml`
   - Confirm `<uses-permission android:name="android.permission.RECORD_AUDIO" />`

2. **Request permission at runtime**:

   ```typescript
   import { Audio } from 'expo-av';
   const { status } = await Audio.requestPermissionsAsync();
   ```

3. **Reset permissions** (if testing):
   - Settings → Apps → YourApp → Permissions → Microphone → Toggle

**Validation**: Permission request dialog appears, and after granting, streaming starts successfully.

---

### Issue 5: Audio Events Not Firing

**Symptom**: `addAudioSampleListener` callback never gets called, even though streaming status is "active".

**Possible Causes**:

1. **Invalid configuration** (sample rate/buffer size mismatch)
2. **VAD filtering all audio** (RMS threshold too high)
3. **Listener registered after stream started**

**Solution**:

1. **Validate configuration**:

   ```typescript
   await startAudioStream({
     sampleRate: 16000, // Must be supported: 8000, 16000, 32000, 44100, 48000
     bufferSize: 2048, // Must be power of 2 on iOS: 512, 1024, 2048, 4096, 8192
     channels: 1, // 1 or 2
   });
   ```

2. **Disable VAD temporarily** (for testing):

   ```typescript
   await startAudioStream({
     vadEnabled: false, // Disables silence filtering
   });
   ```

3. **Register listener BEFORE starting stream**:

   ```typescript
   // ✅ Correct order
   const subscription = addAudioSampleListener((event) => {
     console.log('RMS:', event.rms);
   });
   await startAudioStream({ sampleRate: 16000 });

   // ❌ Wrong order (might miss initial events)
   await startAudioStream({ sampleRate: 16000 });
   const subscription = addAudioSampleListener((event) => {
     console.log('RMS:', event.rms);
   });
   ```

**Validation**: Console logs show "RMS: 0.XXXX" values ~8 times per second.

---

### Issue 6: High CPU Usage or Battery Drain

**Symptom**: App uses excessive CPU (>10%) or drains battery quickly.

**Causes**:

- Buffer size too small (generating too many events per second)
- VAD disabled (processing all audio including silence)
- Sample rate too high for use case

**Solution**:

1. **Increase buffer size** (reduce event rate):

   ```typescript
   bufferSize: 4096; // Reduces event rate from ~8 Hz to ~4 Hz
   ```

2. **Enable VAD** (skip silent frames):

   ```typescript
   vadEnabled: true; // 30-50% battery savings during silence
   ```

3. **Lower sample rate** (if quality allows):

   ```typescript
   sampleRate: 8000; // Half the data of 16kHz
   ```

4. **Enable adaptive processing**:
   ```typescript
   adaptiveProcessing: true; // Auto-reduces rate on low battery
   ```

**Validation**: CPU usage should be 2-5% during active streaming, battery drain 3-8% per hour with VAD enabled.

---

### Issue 7: "App Store Rejection - Missing Permission Description"

**Symptom**: App rejected during App Store review with message about missing microphone permission.

**Root Cause**: `NSMicrophoneUsageDescription` not present in `Info.plist`.

**Solution**:

1. **Add to app.json** (if not already present):

   ```json
   {
     "expo": {
       "ios": {
         "infoPlist": {
           "NSMicrophoneUsageDescription": "This app needs microphone access to record and analyze audio."
         }
       }
     }
   }
   ```

2. **Rebuild**:

   ```bash
   npx expo prebuild --clean
   ```

3. **Verify** before resubmission:
   - Open `ios/YourApp/Info.plist` in Xcode
   - Confirm "Privacy - Microphone Usage Description" key exists
   - Confirm description is user-friendly and explains your use case

**Validation**: App passes App Store review.

---

## Advanced Topics

### 8.1 Voice Activity Detection (VAD) Configuration

#### What is VAD?

Voice Activity Detection automatically detects silence and skips processing silent audio frames, saving battery life.

**Default behavior**: Frames with RMS < 0.01 are considered silent and not delivered to listeners.

#### Customizing VAD Threshold

While the package doesn't expose threshold configuration in v0.3.0, you can implement custom VAD in your listener:

```typescript
addAudioSampleListener((event) => {
  const customThreshold = 0.02; // Stricter than default 0.01

  if (event.rms < customThreshold) {
    // Skip silent frame
    return;
  }

  // Process audio
  processAudio(event.samples);
});
```

#### VAD Use Cases

**Enable VAD (vadEnabled: true)** for:

- Speech recognition applications (skip silence between words)
- Voice commands (save battery when user not speaking)
- Podcast recording (reduce file size by removing silence)

**Disable VAD (vadEnabled: false)** for:

- Real-time audio visualization (need continuous waveform)
- Music recording (silence is part of the composition)
- Environmental sound monitoring (silence is meaningful data)

**Battery Impact**:

- VAD enabled: 3-8% battery per hour
- VAD disabled: 5-12% battery per hour
- **Savings**: 30-50% reduction during typical speech patterns

---

### 8.2 Battery Optimization and Adaptive Processing

#### Adaptive Processing

Adaptive processing automatically reduces frame rate by 50% when device battery drops below 20%.

**How it works**:

```
Normal battery (>20%):  8 Hz event rate (2048 @ 16kHz)
Low battery (<20%):     4 Hz event rate (skips every 2nd frame)
```

**Power savings**: Additional 20-30% battery reduction during low battery conditions.

#### Detecting Adaptive Mode

Listen for status changes:

```typescript
import { addStreamStatusListener } from '@loqalabs/loqa-audio-bridge';

addStreamStatusListener((event) => {
  if (event.status === 'battery_optimized') {
    console.log('Frame rate reduced due to low battery');
    // Optionally notify user or adjust UI
  }
});
```

#### Manual Battery Optimization

For maximum battery efficiency, combine multiple strategies:

```typescript
await startAudioStream({
  sampleRate: 8000, // Lower sample rate = less data
  bufferSize: 4096, // Larger buffer = fewer events
  vadEnabled: true, // Skip silence
  adaptiveProcessing: true, // Auto-reduce on low battery
});
```

**Estimated battery usage** with above config:

- Active speaking: 2-4% per hour
- Mostly silent: 1-2% per hour

---

### 8.3 Buffer Size Tuning (Latency vs. CPU Trade-off)

#### Understanding the Trade-off

**Buffer size affects two key metrics**:

1. **Latency**: Time between sound occurring and your code receiving it
2. **CPU Usage**: Processing overhead from frequent events

#### Buffer Size Comparison Table

| Buffer Size | Sample Rate | Event Rate | Latency | CPU Usage       | Use Case                      |
| ----------- | ----------- | ---------- | ------- | --------------- | ----------------------------- |
| 512         | 16kHz       | ~31 Hz     | 32ms    | High (5-8%)     | Real-time pitch detection     |
| 1024        | 16kHz       | ~16 Hz     | 64ms    | Medium (3-6%)   | Interactive audio visualizer  |
| 2048        | 16kHz       | ~8 Hz      | 128ms   | Low (2-5%)      | Speech recognition (balanced) |
| 4096        | 16kHz       | ~4 Hz      | 256ms   | Very Low (1-3%) | Podcast recording             |
| 8192        | 16kHz       | ~2 Hz      | 512ms   | Minimal (<2%)   | Batch audio processing        |

**Calculation**: `Latency (ms) = (bufferSize / sampleRate) * 1000`

#### Choosing Buffer Size

**Low latency required** (< 100ms): Use 512-2048

- Real-time audio effects
- Interactive music applications
- Live pitch correction

**CPU efficiency priority**: Use 4096-8192

- Background audio recording
- Batch speech transcription
- Non-interactive monitoring

**Balanced (recommended)**: Use 2048

- Most speech recognition use cases
- Voice commands
- General audio streaming

#### iOS Platform Constraint

**⚠️ iOS requires power-of-2 buffer sizes**: 512, 1024, 2048, 4096, 8192

Android is more flexible but using power-of-2 ensures cross-platform compatibility.

---

### 8.4 Multi-Channel (Stereo) Configuration

#### Enabling Stereo Capture

```typescript
await startAudioStream({
  sampleRate: 16000,
  bufferSize: 2048,
  channels: 2, // Stereo
});
```

#### Processing Stereo Samples

Stereo audio samples are interleaved (L, R, L, R, ...):

```typescript
addAudioSampleListener((event) => {
  if (event.channelCount === 2) {
    const leftChannel: number[] = [];
    const rightChannel: number[] = [];

    // Separate left and right channels
    for (let i = 0; i < event.samples.length; i += 2) {
      leftChannel.push(event.samples[i]); // Even indices = left
      rightChannel.push(event.samples[i + 1]); // Odd indices = right
    }

    console.log('Left RMS:', calculateRMS(leftChannel));
    console.log('Right RMS:', calculateRMS(rightChannel));
  }
});

function calculateRMS(samples: number[]): number {
  const sumSquares = samples.reduce((sum, sample) => sum + sample * sample, 0);
  return Math.sqrt(sumSquares / samples.length);
}
```

#### Stereo Use Cases

**When to use stereo**:

- Spatial audio recording (left/right positioning)
- Music production applications
- 3D audio analysis
- Dual-microphone noise cancellation

**When to use mono** (channels: 1):

- Speech recognition (most models expect mono)
- Voice commands
- Transcription
- General audio analysis

**Note**: Stereo doubles data size and CPU usage. Use only when needed.

---

### 8.5 Error Handling Best Practices

#### Comprehensive Error Handling

```typescript
import { addStreamErrorListener, StreamErrorCode } from '@loqalabs/loqa-audio-bridge';

addStreamErrorListener((event) => {
  switch (event.error) {
    case 'PERMISSION_DENIED':
      // User denied microphone permission
      Alert.alert(
        'Permission Required',
        'Microphone access is required. Please enable it in Settings.',
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'Open Settings', onPress: () => Linking.openSettings() },
        ]
      );
      break;

    case 'DEVICE_NOT_AVAILABLE':
      // Microphone hardware not available (e.g., iOS Simulator, hardware failure)
      Alert.alert('Error', 'Microphone not available. Please test on a physical device.');
      break;

    case 'ENGINE_START_FAILED':
      // Audio engine failed to start (rare, usually transient)
      Alert.alert('Error', 'Failed to start audio. Please try again.');
      break;

    case 'SESSION_CONFIG_FAILED':
      // iOS audio session configuration failed
      console.error('iOS audio session error:', event.message);
      break;

    case 'BUFFER_OVERFLOW':
      // Audio processing can't keep up (very rare)
      console.warn('Buffer overflow - consider increasing buffer size');
      break;

    default:
      console.error('Unknown error:', event.error, event.message);
  }
});
```

#### Graceful Degradation

```typescript
async function startStreamingWithFallback() {
  const configs = [
    { sampleRate: 48000, bufferSize: 2048 }, // Ideal config
    { sampleRate: 16000, bufferSize: 2048 }, // Fallback 1
    { sampleRate: 8000, bufferSize: 4096 }, // Fallback 2
  ];

  for (const config of configs) {
    try {
      await startAudioStream(config);
      console.log('Started with config:', config);
      return true;
    } catch (error) {
      console.warn('Config failed:', config, error);
    }
  }

  Alert.alert('Error', 'Could not start audio streaming with any configuration');
  return false;
}
```

---

### 8.6 EAS Build (Cloud Builds)

#### Overview

**Expo Application Services (EAS) Build** enables cloud-based iOS and Android builds without requiring local Xcode or Android Studio installations. The `@loqalabs/loqa-audio-bridge` package works seamlessly with EAS Build with **zero special configuration required**.

**Key Benefits**:

- Build iOS apps without owning a Mac
- Build Android apps without Android Studio setup
- Consistent build environment (no "works on my machine" issues)
- Parallel builds for faster iteration
- Build artifacts stored in cloud

#### Prerequisites

1. **Expo Account**: Sign up at [expo.dev](https://expo.dev)
2. **EAS CLI**: Install globally

   ```bash
   npm install -g eas-cli
   ```

3. **Authentication**: Login to your Expo account

   ```bash
   eas login
   ```

#### Step-by-Step Setup

##### Step 1: Install the Package

```bash
npx expo install @loqalabs/loqa-audio-bridge
```

The package will be added to your `package.json` dependencies.

##### Step 2: Configure EAS Build

Run the configuration command:

```bash
eas build:configure
```

This creates an `eas.json` file in your project root. The default configuration works perfectly:

```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "production": {
      "distribution": "store"
    }
  }
}
```

No modifications needed! The module autolinks automatically in the cloud environment.

##### Step 3: Add Permissions (if not already done)

Ensure your `app.json` includes microphone permissions:

```json
{
  "expo": {
    "ios": {
      "infoPlist": {
        "NSMicrophoneUsageDescription": "This app needs microphone access for audio recording."
      }
    },
    "android": {
      "permissions": ["RECORD_AUDIO"]
    }
  }
}
```

##### Step 4: Trigger iOS Build

```bash
eas build --platform ios --profile development
```

What happens:

1. EAS uploads your project to the cloud
2. Installs dependencies (including `@loqalabs/loqa-audio-bridge`)
3. Runs `npx expo prebuild` (autolinking happens here)
4. Runs `pod install` (CocoaPods links native iOS code)
5. Compiles with Xcodebuild
6. Generates `.ipa` file

Build logs will show:

```text
[iOS] Installing pods...
Auto-linked 'LoqaAudioBridge' module
```

##### Step 5: Trigger Android Build

```bash
eas build --platform android --profile development
```

What happens:

1. EAS uploads your project to cloud
2. Installs dependencies
3. Runs `npx expo prebuild` (autolinking happens here)
4. Gradle detects and links `loqa-audio-bridge` module
5. Compiles with Gradle
6. Generates `.apk` file

Build logs will show:

```text
[Android] Configuring build...
Autolinking found loqa-audio-bridge
```

#### Downloading and Testing Builds

Once builds complete (typically 10-20 minutes), download the artifacts:

**iOS (.ipa)**:

1. Navigate to [expo.dev/accounts/[your-account]/projects/[your-project]/builds](https://expo.dev)
2. Find your iOS build, click "Download"
3. Install on physical device via Xcode or TestFlight

**Android (.apk)**:

1. Download `.apk` from EAS dashboard
2. Transfer to Android device
3. Enable "Install from Unknown Sources" in device settings
4. Tap `.apk` to install

**Testing**: Launch the app and verify audio streaming works identically to local builds.

#### Troubleshooting EAS Builds

##### Issue: Build fails with "Module not found: @loqalabs/loqa-audio-bridge"

Cause: Package not in `package.json` dependencies

Solution:

```bash
npx expo install @loqalabs/loqa-audio-bridge
git add package.json package-lock.json
git commit -m "Add loqa-audio-bridge dependency"
eas build --platform ios
```

---

##### Issue: iOS build fails with "LoqaAudioBridge.podspec not found"

Cause: Corrupted npm package or network issue during install

Solution:

1. Verify package installed correctly:

   ```bash
   npm ls @loqalabs/loqa-audio-bridge
   ```

2. If missing, reinstall:

   ```bash
   npm install @loqalabs/loqa-audio-bridge --force
   ```

3. Retry build

---

##### Issue: Android build fails with Gradle errors

Cause: Gradle cache issues or dependency conflicts

Solution:

Add to `eas.json`:

```json
{
  "build": {
    "development": {
      "android": {
        "gradleCommand": ":app:assembleDebug --no-daemon --console=plain"
      }
    }
  }
}
```

Retry build with clean cache:

```bash
eas build --platform android --clear-cache
```

---

##### Issue: Build succeeds but app crashes on device

Cause: Missing runtime permissions or incompatible Expo SDK version

Solution:

1. Check Expo SDK version compatibility:

   ```bash
   npx expo-doctor
   ```

2. Verify microphone permissions in `app.json` (see Step 3 above)
3. Check device logs:
   - iOS: Xcode → Window → Devices and Simulators → Select device → View logs
   - Android: `adb logcat`

#### Production Builds for App Stores

For production builds destined for Apple App Store or Google Play Store:

```bash
# iOS (App Store)
eas build --platform ios --profile production

# Android (Google Play)
eas build --platform android --profile production
```

**Important**: Production builds require:

- Apple Developer account ($99/year) for iOS
- Google Play Developer account ($25 one-time) for Android
- Proper code signing certificates configured in EAS

See [EAS Submit documentation](https://docs.expo.dev/submit/introduction/) for app store submission.

#### EAS Build Pricing

**Free Tier** (sufficient for testing):

- Limited builds per month
- Shared build queue (may wait for available runner)

**Paid Plans**:

- Priority build queue
- Unlimited builds
- Faster build servers

See [pricing](https://expo.dev/pricing) for current rates.

#### Verification Checklist

After successful EAS build:

- [ ] Build completed without errors (check EAS dashboard)
- [ ] Download `.ipa` (iOS) or `.apk` (Android)
- [ ] Install on physical device
- [ ] App launches successfully
- [ ] Microphone permission prompt appears
- [ ] Grant permission
- [ ] Audio streaming functionality works
- [ ] RMS values update during speech
- [ ] No crashes or errors in device logs

**Success Criteria**: Audio streaming works identically to local development builds.

---

## Additional Resources

- **[README.md](./README.md)**: Quick start guide and feature overview
- **[API.md](./API.md)**: Complete API reference documentation
- **[Example App](./example)**: Working Expo app demonstrating all features
- **[GitHub Issues](https://github.com/loqalabs/loqa/issues)**: Report bugs or request features

---

## Integration Support

If you encounter issues not covered in this guide:

1. **Check the [Troubleshooting](#troubleshooting) section** - covers 90% of common issues
2. **Review the [Example App](./example)** - working reference implementation
3. **Search [GitHub Issues](https://github.com/loqalabs/loqa/issues)** - may already be reported/solved
4. **Create a new issue** with:
   - Expo SDK version (`npx expo --version`)
   - React Native version (from `package.json`)
   - Platform (iOS/Android) and OS version
   - Full error message and stack trace
   - Steps to reproduce

**Expected Response Time**: 1-3 business days for community support.

---

**Document Version**: 1.0.0
**Package Version**: 0.3.0
**Last Updated**: 2025-11-18
