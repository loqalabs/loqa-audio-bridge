# Known Issue: iOS Audio Format Mismatch

**Date**: 2025-11-17
**Story**: 3-4-implement-example-app-audio-streaming-demo
**Severity**: HIGH - Blocks iOS audio streaming functionality
**Status**: DEFERRED to future story

## Problem Summary

When attempting to start audio streaming on iOS, the app crashes with the following error:

```
[AVFAudio] AVAEUtility.mm:176 Format mismatch: input hw
<AVAudioFormat 0x60000216b070: 1 ch, 48000 Hz, Float32>, client format
<AVAudioFormat 0x600002161770: 1 ch, 16000 Hz, Float32>

[CoreFoundation] *** Terminating app due to uncaught exception
'com.apple.coreaudio.avfaudio', reason: 'Failed to create tap due to format
mismatch, <AVAudioFormat 0x600002161770: 1 ch, 16000 Hz, Float32>'
```

## Root Cause

The iOS hardware audio input is running at **48 kHz** (system hardware rate), but our module is requesting a tap at **16 kHz** (our desired sample rate for speech recognition).

iOS's `AVAudioEngine.installTap()` requires the tap format to match the hardware format, or it throws an exception. We cannot directly tap at a different sample rate - we must:

1. Tap at the hardware rate (48 kHz)
2. Use an `AVAudioConverter` to downsample to our desired rate (16 kHz)

## Current Implementation (Incorrect)

From `ios/LoqaAudioBridgeModule.swift`:

```swift
private func installAudioTap(config: StreamConfig) throws {
    let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: config.sampleRate,    // ❌ 16000 Hz - doesn't match hardware!
        channels: AVAudioChannelCount(config.channels),
        interleaved: false
    )

    inputNode.installTap(
        onBus: 0,
        bufferSize: config.bufferSize,
        format: format  // ❌ This will fail with format mismatch!
    ) { [weak self] buffer, time in
        self?.processAudioBuffer(buffer, time: time)
    }
}
```

## Required Fix

The correct implementation requires:

### 1. Tap at Hardware Rate

```swift
// Get the hardware format (48 kHz on most iOS devices)
let hardwareFormat = inputNode.outputFormat(forBus: 0)

// Install tap at hardware rate
inputNode.installTap(
    onBus: 0,
    bufferSize: AVAudioFrameCount(config.bufferSize * 3),  // Scaled for 48kHz
    format: hardwareFormat  // ✅ Use hardware format
) { [weak self] buffer, time in
    self?.processAudioBuffer(buffer, time: time, targetRate: config.sampleRate)
}
```

### 2. Convert to Desired Format

```swift
private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime, targetRate: Double) {
    guard let channelData = buffer.floatChannelData else { return }

    // Create target format (16 kHz)
    guard let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: targetRate,
        channels: buffer.format.channelCount,
        interleaved: false
    ) else { return }

    // Create converter
    guard let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else {
        return
    }

    // Calculate output buffer size
    let inputFrameCount = buffer.frameLength
    let ratio = targetRate / buffer.format.sampleRate
    let outputFrameCount = AVAudioFrameCount(Double(inputFrameCount) * ratio)

    // Create output buffer
    guard let outputBuffer = AVAudioPCMBuffer(
        pcmFormat: targetFormat,
        frameCapacity: outputFrameCount
    ) else { return }

    // Perform conversion
    var error: NSError?
    let status = converter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
        outStatus.pointee = .haveData
        return buffer
    }

    if status == .error {
        sendError(code: "CONVERSION_FAILED", message: "Audio format conversion failed")
        return
    }

    // Now process the downsampled buffer
    sendAudioSamples(outputBuffer)
}
```

### 3. Alternative: Use AVAudioConverter Upfront

```swift
private var converter: AVAudioConverter?

private func installAudioTap(config: StreamConfig) throws {
    let hardwareFormat = inputNode.outputFormat(forBus: 0)

    // Create target format
    guard let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: config.sampleRate,
        channels: AVAudioChannelCount(config.channels),
        interleaved: false
    ) else {
        throw StreamError.configFailed("Invalid audio format")
    }

    // Create converter (reused for each buffer)
    self.converter = AVAudioConverter(from: hardwareFormat, to: targetFormat)

    // Tap at hardware rate
    inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] buffer, time in
        self?.convertAndProcess(buffer, time: time)
    }
}
```

## Impact

**Blocks**:

- Story 3-4 Task 9: iOS testing cannot be completed
- Story 3-4 Acceptance Criteria: Cannot verify app functions on iOS
- Epic 3 Goal: Cannot prove autolinking works end-to-end on iOS

**Does NOT Block**:

- Story 3-4 Tasks 1-8: App implementation is complete and correct
- Metro bundler fix: Successfully resolved
- Android testing: Can proceed independently

## Scope Decision

This issue is **out of scope** for Story 3-4 because:

1. **Different Layer**: This is a native iOS audio engine issue, not an example app implementation issue
2. **Epic 2 Work**: This should have been caught in Story 2-2 (iOS Swift implementation)
3. **Missing Tests**: Story 2-6 (iOS tests) was deferred - this would have caught it
4. **Story Focus**: Story 3-4 is about the example app UI/integration, not fixing native audio bugs

## Recommended Approach

### Option 1: Create New Story (RECOMMENDED)

Create a new story in Epic 2 or 3:

- **Title**: "Fix iOS Audio Format Conversion for Sample Rate Mismatch"
- **Epic**: Either Epic 2 (Native Implementation) or Epic 3 (Integration Testing)
- **Priority**: HIGH - blocks iOS functionality
- **Effort**: 2-3 hours (implement converter, test, validate)

### Option 2: Continue in Story 3-4

Add this fix to the current story, but this would:

- Expand scope significantly beyond example app work
- Mix native implementation fixes with app-level work
- Delay completion of the example app demonstration

## Verification Steps (After Fix)

1. Build and run example app on iOS
2. Grant microphone permission
3. Tap "Start Streaming" button
4. Verify:
   - No crash
   - RMS value updates continuously
   - Audio visualization bar animates
   - "Streaming: Active" status shows
5. Tap "Stop Streaming"
6. Verify streaming stops cleanly

## References

- **Apple AVAudioEngine**: https://developer.apple.com/documentation/avfaudio/avaudioengine
- **Apple AVAudioConverter**: https://developer.apple.com/documentation/avfaudio/avaudioconverter
- **Audio Tap Format Requirements**: https://developer.apple.com/documentation/avfaudio/avaudionode/1387122-installtap

## Related Issues

- Story 2-2: iOS Swift implementation - should have handled format conversion
- Story 2-6: iOS tests deferred - would have caught this issue
- Epic 5 Story 5-2: CI/CD should include iOS device testing with audio hardware

## Temporary Workaround

For testing purposes, you can modify the example app to request 48 kHz (hardware rate):

```typescript
await startAudioStream({
  sampleRate: 48000, // Match hardware rate
  bufferSize: 4096,
  channels: 1,
  vadEnabled: true,
});
```

This will work on iOS but:

- Uses more CPU/battery
- Produces larger data payloads
- Not optimal for speech recognition (16 kHz is standard)

## Conclusion

The Metro bundler issue is **RESOLVED** - the example app successfully launches on iOS with zero JavaScript errors. However, there's a **separate native iOS audio implementation issue** that prevents audio streaming from working.

This issue should be fixed in a dedicated story focused on iOS audio engine implementation, not in the current example app story.
