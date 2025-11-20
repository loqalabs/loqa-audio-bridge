# Epic Technical Specification: Autolinking & Integration Proof

Date: 2025-11-14
Author: Anna
Epic ID: 3
Status: Draft

---

## Overview

Epic 3 focuses on **validating that Expo autolinking works seamlessly on both iOS and Android platforms** without requiring manual configuration, and creating a **working example application** that demonstrates proper integration patterns. This epic provides concrete proof that the v0.3.0 release eliminates the 9-hour integration process experienced in v0.2.0.

The epic consists of five critical validation stories:

1. **iOS autolinking validation** in a fresh Expo project (FR10, FR12)
2. **Android autolinking validation** in a fresh Expo project (FR11)
3. **Example app scaffolding** with proper configuration (FR30)
4. **Example app implementation** with audio streaming demo and visualization (FR30, FR33)
5. **Example app documentation and testing** on both platforms (FR31, FR32)

Success is measured by achieving installation-to-running-app time of **under 30 minutes** (vs. 9 hours in v0.2.0), with zero manual Podfile or build.gradle edits required.

## Objectives and Scope

### In Scope

**iOS Autolinking Validation:**

- Verify CocoaPods automatically discovers the module via `.podspec`
- Confirm no manual Podfile edits required
- Validate ExpoModulesProvider.swift automatically registers module
- Test fresh Expo project installation workflow

**Android Autolinking Validation:**

- Verify Gradle automatically discovers the module via `build.gradle`
- Confirm no manual `settings.gradle` edits required
- Validate module appears in Android Studio project structure
- Test fresh Expo project installation workflow

**Example Application:**

- Minimal Expo app demonstrating module integration
- Basic audio streaming with start/stop controls
- Real-time RMS (volume level) visualization
- Permission handling for both platforms
- Clear code comments explaining each integration step
- Comprehensive README with quick start instructions

**Integration Proof:**

- Document installation timing (target: <5 minutes)
- Validate builds succeed on both platforms
- Confirm audio streaming works without errors
- Demonstrate microphone permission handling

### Out of Scope

**Not Included in Epic 3:**

- Advanced example features (pitch detection, waveform visualization) - deferred to post-v0.3.0
- Expo Snack browser-based demo - deferred to Growth Features
- Multi-configuration testing app - deferred to Growth Features
- CI/CD automated autolinking tests - covered in Epic 5
- EAS Build validation - covered in Epic 5 (Story 5.4)
- Production deployment of example app - example is for reference only

**Assumptions:**

- Epic 2 is complete (compiled module with zero warnings and test exclusions)
- Module can be installed via local file path for testing (before npm publish)
- Developer has Xcode 14+ and Android Studio installed for testing
- iOS simulator and Android emulator are available for testing

## System Architecture Alignment

**Expo Autolinking Architecture:**

Epic 3 validates the autolinking configuration established in Epic 1 and implemented in Epic 2:

```
┌─────────────────────────────────────────┐
│   Fresh Expo Project (npx expo install) │
└───────────────┬─────────────────────────┘
                │
                ├─── iOS Autolinking
                │    ├─ Expo CLI reads LoqaAudioBridge.podspec
                │    ├─ Generates Podfile with pod 'LoqaAudioBridge'
                │    ├─ pod install links native Swift code
                │    └─ ExpoModulesProvider.swift auto-registers module
                │
                └─── Android Autolinking
                     ├─ Expo CLI reads build.gradle
                     ├─ Modifies settings.gradle to include module
                     ├─ Updates app/build.gradle dependencies
                     └─ Gradle links native Kotlin code
```

**Architecture Alignment:**

- **Decision 1 (Foundation Strategy)**: Epic 3 validates that `create-expo-module` scaffolding produces autolinking-ready structure
- **Decision 3 (Test Exclusion)**: Example app verifies that test files are excluded from npm package (no XCTest errors)
- **Section 3.1 (Project Structure)**: Example app follows recommended directory layout with proper separation
- **Section 7 (Integration Architecture)**: Epic 3 is the proof-of-concept for the documented integration flow

**Key Configuration Files Validated:**

| File                      | Purpose                   | Validation Point                |
| ------------------------- | ------------------------- | ------------------------------- |
| `expo-module.config.json` | Expo autolinking config   | iOS + Android discovery         |
| `LoqaAudioBridge.podspec` | CocoaPods specification   | iOS autolinking (Story 3.1)     |
| `android/build.gradle`    | Gradle module config      | Android autolinking (Story 3.2) |
| `example/app.json`        | Expo app configuration    | Permissions setup (Story 3.3)   |
| `example/App.tsx`         | Integration demonstration | API usage patterns (Story 3.4)  |

**Integration with Other Epics:**

- **Epic 1**: Provides the scaffolding and configuration files that Epic 3 validates
- **Epic 2**: Provides the compiled, tested module that Epic 3 integrates
- **Epic 4**: Uses example app as reference for documentation code samples
- **Epic 5**: CI/CD pipeline will automate Epic 3 validation tests

## Detailed Design

### Services and Modules

Epic 3 does not introduce new services or modules—it validates existing infrastructure from Epics 1 and 2. The key components being validated are:

| Component                 | Location             | Responsibility                                                              | Validation Story      |
| ------------------------- | -------------------- | --------------------------------------------------------------------------- | --------------------- |
| **Expo CLI Autolinking**  | System-provided      | Scans package for `expo-module.config.json`, `.podspec`, and `build.gradle` | Stories 3.1, 3.2      |
| **CocoaPods Integration** | iOS toolchain        | Reads `.podspec`, generates Podfile, links native code                      | Story 3.1             |
| **Gradle Integration**    | Android toolchain    | Reads `build.gradle`, modifies `settings.gradle`, links native code         | Story 3.2             |
| **Example App**           | `example/` directory | Demonstrates API usage, permission handling, event listeners                | Stories 3.3, 3.4, 3.5 |
| **Module Package**        | Root directory       | Installed via `npm install <local-path>` for testing                        | All stories           |

**Module Under Test:**

- **@loqalabs/loqa-audio-bridge** (from Epic 2)
  - TypeScript API layer
  - iOS native module (Swift)
  - Android native module (Kotlin)
  - Configuration files (podspec, build.gradle, expo-module.config.json)

### Data Models and Contracts

Epic 3 validates that the existing API contracts from v0.2.0 (preserved in Epic 2) work correctly in the autolinking environment:

**Audio Configuration (Input Contract):**

```typescript
interface AudioConfig {
  sampleRate: number; // 8000 | 16000 | 32000 | 44100 | 48000
  bufferSize: number; // 512-8192 (power of 2 on iOS)
  channels: 1 | 2; // Mono or stereo
  enableVAD?: boolean; // Voice Activity Detection (default: true)
}
```

**Audio Sample Event (Output Contract):**

```typescript
interface AudioSample {
  samples: Float32Array; // Raw audio data
  sampleRate: number; // Configured sample rate
  frameLength: number; // Number of samples in buffer
  timestamp: number; // Event timestamp (milliseconds)
  rms: number; // Root mean square (volume level)
  isSilent?: boolean; // VAD detection result
}
```

**Stream Status Event:**

```typescript
interface StreamStatus {
  status: 'streaming' | 'stopped' | 'paused' | 'battery_optimized';
  timestamp: number;
}
```

**Stream Error Event:**

```typescript
interface StreamError {
  code: string; // Error code (e.g., 'PERMISSION_DENIED')
  message: string; // Human-readable error
  platform: 'ios' | 'android';
  timestamp: number;
}
```

**Validation Focus:**

- Example app must successfully use these contracts
- Type definitions must compile without errors
- Events must fire correctly on both platforms
- No API changes from v0.2.0 (100% compatibility)

### APIs and Interfaces

Epic 3 validates the public API surface defined in Epic 2:

**Module Methods (Validated in Stories 3.4, 3.5):**

```typescript
// Start audio streaming
async function startAudioStream(config: AudioConfig): Promise<void>;
// Throws: Error if permission denied or invalid config
// Platform behavior: Requests microphone permission if not granted

// Stop audio streaming
async function stopAudioStream(): Promise<void>;
// Returns: Resolves when streaming fully stopped

// Check streaming status
function isStreaming(): boolean;
// Returns: true if currently streaming
```

**Event Listeners (Validated in Stories 3.4, 3.5):**

```typescript
// Listen for audio samples
function addAudioSamplesListener(callback: (event: AudioSample) => void): Subscription;
// Frequency: ~8 Hz at 16kHz/2048 config
// Platform: Works on iOS and Android

// Listen for status changes
function addStreamStatusListener(callback: (event: StreamStatus) => void): Subscription;

// Listen for errors
function addStreamErrorListener(callback: (event: StreamError) => void): Subscription;

// Subscription interface
interface Subscription {
  remove(): void; // Unsubscribe from events
}
```

**React Hook (Validated in Example App):**

```typescript
function useAudioStreaming(config: AudioConfig): {
  isStreaming: boolean;
  startStreaming: () => Promise<void>;
  stopStreaming: () => Promise<void>;
  audioSample: AudioSample | null;
  status: StreamStatus | null;
  error: StreamError | null;
};
// Auto-cleanup: Stops streaming on component unmount
```

**Platform-Specific APIs (Validated via Testing):**

- **iOS Permission**: `AVAudioSession.requestRecordPermission()`
- **Android Permission**: `PermissionsAndroid.request('RECORD_AUDIO')`
- Both must be handled gracefully in example app

### Workflows and Sequencing

**Story 3.1: iOS Autolinking Validation Workflow**

```
1. Create fresh directory outside module repo
2. Run: npx create-expo-app test-install
3. Run: cd test-install
4. Run: npm install /path/to/loqa-audio-bridge
   → package.json updated with local dependency
5. Run: npx expo prebuild --platform ios
   → Expo CLI scans for native modules
   → Reads LoqaAudioBridge.podspec
   → Generates ios/Podfile with pod entry
6. Run: npx pod-install
   → CocoaPods installs LoqaAudioBridge
   → Links Swift code to Xcode project
7. Open ios/*.xcworkspace in Xcode
   → Verify LoqaAudioBridge in Pods project
   → Verify ExpoModulesProvider.swift auto-generated
8. Build in Xcode
   → Success: Zero errors, module linked ✅
   → Failure: Log error, investigate autolinking issue ❌
9. Document timing (target: <5 minutes)
```

**Story 3.2: Android Autolinking Validation Workflow**

```
1. Use same fresh Expo project from Story 3.1
2. Run: npx expo prebuild --platform android
   → Expo CLI scans for native modules
   → Reads android/build.gradle
   → Modifies android/settings.gradle
   → Updates android/app/build.gradle
3. Open android/ in Android Studio
   → Verify LoqaAudioBridge module in project structure
4. Run: ./gradlew :app:assembleDebug
   → Gradle resolves LoqaAudioBridge dependency
   → Links Kotlin code to app
   → Success: APK built ✅
   → Failure: Log error, investigate autolinking issue ❌
5. Document timing (target: <5 minutes)
```

**Story 3.3: Example App Scaffolding Workflow**

```
1. Create example/ directory in module root
2. Run: npx create-expo-app example --template blank-typescript
3. Edit example/package.json:
   → Add dependency: "@loqalabs/loqa-audio-bridge": "file:.."
4. Run: npm install (in example/)
5. Edit example/app.json:
   → Add iOS microphone permission (NSMicrophoneUsageDescription)
   → Add Android permission (RECORD_AUDIO)
6. Run: npx expo prebuild (in example/)
7. Test build:
   → iOS: npx expo run:ios
   → Android: npx expo run:android
8. Validate: Apps build and launch successfully
```

**Story 3.4: Example App Implementation Workflow**

```
1. Create example/App.tsx with integration code
2. Implement UI components:
   → Permission status display
   → Start/Stop buttons
   → RMS visualization (bar or number)
   → Configuration display
3. Implement permission handling:
   → Request on mount (iOS and Android)
   → Handle denied permission gracefully
4. Implement audio streaming:
   → startAudioStream() on button press
   → addAudioSamplesListener() for RMS updates
   → stopAudioStream() on stop button
   → Clean up listeners on unmount
5. Add clear code comments (FR33)
6. Test on both platforms:
   → Verify permission prompts
   → Verify RMS updates in real-time
   → Verify start/stop functionality
```

**Story 3.5: Example App Testing Workflow**

```
1. Create example/README.md with quick start
2. Test iOS:
   → Run: npm install && npx expo run:ios
   → Time the process (target: <10 minutes)
   → Tap Start → Grant permission → Verify RMS updates
   → Tap Stop → Verify streaming stops
   → Check for crashes/errors
3. Test Android:
   → Run: npx expo run:android
   → Time the process (target: <10 minutes)
   → Tap Start → Grant permission → Verify RMS updates
   → Tap Stop → Verify streaming stops
   → Check for crashes/errors
4. Document results:
   → Build times
   → Integration time (install to running)
   → Any issues encountered
5. Validate: <30 minutes total integration time achieved ✅
```

## Non-Functional Requirements

### Performance

**NFR1: Integration Time Reduction (Primary Success Metric)**

- **Target**: Installation to running app in <30 minutes (vs. 9 hours in v0.2.0)
- **Measurement**: Time from `npm install` to successful `startAudioStream()` call
- **Breakdown**:
  - iOS autolinking validation: <5 minutes (Story 3.1)
  - Android autolinking validation: <5 minutes (Story 3.2)
  - Example app build (iOS): <10 minutes (Story 3.5)
  - Example app build (Android): <10 minutes (Story 3.5)
- **Validation**: Timed on M-series Mac with standard internet connection

**NFR2: Build Time Performance**

- **iOS Build**: <5 minutes from `npx expo run:ios` to app launch (M-series Mac)
- **Android Build**: <5 minutes from `npx expo run:android` to app launch
- **Rationale**: Fast iteration cycle for developers testing integration

**NFR3: Runtime Performance (Inherited from v0.2.0)**

- Module must maintain v0.2.0 performance characteristics:
  - CPU usage: 2-5% per core during active streaming
  - Memory footprint: 5-10 MB including buffer pool
  - Battery impact: 3-8%/hour with VAD enabled
  - Event rate: ~8 Hz at 16kHz/2048 buffer configuration
- **Validation**: Example app performance profiling on both platforms

**NFR4: No Performance Regression**

- Autolinking must not introduce latency vs. manual linking
- Module initialization time: <100ms
- First audio event delivery: <200ms after `startAudioStream()` call

### Security

**NFR5: Microphone Permission Handling**

- **iOS**: Must request permission via `NSMicrophoneUsageDescription` in Info.plist
- **Android**: Must request `RECORD_AUDIO` runtime permission (API 23+)
- **Graceful Denial**: App must not crash if permission denied
- **User Feedback**: Clear error message indicating permission required
- **Validation**: Example app demonstrates proper permission flow

**NFR6: No Data Leakage**

- Module must not transmit audio data externally
- All audio processing occurs locally on device
- No analytics or telemetry included in module
- **Validation**: Network traffic monitoring during example app testing

**NFR7: Secure Example App**

- Example app permissions limited to microphone only
- No unnecessary iOS capabilities or Android permissions
- Clear permission rationale in app.json configuration
- **Compliance**: Follows iOS App Store and Google Play privacy guidelines

### Reliability/Availability

**NFR8: Autolinking Success Rate**

- **Target**: 100% success rate in fresh Expo project installations
- **Validation**: CI tests will automate this in Epic 5
- **Manual Validation**: Stories 3.1 and 3.2 test on clean environment
- **Failure Handling**: If autolinking fails, provide actionable error message

**NFR9: Example App Stability**

- **Crash Rate**: Zero crashes during normal operation
- **Error Handling**: Graceful degradation on permission denial
- **Platform Coverage**: Must work on iOS 13.4+ and Android API 24+
- **Validation**: Manual testing on both platforms (Story 3.5)

**NFR10: Build Reproducibility**

- Same source code must produce identical builds across machines
- No dependency on developer's local environment configuration
- Fresh clone + npm install must work immediately
- **Validation**: Test on different Mac models and Linux VM

**NFR11: Platform Consistency**

- API behavior must be identical on iOS and Android
- Events must fire at same frequency on both platforms
- Error codes and messages must be consistent
- **Validation**: Side-by-side testing in example app

### Observability

**NFR12: Clear Build Feedback**

- Autolinking progress visible in terminal output
- CocoaPods installation shows "Installing LoqaAudioBridge"
- Gradle output shows "Project ':loqaaudiobridge' configured"
- Build failures include actionable error messages

**NFR13: Example App Instrumentation**

- Display current streaming status (streaming/stopped)
- Show real-time RMS values for validation
- Display sample rate and buffer size
- Show permission status (granted/denied/not requested)

**NFR14: Integration Timing Metrics**

- Document actual integration times for both platforms
- Compare against <30 minute target
- Identify any bottlenecks in the process
- **Deliverable**: Timing report in Story 3.5

**NFR15: Developer Feedback**

- Clear console logs for debugging
- Error messages include platform (iOS/Android)
- TypeScript types provide IntelliSense hints
- Example code comments explain each step (FR33)

## Dependencies and Integrations

### Module Dependencies (From Epic 2)

**Production Dependencies (Peer Dependencies):**

| Dependency          | Version  | Purpose                   | Epic 3 Validation                 |
| ------------------- | -------- | ------------------------- | --------------------------------- |
| `expo`              | >=52.0.0 | Expo Modules Core runtime | Required for autolinking          |
| `expo-modules-core` | \*       | Native module bridge      | Event emitters, module definition |
| `react`             | >=18.0.0 | React library             | Example app UI                    |
| `react-native`      | >=0.72.0 | React Native runtime      | Platform APIs, permissions        |

**Development Dependencies (Example App):**

| Dependency     | Version | Purpose                      |
| -------------- | ------- | ---------------------------- |
| `typescript`   | ^5.3.0  | Type checking in example app |
| `@types/react` | ^18.0.0 | React type definitions       |
| `expo-cli`     | latest  | Building and running example |

### Platform Integrations

**iOS Platform Dependencies:**

```ruby
# LoqaAudioBridge.podspec
Pod::Spec.new do |s|
  s.dependency 'ExpoModulesCore'
  # No additional iOS dependencies - uses native AVFoundation
end
```

**Native iOS Frameworks:**

- `AVFoundation` - Audio capture via AVAudioEngine (system framework)
- `UIKit` - Battery level monitoring (system framework)
- `ExpoModulesCore` - Expo native bridge (peer dependency)

**Android Platform Dependencies:**

```gradle
// android/build.gradle
dependencies {
  implementation project(':expo-modules-core')
  // No additional Android dependencies - uses native android.media
}
```

**Native Android Frameworks:**

- `android.media.AudioRecord` - Audio capture (system API)
- `android.os.BatteryManager` - Battery monitoring (system API)
- `expo.modules.kotlin` - Expo native bridge (peer dependency)

### External System Integrations

**Development Tools Required:**

| Tool               | Minimum Version | Purpose                       | Story       |
| ------------------ | --------------- | ----------------------------- | ----------- |
| **Xcode**          | 14.0+           | iOS builds                    | 3.1, 3.5    |
| **Android Studio** | Flamingo+       | Android builds                | 3.2, 3.5    |
| **Node.js**        | 18+             | npm, Expo CLI                 | All stories |
| **CocoaPods**      | 1.12+           | iOS dependency management     | 3.1         |
| **Gradle**         | 8.x             | Android dependency management | 3.2         |
| **Expo CLI**       | Latest          | Prebuild, autolinking         | All stories |

**Expo Autolinking Integration:**

```
Epic 3 Validation Flow:
┌─────────────────────────────────┐
│  @loqalabs/loqa-audio-bridge    │
│  (installed in node_modules/)   │
└───────────┬─────────────────────┘
            │
            ├─ expo-module.config.json
            │  → Expo CLI reads platform config
            │
            ├─ LoqaAudioBridge.podspec
            │  → CocoaPods discovers pod
            │  → Adds to Podfile automatically
            │
            └─ android/build.gradle
               → Gradle discovers module
               → Adds to settings.gradle automatically
```

### Integration Points Validated in Epic 3

**Story 3.1: iOS Autolinking Integration**

- **Entry Point**: `npx expo prebuild --platform ios`
- **Discovery**: Expo CLI scans `node_modules/@loqalabs/loqa-audio-bridge/LoqaAudioBridge.podspec`
- **Generation**: Creates `ios/Podfile` with pod entry
- **Linking**: `pod install` links Swift code to Xcode project
- **Registration**: ExpoModulesProvider.swift auto-generated with module registration

**Story 3.2: Android Autolinking Integration**

- **Entry Point**: `npx expo prebuild --platform android`
- **Discovery**: Expo CLI scans `node_modules/@loqalabs/loqa-audio-bridge/android/build.gradle`
- **Generation**: Modifies `android/settings.gradle` to include module
- **Linking**: Gradle syncs and links Kotlin code to app
- **Registration**: MainApplication auto-generated with module registration

**Story 3.3-3.5: Example App Integrations**

- **Local Module**: Uses `file:..` dependency for pre-publish testing
- **Permissions**: Integrates with iOS Info.plist and Android manifest
- **API Usage**: Demonstrates TypeScript → Native bridge
- **Event Flow**: Validates EventEmitter integration

## Acceptance Criteria (Authoritative)

### Epic-Level Acceptance Criteria

**AC1: iOS Autolinking Works Without Manual Configuration (FR10, FR12)**

- **Given** Epic 2 is complete (module compiled with zero warnings)
- **When** I create a fresh Expo project and install the module
- **Then** iOS autolinking discovers the module automatically
- **And** CocoaPods installs the module without manual Podfile edits
- **And** ExpoModulesProvider.swift auto-registers the module
- **And** Xcode build succeeds with zero errors
- **Validation**: Story 3.1 completion

**AC2: Android Autolinking Works Without Manual Configuration (FR11)**

- **Given** Epic 2 is complete (module compiled with zero warnings)
- **When** I create a fresh Expo project and install the module
- **Then** Android autolinking discovers the module automatically
- **And** Gradle links the module without manual settings.gradle edits
- **And** Android build succeeds with zero errors
- **Validation**: Story 3.2 completion

**AC3: Example App Demonstrates Integration (FR30, FR31, FR32, FR33)**

- **Given** autolinking validation passed (AC1, AC2)
- **When** I run the example app on both platforms
- **Then** the app builds successfully on iOS and Android
- **And** audio streaming starts when "Start" button tapped
- **And** RMS visualization updates in real-time
- **And** audio streaming stops when "Stop" button tapped
- **And** code includes clear comments explaining integration steps
- **And** no crashes or errors occur during normal operation
- **Validation**: Stories 3.3, 3.4, 3.5 completion

**AC4: Integration Time Target Achieved (FR13, NFR1)**

- **Given** all stories complete
- **When** I time the full integration process
- **Then** installation to running app takes <30 minutes
- **And** iOS autolinking completes in <5 minutes
- **And** Android autolinking completes in <5 minutes
- **And** example app builds in <10 minutes per platform
- **Validation**: Documented timing report in Story 3.5

**AC5: Zero Manual Steps Required (Epic Goal)**

- **Given** fresh Expo project installation
- **When** I follow only the example README instructions
- **Then** no manual Podfile edits required
- **And** no manual build.gradle edits required
- **And** no manual ExpoModulesProvider.swift edits required
- **And** no post-prebuild scripts or sed commands needed
- **Validation**: All five stories demonstrate zero manual configuration

### Story-Level Acceptance Criteria (Summary)

**Story 3.1: Validate iOS Autolinking in Fresh Expo Project**

1. Fresh Expo project created outside module repo ✅
2. Module installs via local file path ✅
3. `npx expo prebuild --platform ios` generates Podfile with module entry ✅
4. `npx pod-install` succeeds and shows "Installing LoqaAudioBridge" ✅
5. Xcode workspace includes LoqaAudioBridge in Pods project ✅
6. Xcode build succeeds with zero errors ✅
7. Integration timing documented (<5 minutes) ✅

**Story 3.2: Validate Android Autolinking in Fresh Expo Project**

1. Same fresh project from Story 3.1 used ✅
2. `npx expo prebuild --platform android` modifies settings.gradle ✅
3. Android Studio shows LoqaAudioBridge in project structure ✅
4. `./gradlew assembleDebug` succeeds ✅
5. Build output shows "Project ':loqaaudiobridge' configured" ✅
6. Integration timing documented (<5 minutes) ✅

**Story 3.3: Create Example App Scaffolding**

1. `example/` directory created with blank TypeScript template ✅
2. package.json includes `file:..` dependency ✅
3. app.json includes iOS microphone permission (NSMicrophoneUsageDescription) ✅
4. app.json includes Android RECORD_AUDIO permission ✅
5. `npx expo run:ios` builds and launches successfully ✅
6. `npx expo run:android` builds and launches successfully ✅

**Story 3.4: Implement Example App Audio Streaming Demo**

1. App.tsx imports module correctly ✅
2. Permission handling implemented for both platforms ✅
3. Start/Stop buttons functional ✅
4. RMS visualization updates in real-time (~8 Hz) ✅
5. Configuration display shows sample rate and buffer size ✅
6. Code includes clear explanatory comments (FR33) ✅
7. No crashes when starting/stopping streaming ✅

**Story 3.5: Add Example App Documentation and Testing**

1. example/README.md created with quick start instructions ✅
2. iOS test: npm install → npx expo run:ios → app runs (<10 min) ✅
3. iOS test: Permission granted → RMS updates → Stop works ✅
4. Android test: npx expo run:android → app runs (<10 min) ✅
5. Android test: Permission granted → RMS updates → Stop works ✅
6. Integration timing documented (total <30 minutes) ✅
7. Zero crashes or errors on both platforms ✅

## Traceability Mapping

### Functional Requirements Coverage

| FR       | Requirement                                                  | Epic 3 Story  | Validation Method          |
| -------- | ------------------------------------------------------------ | ------------- | -------------------------- |
| **FR10** | Enable iOS autolinking without manual Podfile edits          | 3.1           | Fresh project test         |
| **FR11** | Enable Android autolinking without manual build.gradle edits | 3.2           | Fresh project test         |
| **FR12** | Auto-register module in ExpoModulesProvider.swift            | 3.1           | Verify auto-generated file |
| **FR13** | Validate autolinking in fresh Expo project                   | 3.1, 3.2, 3.5 | Integration test           |
| **FR30** | Include working example/ directory with Expo app             | 3.3, 3.4      | Code review                |
| **FR31** | Example app builds and runs successfully                     | 3.5           | Manual testing             |
| **FR32** | Example demonstrates both iOS and Android                    | 3.5           | Platform testing           |
| **FR33** | Example includes clear code comments                         | 3.4           | Code review                |

### Non-Functional Requirements Coverage

| NFR       | Requirement                          | Epic 3 Story  | Measurement          |
| --------- | ------------------------------------ | ------------- | -------------------- |
| **NFR1**  | Integration time <30 minutes         | 3.1, 3.2, 3.5 | Timed testing        |
| **NFR5**  | Microphone permission handling       | 3.3, 3.4, 3.5 | Permission flow test |
| **NFR6**  | No data leakage                      | 3.5           | Network monitoring   |
| **NFR8**  | 100% autolinking success rate        | 3.1, 3.2      | Fresh project test   |
| **NFR9**  | Example app stability (zero crashes) | 3.5           | Manual testing       |
| **NFR10** | Build reproducibility                | 3.1, 3.2, 3.5 | Multi-machine test   |
| **NFR11** | Platform consistency                 | 3.5           | Side-by-side testing |

### Acceptance Criteria → Component → Test Mapping

| AC      | Component           | Test Method                        | Expected Outcome                     |
| ------- | ------------------- | ---------------------------------- | ------------------------------------ |
| **AC1** | iOS Autolinking     | Fresh Expo project install + build | CocoaPods links module automatically |
| **AC2** | Android Autolinking | Fresh Expo project install + build | Gradle links module automatically    |
| **AC3** | Example App         | Manual testing on both platforms   | Audio streaming works, no crashes    |
| **AC4** | Integration Process | Timed workflow execution           | <30 minutes total                    |
| **AC5** | Zero Manual Steps   | Fresh project walkthrough          | No manual edits required             |

### PRD Success Criteria → Epic 3 Validation

| PRD Success Criteria                            | Epic 3 Validation                      |
| ----------------------------------------------- | -------------------------------------- |
| **Integration time <30 minutes**                | Story 3.5 timing report                |
| **Zero manual steps**                           | Stories 3.1, 3.2 prove no manual edits |
| **Autolinking works seamlessly**                | Stories 3.1, 3.2 fresh project tests   |
| **Example app demonstrates features**           | Stories 3.3, 3.4, 3.5 implementation   |
| **Clear error messages**                        | Story 3.4 permission denial handling   |
| **Documentation answers integration questions** | Story 3.5 example README               |

### Architecture Decision → Epic 3 Proof

| Architecture Decision                          | Epic 3 Validation                                                          |
| ---------------------------------------------- | -------------------------------------------------------------------------- |
| **Decision 1: create-expo-module scaffolding** | Stories 3.1, 3.2 validate scaffolding produces autolinking-ready structure |
| **Decision 3: Multi-layer test exclusion**     | Story 3.1 verifies no XCTest errors (tests excluded from package)          |
| **Section 7: Integration Architecture**        | Epic 3 entire epic is proof-of-concept for documented integration flow     |

## Risks, Assumptions, Open Questions

### Risks

**RISK-1: Autolinking Fails in Fresh Project (Medium Probability, High Impact)**

- **Description**: Expo autolinking may not discover module due to misconfigured files
- **Impact**: Epic 3 validation fails, blocks v0.3.0 release
- **Mitigation**:
  - Story 3.1 and 3.2 test on clean environments (not developer machines)
  - Use exact scaffolding from Epic 1 (create-expo-module)
  - Validate podspec and build.gradle syntax before testing
  - Test on Docker container or fresh VM for reproducibility
- **Contingency**: If autolinking fails, revert to Epic 1 scaffolding review

**RISK-2: Platform-Specific Build Failures (Low Probability, Medium Impact)**

- **Description**: iOS or Android builds may fail due to environment issues (Xcode/Gradle versions)
- **Impact**: Cannot validate autolinking on one platform
- **Mitigation**:
  - Document exact tool versions in acceptance criteria
  - Test on known-good Xcode 15.0+ and Android Studio Flamingo+
  - Use GitHub Actions macOS and Ubuntu runners for validation (Epic 5)
- **Contingency**: Document platform-specific requirements in troubleshooting guide

**RISK-3: Example App Permission Handling Issues (Medium Probability, Low Impact)**

- **Description**: Permission requests may behave differently on simulators vs. real devices
- **Impact**: Example app may not demonstrate permissions correctly
- **Mitigation**:
  - Test on both iOS simulator and physical device
  - Test on both Android emulator and physical device
  - Handle permission denial gracefully with clear error messages
- **Contingency**: Add troubleshooting section to example README

**RISK-4: Integration Time Exceeds 30 Minutes (Low Probability, Medium Impact)**

- **Description**: Build times on slower machines may exceed target
- **Impact**: NFR1 not met, success criteria partially failed
- **Mitigation**:
  - Time on standard hardware (M-series Mac, not Intel)
  - Optimize example app build (minimal dependencies)
  - Cache CocoaPods and Gradle dependencies
- **Contingency**: Adjust target to 45 minutes with footnote about hardware requirements

**RISK-5: Test File Exclusion Failure (Low Probability, High Impact)**

- **Description**: Test files may ship to example app despite podspec exclusions
- **Impact**: XCTest import errors during integration (v0.2.0 bug repeats)
- **Mitigation**:
  - Multi-layer exclusion strategy from Epic 2 (Decision 3)
  - Validate with `npm pack` and tarball inspection
  - CI validation in Epic 5 automates this check
- **Contingency**: Emergency fix to podspec and re-test

### Assumptions

**ASSUMPTION-1: Epic 2 Complete with Zero Warnings**

- Epic 3 assumes all Epic 2 stories are done (2.1-2.8)
- Module compiles successfully on both platforms
- Test exclusions working correctly
- **Validation**: Epic 2 retrospective confirms completion

**ASSUMPTION-2: Developer Has Required Tools Installed**

- Xcode 14+ and CocoaPods for iOS validation
- Android Studio Flamingo+ and Gradle 8.x for Android validation
- Node.js 18+ and Expo CLI latest version
- **Impact**: If tools missing, autolinking tests cannot run

**ASSUMPTION-3: Local File Installation Works for Pre-Publish Testing**

- `npm install /path/to/module` works for testing before npm publish
- Expo autolinking scans node_modules for local modules
- **Validation**: Story 3.1 and 3.2 will confirm this assumption

**ASSUMPTION-4: Fresh Expo Project == Production Integration**

- Testing in fresh Expo project accurately represents real-world integration
- No hidden dependencies on developer's global environment
- **Validation**: Testing on Docker or clean VM confirms this

**ASSUMPTION-5: RMS Visualization Sufficient for Example**

- Simple RMS (volume level) display adequate for demonstrating integration
- Advanced visualizations (waveform, spectrogram) deferred to post-v0.3.0
- **Rationale**: Focus on integration proof, not feature showcase

### Open Questions

**Q1: Should Example App Use useAudioStreaming Hook or Direct API?**

- **Options**:
  - A) Use `useAudioStreaming` hook (simpler, recommended pattern)
  - B) Use direct API calls (shows more detail)
  - C) Show both patterns in separate components
- **Decision Needed**: Before Story 3.4
- **Recommendation**: Option A (hook) for simplicity, mention direct API in comments

**Q2: What RMS Threshold Should Example Use for "Silence" Indicator?**

- **Options**:
  - A) Use default threshold from module (0.01)
  - B) Make threshold configurable in UI
  - C) Just show raw RMS value, no silence detection
- **Decision Needed**: Before Story 3.4
- **Recommendation**: Option C (raw RMS) for simplicity

**Q3: Should Example App Work on Expo Go or Require Dev Client?**

- **Context**: Native modules don't work in Expo Go, require dev client
- **Options**:
  - A) Require dev client (realistic integration)
  - B) Add note that Expo Go not supported
- **Decision Needed**: Before Story 3.3
- **Recommendation**: Option A + B (dev client required, document clearly)

**Q4: How to Handle iOS Simulator Microphone Limitation?**

- **Context**: iOS simulator doesn't have microphone, requires physical device
- **Options**:
  - A) Document in README: "Use physical device for iOS testing"
  - B) Mock audio input on simulator
  - C) Gracefully handle "no microphone" error
- **Decision Needed**: Before Story 3.5
- **Recommendation**: Option A + C (document + graceful error)

**Q5: Should Epic 3 Include Performance Profiling?**

- **Context**: NFR3 mentions validating v0.2.0 performance characteristics
- **Options**:
  - A) Include basic CPU/memory profiling in Story 3.5
  - B) Defer profiling to Epic 5 (CI/CD performance tests)
  - C) Just document "no noticeable lag" qualitatively
- **Decision Needed**: Before Story 3.5
- **Recommendation**: Option C for Epic 3, defer quantitative to Epic 5

## Test Strategy Summary

### Testing Approach

Epic 3 uses **manual validation testing** to prove autolinking and integration work correctly. Automated tests will be added in Epic 5.

**Test Levels:**

1. **Integration Testing** (Stories 3.1, 3.2)

   - Fresh Expo project installation
   - Autolinking discovery and linking
   - Build success validation
   - Platform: Both iOS and Android

2. **End-to-End Testing** (Stories 3.3-3.5)

   - Example app build and launch
   - Permission request flow
   - Audio streaming functionality
   - UI responsiveness
   - Platform: Both iOS and Android

3. **Timing Validation** (All Stories)
   - Measure installation time
   - Measure build time
   - Compare against <30 minute target
   - Document any bottlenecks

### Test Environments

**iOS Testing:**

- **Hardware**: M-series Mac or recent Intel Mac
- **Software**: macOS 13+, Xcode 15.0+, CocoaPods 1.12+
- **Targets**:
  - iOS Simulator 17.0 (for build validation)
  - Physical iPhone (iOS 15.0+) for full audio testing
- **Clean Environment**: Test on Docker macOS image or fresh VM

**Android Testing:**

- **Hardware**: Mac, Linux, or Windows with Android Studio
- **Software**: Android Studio Flamingo+, Gradle 8.x
- **Targets**:
  - Android Emulator API 34 (for build validation)
  - Physical Android device (API 26+) for full audio testing
- **Clean Environment**: Test on Docker Ubuntu image

### Test Cases

**TC-1: iOS Autolinking (Story 3.1)**

- **Steps**: Create fresh Expo project → Install module → Prebuild iOS → Build
- **Expected**: Build succeeds with zero errors, module linked
- **Validation**: Xcode workspace contains LoqaAudioBridge pod

**TC-2: Android Autolinking (Story 3.2)**

- **Steps**: Use same project → Prebuild Android → Build
- **Expected**: Build succeeds with zero errors, module linked
- **Validation**: Gradle output shows module configured

**TC-3: Example App Build (Story 3.3)**

- **Steps**: Create example app → Configure permissions → Build both platforms
- **Expected**: Both builds succeed, apps launch
- **Validation**: Apps display UI without crashes

**TC-4: Audio Streaming (Story 3.4)**

- **Steps**: Tap Start → Grant permission → Observe RMS → Tap Stop
- **Expected**: RMS updates ~8 Hz, stops when button tapped
- **Validation**: Console logs show audio events

**TC-5: Permission Denial (Story 3.4)**

- **Steps**: Tap Start → Deny permission
- **Expected**: Clear error message, no crash
- **Validation**: UI shows "Permission denied" state

**TC-6: Integration Timing (Story 3.5)**

- **Steps**: Time full workflow from npm install to running app
- **Expected**: <30 minutes total (iOS + Android)
- **Validation**: Documented timing report

### Success Criteria

**Epic 3 passes if:**

- ✅ All 5 stories complete with acceptance criteria met
- ✅ iOS autolinking works (TC-1 passes)
- ✅ Android autolinking works (TC-2 passes)
- ✅ Example app builds and runs (TC-3, TC-4 pass)
- ✅ Integration time <30 minutes (TC-6 passes)
- ✅ Zero manual configuration steps required
- ✅ No test files cause build errors (validates Epic 2)

**Epic 3 fails if:**

- ❌ Autolinking requires manual Podfile or build.gradle edits
- ❌ Example app crashes during normal operation
- ❌ Integration time exceeds 45 minutes (hard limit)
- ❌ XCTest import errors appear (test exclusion failed)
- ❌ Cannot reproduce on clean environment

### Defect Management

**Blocking Defects** (Halt epic, must fix):

- Autolinking not working
- Module cannot be imported
- Example app crashes on launch
- Build errors on clean environment

**Non-Blocking Defects** (Document, fix in Epic 4 or 5):

- Slow build times (>10 min but <15 min)
- Permission UI could be clearer
- Example README missing troubleshooting section
- RMS visualization framerate slightly low

### Test Deliverables

**Story 3.1:** iOS autolinking validation report (timing, screenshots)
**Story 3.2:** Android autolinking validation report (timing, screenshots)
**Story 3.3:** Example app scaffolding (code + configuration)
**Story 3.4:** Example app implementation (code + UI)
**Story 3.5:** Integration timing report + example README

---

**Tech Spec Status:** Complete - Ready for Implementation
**Next Steps:** Begin Story 3.1 (Validate iOS Autolinking) after Epic 2 completion
