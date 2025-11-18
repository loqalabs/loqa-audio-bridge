# Epic Technical Specification: Code Migration & Quality Fixes

Date: 2025-11-13
Author: Anna
Epic ID: 2
Status: Draft

---

## Overview

Epic 2 transforms the working v0.2.0 VoicelineDSP prototype code into production-ready @loqalabs/loqa-audio-bridge v0.3.0 by systematically migrating TypeScript, Swift, and Kotlin implementations into the properly scaffolded structure created in Epic 1. This epic fixes critical compilation errors discovered during v0.2.0 integration (missing `required` keyword in Swift init, deprecated `.allowBluetooth` API), implements multi-layered test exclusions to prevent XCTest import failures, and validates 100% feature parity preservation through comprehensive test migration. The result is a compilable, zero-warning module with all v0.2.0 capabilities intact (real-time streaming, VAD, adaptive battery optimization) ready for autolinking validation in Epic 3.

## Objectives and Scope

**In Scope:**
- Migration of all TypeScript source files (index.ts, module bindings, types, buffer utilities, React hooks) with module renaming from VoicelineDSP to LoqaAudioBridge
- Migration of iOS Swift implementation with compilation fixes (FR6: add `required` keyword, FR7: update deprecated Bluetooth API)
- Migration of Android Kotlin implementation with proper package/class naming updates
- Implementation of multi-layered test exclusion (podspec exclude_files, .npmignore, tsconfig.json exclusions) to prevent v0.2.0 test shipping bug
- Migration and execution of all v0.2.0 tests (TypeScript unit, iOS Swift unit/integration, Android Kotlin unit/instrumented) with zero failures
- Achievement of zero compilation warnings across all platforms (iOS Swift, Android Kotlin, TypeScript, ESLint)
- Validation of 100% API surface preservation (FR14-FR20: streaming API, VAD, adaptive processing, event architecture, React hooks, TypeScript types)

**Out of Scope:**
- Feature additions or enhancements (deferred to v0.4.0+)
- Autolinking validation (Epic 3 responsibility)
- Documentation creation (Epic 4 responsibility)
- Example app development (Epic 3 responsibility)
- CI/CD pipeline setup (Epic 5 responsibility)
- npm package publishing (Epic 5 responsibility)

## System Architecture Alignment

This epic implements **Architecture Decision 3 (Multi-Layered Test Exclusion)** from the architecture document through coordinated configuration across four layers:

1. **Layer 1 (iOS Podspec)**: `s.exclude_files = ["ios/Tests/**/*", "ios/**/*Tests.swift"]` prevents CocoaPods from including test files in client projects
2. **Layer 2 (Android Gradle)**: Leverages Gradle convention-based exclusion of `src/test/` and `src/androidTest/` directories
3. **Layer 3 (npm Package)**: `.npmignore` excludes `__tests__/`, `*.test.ts`, `ios/Tests/`, `android/src/test/` from published tarball
4. **Layer 4 (TypeScript Compilation)**: `tsconfig.json` excludes test patterns from build output

The migration aligns with **Decision 1 (Foundation Strategy)** by populating the `create-expo-module` scaffolded structure with v0.2.0 implementation code, and **Decision 5 (TypeScript Configuration)** by compiling with strict mode enabled. All code changes preserve the production architecture described in Section 1.3 (React Native → Expo Modules Core → iOS AVAudioEngine / Android AudioRecord) without architectural modifications.

## Detailed Design

### Services and Modules

| Module | Responsibility | Input | Output | Owner/Location |
|--------|---------------|-------|--------|----------------|
| **index.ts** | Main API entry point, re-exports all public interfaces | N/A | TypeScript API surface (startAudioStream, stopAudioStream, isStreaming, listeners) | `index.ts` (root) |
| **LoqaAudioBridgeModule.ts** | Native module bindings via Expo Modules Core | Function calls from JS | Native method invocations, EventEmitter subscriptions | `src/LoqaAudioBridgeModule.ts` |
| **types.ts** | TypeScript type definitions and interfaces | N/A | AudioConfig, AudioSampleEvent, StreamStatusEvent, StreamErrorEvent types | `src/types.ts` |
| **buffer-utils.ts** | Audio buffer manipulation utilities | Audio sample arrays, format specs | Converted/validated buffers | `src/buffer-utils.ts` |
| **useAudioStreaming.tsx** | React hook for lifecycle management | StreamConfig | { isStreaming, start, stop, samples } hook return | `hooks/useAudioStreaming.tsx` |
| **LoqaAudioBridgeModule.swift** | iOS native implementation via AVAudioEngine | startAudioStream(config), stopAudioStream() | Audio sample events via EventEmitter | `ios/LoqaAudioBridgeModule.swift` |
| **LoqaAudioBridgeModule.kt** | Android native implementation via AudioRecord | startAudioStream(config), stopAudioStream() | Audio sample events via EventEmitter | `android/src/main/java/expo/modules/loqaaudiobridge/LoqaAudioBridgeModule.kt` |

**Migration Strategy:** Direct file copy from v0.2.0 with systematic renaming:
- All `VoicelineDSP` → `LoqaAudioBridge` replacements
- iOS class name update in Swift file
- Android package name update: `expo.modules.voicelinedsp` → `expo.modules.loqaaudiobridge`
- TypeScript module imports updated to reflect new file paths in scaffolded structure

### Data Models and Contracts

**TypeScript Interfaces (src/types.ts):**

```typescript
// Stream Configuration
export interface AudioConfig {
  sampleRate: number;        // 8000-48000 Hz
  bufferSize: number;         // 512-8192 samples (power-of-2 on iOS)
  channels: number;           // 1 (mono) or 2 (stereo)
  enableVAD?: boolean;        // Default: true
  vadThreshold?: number;      // Default: 0.01 (RMS threshold)
  enableBatterySaver?: boolean; // Default: true
}

// Audio Sample Event
export interface AudioSampleEvent {
  samples: number[];          // Float32 array [-1.0, 1.0]
  sampleRate: number;         // Actual sample rate
  frameLength: number;        // Number of samples in this frame
  timestamp: number;          // Timestamp in milliseconds
  rms: number;                // Computed RMS amplitude
}

// Stream Status Event
export interface StreamStatusEvent {
  status: 'streaming' | 'stopped' | 'paused' | 'battery_optimized';
}

// Stream Error Event
export interface StreamErrorEvent {
  code: string;               // Error code (e.g., 'PERMISSION_DENIED')
  message: string;            // Human-readable error message
  platform: 'ios' | 'android'; // Platform where error occurred
  timestamp: number;          // Error timestamp
}
```

**Swift Types (iOS):**
- Native AVAudioEngine types (AVAudioPCMBuffer, AVAudioFormat)
- RMS calculation: `Float` (single-precision)
- Battery level: `Float` from UIDevice.current.batteryLevel

**Kotlin Types (Android):**
- Native AudioRecord types (ShortArray, FloatArray)
- RMS calculation: `Float` (Kotlin)
- Battery level: `Int` from BatteryManager.BATTERY_PROPERTY_CAPACITY

**Data Flow Contract:**
1. JavaScript calls `startAudioStream(config)` with AudioConfig
2. Native module validates config, initializes audio engine
3. Audio tap/callback fires at ~8Hz rate (16kHz/2048 default)
4. Native computes RMS, checks VAD threshold
5. If RMS > threshold OR VAD disabled: emit onAudioSamples event
6. JavaScript EventEmitter delivers AudioSampleEvent to listeners
7. React hook manages subscription lifecycle automatically

### APIs and Interfaces

**Public JavaScript API (exported from index.ts):**

```typescript
// Core Functions
export function startAudioStream(config: AudioConfig): Promise<boolean>;
export function stopAudioStream(): boolean;
export function isStreaming(): boolean;

// Event Listeners
export function addAudioSamplesListener(
  callback: (event: AudioSampleEvent) => void
): Subscription;

export function addStreamStatusListener(
  callback: (event: StreamStatusEvent) => void
): Subscription;

export function addStreamErrorListener(
  callback: (event: StreamErrorEvent) => void
): Subscription;

// React Hook
export function useAudioStreaming(config?: AudioConfig): {
  isStreaming: boolean;
  start: () => Promise<void>;
  stop: () => void;
  samples: AudioSampleEvent | null;
  error: StreamErrorEvent | null;
};
```

**Native Module Interface (Expo Modules Core):**

**iOS (Swift):**
```swift
public class LoqaAudioBridgeModule: Module {
  public func definition() -> ModuleDefinition {
    Name("LoqaAudioBridge")

    AsyncFunction("startAudioStream") { (config: AudioConfig) -> Bool in
      // Start AVAudioEngine with config
      return true
    }

    Function("stopAudioStream") { () -> Bool in
      // Stop engine, cleanup
      return true
    }

    Function("isStreaming") { () -> Bool in
      return engine.isRunning
    }

    Events("onAudioSamples", "onStreamStatusChange", "onStreamError")
  }
}
```

**Android (Kotlin):**
```kotlin
class LoqaAudioBridgeModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("LoqaAudioBridge")

    AsyncFunction("startAudioStream") { config: Map<String, Any> ->
      // Start AudioRecord with config
      true
    }

    Function("stopAudioStream") {
      // Stop recording, cleanup
      true
    }

    Function("isStreaming") {
      isRecording
    }

    Events("onAudioSamples", "onStreamStatusChange", "onStreamError")
  }
}
```

**Error Codes:**
- `PERMISSION_DENIED`: Microphone permission not granted
- `INVALID_CONFIG`: Invalid sample rate or buffer size
- `DEVICE_UNAVAILABLE`: Audio device not accessible
- `ENGINE_START_FAILED`: AVAudioEngine/AudioRecord initialization failed
- `ALREADY_STREAMING`: Attempted to start while already active

### Workflows and Sequencing

**Story 2.0 - Migration Feasibility Validation (GATE):**
```
1. Developer copies buffer-utils.ts → src/buffer-utils.ts
2. Run `npx tsc` → Verify compiles successfully
3. Developer copies partial Swift audio capture code → ios/LoqaAudioBridgeModule.swift
4. Run `xcodebuild build` → Verify compiles successfully
5. Developer copies partial Kotlin audio record code → android/src/main/java/.../LoqaAudioBridgeModule.kt
6. Run `./gradlew build` → Verify compiles successfully
7. IF any failures: HALT, escalate to architect, document blockers
8. IF all pass: Proceed to Story 2.1
```

**Story 2.1-2.4 - Code Migration Sequence:**
```
2.1: TypeScript Migration
  → Copy all .ts/.tsx files
  → Update imports (paths, module names)
  → Run `npx tsc` → Fix errors
  → Verify API exports match v0.2.0

2.2: iOS Swift Migration
  → Copy VoicelineDSPModule.swift → ios/LoqaAudioBridgeModule.swift
  → Update class name globally
  → Fix FR6: Add `required` keyword to init override
  → Fix FR7: Change `.allowBluetooth` → `.allowBluetoothA2DP`
  → Run `xcodebuild build` → Zero warnings

2.3: iOS Podspec Test Exclusion
  → Update LoqaAudioBridge.podspec with exclude_files
  → Add test_spec for development tests
  → Run `pod spec lint` → Passes
  → Run `npm pack` → Verify no test files in tarball

2.4: Android Kotlin Migration
  → Copy VoicelineDSPModule.kt → android/.../LoqaAudioBridgeModule.kt
  → Update package name to expo.modules.loqaaudiobridge
  → Update build.gradle configuration
  → Run `./gradlew build` → Zero warnings
```

**Story 2.5-2.7 - Test Migration Sequence:**
```
2.5: TypeScript Tests
  → Copy __tests__/*.test.ts files
  → Update imports for new module name
  → Configure Jest in package.json
  → Run `npm test` → All pass (zero failures)

2.6: iOS Tests
  → Copy ios/Tests/*.swift test files
  → Update test class names
  → Run `xcodebuild test` → All pass

2.7: Android Tests
  → Copy android/src/test/ and android/src/androidTest/ files
  → Update package names and class references
  → Run `./gradlew test` → Unit tests pass
  → Run `./gradlew connectedAndroidTest` → Integration tests pass
```

**Story 2.8 - Zero Warnings Validation:**
```
1. Run iOS build: `xcodebuild ... clean build` → 0 warnings
2. Run Android build: `./gradlew clean build` → 0 warnings
3. Run TypeScript: `npx tsc` → 0 errors, 0 warnings
4. Run linter: `npm run lint` → 0 errors, 0 warnings
5. Fix any issues discovered → Re-run all builds
6. Document completion when all platforms show zero warnings
```

## Non-Functional Requirements

### Performance

**NFR-P1: Compilation Time**
- TypeScript compilation (`npx tsc`): Complete in <10 seconds on standard Mac hardware
- iOS build (`xcodebuild build`): Complete in <3 minutes on M-series Mac
- Android build (`./gradlew build`): Complete in <2 minutes on M-series Mac
- Measurement: Time from clean state to successful build completion

**NFR-P2: Test Execution Time**
- TypeScript unit tests (`npm test`): Complete in <30 seconds
- iOS tests (`xcodebuild test`): Complete in <2 minutes
- Android unit tests (`./gradlew test`): Complete in <1 minute
- Rationale: Fast test feedback loop for development

**NFR-P3: Runtime Performance Preservation (FR14-FR16)**
- CPU usage: Maintain v0.2.0 baseline of 2-5% per core during active streaming
- Memory footprint: Maintain 5-10 MB including buffer pool
- Battery impact: Maintain 3-8%/hour with VAD enabled
- Event rate: Maintain ~8 Hz at 16kHz/2048 buffer configuration
- Validation: Profiling comparison between v0.2.0 and v0.3.0 implementations

**NFR-P4: Code Migration Efficiency**
- Story 2.0 (feasibility validation): Complete in <2 hours
- Stories 2.1-2.4 (code migration): Complete in <8 hours total
- Stories 2.5-2.7 (test migration): Complete in <4 hours total
- Story 2.8 (zero warnings): Complete in <2 hours
- Rationale: Epic 2 should complete in 2-3 development days

### Security

**NFR-S1: No Security Regression**
- Preserve v0.2.0 microphone permission handling on both platforms
- iOS: NSMicrophoneUsageDescription must be present in Info.plist
- Android: RECORD_AUDIO runtime permission must be requested
- No new security vulnerabilities introduced during migration

**NFR-S2: Test Exclusion Security**
- Test files must not ship to production (prevents XCTest dependency exposure)
- Four-layer exclusion prevents accidental test file inclusion in npm package
- Validation: `npm pack` inspection shows zero test files in tarball

**NFR-S3: Code Review Requirements**
- All Swift compilation fixes (FR6, FR7) reviewed for security impact
- No hardcoded credentials or sensitive data in migrated code
- Deprecated API replacements validated for security equivalence

### Reliability/Availability

**NFR-R1: Zero Compilation Errors (FR9)**
- iOS Swift: 100% successful build with zero errors
- Android Kotlin: 100% successful build with zero errors
- TypeScript: 100% successful compilation with zero errors
- Mandatory gate: No story marked complete if compilation fails

**NFR-R2: Zero Compilation Warnings (FR9)**
- iOS Swift: Build output shows **0 warnings**
- Android Kotlin: Build output shows **0 warnings**
- TypeScript: Compilation shows **0 warnings**
- ESLint: Linting shows **0 errors, 0 warnings**
- Rationale: Warnings indicate potential code quality/reliability issues

**NFR-R3: Test Pass Rate (FR20)**
- TypeScript unit tests: 100% pass rate (zero failures)
- iOS Swift tests: 100% pass rate (zero failures)
- Android Kotlin tests: 100% pass rate (zero failures)
- Mandatory: All v0.2.0 tests must pass without modification

**NFR-R4: API Compatibility (FR19)**
- 100% backward compatibility with v0.2.0 TypeScript API surface
- All function signatures unchanged
- All TypeScript types unchanged
- All EventEmitter event contracts unchanged
- Validation: TypeScript type checking confirms no breaking changes

**NFR-R5: Feature Parity (FR14-FR18)**
- Voice Activity Detection (VAD) functionality preserved with identical behavior
- Adaptive battery optimization preserved with identical thresholds
- Event-driven architecture preserved (onAudioSamples, onStreamStatusChange, onStreamError)
- React hook (useAudioStreaming) functionality preserved
- Validation: Integration tests from v0.2.0 pass without modification

### Observability

**NFR-O1: Build Output Transparency**
- iOS build: Display all warnings/errors to console (none should appear)
- Android build: Display all warnings/errors to console (none should appear)
- TypeScript compilation: Display all errors/warnings to console (none should appear)
- Developer visibility into compilation status at all times

**NFR-O2: Test Execution Visibility**
- TypeScript tests: Jest output shows pass/fail status for each test
- iOS tests: XCTest output shows pass/fail status for each test
- Android tests: Gradle output shows pass/fail status for each test
- Clear indication when test suite completes successfully

**NFR-O3: Migration Progress Tracking**
- Each story (2.0-2.8) has clear completion criteria
- Developer can measure progress through 9 discrete milestones
- Story 2.0 serves as explicit GATE preventing wasted effort on blocked migration

**NFR-O4: Error Message Quality**
- Compilation errors provide actionable information (file, line number, specific issue)
- Test failures show expected vs actual values
- Linting errors show rule violation and suggested fix
- No cryptic error messages that require external research

## Dependencies and Integrations

**Epic 1 Dependency (Prerequisite):**
- Epic 2 requires Epic 1 (Foundation & Scaffolding) to be 100% complete
- Scaffolded structure must exist: package.json, expo-module.config.json, LoqaAudioBridge.podspec, android/build.gradle
- All Epic 1 configuration files must be in place before code migration begins
- Validation: Epic 1 stories 1.1-1.4 marked as "done" in sprint-status.yaml

**External Dependencies (Preserved from v0.2.0):**

| Dependency | Version/Constraint | Purpose | Platform | Migration Impact |
|------------|-------------------|---------|----------|------------------|
| **expo** | >=52.0.0 | Expo Modules Core framework | All | Peer dependency - no change |
| **react** | >=18.0.0 | React library | All | Peer dependency - no change |
| **react-native** | >=0.72.0 | React Native runtime | All | Peer dependency - no change |
| **typescript** | ^5.3.0 | TypeScript compiler | Dev | Dev dependency - verify version compatible with Expo 52+ |
| **@types/react** | ^18.0.0 | React type definitions | Dev | Dev dependency - no change |
| **eslint** | ^8.0.0 | Code linting | Dev | Dev dependency - configure with Expo preset |
| **prettier** | ^3.0.0 | Code formatting | Dev | Dev dependency - configure per Decision 6 |
| **jest** | ^29.0.0 | Testing framework | Dev | Dev dependency - configure with expo preset |
| **@testing-library/react-native** | ^12.0.0 | React Native testing utilities | Dev | Dev dependency - for hook testing |

**iOS Native Dependencies:**
```ruby
# LoqaAudioBridge.podspec
s.dependency 'ExpoModulesCore'
# iOS uses system frameworks (no additional CocoaPods dependencies):
# - AVFoundation (audio capture via AVAudioEngine)
# - UIKit (battery monitoring)
```

**Android Native Dependencies:**
```gradle
// android/build.gradle
dependencies {
  implementation project(':expo-modules-core')
  // Android uses system APIs (no additional Gradle dependencies):
  // - android.media.AudioRecord (audio capture)
  // - android.os.BatteryManager (battery monitoring)
}
```

**Test Dependencies:**
```json
// package.json (devDependencies)
{
  "jest": "^29.0.0",
  "@testing-library/react-native": "^12.0.0",
  "@testing-library/jest-native": "^5.0.0"
}
```

**iOS Test Dependencies (test_spec in podspec):**
```ruby
s.test_spec 'Tests' do |test_spec|
  test_spec.dependency 'Quick', '~> 7.0'     # BDD testing framework
  test_spec.dependency 'Nimble', '~> 12.0'   # Matchers for Quick
end
```

**Android Test Dependencies:**
```gradle
// android/build.gradle
testImplementation 'junit:junit:4.13.2'
testImplementation 'org.mockito:mockito-core:5.3.1'
androidTestImplementation 'androidx.test.ext:junit:1.1.5'
androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
```

**Integration Points:**

1. **Expo Modules Core EventEmitter**: Migration must preserve EventEmitter subscription pattern for onAudioSamples, onStreamStatusChange, onStreamError events
2. **AVAudioEngine (iOS)**: Swift code must maintain correct AVAudioSession configuration and audio tap installation
3. **AudioRecord (Android)**: Kotlin code must maintain correct AudioRecord initialization and coroutine-based read loop
4. **TypeScript Compiler**: All migrated .ts/.tsx files must compile with strict mode enabled (Decision 5)
5. **ESLint with Expo Config**: Linting must pass with @expo/eslint-config rules (Decision 6)

**v0.2.0 Source Location:**
- TypeScript sources: `modules/voiceline-dsp/src/`, `modules/voiceline-dsp/hooks/`, `modules/voiceline-dsp/index.ts`
- iOS Swift: `modules/voiceline-dsp/ios/VoicelineDSPModule.swift`
- Android Kotlin: `modules/voiceline-dsp/android/src/main/java/expo/modules/voicelinedsp/VoicelineDSPModule.kt`
- Tests: `modules/voiceline-dsp/__tests__/`, `modules/voiceline-dsp/ios/Tests/`, `modules/voiceline-dsp/android/src/test/`, `modules/voiceline-dsp/android/src/androidTest/`

**Migration assumes v0.2.0 code is available at these paths** for copying during Epic 2 execution.

## Acceptance Criteria (Authoritative)

**Epic 2 is complete when ALL of the following criteria are met:**

**AC1: Migration Feasibility Validated (Story 2.0)**
- Representative TypeScript file (buffer-utils.ts) compiles successfully with `npx tsc`
- Representative Swift file compiles successfully with `xcodebuild build`
- Representative Kotlin file compiles successfully with `./gradlew build`
- Zero blocker issues discovered that prevent full migration
- If blockers found: documented and escalated, migration HALTED until resolved

**AC2: TypeScript Source Migrated (Story 2.1)**
- All TypeScript files copied from v0.2.0: index.ts, src/*.ts, hooks/*.tsx
- Module renamed from VoicelineDSP to LoqaAudioBridge throughout
- All imports resolve correctly (zero TypeScript errors)
- `npx tsc` compiles successfully
- API exports match v0.2.0: startAudioStream, stopAudioStream, isStreaming, listeners, useAudioStreaming
- Type definitions export correctly: AudioConfig, AudioSampleEvent, StreamStatusEvent, StreamErrorEvent

**AC3: iOS Swift Migrated with Fixes (Story 2.2)**
- VoicelineDSPModule.swift copied to ios/LoqaAudioBridgeModule.swift
- Class name updated to LoqaAudioBridgeModule
- FR6 fixed: `required` keyword added to init override
- FR7 fixed: `.allowBluetooth` changed to `.allowBluetoothA2DP`
- `xcodebuild build` succeeds with **zero warnings**
- Native module definition exports match TypeScript API

**AC4: iOS Podspec Test Exclusion Implemented (Story 2.3)**
- LoqaAudioBridge.podspec includes `s.exclude_files` for tests
- test_spec section exists for development testing
- `pod spec lint` passes validation
- `npm pack` tarball inspection shows zero test files (no ios/Tests/, no *Tests.swift)

**AC5: Android Kotlin Migrated (Story 2.4)**
- VoicelineDSPModule.kt copied to android/src/main/java/expo/modules/loqaaudiobridge/LoqaAudioBridgeModule.kt
- Package name updated to expo.modules.loqaaudiobridge
- Class name updated to LoqaAudioBridgeModule
- android/build.gradle updated (namespace, Kotlin version, SDK versions)
- `./gradlew build` succeeds with **zero warnings**
- Native module definition exports match TypeScript API

**AC6: TypeScript Tests Migrated and Passing (Story 2.5)**
- All test files copied from v0.2.0: __tests__/*.test.ts, __tests__/*.test.tsx
- Imports updated for new module name
- Jest configured in package.json
- `npm test` executes all tests with **zero failures**
- Test coverage matches v0.2.0 baseline (API contracts, buffer utils, hook lifecycle)

**AC7: iOS Tests Migrated and Passing (Story 2.6)**
- Test files copied to ios/Tests/: LoqaAudioBridgeTests.swift, LoqaAudioBridgeIntegrationTests.swift
- Test class names and module references updated
- `xcodebuild test` executes all tests with **zero failures**
- Tests validate audio session, AVAudioEngine, RMS calculation, battery monitoring, event emission
- Tests excluded from npm package (verified in Story 2.3)

**AC8: Android Tests Migrated and Passing (Story 2.7)**
- Test files copied to android/src/test/ and android/src/androidTest/
- Package names and class references updated
- `./gradlew test` executes unit tests with **zero failures**
- `./gradlew connectedAndroidTest` executes instrumented tests with **zero failures** (requires emulator)
- Tests validate AudioRecord initialization, RMS calculation, battery monitoring, permissions
- Tests auto-excluded from AAR build (Gradle convention)

**AC9: Zero Compilation Warnings Achieved (Story 2.8)**
- iOS build: `xcodebuild clean build` → **0 warnings**
- Android build: `./gradlew clean build` → **0 warnings**
- TypeScript: `npx tsc` → **0 errors, 0 warnings**
- ESLint: `npm run lint` → **0 errors, 0 warnings**
- All deprecated APIs updated, unused variables removed, type annotations complete

**AC10: Feature Parity Validated (FR14-FR20)**
- Real-time audio streaming API preserved (startAudioStream, stopAudioStream, isStreaming)
- Configurable sample rates preserved (8kHz-48kHz)
- Configurable buffer sizes preserved (512-8192 samples)
- Voice Activity Detection (VAD) functionality preserved
- Adaptive Processing (battery optimization) functionality preserved
- Event-driven architecture preserved (onAudioSamples, onStreamStatusChange, onStreamError)
- React hook (useAudioStreaming) preserved
- TypeScript type definitions preserved
- All v0.2.0 tests pass without modification

**AC11: Multi-Layer Test Exclusion Validated**
- Layer 1 (Podspec): `s.exclude_files` excludes ios/Tests/
- Layer 2 (Gradle): src/test/ and src/androidTest/ auto-excluded
- Layer 3 (npm): .npmignore excludes __tests__/, *.test.ts, ios/Tests/, android/src/test/
- Layer 4 (TypeScript): tsconfig.json excludes test patterns
- `npm pack` tarball contains zero test files (validated in AC4)

**Definition of Done:** All 11 acceptance criteria verified, Epic 2 marked "contexted" in sprint-status.yaml, ready for Epic 3 (Autolinking & Integration Proof).

## Traceability Mapping

| AC | Spec Section | Component/API | Test Validation | PRD FR | Story |
|----|--------------|---------------|-----------------|--------|-------|
| **AC1** | Workflows and Sequencing → Story 2.0 | buffer-utils.ts, Swift partial, Kotlin partial | Compilation success | N/A | 2.0 |
| **AC2** | APIs and Interfaces → Public JavaScript API | index.ts, src/*.ts, hooks/*.tsx | TypeScript compilation, API export verification | FR14, FR17, FR18, FR19 | 2.1 |
| **AC3** | APIs and Interfaces → iOS Swift | ios/LoqaAudioBridgeModule.swift | xcodebuild build (zero warnings) | FR6, FR7, FR9, FR14-FR16 | 2.2 |
| **AC4** | System Architecture Alignment → Layer 1 | LoqaAudioBridge.podspec | pod spec lint, npm pack inspection | FR8 | 2.3 |
| **AC5** | APIs and Interfaces → Android Kotlin | android/.../LoqaAudioBridgeModule.kt | ./gradlew build (zero warnings) | FR9, FR14-FR16 | 2.4 |
| **AC6** | Services and Modules → TypeScript | __tests__/*.test.ts | npm test (zero failures) | FR20 | 2.5 |
| **AC7** | Services and Modules → iOS Native | ios/Tests/*.swift | xcodebuild test (zero failures) | FR20 | 2.6 |
| **AC8** | Services and Modules → Android Native | android/src/test/, android/src/androidTest/ | ./gradlew test, connectedAndroidTest (zero failures) | FR20 | 2.7 |
| **AC9** | NFR-R2: Zero Compilation Warnings | All modules | Build output inspection | FR9 | 2.8 |
| **AC10** | Data Models and Contracts | AudioConfig, AudioSampleEvent, event flow | Integration tests from v0.2.0 | FR14-FR20 | 2.1-2.8 |
| **AC11** | System Architecture Alignment → Multi-Layer Exclusion | Test exclusion configs | npm pack tarball inspection | FR8, ADR-003 | 2.3 |

**FR Coverage:**
- FR6 (Swift init fix): AC3 → Story 2.2
- FR7 (Bluetooth API update): AC3 → Story 2.2
- FR8 (Test exclusion): AC4, AC11 → Story 2.3
- FR9 (Zero warnings): AC3, AC5, AC9 → Stories 2.2, 2.4, 2.8
- FR14 (Feature parity): AC2, AC3, AC5, AC10 → Stories 2.1, 2.2, 2.4
- FR15 (VAD preservation): AC10 → Stories 2.2, 2.4
- FR16 (Adaptive processing): AC10 → Stories 2.2, 2.4
- FR17 (Event architecture): AC2, AC10 → Story 2.1
- FR18 (React hook): AC2, AC10 → Story 2.1
- FR19 (TypeScript types): AC2, AC10 → Story 2.1
- FR20 (Test preservation): AC6, AC7, AC8, AC10 → Stories 2.5, 2.6, 2.7

**Architecture Decision Coverage:**
- ADR-001 (create-expo-module foundation): Epic 1 prerequisite → Epic 2 populates scaffolded structure
- ADR-002 (Rename to loqa-audio-bridge): Module renaming throughout Epic 2 (VoicelineDSP → LoqaAudioBridge)
- ADR-003 (Multi-layered test exclusion): AC4, AC11 → Story 2.3 implements all 4 layers
- ADR-004 (Git tag-based publishing): Out of scope for Epic 2 (Epic 5 responsibility)

## Risks, Assumptions, Open Questions

**RISKS:**

**R1: Expo Modules Core API Breaking Changes** (Medium probability, High impact)
- Risk: expo-modules-core API changed between v0.2.0 development and current Expo 52+, causing compilation failures
- Mitigation: Story 2.0 (GATE story) validates API compatibility early with representative code samples
- Fallback: If blockers found, escalate to architect (Winston) for API upgrade strategy before proceeding

**R2: Test Shipping Bug Recurrence** (Low probability, High impact)
- Risk: Despite 4-layer exclusion strategy, test files accidentally ship to production (v0.2.0 failure repeats)
- Mitigation: Multi-layered defense (podspec, gradle, npmignore, tsconfig) + CI validation in Story 2.3
- Validation: Manual `npm pack` inspection in AC4 confirms zero test files in tarball
- Consequence: If tests ship, clients experience XCTest import errors (critical bug)

**R3: v0.2.0 Code Unavailability** (Low probability, Medium impact)
- Risk: v0.2.0 source code not accessible at expected paths (modules/voiceline-dsp/)
- Mitigation: Validate v0.2.0 code presence before starting Epic 2
- Fallback: Locate v0.2.0 backup or reconstruct from documentation (significant delay)

**R4: Feature Regression During Migration** (Medium probability, High impact)
- Risk: Subtle functionality breaks during module renaming (VAD thresholds, event timing, buffer handling)
- Mitigation: Preserve all v0.2.0 tests (Stories 2.5-2.7) and run without modification
- Validation: AC10 requires all integration tests pass, confirming feature parity
- Detection: If tests fail, investigation required before marking story complete

**R5: Platform-Specific Compilation Differences** (Medium probability, Medium impact)
- Risk: Code compiles on macOS but fails on CI (Linux) or different Xcode/Android Studio versions
- Mitigation: Test on multiple developer machines during Stories 2.2, 2.4
- Note: Epic 5 (CI/CD) will add automated multi-platform validation
- Temporary acceptance: Manual validation on 2+ machines sufficient for Epic 2

**ASSUMPTIONS:**

**A1:** Epic 1 (Foundation & Scaffolding) is 100% complete with all configuration files properly generated before Epic 2 starts

**A2:** v0.2.0 VoicelineDSP code is available at `modules/voiceline-dsp/` for copying during migration

**A3:** Developer has macOS with Xcode 14+ and Android Studio Flamingo+ installed for building both platforms

**A4:** Developer has access to Android emulator or physical device for running instrumented tests (Story 2.7)

**A5:** All v0.2.0 tests are passing in the original codebase (baseline for comparison)

**A6:** Module renaming (VoicelineDSP → LoqaAudioBridge) is purely textual replacement with no architectural implications

**A7:** Expo 52+ EventEmitter API is backward compatible with v0.2.0 event subscription patterns

**A8:** Swift 5.4+ and Kotlin 1.8+ compilers are available (specified in Epic 1 configuration)

**OPEN QUESTIONS:**

**Q1:** Are there any v0.2.0 integration issues NOT documented in the 360-line feedback document that might surface during migration?
- **Answer:** Unknown until Story 2.0 feasibility validation
- **Resolution:** Story 2.0 GATE story will reveal unexpected issues early

**Q2:** Will the `required` keyword fix (FR6) and `.allowBluetoothA2DP` change (FR7) require any runtime behavior validation beyond compilation?
- **Answer:** Likely no - both are compile-time fixes for structural issues
- **Validation:** iOS tests in Story 2.6 will validate audio session configuration still works

**Q3:** Should we run performance profiling during Epic 2 to validate NFR-P3 (runtime performance preservation)?
- **Answer:** Defer to Epic 3 (example app provides profiling environment)
- **Rationale:** Epic 2 focuses on migration correctness; Epic 3 provides end-to-end validation context

**Q4:** What is the escalation path if Story 2.0 discovers critical Expo Modules Core API incompatibilities?
- **Answer:** Escalate to architect (Winston) immediately, document blockers, HALT Epic 2 until resolved
- **Options:** API shim layer, downgrade Expo version, or refactor v0.2.0 code for new API

**Q5:** Should .npmignore or .gitignore be used for npm package exclusions?
- **Answer:** Use .npmignore (dedicated npm packaging file, clearer separation)
- **Rationale:** .gitignore controls version control, .npmignore controls distribution

## Test Strategy Summary

**Testing Philosophy:**
Epic 2 validation relies on **test preservation** - all v0.2.0 tests migrate unchanged and must pass, proving feature parity. Zero tolerance for test failures indicates successful migration.

**Test Layers:**

**Layer 1: TypeScript Unit Tests (Story 2.5)**
- **Framework:** Jest with @testing-library/react-native
- **Coverage:** API contracts (startAudioStream, stopAudioStream, listeners), buffer utilities, React hook lifecycle
- **Execution:** `npm test` runs all __tests__/*.test.ts files
- **Pass Criteria:** 100% pass rate (zero failures)
- **Exclusion:** Tests excluded from npm via .npmignore and tsconfig.json

**Layer 2: iOS Native Tests (Story 2.6)**
- **Framework:** XCTest with Quick/Nimble (BDD style)
- **Coverage:** Audio session configuration, AVAudioEngine instantiation, RMS calculation, battery monitoring, event emission
- **Execution:** `xcodebuild test -workspace ios/LoqaAudioBridge.xcworkspace -scheme LoqaAudioBridge`
- **Pass Criteria:** 100% pass rate (zero failures)
- **Exclusion:** Tests excluded from CocoaPods via podspec `s.exclude_files` and test_spec

**Layer 3: Android Native Tests (Story 2.7)**
- **Framework:** JUnit 4 + Mockito (unit), Espresso (instrumented)
- **Coverage:** AudioRecord initialization, audio format configuration, RMS calculation, battery monitoring, permissions
- **Execution:** `./gradlew test` (unit), `./gradlew connectedAndroidTest` (instrumented, requires emulator)
- **Pass Criteria:** 100% pass rate (zero failures)
- **Exclusion:** Tests auto-excluded from AAR via Gradle convention (src/test/, src/androidTest/)

**Layer 4: Compilation Validation (Story 2.8)**
- **Validation:** Zero warnings across all platforms confirms code quality
- **iOS:** `xcodebuild clean build` → 0 warnings
- **Android:** `./gradlew clean build` → 0 warnings
- **TypeScript:** `npx tsc` → 0 errors, 0 warnings
- **Linting:** `npm run lint` → 0 errors, 0 warnings

**Layer 5: Package Distribution Validation (Story 2.3)**
- **Validation:** `npm pack` creates tarball, extract and inspect for test file absence
- **Automated:** CI pipeline will automate this in Epic 5 (see Architecture Decision 3.3)
- **Manual:** Developer manually inspects tarball in Story 2.3

**Test Exclusion Validation Matrix:**

| Test Location | Exclusion Method | Validation Command | Expected Result |
|---------------|------------------|-------------------|-----------------|
| `__tests__/*.test.ts` | .npmignore, tsconfig.json exclude | `npm pack && tar -tzf *.tgz \| grep test` | No matches |
| `ios/Tests/*.swift` | podspec exclude_files | `npm pack && tar -tzf *.tgz \| grep Tests` | No matches |
| `android/src/test/` | Gradle convention | `npm pack && tar -tzf *.tgz \| grep "src/test"` | No matches |
| `android/src/androidTest/` | Gradle convention | `npm pack && tar -tzf *.tgz \| grep androidTest` | No matches |

**Regression Prevention:**
- **Baseline:** All v0.2.0 tests must pass in original codebase before migration
- **Migration:** Tests copied unchanged (only module name updated in imports)
- **Validation:** If any test fails after migration, root cause investigation required
- **Blocker:** Test failures block story completion until resolved

**Edge Cases:**
- **Empty event streams:** Validated by v0.2.0 tests (VAD silence detection)
- **Buffer overflow:** Validated by v0.2.0 buffer-utils tests
- **Permission denial:** Validated by v0.2.0 Android instrumented tests
- **Bluetooth audio routing:** Validated by iOS tests (AVAudioSession configuration)
- **Low battery behavior:** Validated by both iOS and Android tests (adaptive processing)

**Out of Scope for Epic 2:**
- End-to-end integration testing (Epic 3: example app)
- Autolinking validation (Epic 3: fresh Expo project)
- Performance profiling (deferred to Epic 3)
- CI/CD automated testing (Epic 5)
- Multi-platform CI validation (Epic 5)

**Success Metric:** Epic 2 complete when all 4 test layers pass (TypeScript, iOS, Android unit tests pass; zero compilation warnings; zero test files in tarball).
