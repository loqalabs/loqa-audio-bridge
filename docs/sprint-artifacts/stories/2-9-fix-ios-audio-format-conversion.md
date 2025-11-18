# Story 2.9: Fix iOS Audio Format Conversion for Sample Rate Mismatch

**Epic**: 2 - Code Migration & Quality Fixes
**Story Key**: 2-9-fix-ios-audio-format-conversion
**Story Type**: Bug Fix / Native Implementation
**Status**: ready-for-dev
**Created**: 2025-11-17
**Priority**: HIGH - Blocks iOS audio streaming functionality

---

## User Story

As a developer using the module on iOS,
I want audio streaming to work at my requested sample rate (16kHz),
So that the module functions correctly for speech recognition use cases.

---

## Problem Summary

When attempting to start audio streaming on iOS, the app crashes with:

```
[AVFAudio] AVAEUtility.mm:176 Format mismatch: input hw
<AVAudioFormat 0x60000216b070: 1 ch, 48000 Hz, Float32>, client format
<AVAudioFormat 0x600002161770: 1 ch, 16000 Hz, Float32>

[CoreFoundation] *** Terminating app due to uncaught exception
'com.apple.coreaudio.avfaudio', reason: 'Failed to create tap due to format
mismatch, <AVAudioFormat 0x600002161770: 1 ch, 16000 Hz, Float32>'
```

**Root Cause**: iOS hardware audio input runs at **48 kHz** (system hardware rate), but the module requests a tap at **16 kHz** (desired sample rate for speech recognition). iOS's `AVAudioEngine.installTap()` requires the tap format to match the hardware format, or it throws an exception.

**Required Solution**:
1. Tap at the hardware rate (48 kHz)
2. Use `AVAudioConverter` to downsample to the requested rate (16 kHz)

---

## Acceptance Criteria

**Given** the iOS Swift implementation in `ios/LoqaAudioBridgeModule.swift`
**When** the user calls `startAudioStream({ sampleRate: 16000, bufferSize: 2048, channels: 1, vadEnabled: true })`
**Then** the module:

1. **Detects Hardware Format**:
   - Gets the hardware format from `inputNode.outputFormat(forBus: 0)`
   - Identifies the hardware sample rate (typically 48000 Hz)
   - Logs the hardware format for debugging

2. **Installs Tap at Hardware Rate**:
   - Creates tap using `inputNode.installTap(onBus: 0, bufferSize: scaledBufferSize, format: hardwareFormat)`
   - Scales buffer size proportionally (e.g., 2048 * (48000/16000) = 6144 samples)
   - Does NOT use the requested sample rate for the tap format

3. **Converts to Requested Format**:
   - Creates `AVAudioConverter` from hardware format to target format (16 kHz)
   - In the tap callback, converts each buffer from 48 kHz → 16 kHz
   - Handles conversion errors gracefully with error events

4. **Sends Downsampled Audio**:
   - Calculates RMS on the downsampled audio (not the 48 kHz audio)
   - Sends audio samples at the requested rate (16 kHz)
   - Event rate matches expected rate (e.g., ~8 Hz for 2048 buffer @ 16 kHz)

**And** when the user runs the example app on iOS:
- Taps "Start Streaming" button
- Audio streaming starts without crash
- RMS visualization updates in real-time
- No `AVAudioEngine` format mismatch errors

**And** the implementation:
- Preserves sample accuracy (no dropped samples)
- Handles variable hardware rates (44.1kHz, 48kHz, etc.)
- Includes error handling for conversion failures
- Logs format conversion details for debugging

---

## Tasks/Subtasks

### Task 1: Update `installAudioTap` to Use Hardware Format
- [ ] Open `ios/LoqaAudioBridgeModule.swift`
- [ ] Locate the `installAudioTap(config: StreamConfig)` function
- [ ] Replace the current tap format creation:
  ```swift
  // BEFORE (causes crash)
  let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: config.sampleRate,  // ❌ Doesn't match hardware
      channels: AVAudioChannelCount(config.channels),
      interleaved: false
  )

  // AFTER (uses hardware format)
  let hardwareFormat = inputNode.outputFormat(forBus: 0)
  NSLog("LoqaAudioBridge: Hardware format: \(hardwareFormat)")
  NSLog("LoqaAudioBridge: Requested format: \(config.sampleRate) Hz")
  ```
- [ ] Calculate scaled buffer size for hardware rate:
  ```swift
  let ratio = hardwareFormat.sampleRate / config.sampleRate
  let scaledBufferSize = AVAudioFrameCount(Double(config.bufferSize) * ratio)
  ```
- [ ] Update `installTap` call to use hardware format:
  ```swift
  inputNode.installTap(
      onBus: 0,
      bufferSize: scaledBufferSize,
      format: hardwareFormat  // ✅ Matches hardware
  ) { [weak self] buffer, time in
      self?.processAndConvertAudioBuffer(buffer, time: time, targetConfig: config)
  }
  ```

### Task 2: Implement Audio Format Conversion
- [ ] Add a new property to store the converter:
  ```swift
  private var audioConverter: AVAudioConverter?
  ```
- [ ] Create a new function `processAndConvertAudioBuffer`:
  ```swift
  private func processAndConvertAudioBuffer(
      _ buffer: AVAudioPCMBuffer,
      time: AVAudioTime,
      targetConfig: StreamConfig
  ) {
      // Create target format
      guard let targetFormat = AVAudioFormat(
          commonFormat: .pcmFormatFloat32,
          sampleRate: targetConfig.sampleRate,
          channels: buffer.format.channelCount,
          interleaved: false
      ) else {
          sendError(code: "FORMAT_ERROR", message: "Failed to create target format")
          return
      }

      // Create converter if needed
      if audioConverter == nil ||
         audioConverter?.inputFormat.sampleRate != buffer.format.sampleRate {
          audioConverter = AVAudioConverter(from: buffer.format, to: targetFormat)
          NSLog("LoqaAudioBridge: Created converter \(buffer.format.sampleRate) Hz → \(targetFormat.sampleRate) Hz")
      }

      guard let converter = audioConverter else {
          sendError(code: "CONVERTER_ERROR", message: "Audio converter is nil")
          return
      }

      // Calculate output buffer size
      let inputFrames = buffer.frameLength
      let ratio = targetFormat.sampleRate / buffer.format.sampleRate
      let outputFrames = AVAudioFrameCount(Double(inputFrames) * ratio)

      // Create output buffer
      guard let outputBuffer = AVAudioPCMBuffer(
          pcmFormat: targetFormat,
          frameCapacity: outputFrames
      ) else {
          sendError(code: "BUFFER_ERROR", message: "Failed to create output buffer")
          return
      }

      // Perform conversion
      var error: NSError?
      let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
          outStatus.pointee = .haveData
          return buffer
      }

      let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

      if status == .error {
          sendError(
              code: "CONVERSION_FAILED",
              message: "Audio format conversion failed: \(error?.localizedDescription ?? "unknown")"
          )
          return
      }

      // Process the downsampled buffer
      processAudioBuffer(outputBuffer, time: time)
  }
  ```

### Task 3: Update Error Handling
- [ ] Add new error codes to the module's error handling:
  - `FORMAT_ERROR`: Failed to create audio format
  - `CONVERTER_ERROR`: Audio converter initialization failed
  - `CONVERSION_FAILED`: Runtime conversion error
- [ ] Ensure errors are sent via the existing `sendError` mechanism

### Task 4: Add Logging for Debugging
- [ ] Log hardware format detection
- [ ] Log converter creation
- [ ] Log buffer size scaling
- [ ] Log conversion success/failure
- [ ] Use `NSLog` for compatibility with Xcode console

### Task 5: Clean Up Converter on Stream Stop
- [ ] Update `stopAudioStream` to clean up the converter:
  ```swift
  private func stopAudioStream() throws {
      // ... existing cleanup code ...
      audioConverter = nil
  }
  ```

### Task 6: Test with Example App
- [ ] Navigate to `modules/loqa-audio-bridge/example/`
- [ ] Build and run on iOS: `npx expo run:ios`
- [ ] Grant microphone permission when prompted
- [ ] Tap "Start Streaming" button
- [ ] Verify:
  - No crash occurs
  - No `AVAudioEngine` format mismatch errors
  - RMS value updates continuously in the UI
  - Audio visualization bar animates
  - Streaming status shows "Active"
- [ ] Tap "Stop Streaming" button
- [ ] Verify streaming stops cleanly without errors

### Task 7: Test with Different Sample Rates
- [ ] Test with 16000 Hz (speech recognition)
- [ ] Test with 44100 Hz (CD quality)
- [ ] Test with 48000 Hz (matches hardware - no conversion needed)
- [ ] Verify all rates work correctly

### Task 8: Update Documentation
- [ ] Add comments explaining the format conversion approach
- [ ] Document why we tap at hardware rate vs requested rate
- [ ] Add inline documentation for the converter setup

---

## Dev Notes

### Technical Context

**iOS Audio Architecture**: Unlike Android, iOS's `AVAudioEngine` is strict about format matching. The `installTap` API requires that the tap format matches the hardware's output format exactly. This is a fundamental limitation of the Core Audio framework.

**Why This Wasn't Caught Earlier**:
- Story 2-2 (iOS Swift implementation) migrated v0.2.0 code that didn't account for this
- Story 2-6 (iOS tests) was deferred, so no unit tests validated audio tap creation
- Story 3-4 (example app) was the first end-to-end iOS runtime test

**Hardware Sample Rates**:
- Most iOS devices: 48000 Hz
- Some older devices: 44100 Hz
- Can vary based on connected audio accessories (Bluetooth headphones, etc.)

### Conversion Strategy

**Option 1: Inline Conversion (CHOSEN)**
- Tap at hardware rate
- Convert each buffer in the tap callback
- Send downsampled audio to JavaScript

**Advantages**:
- Simpler state management
- Lower latency (no buffering)
- Memory efficient (convert and discard)

**Disadvantages**:
- CPU overhead per callback
- More complex error handling

**Option 2: Separate Converter Node**
- Use `AVAudioMixerNode` and `AVAudioConverter`
- Connect nodes in audio graph
- Let Core Audio handle conversion

**Advantages**:
- Potentially more efficient (Core Audio optimizations)
- Cleaner separation of concerns

**Disadvantages**:
- More complex audio graph setup
- Higher memory overhead
- Harder to debug

**Decision**: Use Option 1 (inline conversion) for simplicity and to match the existing architecture where we process buffers directly in the tap callback.

### Performance Considerations

**CPU Impact**: Downsampling from 48 kHz → 16 kHz is a 3:1 reduction. Apple's `AVAudioConverter` uses optimized DSP algorithms (typically polyphase filters) that are efficient.

**Estimated Overhead**:
- 48 kHz → 16 kHz conversion: ~2-5% CPU on modern iPhones
- Negligible impact on battery life
- Acceptable for real-time speech recognition use cases

**Buffer Size Scaling**:
- Requested: 2048 samples @ 16 kHz = 128ms
- Hardware: 6144 samples @ 48 kHz = 128ms (same duration)
- Output: 2048 samples @ 16 kHz (as requested)

### Alternative Solutions Considered

**Workaround 1: Match Hardware Rate**
- Request 48 kHz instead of 16 kHz
- No conversion needed

**Why Not**:
- Defeats the purpose of allowing custom sample rates
- Speech recognition models expect 16 kHz
- 3x more data sent to JavaScript (wasted bandwidth)

**Workaround 2: Software Tap**
- Use `AVAudioRecorder` instead of `AVAudioEngine`
- Record to buffer, then read

**Why Not**:
- Higher latency (buffering required)
- More complex state management
- Doesn't align with the existing architecture

### Epic 2 Context

This story is added to Epic 2 (Code Migration & Quality Fixes) because it's fixing a bug introduced during the iOS Swift migration (Story 2-2). The original v0.2.0 implementation likely had the same issue but it went unnoticed due to lack of testing.

**Relationship to Other Stories**:
- Story 2-2: iOS Swift implementation (introduced the bug)
- Story 2-6: iOS tests deferred (would have caught this)
- Story 3-4: Example app implementation (discovered the bug)

### Learnings for Voiceline Team

When integrating this module into the Voiceline app:
1. iOS audio streaming will work correctly at any requested sample rate
2. The module handles format conversion transparently
3. No special configuration needed
4. Monitor logs for format conversion messages if debugging

---

## References

- **Apple AVAudioEngine**: https://developer.apple.com/documentation/avfaudio/avaudioengine
- **Apple AVAudioConverter**: https://developer.apple.com/documentation/avfaudio/avaudioconverter
- **Audio Tap Format Requirements**: https://developer.apple.com/documentation/avfaudio/avaudionode/1387122-installtap
- **KNOWN-ISSUE-IOS-AUDIO-FORMAT.md**: Complete problem documentation
- **Story 3-4**: Example app implementation that discovered this issue

---

## Definition of Done

- [ ] `ios/LoqaAudioBridgeModule.swift` updated to detect hardware format
- [ ] Tap installed at hardware rate (not requested rate)
- [ ] `AVAudioConverter` created to downsample to requested rate
- [ ] Conversion performed on each audio buffer in tap callback
- [ ] Error handling added for format and conversion failures
- [ ] Converter cleaned up when streaming stops
- [ ] Example app tested on iOS - streaming works without crashes
- [ ] Example app tested - RMS visualization updates correctly
- [ ] Tested with multiple sample rates (16kHz, 44.1kHz, 48kHz)
- [ ] Code includes comments explaining the conversion approach
- [ ] Xcode build succeeds with zero errors
- [ ] No `AVAudioEngine` format mismatch errors in console
- [ ] Story 3-4 Task 9 unblocked (iOS testing can complete)
- [ ] Story status updated in sprint-status.yaml (ready-for-dev → done)

---

## Impact

**Unblocks**:
- Story 3-4 Task 9: iOS testing can now be completed
- Story 3-4 Acceptance Criteria: Can verify app functions on iOS
- Epic 3 Goal: Can prove autolinking works end-to-end on iOS

**Validates**:
- FR14: Maintains 100% feature parity with v0.2.0 (audio streaming works)
- FR10: iOS autolinking works correctly (once audio streaming works)
- Epic 2 Goal: Working, compilable module with all v0.2.0 features intact
