# iOS Audio Streaming Implementation Design

**Platform:** iOS 13.0+
**Frameworks:** AVFoundation (AVAudioEngine, AVAudioSession)
**Language:** Swift 5.0+
**Module Type:** Expo Module
**Status:** Design Document
**Last Updated:** 2025-11-12

## Overview

This document specifies the iOS implementation approach for VoicelineDSP v0.2.0 real-time audio streaming using AVAudioEngine and AVAudioSession. The implementation captures audio from the device microphone, converts to Float32 format, and delivers samples to JavaScript via Expo EventEmitter.

### Key Technologies

- **AVAudioEngine:** High-level audio processing graph (input node tap for sample capture)
- **AVAudioSession:** Audio session management (configuration, interruption handling)
- **AVAudioPCMBuffer:** Audio buffer representation (converted to Float32 array)
- **Expo EventEmitter:** Event delivery to JavaScript (type-safe subscriptions)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS Audio Stack                         │
└─────────────────────────────────────────────────────────────────┘

   Microphone
      │
      ▼
┌──────────────────┐
│  AVAudioSession  │  Configure audio session (.record category)
│  Configuration   │  Handle interruptions (phone calls, other apps)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  AVAudioEngine   │  Audio processing graph
│  Input Node      │  Sample rate, format, buffer size
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  installTap()    │  Register callback for audio buffers
│  Callback        │  Called on audio thread (real-time priority)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  AVAudioPCM      │  Audio buffer (Int16 or Float32 format)
│  Buffer          │  Convert to normalized Float32 array
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Expo Module     │  Dispatch to main queue
│  EventEmitter    │  Emit "onAudioSample" event
└────────┬─────────┘
         │
         ▼
   JavaScript Layer
   (AudioSampleEvent)
```

---

## Implementation Components

### 1. AVAudioSession Configuration

AVAudioSession manages the audio behavior of the app (category, mode, options).

```swift
import AVFoundation

/// Configure AVAudioSession for audio recording
func configureAudioSession() throws {
    let audioSession = AVAudioSession.sharedInstance()

    // Set category to .record (input-only, no playback)
    // Alternative: .playAndRecord if simultaneous playback needed
    try audioSession.setCategory(
        .record,
        mode: .measurement,  // Optimized for accurate measurement
        options: [.allowBluetooth]  // Allow Bluetooth microphones
    )

    // Activate the audio session
    try audioSession.setActive(true, options: [])

    print("✅ AVAudioSession configured: category=.record, mode=.measurement")
}
```

**Configuration Details:**

| Parameter    | Value             | Rationale                                                     |
| ------------ | ----------------- | ------------------------------------------------------------- |
| **Category** | `.record`         | Input-only mode (no playback)                                 |
| **Mode**     | `.measurement`    | Optimized for accurate measurement, minimal signal processing |
| **Options**  | `.allowBluetooth` | Enable Bluetooth microphones (AirPods, headsets)              |

**Alternative Configurations:**

- **Category `.playAndRecord`:** If simultaneous audio playback needed (e.g., metronome, backing track)
- **Mode `.voiceChat`:** If voice communication optimizations preferred (echo cancellation, AGC)
- **Option `.defaultToSpeaker`:** Route audio to speaker instead of receiver

**Error Handling:**

```swift
do {
    try configureAudioSession()
} catch let error as NSError {
    // Common errors:
    // - Code 561015905 ('!cat'): Category not supported
    // - Code 560030580 ('!act'): Session activation failed
    print("❌ AVAudioSession configuration failed: \(error.localizedDescription)")
    throw StreamError.sessionConfigFailed(error.localizedDescription)
}
```

---

### 2. AVAudioEngine Setup

AVAudioEngine provides a high-level audio processing graph. We use the input node to capture microphone audio.

```swift
import AVFoundation

class AudioStreamManager {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?

    /// Initialize and configure AVAudioEngine
    func setupAudioEngine(config: StreamConfig) throws {
        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else {
            throw StreamError.engineInitFailed("Failed to create AVAudioEngine")
        }

        // Get input node (represents microphone)
        inputNode = engine.inputNode

        print("✅ AVAudioEngine initialized")
        print("   Input format: \(inputNode?.inputFormat(forBus: 0) ?? "unknown")")
    }
}
```

**Input Node Details:**

- **Bus 0:** Default input bus (microphone)
- **Format:** Determined by AVAudioSession (sample rate, channel count)
- **Hardware Format:** Typically 48kHz stereo (device dependent)

**Format Conversion:**

AVAudioEngine automatically converts between hardware format and requested format when installing tap.

---

### 3. Input Node Tap Installation

Install a tap on the input node to receive audio buffers in real-time.

```swift
import AVFoundation

extension AudioStreamManager {
    /// Install tap on input node to capture audio buffers
    func installTap(config: StreamConfig, callback: @escaping (AVAudioPCMBuffer) -> Void) throws {
        guard let inputNode = inputNode else {
            throw StreamError.engineNotInitialized("Input node not available")
        }

        // Define desired audio format
        // Force to mono (1 channel) if config specifies mono
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,  // Float32 format
            sampleRate: Double(config.sampleRate),
            channels: AVAudioChannelCount(config.channels),
            interleaved: false  // Non-interleaved (better performance)
        ) else {
            throw StreamError.invalidFormat("Failed to create audio format")
        }

        // Install tap on bus 0 with specified buffer size and format
        inputNode.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(config.bufferSize),
            format: format
        ) { [weak self] (buffer, time) in
            // Called on audio thread (real-time priority)
            // Keep processing minimal to avoid glitches
            callback(buffer)
        }

        print("✅ Tap installed: bufferSize=\(config.bufferSize), format=\(format)")
    }
}
```

**Tap Callback Details:**

- **Thread:** Called on audio I/O thread (real-time priority)
- **Frequency:** Every `bufferSize / sampleRate` seconds (e.g., 128ms for 2048 @ 16kHz)
- **Parameters:**
  - `buffer: AVAudioPCMBuffer` - Audio samples
  - `time: AVAudioTime` - Sample time (host time, sample time, audio time)

**Performance Considerations:**

⚠️ **Keep tap callback fast** - Audio thread is real-time priority, blocking causes audio glitches
✅ **Minimize processing** - Convert buffer, emit event, return quickly
✅ **Dispatch to main queue** - Perform heavy processing on main/background queue

---

### 4. Audio Buffer Conversion

Convert AVAudioPCMBuffer (Float32 or Int16) to normalized Float32 array for JavaScript.

```swift
import AVFoundation

extension AudioStreamManager {
    /// Convert AVAudioPCMBuffer to normalized Float32 array
    func convertBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else {
            print("⚠️ No float channel data available")
            return []
        }

        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        // If mono, use channel 0 directly
        if channelCount == 1 {
            let samples = Array(
                UnsafeBufferPointer(start: channelData[0], count: frameLength)
            )
            return samples
        }

        // If stereo, convert to mono by averaging channels
        var monoSamples = [Float](repeating: 0.0, count: frameLength)
        for frame in 0..<frameLength {
            var sum: Float = 0.0
            for channel in 0..<channelCount {
                sum += channelData[channel][frame]
            }
            monoSamples[frame] = sum / Float(channelCount)
        }

        return monoSamples
    }

    /// Normalize samples to [-1.0, 1.0] range
    /// (Float32 format is already normalized, but explicit for clarity)
    func normalizeSamples(_ samples: [Float]) -> [Float] {
        // AVAudioPCMBuffer Float32 format is already normalized [-1.0, 1.0]
        // This function is a no-op but included for API consistency
        return samples
    }
}
```

**Format Notes:**

- **Float32 Format:** Already normalized to [-1.0, 1.0] range
- **Int16 Format:** Would require conversion: `Float(int16Value) / 32768.0`
- **Stereo to Mono:** Average all channels to produce single channel

**Optimization:**

For better performance with large buffers, consider using `vDSP_meanv` from Accelerate framework for averaging:

```swift
import Accelerate

func convertStereoToMono(_ buffer: AVAudioPCMBuffer) -> [Float] {
    guard let channelData = buffer.floatChannelData else { return [] }
    let frameLength = Int(buffer.frameLength)
    let channelCount = Int(buffer.format.channelCount)

    if channelCount == 1 {
        return Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
    }

    var monoSamples = [Float](repeating: 0.0, count: frameLength)
    for frame in 0..<frameLength {
        // Use vDSP for fast averaging
        var sum: Float = 0.0
        vDSP_meanv(channelData[0] + frame, vDSP_Stride(channelCount), &sum, vDSP_Length(channelCount))
        monoSamples[frame] = sum
    }

    return monoSamples
}
```

---

### 5. Expo EventEmitter Integration

Emit audio samples and status updates to JavaScript using Expo EventEmitter pattern.

```swift
import ExpoModulesCore

public class VoicelineDSPModule: Module {
    private var audioStreamManager: AudioStreamManager?

    // Define Expo module
    public func definition() -> ModuleDefinition {
        Name("VoicelineDSP")

        // Define events that can be emitted
        Events("onAudioSample", "onStreamStatus", "onStreamError")

        // Function: startAudioStream
        AsyncFunction("startAudioStream") { (config: StreamConfig) in
            try await self.startStreaming(config: config)
        }

        // Function: stopAudioStream
        AsyncFunction("stopAudioStream") {
            try await self.stopStreaming()
        }

        // Function: isStreaming
        AsyncFunction("isStreaming") { () -> Bool in
            return self.audioStreamManager?.isStreaming ?? false
        }
    }

    // Start audio streaming
    private func startStreaming(config: StreamConfig) async throws {
        guard audioStreamManager == nil else {
            throw StreamError.alreadyStreaming("Audio stream already active")
        }

        let manager = AudioStreamManager()
        audioStreamManager = manager

        // Configure audio session
        try manager.configureAudioSession()

        // Setup audio engine
        try manager.setupAudioEngine(config: config)

        // Install tap with callback
        try manager.installTap(config: config) { [weak self] buffer in
            // Convert buffer to Float32 array
            let samples = manager.convertBuffer(buffer)

            // Emit event to JavaScript (dispatch to main queue)
            DispatchQueue.main.async {
                self?.sendEvent("onAudioSample", [
                    "samples": samples,
                    "sampleRate": config.sampleRate,
                    "frameLength": samples.count,
                    "timestamp": Date().timeIntervalSince1970 * 1000
                ])
            }
        }

        // Start audio engine
        try manager.startEngine()

        // Emit status event
        sendEvent("onStreamStatus", ["status": "streaming"])
    }

    // Stop audio streaming
    private func stopStreaming() async throws {
        guard let manager = audioStreamManager else {
            return  // Already stopped, no-op
        }

        // Stop engine and remove tap
        try manager.stopEngine()

        // Cleanup
        audioStreamManager = nil

        // Emit status event
        sendEvent("onStreamStatus", ["status": "stopped"])
    }
}
```

**Event Payload Structures:**

| Event            | Payload Fields                                      | Types                                          |
| ---------------- | --------------------------------------------------- | ---------------------------------------------- |
| `onAudioSample`  | `samples`, `sampleRate`, `frameLength`, `timestamp` | `[Float]`, `Int`, `Int`, `Double`              |
| `onStreamStatus` | `status`, `timestamp?`                              | `String`, `Double?`                            |
| `onStreamError`  | `error`, `message`, `platform`, `details?`          | `String`, `String`, `String`, `[String: Any]?` |

**Threading Model:**

- **Tap callback:** Audio I/O thread (real-time priority)
- **Event emission:** Main queue (DispatchQueue.main)
- **Reason:** Expo EventEmitter expects main thread, JavaScript events delivered on JS thread

---

### 6. Resource Cleanup

Properly stop engine, remove tap, and deactivate audio session.

```swift
import AVFoundation

extension AudioStreamManager {
    /// Stop audio engine and cleanup resources
    func stopEngine() throws {
        guard let engine = audioEngine, let inputNode = inputNode else {
            return  // Already stopped
        }

        // Remove tap from input node (must be done before stopping engine)
        inputNode.removeTap(onBus: 0)
        print("✅ Tap removed from input node")

        // Stop audio engine
        engine.stop()
        print("✅ AVAudioEngine stopped")

        // Deactivate audio session (release audio resources)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
        print("✅ AVAudioSession deactivated")

        // Cleanup references
        audioEngine = nil
        inputNode = nil
    }
}
```

**Cleanup Order:**

1. **Remove tap first** - Prevents callbacks after engine stopped
2. **Stop engine** - Halts audio processing
3. **Deactivate session** - Releases audio resources, notifies other apps

**Options:**

- **`.notifyOthersOnDeactivation`:** Allow other apps to resume audio (e.g., music apps)

---

### 7. Interruption Handling

Handle audio interruptions (phone calls, Siri, other apps) using AVAudioSession notifications.

```swift
import AVFoundation

extension AudioStreamManager {
    /// Setup interruption notification observer
    func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        print("✅ Interruption handling configured")
    }

    /// Handle audio session interruption
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began (phone call, Siri, etc.)
            print("⚠️ Audio interruption began")

            // Engine automatically stops, emit status event
            sendEvent("onStreamStatus", ["status": "stopped"])

        case .ended:
            // Interruption ended
            print("✅ Audio interruption ended")

            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }

            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

            if options.contains(.shouldResume) {
                // System recommends resuming audio
                do {
                    try audioEngine?.start()
                    print("✅ Audio engine resumed after interruption")
                    sendEvent("onStreamStatus", ["status": "streaming"])
                } catch {
                    print("❌ Failed to resume engine: \(error.localizedDescription)")
                    sendEvent("onStreamError", [
                        "error": "ENGINE_START_FAILED",
                        "message": "Failed to resume after interruption: \(error.localizedDescription)",
                        "platform": "ios"
                    ])
                }
            }

        @unknown default:
            print("⚠️ Unknown interruption type: \(typeValue)")
        }
    }

    /// Cleanup notification observer
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
}
```

**Interruption Types:**

- **`.began`:** Interruption started (phone call incoming, Siri activated, another app takes audio session)
- **`.ended`:** Interruption finished (phone call ended, Siri dismissed)

**Auto-Resume Behavior:**

- **`shouldResume` option present:** System recommends resuming audio
- **No option:** Do not resume automatically (user explicitly stopped)

**User Experience:**

- **Began:** Stop streaming, notify UI (hide recording indicator)
- **Ended (shouldResume):** Auto-resume streaming, notify UI (show recording indicator)
- **Ended (no resume):** Leave stopped, wait for user action

---

## Complete Implementation Example

```swift
import ExpoModulesCore
import AVFoundation

// MARK: - Configuration Types

struct StreamConfig: Record {
    @Field var sampleRate: Int = 16000
    @Field var bufferSize: Int = 2048
    @Field var channels: Int = 1
}

enum StreamError: Error {
    case sessionConfigFailed(String)
    case engineInitFailed(String)
    case engineNotInitialized(String)
    case invalidFormat(String)
    case engineStartFailed(String)
    case alreadyStreaming(String)
}

// MARK: - Audio Stream Manager

class AudioStreamManager {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isActive = false

    var isStreaming: Bool {
        return isActive && (audioEngine?.isRunning ?? false)
    }

    func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.allowBluetooth])
        try audioSession.setActive(true, options: [])
    }

    func setupAudioEngine(config: StreamConfig) throws {
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else {
            throw StreamError.engineInitFailed("Failed to create AVAudioEngine")
        }
        inputNode = engine.inputNode
    }

    func installTap(config: StreamConfig, callback: @escaping (AVAudioPCMBuffer) -> Void) throws {
        guard let inputNode = inputNode else {
            throw StreamError.engineNotInitialized("Input node not available")
        }

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(config.sampleRate),
            channels: AVAudioChannelCount(config.channels),
            interleaved: false
        ) else {
            throw StreamError.invalidFormat("Failed to create audio format")
        }

        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(config.bufferSize), format: format) { buffer, time in
            callback(buffer)
        }
    }

    func startEngine() throws {
        guard let engine = audioEngine else {
            throw StreamError.engineNotInitialized("Audio engine not initialized")
        }

        try engine.start()
        isActive = true
    }

    func stopEngine() throws {
        guard let engine = audioEngine, let inputNode = inputNode else {
            return
        }

        inputNode.removeTap(onBus: 0)
        engine.stop()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])

        isActive = false
        audioEngine = nil
        inputNode = nil
    }

    func convertBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        if channelCount == 1 {
            return Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        }

        var monoSamples = [Float](repeating: 0.0, count: frameLength)
        for frame in 0..<frameLength {
            var sum: Float = 0.0
            for channel in 0..<channelCount {
                sum += channelData[channel][frame]
            }
            monoSamples[frame] = sum / Float(channelCount)
        }
        return monoSamples
    }
}

// MARK: - Expo Module

public class VoicelineDSPModule: Module {
    private var audioStreamManager: AudioStreamManager?

    public func definition() -> ModuleDefinition {
        Name("VoicelineDSP")
        Events("onAudioSample", "onStreamStatus", "onStreamError")

        AsyncFunction("startAudioStream") { (config: StreamConfig) in
            try await self.startStreaming(config: config)
        }

        AsyncFunction("stopAudioStream") {
            try await self.stopStreaming()
        }

        AsyncFunction("isStreaming") { () -> Bool in
            return self.audioStreamManager?.isStreaming ?? false
        }
    }

    private func startStreaming(config: StreamConfig) async throws {
        guard audioStreamManager == nil else {
            throw StreamError.alreadyStreaming("Audio stream already active")
        }

        let manager = AudioStreamManager()
        audioStreamManager = manager

        do {
            try manager.configureAudioSession()
            try manager.setupAudioEngine(config: config)
            try manager.installTap(config: config) { [weak self] buffer in
                let samples = manager.convertBuffer(buffer)
                DispatchQueue.main.async {
                    self?.sendEvent("onAudioSample", [
                        "samples": samples,
                        "sampleRate": config.sampleRate,
                        "frameLength": samples.count,
                        "timestamp": Date().timeIntervalSince1970 * 1000
                    ])
                }
            }
            try manager.startEngine()
            sendEvent("onStreamStatus", ["status": "streaming"])
        } catch {
            audioStreamManager = nil
            sendEvent("onStreamError", [
                "error": "ENGINE_START_FAILED",
                "message": error.localizedDescription,
                "platform": "ios"
            ])
            throw error
        }
    }

    private func stopStreaming() async throws {
        guard let manager = audioStreamManager else { return }
        try manager.stopEngine()
        audioStreamManager = nil
        sendEvent("onStreamStatus", ["status": "stopped"])
    }
}
```

---

## Performance Optimization

### 1. Buffer Size Tuning

Choose buffer size based on latency requirements:

| Buffer Size  | Sample Rate | Latency | Frequency Resolution |
| ------------ | ----------- | ------- | -------------------- |
| 512 samples  | 16kHz       | 32ms    | Low                  |
| 1024 samples | 16kHz       | 64ms    | Medium               |
| 2048 samples | 16kHz       | 128ms   | High (recommended)   |
| 4096 samples | 16kHz       | 256ms   | Very high            |

**Recommendation:** 2048 samples @ 16kHz (128ms) for voice analysis (optimal for YIN pitch detection)

### 2. Use Accelerate Framework

Leverage vDSP for fast audio processing:

```swift
import Accelerate

// Fast stereo to mono conversion
func fastStereoToMono(left: [Float], right: [Float]) -> [Float] {
    var mono = [Float](repeating: 0.0, count: left.count)
    vDSP_vadd(left, 1, right, 1, &mono, 1, vDSP_Length(left.count))
    var scale: Float = 0.5
    vDSP_vsmul(mono, 1, &scale, &mono, 1, vDSP_Length(mono.count))
    return mono
}
```

### 3. Minimize Main Thread Work

Keep main thread free for UI updates:

```swift
// Use background queue for heavy processing
let processingQueue = DispatchQueue(label: "audio.processing", qos: .userInitiated)

inputNode.installTap(...) { buffer in
    let samples = convertBuffer(buffer)

    // Offload processing to background queue
    processingQueue.async {
        let pitch = detectPitch(samples)

        // Emit event on main thread
        DispatchQueue.main.async {
            self.sendEvent("onAudioSample", [...])
        }
    }
}
```

---

## Error Scenarios

### Permission Denied

```swift
// No explicit permission check needed on iOS
// AVAudioSession automatically prompts user on first access
// If permission denied, engine.start() throws error

do {
    try engine.start()
} catch {
    sendEvent("onStreamError", [
        "error": "PERMISSION_DENIED",
        "message": "Microphone permission not granted",
        "platform": "ios"
    ])
}
```

### Session Configuration Failed

```swift
do {
    try audioSession.setCategory(.record, mode: .measurement, options: [.allowBluetooth])
} catch {
    sendEvent("onStreamError", [
        "error": "SESSION_CONFIG_FAILED",
        "message": "Failed to configure audio session: \(error.localizedDescription)",
        "platform": "ios"
    ])
}
```

### Device Not Available

```swift
if audioEngine.inputNode.inputFormat(forBus: 0).channelCount == 0 {
    sendEvent("onStreamError", [
        "error": "DEVICE_NOT_AVAILABLE",
        "message": "No microphone available on this device",
        "platform": "ios"
    ])
}
```

---

## Testing Recommendations

### Unit Tests

- Test buffer conversion (stereo → mono, Float32 normalization)
- Test configuration validation (sample rate, buffer size ranges)
- Test error handling (nil checks, invalid formats)

### Integration Tests

- Test AVAudioSession configuration
- Test AVAudioEngine start/stop lifecycle
- Test interruption handling (simulate phone call)
- Test memory cleanup (no leaks after stop)

### Performance Tests

- Measure tap callback duration (<1ms target)
- Measure end-to-end latency (mic → JS event)
- Profile memory usage during long sessions
- Monitor battery impact (Instruments Energy Log)

---

## Next Steps

This design document serves as the blueprint for **Story 2D.2: Implement iOS Native Streaming**.

Implementation checklist:

- [ ] Create Swift module in `modules/voiceline-dsp/ios/`
- [ ] Implement AudioStreamManager class
- [ ] Implement VoicelineDSPModule with Expo bindings
- [ ] Add interruption handling
- [ ] Write unit tests for buffer conversion
- [ ] Write integration tests for AVAudioEngine lifecycle
- [ ] Profile performance and optimize
- [ ] Document any deviations from this design

---

## References

- [AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [AVAudioSession Documentation](https://developer.apple.com/documentation/avfoundation/avaudiosession)
- [installTap Reference](https://developer.apple.com/documentation/avfaudio/avaudionode/1387122-installtap)
- [Expo Modules API](https://docs.expo.dev/modules/module-api/)
- [Accelerate Framework (vDSP)](https://developer.apple.com/documentation/accelerate/vdsp)
