# VoicelineDSP v0.2.0 Testing Procedures

**Story:** 2D.8 - Integration Testing and Performance Validation
**Date:** 2025-11-13
**Author:** Loqa Dev Team

---

## Table of Contents

1. [Overview](#overview)
2. [Automated Test Suites](#automated-test-suites)
3. [Battery Profiling Procedures](#battery-profiling-procedures)
4. [Memory Profiling Procedures](#memory-profiling-procedures)
5. [Audio Quality Testing](#audio-quality-testing)
6. [Device Diversity Testing](#device-diversity-testing)
7. [Performance Benchmarking](#performance-benchmarking)

---

## Overview

This document provides step-by-step procedures for validating the VoicelineDSP v0.2.0 audio streaming system across iOS and Android platforms. The testing covers:

- Functional correctness (E2E integration tests)
- Performance targets (latency <100ms, battery <5%, memory <10MB)
- Audio quality (dropout rate <0.1%, cross-platform consistency)
- Device diversity (multiple models and OS versions)

---

## Automated Test Suites

### iOS Integration Tests

**Location:** `modules/voiceline-dsp/ios/Tests/VoicelineDSPIntegrationTests.swift`

**Prerequisites:**

- Xcode 15.0+ installed
- iOS 17.0+ physical device or simulator
- Microphone access granted

**Running Tests:**

```bash
# Run on simulator (Intel/Apple Silicon)
cd modules/voiceline-dsp
xcodebuild test \
  -workspace VoicelineDSP.xcworkspace \
  -scheme VoicelineDSP \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

# Run on physical device (iPhone 12+)
xcodebuild test \
  -workspace VoicelineDSP.xcworkspace \
  -scheme VoicelineDSP \
  -destination 'platform=iOS,name=Anna'\''s iPhone'

# Or use Xcode GUI: Product → Test (⌘+U)
```

**Test Coverage:**

- ✅ Start/stop streaming lifecycle
- ✅ Event rate validation (~8Hz)
- ✅ Sample value range [-1.0, 1.0]
- ✅ RMS pre-computation
- ✅ VAD silence detection
- ✅ Adaptive processing (low battery)
- ✅ Error event handling
- ✅ Cleanup and memory management

**Expected Results:**

- All tests pass on simulator and physical device
- No crashes or memory leaks detected
- Event rate within 6-10 Hz range

---

### Android Integration Tests

**Location:** `modules/voiceline-dsp/android/src/androidTest/java/expo/modules/voicelinedsp/VoicelineDSPIntegrationTest.kt`

**Prerequisites:**

- Android Studio installed
- Android device (API 26+) or emulator
- RECORD_AUDIO permission granted

**Running Tests:**

```bash
# Run on emulator (x86/ARM)
cd modules/voiceline-dsp/android
./gradlew connectedAndroidTest

# Run on physical device (API 26+)
# 1. Connect device via USB
# 2. Enable USB debugging
# 3. Run: ./gradlew connectedAndroidTest

# Or use Android Studio GUI: Run → Run 'All Tests'
```

**Test Coverage:**

- ✅ Permission handling (grant/deny)
- ✅ Start/stop streaming lifecycle
- ✅ Event rate validation (~8Hz)
- ✅ Sample value range [-1.0, 1.0]
- ✅ RMS pre-computation
- ✅ VAD silence detection
- ✅ Adaptive processing (low battery)
- ✅ Error event handling
- ✅ Cleanup and memory management

**Expected Results:**

- All tests pass on emulator and physical device
- No crashes or ANRs detected
- Event rate within 5-12 Hz range

---

### TypeScript Latency Tests

**Location:** `modules/voiceline-dsp/__tests__/latency-measurement.test.ts`

**Running Tests:**

```bash
cd modules/voiceline-dsp
npm test -- latency-measurement.test.ts

# Or with yarn
yarn test latency-measurement.test.ts
```

**Test Coverage:**

- ✅ Component latency calculations
- ✅ Percentile statistics (50th, 95th, 99th)
- ✅ Platform-specific expectations
- ✅ Outlier detection and removal
- ✅ Buffer size impact analysis
- ✅ Timestamp accuracy validation

**Expected Results:**

- 95th percentile latency <100ms
- Native component <45ms (median)
- Bridge component <15ms (median)

---

## Battery Profiling Procedures

### iOS Battery Profiling (Xcode Instruments)

**Tool:** Xcode Instruments - Energy Log template

**Setup:**

1. **Build Release Configuration:**

   ```bash
   cd modules/voiceline-dsp
   xcodebuild -configuration Release
   ```

2. **Install on Physical Device:**

   - Connect iPhone via USB
   - Install app: `Product → Run` in Xcode (Release scheme)

3. **Open Instruments:**
   - Xcode → `Product → Profile` (⌘+I)
   - Select "Energy Log" template
   - Choose target device: Your iPhone

**Baseline Test (No Streaming):**

1. Launch app on device
2. Start recording in Instruments
3. Let app idle for **30 minutes**
4. Note battery % before: **\_**
5. Note battery % after: **\_**
6. Calculate drain: **Baseline = **\_**% **

7. Export Instruments data:
   - `File → Export`
   - Save as `ios-baseline-energy.trace`

**Streaming Test:**

1. Reset: Stop recording, close app
2. Note battery % before: **\_**
3. Launch app, start audio streaming
4. Speak continuously or play audio loop for **30 minutes**
5. Note battery % after: **\_**
6. Calculate drain: **Streaming = **\_**% **

7. Export Instruments data:
   - `File → Export`
   - Save as `ios-streaming-energy.trace`

**Calculate Overhead:**

```
Streaming Overhead = Streaming % - Baseline %
Target: <5%

Example:
Baseline: 2% (30 min idle)
Streaming: 5% (30 min streaming)
Overhead: 3% ✅ (within target)
```

**Metrics to Capture:**

- CPU energy (mWh)
- GPU energy (mWh)
- Network energy (mWh)
- Display energy (mWh)
- **Total energy** (sum of all components)

**Screenshots Needed:**

1. Energy Log timeline (full 30-minute session)
2. Energy breakdown by component (CPU, GPU, etc.)
3. Battery level graph

---

### Android Battery Profiling (Battery Historian)

**Tool:** Android Battery Historian web tool

**Setup:**

1. **Build Release APK:**

   ```bash
   cd modules/voiceline-dsp/android
   ./gradlew assembleRelease
   ```

2. **Install on Physical Device:**

   ```bash
   adb install app/build/outputs/apk/release/app-release.apk
   ```

3. **Setup Battery Historian:**
   - Visit: https://bathist.ef.lc/
   - Or install locally: https://github.com/google/battery-historian

**Baseline Test (No Streaming):**

1. Connect device via USB
2. Reset battery stats:

   ```bash
   adb shell dumpsys batterystats --reset
   ```

3. **Disconnect USB** (battery stats accurate only when unplugged)
4. Launch app, let idle for **30 minutes**
5. Note battery % before: **\_**
6. Note battery % after: **\_**

7. Reconnect USB, capture bugreport:

   ```bash
   adb bugreport > baseline.zip
   ```

8. Upload `baseline.zip` to Battery Historian
9. Save report as PDF: `android-baseline-battery.pdf`

**Streaming Test:**

1. Reset battery stats:

   ```bash
   adb shell dumpsys batterystats --reset
   ```

2. **Disconnect USB**
3. Launch app, start audio streaming
4. Stream continuously for **30 minutes**
5. Note battery % before: **\_**
6. Note battery % after: **\_**

7. Reconnect USB, capture bugreport:

   ```bash
   adb bugreport > streaming.zip
   ```

8. Upload `streaming.zip` to Battery Historian
9. Save report as PDF: `android-streaming-battery.pdf`

**Calculate Overhead:**

```
Streaming Overhead = Streaming % - Baseline %
Target: <5%

Example:
Baseline: 2% (30 min idle)
Streaming: 6% (30 min streaming)
Overhead: 4% ✅ (within target)
```

**Metrics to Capture:**

- Screen-on time
- CPU usage (user + system)
- Audio subsystem usage
- Per-app battery usage
- **Total battery drain %**

**Screenshots Needed:**

1. Battery Historian timeline (full session)
2. App-specific battery breakdown
3. CPU and audio usage graphs

---

## Memory Profiling Procedures

### iOS Memory Profiling (Xcode Instruments)

**Tool:** Xcode Instruments - Allocations + Leaks templates

**Setup:**

1. **Profile in Release Mode:**
   - Xcode → `Product → Profile` (⌘+I)
   - Select "Allocations" template
   - Choose target device

**1-Hour Streaming Session:**

1. Launch app with profiling
2. Start audio streaming
3. Record for **1 hour** (continuous streaming)
4. Monitor: Persistent allocations over time

**Verify Memory Stability:**

1. At **30-minute mark:** `Mark Generation` in Instruments
2. At **1-hour mark:** `Mark Generation` again
3. Filter: Show only persistent allocations between marks
4. **Verify:** Total persistent allocations <10MB

**Verify Cleanup:**

1. Stop streaming in app
2. Trigger memory warning: `Debug → Simulate Memory Warning` in Xcode
3. Observe: Allocations should drop back to baseline

**Leak Detection:**

1. Switch to "Leaks" instrument
2. Verify: **Zero leaks** detected throughout session

**Metrics to Capture:**

- Total allocations (MB) at start
- Total allocations (MB) at 30 minutes
- Total allocations (MB) at 1 hour
- Persistent allocations (MB) between marks
- Leak count (should be 0)

**Screenshots Needed:**

1. Allocations graph (1-hour timeline)
2. Persistent allocations summary
3. Leaks summary (should show 0 leaks)

**Export Data:**

- `File → Export` → Save as `ios-memory-profile.trace`

---

### Android Memory Profiling (Android Studio)

**Tool:** Android Studio Memory Profiler

**Setup:**

1. **Open Android Studio**
2. **Run app** on device with profiling enabled:

   - `Run → Profile 'app'`
   - Or click "Profile" icon in toolbar

3. **Open Memory Profiler:**
   - `View → Tool Windows → Profiler`
   - Select "Memory" section

**1-Hour Streaming Session:**

1. Start audio streaming in app
2. Click **"Record allocations"** in Memory Profiler
3. Stream continuously for **1 hour**
4. Monitor: Memory usage over time (Java + Native heap)

**Verify Memory Stability:**

1. At **30-minute mark:** Note total memory usage
2. At **1-hour mark:** Note total memory usage
3. **Verify:** Memory usage <10MB and stable (not continuously growing)

**Verify Cleanup:**

1. Stop streaming in app
2. Force GC: Memory Profiler → **"Initiate GC"** button
3. Observe: Memory should drop back to baseline

**Heap Dump Analysis:**

1. After 1 hour, click **"Capture heap dump"**
2. Analyze: Look for leaked objects:
   - AudioRecord instances
   - Coroutine jobs not cancelled
   - Event listeners not removed
3. **Verify:** No leaked objects found

**Metrics to Capture:**

- Java Heap (MB) at start
- Native Heap (MB) at start
- Total Memory (MB) at start
- Java Heap (MB) at 1 hour
- Native Heap (MB) at 1 hour
- Total Memory (MB) at 1 hour
- Graphics (MB) if applicable
- Leak count (should be 0)

**Screenshots Needed:**

1. Memory timeline (1-hour session)
2. Heap dump analysis (no leaks)
3. Memory usage by category (Java/Native/Graphics)

**Export Data:**

- Memory Profiler → `Export` → Save as `android-memory-profile.hprof`

---

## Audio Quality Testing

### Cross-Platform Consistency Test

**Objective:** Verify iOS and Android produce identical sample values for same audio input

**Setup:**

1. Prepare identical audio input (WAV file)
2. Play through speakers or audio interface
3. Record on iOS and Android simultaneously

**Procedure:**

1. **iOS Recording:**

   - Start VoicelineDSP streaming
   - Play test audio for 10 seconds
   - Export samples to file: `ios-samples.txt`

2. **Android Recording:**

   - Start VoicelineDSP streaming
   - Play same test audio for 10 seconds
   - Export samples to file: `android-samples.txt`

3. **Compare Samples:**

   ```python
   import numpy as np

   ios_samples = np.loadtxt('ios-samples.txt')
   android_samples = np.loadtxt('android-samples.txt')

   # Calculate mean absolute difference
   mad = np.mean(np.abs(ios_samples - android_samples))

   # Verify: MAD < 0.01 (allowing for timing differences)
   assert mad < 0.01, f"Cross-platform MAD too high: {mad}"
   ```

**Expected Results:**

- Sample values within 0.01 tolerance
- No systematic bias (iOS consistently higher/lower than Android)

---

### Audio Dropout Stress Test

**Objective:** Verify dropout rate <0.1% under high CPU load

**Procedure:**

1. **Start streaming** on device
2. **Launch heavy CPU task** (compute-intensive loop):

   - iOS: Run Geekbench CPU benchmark simultaneously
   - Android: Run CPU stress test app

3. **Monitor dropout rate:**

   - iOS: Check console for `Buffer overflow` warnings
   - Android: Check logcat for `underrun` warnings

4. **Calculate dropout rate:**
   ```
   Dropout Rate = (Dropped Frames / Total Frames) * 100%
   Target: <0.1%
   ```

**Expected Results:**

- Dropout rate <0.1% on both platforms
- Android may have slightly higher rate on low-end devices (still <0.1%)

---

### VAD Quality Test

**Objective:** Verify VAD doesn't cut off speech onset/offset

**Test Audio:** Speech sample with silence before/after (e.g., "Hello" with 500ms silence on each end)

**Procedure:**

1. Play test audio through speakers
2. Record with VoicelineDSP (VAD enabled)
3. Verify in captured samples:
   - First phoneme of "Hello" is captured
   - Last phoneme of "Hello" is captured
   - Silence is skipped (no samples emitted when RMS <0.01)

**Expected Results:**

- Speech onset not cut off
- Speech offset not cut off
- VAD threshold (0.01) is appropriate

---

## Device Diversity Testing

### iOS Devices

Test on the following devices (or best available):

| Device        | OS Version | Test Status | Latency  | Battery | Notes |
| ------------- | ---------- | ----------- | -------- | ------- | ----- |
| iPhone 12     | iOS 15     | Pending     | \_\_\_ms | \_\_\_% |       |
| iPhone 13 Pro | iOS 16     | Pending     | \_\_\_ms | \_\_\_% |       |
| iPhone 14     | iOS 17     | Pending     | \_\_\_ms | \_\_\_% |       |
| iPad Air      | iOS 16     | Pending     | \_\_\_ms | \_\_\_% |       |

**For Each Device:**

1. Run integration test suite
2. Measure latency (procedure above)
3. Measure battery impact (30-minute session)
4. Document any device-specific issues

---

### Android Devices

Test on the following devices (or best available):

| Device             | OS Version    | Test Status | Latency  | Battery | Notes             |
| ------------------ | ------------- | ----------- | -------- | ------- | ----------------- |
| Samsung Galaxy S21 | Android 12    | Pending     | \_\_\_ms | \_\_\_% | OneUI skin        |
| Google Pixel 6     | Android 13    | Pending     | \_\_\_ms | \_\_\_% | Stock Android     |
| OnePlus 9          | Android 12    | Pending     | \_\_\_ms | \_\_\_% | OxygenOS          |
| Android Emulator   | API 26 (8.0)  | Pending     | \_\_\_ms | N/A     | Slowest supported |
| Android Emulator   | API 30 (11.0) | Pending     | \_\_\_ms | N/A     |                   |
| Android Emulator   | API 33 (13.0) | Pending     | \_\_\_ms | N/A     | Latest            |

**For Each Device:**

1. Run integration test suite
2. Measure latency (procedure above)
3. Measure battery impact (30-minute session, physical devices only)
4. Document any device-specific issues or workarounds

---

## Performance Benchmarking

### Latency Breakdown Analysis

**Procedure:**

1. Instrument code with timestamps at each stage:

   - `t1`: Audio generated (reference time)
   - `t2`: Native buffer received
   - `t3`: JS event received
   - `t4`: Processing complete
   - `t5`: Visual update

2. Run 100 iterations, collect timestamps
3. Calculate component latencies:

   - Native: `t2 - t1`
   - Bridge: `t3 - t2`
   - Processing: `t4 - t3`
   - Visual: `t5 - t4`
   - Total: `t5 - t1`

4. Calculate percentiles (50th, 95th, 99th)
5. Document results in performance report

**Target Breakdown:**

| Component             | iOS Target | Android Target |
| --------------------- | ---------- | -------------- |
| Native (mic → buffer) | <40ms      | <50ms          |
| Bridge (native → JS)  | <10ms      | <15ms          |
| Processing (JS)       | <15ms      | <15ms          |
| Visual (render)       | <10ms      | <10ms          |
| **Total (E2E)**       | **<75ms**  | **<90ms**      |

---

### Battery Optimization Analysis

**Procedure:**

1. Measure battery impact in 4 configurations:

   - Baseline (no streaming)
   - Streaming (VAD disabled, adaptive disabled)
   - Streaming (VAD enabled, adaptive disabled)
   - Streaming (VAD enabled, adaptive enabled)

2. Calculate savings:

   - VAD savings = (No VAD %) - (VAD enabled %)
   - Adaptive savings = (Adaptive disabled %) - (Adaptive enabled %)

3. Document results in performance report

**Expected Savings:**

- VAD: 10-15% reduction in battery drain
- Adaptive processing: 15-25% reduction during low battery

---

### Memory Allocation Patterns

**Procedure:**

1. Profile memory allocations during streaming
2. Identify allocation hotspots:

   - Buffer allocations per frame
   - Event payload allocations
   - Temporary objects

3. Verify buffer pooling is active (reuse instead of allocate)
4. Document allocation patterns in performance report

**Expected Results:**

- Buffer pooling active (no allocations after warm-up)
- Event payloads reused where possible
- Steady-state allocations <10MB

---

## Report Generation

After completing all tests, compile results into:

**Performance Benchmark Report:**

- Location: `docs/voiceline/voicelinedsp-v0.2.0-performance-report.md`
- Template provided in this repository
- Include all metrics, screenshots, and device compatibility matrix

**Sections:**

1. Executive Summary (pass/fail status, key metrics)
2. Latency Analysis (breakdown by component, percentiles)
3. Battery Impact (baseline vs streaming, optimization effects)
4. Memory Profiling (allocation patterns, leak detection)
5. Audio Quality (dropout rates, cross-platform consistency)
6. Optimization Impact (VAD savings, adaptive processing savings)
7. Device Diversity (compatibility matrix, device-specific notes)
8. Conclusion and Recommendations

---

## Troubleshooting

### Common Issues

**Issue:** iOS tests fail with "Audio session activation failed"

- **Fix:** Check microphone permissions in Settings → Privacy → Microphone

**Issue:** Android tests fail with "PERMISSION_DENIED"

- **Fix:** Grant RECORD_AUDIO permission before running tests

**Issue:** High latency on emulator

- **Fix:** Emulator has additional buffering; test on physical device for accurate latency

**Issue:** Battery drain higher on older devices

- **Fix:** Expected; enable adaptive processing by default for older devices

**Issue:** Memory leaks detected

- **Fix:** Verify event listeners are removed on cleanup, coroutines are cancelled

---

## Appendix

### Test Data Files

- `ios-samples.txt` - iOS recorded samples
- `android-samples.txt` - Android recorded samples
- `ios-baseline-energy.trace` - iOS baseline energy profile
- `ios-streaming-energy.trace` - iOS streaming energy profile
- `android-baseline-battery.pdf` - Android baseline battery report
- `android-streaming-battery.pdf` - Android streaming battery report
- `ios-memory-profile.trace` - iOS memory profile
- `android-memory-profile.hprof` - Android heap dump

### Useful Commands

```bash
# iOS: Check console logs
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "VoicelineDSP"'

# Android: Check logcat
adb logcat | grep VoicelineDSP

# iOS: Capture screenshots
xcrun simctl io booted screenshot screenshot.png

# Android: Capture screenshots
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
```

---

**Version:** 1.0
**Last Updated:** 2025-11-13
**Status:** Ready for Testing
