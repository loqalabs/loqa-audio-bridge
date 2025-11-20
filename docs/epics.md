# @loqalabs/loqa-audio-bridge - Epic Breakdown

**Author:** Anna
**Date:** 2025-11-13
**Project Level:** 3 (Brownfield Refactoring)
**Target Scale:** 27 stories across 5 epics
**Package:** @loqalabs/loqa-audio-bridge v0.3.0 (formerly VoicelineDSP)

---

## Overview

This document provides the complete epic and story breakdown for **@loqalabs/loqa-audio-bridge v0.3.0**, a production-grade Expo native module for real-time audio streaming. This is a brownfield refactoring project transforming the functional v0.2.0 prototype into a production-ready npm package with proper packaging, autolinking, and comprehensive documentation.

**Key Transformation:**

- **v0.2.0**: Working code, but 9-hour manual integration process
- **v0.3.0**: Production package with autolinking (<30 minutes to integrate)

**Living Document Notice:** This epic breakdown is the implementation plan for v0.3.0. It will be referenced during Phase 4 implementation via the `create-story` workflow.

---

## Epic Summary

### Epic 1: Foundation & Scaffolding

**Goal:** Establish proper Expo module structure using official scaffolding to ensure autolinking works out-of-the-box.

**Value:** Correct foundation prevents 90% of v0.2.0 integration failures.

**Stories:** 4 | **FRs Covered:** FR1-FR5

---

### Epic 2: Code Migration & Quality Fixes

**Goal:** Migrate v0.2.0 TypeScript, Swift, and Kotlin code into new scaffolding while fixing compilation errors and implementing test exclusions.

**Value:** Working, compilable module with zero warnings and all v0.2.0 features intact.

**Stories:** 11 | **FRs Covered:** FR6-FR9, FR14-FR20

---

### Epic 3: Autolinking & Integration Proof

**Goal:** Validate Expo autolinking works seamlessly on both platforms and create working example app.

**Value:** Concrete proof that v0.3.0 eliminates v0.2.0's integration hell.

**Stories:** 5 | **FRs Covered:** FR10-FR13, FR30-FR33

---

### Epic 4: Developer Experience & Documentation

**Goal:** Create comprehensive documentation that enables <30 minute integration.

**Value:** Documentation eliminates confusion that caused v0.2.0's 9-hour integration time.

**Stories:** 4 | **FRs Covered:** FR26-FR29

---

### Epic 5: Distribution & CI/CD

**Goal:** Set up automated npm publishing, GitHub Actions CI/CD, and multi-platform build validation.

**Value:** Automated quality gates prevent regressions and make releases reliable.

**Stories:** 5 | **FRs Covered:** FR21-FR25, FR34-FR38

---

## Functional Requirements Inventory

**Packaging & Scaffolding (FR1-FR5)**

- **FR1**: Regenerate module structure using `create-expo-module` CLI
- **FR2**: Include complete package.json with proper metadata
- **FR3**: Include expo-module.config.json with platform specifications
- **FR4**: Include voiceline-dsp.podspec for iOS with test exclusions
- **FR5**: Include Android build.gradle with proper configuration

**Code Quality & Compilation (FR6-FR9)**

- **FR6**: Fix Swift compilation error (add `required` keyword to init override)
- **FR7**: Update deprecated iOS API (`.allowBluetooth` → `.allowBluetoothA2DP`)
- **FR8**: Exclude test files from production builds via podspec
- **FR9**: Compile with zero warnings on iOS and Android

**Autolinking & Integration (FR10-FR13)**

- **FR10**: Enable iOS autolinking without manual Podfile edits
- **FR11**: Enable Android autolinking without manual build.gradle edits
- **FR12**: Auto-register module in ExpoModulesProvider.swift
- **FR13**: Validate autolinking in fresh Expo project

**Core Functionality Preservation (FR14-FR20)**

- **FR14**: Maintain 100% feature parity with v0.2.0 (streaming API, sample rates, buffer sizes)
- **FR15**: Preserve Voice Activity Detection (VAD) functionality
- **FR16**: Preserve Adaptive Processing functionality (battery optimization)
- **FR17**: Maintain event-driven architecture (3 event types)
- **FR18**: Preserve React hook (useAudioStreaming)
- **FR19**: Maintain TypeScript type definitions
- **FR20**: Preserve all existing tests

**npm Package Distribution (FR21-FR25)**

- **FR21**: Publish to npm as @loqalabs/loqa-audio-bridge
- **FR22**: Support `npx expo install` installation
- **FR23**: Include all source code and native implementations in package
- **FR24**: Follow semantic versioning
- **FR25**: Include complete package metadata

**Documentation (FR26-FR29)**

- **FR26**: Provide README.md with installation and quick start
- **FR27**: Provide INTEGRATION_GUIDE.md with step-by-step instructions
- **FR28**: Migrate existing API.md (730 lines)
- **FR29**: Provide MIGRATION.md with v0.2.0 → v0.3.0 upgrade guide

**Example Application (FR30-FR33)**

- **FR30**: Include working example/ directory with Expo app
- **FR31**: Example app builds and runs successfully
- **FR32**: Example demonstrates both iOS and Android
- **FR33**: Example includes clear code comments

**Build & Release (FR34-FR38)**

- **FR34**: Support iOS builds with Xcode 14+ and 15+
- **FR35**: Support Android builds with Gradle 8.x
- **FR36**: Compatible with Expo 52, 53, and 54
- **FR37**: Compatible with React Native 0.72+
- **FR38**: Work with EAS Build without special configuration

**Total: 38 Functional Requirements**

---

## FR Coverage Map

| Epic                                         | FRs Covered      | Count |
| -------------------------------------------- | ---------------- | ----- |
| Epic 1: Foundation & Scaffolding             | FR1-5            | 5     |
| Epic 2: Code Migration & Quality             | FR6-9, FR14-20   | 11    |
| Epic 3: Autolinking & Integration Proof      | FR10-13, FR30-33 | 8     |
| Epic 4: Developer Experience & Documentation | FR26-29          | 4     |
| Epic 5: Distribution & CI/CD                 | FR21-25, FR34-38 | 10    |

**Total: 38 FRs, 100% coverage ✅**

---

## Epic 1: Foundation & Scaffolding

**Epic Goal:** Establish proper Expo module structure using official scaffolding to ensure autolinking works out-of-the-box, eliminating the manual configuration hell of v0.2.0.

**Value Delivery:** Correct foundation prevents 90% of v0.2.0 integration failures.

---

### Story 1.1: Generate Module Scaffolding with create-expo-module

As a developer,
I want the module structure generated using create-expo-module CLI,
So that all required configuration files are present and properly formatted.

**Acceptance Criteria:**

**Given** the project repository is empty
**When** I run `npx create-expo-module@latest loqa-audio-bridge`
**Then** the following files are generated:

- package.json with proper npm metadata structure
- expo-module.config.json with platform definitions
- LoqaAudioBridge.podspec for iOS CocoaPods
- android/build.gradle for Android module
- index.ts as main entry point
- ios/ and android/ directories with starter code

**And** the generated package.json includes:

- name: "@loqalabs/loqa-audio-bridge"
- version: "0.3.0"
- Peer dependencies for expo, react, react-native

**And** expo-module.config.json specifies:

- platforms: ["ios", "android"]
- iOS deployment target: 13.4+
- Android minSdkVersion: 24

**Prerequisites:** None (first story)

**Technical Notes:**

- Use latest create-expo-module version compatible with Expo 52+
- Answer prompts with: package name "@loqalabs/loqa-audio-bridge", supports iOS + Android
- Verify generated structure matches architecture Decision 1

---

### Story 1.2: Configure Package Metadata and Dependencies

As a developer,
I want complete package.json metadata configured,
So that the package is properly indexed on npm and dependencies are clear.

**Acceptance Criteria:**

**Given** the scaffolded package.json exists
**When** I update metadata fields
**Then** package.json includes:

- description: "Production-grade Expo native module for real-time audio streaming with VAD and battery optimization"
- author: "Loqa Labs"
- license: "MIT"
- repository: GitHub URL for loqa-audio-bridge
- keywords: ["expo", "react-native", "audio", "streaming", "vad", "microphone"]
- homepage: GitHub repository URL
- bugs: GitHub issues URL

**And** peerDependencies are set to:

```json
{
  "expo": ">=52.0.0",
  "expo-modules-core": "*",
  "react": ">=18.0.0",
  "react-native": ">=0.72.0"
}
```

**And** devDependencies include:

- typescript: ^5.3.0
- @types/react: ^18.0.0
- eslint: ^8.0.0
- prettier: ^3.0.0

**And** scripts section includes:

- "build": "tsc"
- "lint": "eslint ."
- "test": "jest"

**Prerequisites:** Story 1.1

**Technical Notes:**

- Follow semantic versioning for peerDependencies (>= for minimum versions)
- Use exact versions for devDependencies to ensure reproducible builds
- Align with architecture Decision 2 (version strategy)

---

### Story 1.3: Configure TypeScript Build System

As a developer,
I want TypeScript configured with strict mode,
So that type errors are caught early and declaration files are generated.

**Acceptance Criteria:**

**Given** the scaffolded project structure exists
**When** I create/update tsconfig.json
**Then** compiler options include:

- strict: true
- target: "ES2020"
- module: "ESNext"
- moduleResolution: "bundler"
- declaration: true (generate .d.ts files)
- declarationMap: true
- outDir: "./build"
- skipLibCheck: true

**And** include paths are: ["src/**/*", "index.ts", "hooks/**/*"]

**And** exclude paths are:

- "**tests**"
- "\*_/_.test.ts"
- "\*_/_.spec.ts"
- "example"
- "ios/Tests"
- "android/src/test"
- "android/src/androidTest"

**And** running `npx tsc` compiles successfully with zero errors

**And** build/ directory contains:

- Compiled .js files
- Type definition .d.ts files
- Source maps .d.ts.map files

**Prerequisites:** Story 1.1

**Technical Notes:**

- TypeScript config aligns with architecture Decision 5
- Exclude test files from compilation (multi-layer exclusion strategy)
- ES2020 targets React Native 0.72+ environments

---

### Story 1.4: Configure Linting and Code Quality Tools

As a developer,
I want ESLint and Prettier configured,
So that code style is consistent and quality issues are caught automatically.

**Acceptance Criteria:**

**Given** the project structure exists
**When** I configure ESLint and Prettier
**Then** .eslintrc.js extends:

- 'expo' (Expo's recommended config)
- 'prettier' (Prettier integration)

**And** .prettierrc specifies:

- semi: true
- trailingComma: "es5"
- singleQuote: true
- printWidth: 100
- tabWidth: 2

**And** package.json scripts include:

- "lint": "eslint . --ext .ts,.tsx"
- "format": "prettier --write \"\*_/_.{ts,tsx,json,md}\""

**And** running `npm run lint` on scaffolded code shows zero errors

**And** running `npm run format` formats all files consistently

**Prerequisites:** Story 1.2, 1.3

**Technical Notes:**

- Aligns with architecture Decision 6 (linting strategy)
- Use @expo/eslint-config for Expo-specific rules
- Pre-commit hooks optional for v0.3.0 (defer to v0.4.0)

---

## Epic 2: Code Migration & Quality Fixes

**Epic Goal:** Migrate v0.2.0 TypeScript, Swift, and Kotlin code into the new scaffolding structure while fixing compilation errors, implementing test exclusions, and preserving 100% of existing functionality.

**Value Delivery:** Working, compilable module with zero warnings and all v0.2.0 features intact.

---

### Story 2.0: Validate Code Migration Feasibility (Risk Reduction)

As a developer,
I want to validate that v0.2.0 code can be migrated cleanly,
So that I catch architectural mismatches early before committing to full migration.

**Acceptance Criteria:**

**Given** Epic 1 scaffolding is complete
**When** I copy one representative module (buffer-utils.ts) from v0.2.0 into src/
**Then** TypeScript imports resolve correctly
**And** the module compiles with `npx tsc` without errors
**And** Expo Modules Core API imports work (no breaking changes)

**And** I copy one Swift file (basic audio capture logic) into ios/
**Then** Swift imports resolve (AVFoundation, ExpoModulesCore)
**And** Xcode compiles the file without errors

**And** I copy one Kotlin file (basic audio record logic) into android/src/main/
**Then** Kotlin imports resolve (AudioRecord, ExpoModulesCore)
**And** Gradle compiles the file without errors

**And** if any blocker issues found:

- Document the issue clearly
- Escalate to architect (Winston) for resolution
- Do NOT proceed to remaining Epic 2 stories until resolved

**Prerequisites:** Epic 1 complete (Stories 1.1-1.4)

**Technical Notes:**

- This is a GATE story—must pass before continuing Epic 2
- Focus on API compatibility (expo-modules-core v1.x changes)
- Check for deprecated methods that need updates

---

### Story 2.1: Migrate TypeScript Source Code

As a developer,
I want all TypeScript source files migrated from v0.2.0,
So that the JavaScript API layer is available in the new structure.

**Acceptance Criteria:**

**Given** Story 2.0 validation passed
**When** I copy all TypeScript files from v0.2.0 into new structure:

- index.ts → index.ts (update imports for new paths)
- src/VoicelineDSPModule.ts → src/LoqaAudioBridgeModule.ts (rename module references)
- src/types.ts → src/types.ts
- src/buffer-utils.ts → src/buffer-utils.ts
- hooks/useAudioStreaming.tsx → hooks/useAudioStreaming.tsx

**Then** all imports resolve correctly (no red squiggles in VS Code)

**And** running `npx tsc` compiles successfully

**And** TypeScript types match v0.2.0 API surface (no breaking changes)

**And** module exports include:

- startAudioStream
- stopAudioStream
- isStreaming
- addAudioSamplesListener
- addStreamStatusListener
- addStreamErrorListener
- useAudioStreaming hook

**And** all type definitions export correctly (AudioConfig, AudioSample, StreamStatus, StreamError)

**Prerequisites:** Story 2.0

**Technical Notes:**

- Update module name from "VoicelineDSP" to "LoqaAudioBridge" everywhere
- Verify EventEmitter subscriptions still work with expo-modules-core updates
- Maintain 100% API compatibility (FR19)

---

### Story 2.2: Migrate iOS Swift Implementation

As a developer,
I want the iOS Swift code migrated with compilation errors fixed,
So that the iOS native module compiles with zero warnings.

**Acceptance Criteria:**

**Given** TypeScript migration is complete (Story 2.1)
**When** I copy iOS Swift files from v0.2.0:

- VoicelineDSPModule.swift → ios/LoqaAudioBridgeModule.swift

**Then** I update the class name to LoqaAudioBridgeModule throughout

**And** I fix FR6 (Swift compilation error):

- Add `required` keyword to init override: `required init(appContext: EXAppContext)`

**And** I fix FR7 (deprecated iOS API):

- Change `.allowBluetooth` to `.allowBluetoothA2DP` in AVAudioSession configuration
- Line is in: `audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothA2DP])`

**And** I update import statements:

- `import ExpoModulesCore` (verify correct for Expo 52+)
- `import AVFoundation`

**And** running `xcodebuild -workspace ios/LoqaAudioBridge.xcworkspace -scheme LoqaAudioBridge build` succeeds

**And** build output shows **zero warnings**

**And** module definition exports match TypeScript API:

- startAudioStream
- stopAudioStream
- isStreaming
- Event emitters configured for: onAudioSamples, onStreamStatusChange, onStreamError

**Prerequisites:** Story 2.1

**Technical Notes:**

- Swift 5.4+ syntax required (podspec specifies this)
- AVAudioEngine code unchanged from v0.2.0 (preserve FR14)
- VAD logic (RMS calculation) preserved exactly (FR15)
- Battery monitoring code preserved (FR16)

---

### Story 2.3: Implement iOS Podspec Test Exclusions

As a developer,
I want test files excluded from the iOS podspec,
So that XCTest imports don't cause client build failures (v0.2.0 bug fix).

**Acceptance Criteria:**

**Given** iOS Swift code is migrated (Story 2.2)
**When** I update LoqaAudioBridge.podspec
**Then** the podspec includes:

```ruby
s.source_files = "ios/**/*.{h,m,mm,swift}"

s.exclude_files = [
  "ios/Tests/**/*",
  "ios/**/*Tests.swift",
  "ios/**/*Test.swift"
]
```

**And** test_spec section exists for development:

```ruby
s.test_spec 'Tests' do |test_spec|
  test_spec.source_files = "ios/Tests/**/*.{h,m,swift}"
  test_spec.dependency 'Quick'
  test_spec.dependency 'Nimble'
end
```

**And** running `pod spec lint LoqaAudioBridge.podspec` passes validation

**And** creating a tarball with `npm pack` and inspecting shows:

- ios/LoqaAudioBridgeModule.swift present ✅
- ios/Tests/ directory absent ✅
- No \*Tests.swift files present ✅

**Prerequisites:** Story 2.2

**Technical Notes:**

- Implements architecture Decision 3 (Layer 1: podspec exclusion)
- Test files still exist in repo, just excluded from distribution
- Aligns with FR8 (exclude test files from production builds)

---

### Story 2.4: Migrate Android Kotlin Implementation

As a developer,
I want the Android Kotlin code migrated into the new module structure,
So that the Android native module compiles with zero warnings.

**Acceptance Criteria:**

**Given** iOS migration is complete (Story 2.2-2.3)
**When** I copy Android Kotlin files from v0.2.0:

- VoicelineDSPModule.kt → android/src/main/java/expo/modules/loqaaudiobridge/LoqaAudioBridgeModule.kt

**Then** I update package name to: `expo.modules.loqaaudiobridge`

**And** I update class name to: `LoqaAudioBridgeModule`

**And** I update android/build.gradle:

- namespace: "expo.modules.loqaaudiobridge"
- Kotlin version: 1.8+
- compileSdkVersion: 34
- minSdkVersion: 24

**And** I verify imports:

- `import expo.modules.kotlin.modules.Module`
- `import expo.modules.kotlin.Promise`
- `import android.media.AudioRecord`
- `import android.media.AudioFormat`

**And** running `./gradlew :loqaaudiobridge:build` in android/ succeeds

**And** build output shows **zero warnings**

**And** module definition exports match TypeScript API

**And** AudioRecord code unchanged from v0.2.0 (preserve FR14)

**And** VAD logic (RMS calculation) preserved (FR15)

**And** Battery monitoring code preserved (FR16)

**Prerequisites:** Story 2.2

**Technical Notes:**

- Gradle automatically excludes src/test/ and src/androidTest/ (no explicit config needed)
- Kotlin 1.8+ required for Expo 52 compatibility
- Verify AudioRecord permissions handling unchanged

---

### Story 2.5: Migrate and Run TypeScript Tests

As a developer,
I want all TypeScript tests migrated and passing,
So that API contracts are validated and regressions are caught.

**Acceptance Criteria:**

**Given** TypeScript source is migrated (Story 2.1)
**When** I copy test files from v0.2.0:

- **tests**/index.test.ts
- **tests**/buffer-utils.test.ts
- **tests**/useAudioStreaming.test.tsx

**Then** I update imports to match new module name (LoqaAudioBridge)

**And** I configure Jest in package.json:

```json
"jest": {
  "preset": "expo",
  "transformIgnorePatterns": [
    "node_modules/(?!((jest-)?react-native|@react-native(-community)?)|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@unimodules/.*|unimodules|sentry-expo|native-base|react-native-svg)"
  ]
}
```

**And** running `npm test` executes all tests

**And** all tests pass with **zero failures**

**And** test coverage matches v0.2.0 baseline:

- API contracts tested (startAudioStream, stopAudioStream, listeners)
- Buffer utilities tested (format conversions, validations)
- React hook lifecycle tested

**And** tests verify FR19 (TypeScript types unchanged)

**Prerequisites:** Story 2.1

**Technical Notes:**

- Use @testing-library/react-native for hook testing
- Mock native module calls (no actual audio recording in tests)
- Tests are excluded from npm package via .npmignore (Decision 3, Layer 3)

---

### Story 2.6: Migrate and Run iOS Tests

As a developer,
I want iOS Swift tests migrated and passing,
So that native iOS functionality is validated.

**Acceptance Criteria:**

**Given** iOS Swift code is migrated (Story 2.2)
**When** I copy iOS test files from v0.2.0 into ios/Tests/:

- LoqaAudioBridgeTests.swift (unit tests)
- LoqaAudioBridgeIntegrationTests.swift (integration tests)

**Then** I update test class names and module references to LoqaAudioBridge

**And** I configure test dependencies in podspec test_spec (already done in Story 2.3)

**And** running `xcodebuild test -workspace ios/LoqaAudioBridge.xcworkspace -scheme LoqaAudioBridge` executes all tests

**And** all tests pass with **zero failures**

**And** tests validate:

- Audio session configuration works
- AVAudioEngine can be instantiated
- RMS calculation accuracy (VAD)
- Battery level monitoring
- Event emission to JavaScript

**And** tests are excluded from npm package (verified in Story 2.3)

**Prerequisites:** Story 2.2, 2.3

**Technical Notes:**

- Use Quick/Nimble for BDD-style Swift tests (already in v0.2.0)
- Tests run in Xcode but excluded from CocoaPods distribution
- FR20 compliance: all v0.2.0 tests preserved

---

### Story 2.7: Migrate and Run Android Tests

As a developer,
I want Android Kotlin tests migrated and passing,
So that native Android functionality is validated.

**Acceptance Criteria:**

**Given** Android Kotlin code is migrated (Story 2.4)
**When** I copy Android test files from v0.2.0:

- android/src/test/java/.../LoqaAudioBridgeModuleTest.kt (unit tests)
- android/src/androidTest/java/.../LoqaAudioBridgeIntegrationTest.kt (instrumented tests)

**Then** I update package names to `expo.modules.loqaaudiobridge`

**And** I update test class references to LoqaAudioBridgeModule

**And** running `./gradlew test` executes unit tests

**And** all unit tests pass with **zero failures**

**And** running `./gradlew connectedAndroidTest` executes instrumented tests (requires emulator)

**And** all instrumented tests pass

**And** tests validate:

- AudioRecord can be initialized
- Audio format configuration correct
- RMS calculation accuracy (VAD)
- Battery level monitoring
- Permission handling

**And** tests are auto-excluded from AAR build (Gradle convention)

**Prerequisites:** Story 2.4

**Technical Notes:**

- Use JUnit 4 + Mockito for unit tests
- Instrumented tests require Android emulator or device
- FR20 compliance: all v0.2.0 tests preserved
- Gradle automatically excludes test directories from production builds

---

### Story 2.8: Achieve Zero Compilation Warnings

As a developer,
I want both iOS and Android builds to compile with zero warnings,
So that code quality is production-ready (FR9).

**Acceptance Criteria:**

**Given** all code migration stories are complete (2.1-2.4)
**When** I run iOS build: `xcodebuild -workspace ios/LoqaAudioBridge.xcworkspace -scheme LoqaAudioBridge clean build`
**Then** build succeeds with **0 warnings**

**And** when I run Android build: `./gradlew :loqaaudiobridge:clean :loqaaudiobridge:build`
**Then** build succeeds with **0 warnings**

**And** when I run TypeScript compilation: `npx tsc`
**Then** compilation succeeds with **0 errors** and **0 warnings**

**And** when I run linter: `npm run lint`
**Then** linting passes with **0 errors** and **0 warnings**

**And** I fix any warnings found by:

- Updating deprecated API calls
- Adding missing type annotations
- Resolving unused variable warnings
- Fixing any Swift/Kotlin compiler suggestions

**Prerequisites:** Stories 2.1-2.7

**Technical Notes:**

- FR9 explicit requirement: zero warnings on both platforms
- Use `-Werror` flag to treat warnings as errors in CI (Epic 5)
- Document any suppressed warnings with justification comments
- **Post-Story 3-4 Learning**: Zero compilation warnings is necessary but NOT sufficient - Story 3-4 discovered that module structural issues (root-level TypeScript files) cause Metro bundler failures despite zero TypeScript warnings. Consider adding structural validation (Task 8 in story file) or creating Story 2-10 for module structure validation.

---

### Story 2.9: Fix iOS Audio Format Conversion for Sample Rate Mismatch

As a developer using the module on iOS,
I want audio streaming to work at my requested sample rate (16kHz),
So that the module functions correctly for speech recognition use cases.

**Acceptance Criteria:**

**Given** the iOS Swift implementation in `ios/LoqaAudioBridgeModule.swift`
**When** the user calls `startAudioStream({ sampleRate: 16000, bufferSize: 2048, channels: 1, vadEnabled: true })`
**Then** the module:

1. **Detects Hardware Format**: Gets hardware format from `inputNode.outputFormat(forBus: 0)`, identifies hardware sample rate (typically 48000 Hz)

2. **Installs Tap at Hardware Rate**: Creates tap using hardware format (not requested format), scales buffer size proportionally

3. **Converts to Requested Format**: Creates `AVAudioConverter` from hardware format to target format (16 kHz), converts each buffer in tap callback

4. **Sends Downsampled Audio**: Calculates RMS on downsampled audio, sends samples at requested rate (16 kHz)

**And** when user runs example app on iOS:

- Taps "Start Streaming" → audio streaming starts without crash
- RMS visualization updates in real-time
- No `AVAudioEngine` format mismatch errors

**And** the implementation:

- Preserves sample accuracy (no dropped samples)
- Handles variable hardware rates (44.1kHz, 48kHz, etc.)
- Includes error handling for conversion failures
- Logs format conversion details for debugging

**Prerequisites:** Stories 2.1-2.4, Story 3-4 (discovered the issue)

**Technical Notes:**

- **Problem**: iOS `AVAudioEngine.installTap()` requires tap format to match hardware format exactly
- **Root Cause**: Hardware runs at 48kHz but module requests 16kHz, causing crash
- **Solution**: Tap at hardware rate, use `AVAudioConverter` to downsample to requested rate
- **Discovered in**: Story 3-4 (example app) - first end-to-end iOS runtime test
- **Should have been caught in**: Story 2-6 (iOS tests - deferred)
- **Impact**: HIGH - blocks all iOS audio streaming functionality
- **Related**: KNOWN-ISSUE-IOS-AUDIO-FORMAT.md, CRITICAL-LEARNINGS-METRO-BUNDLER.md

---

### Story 2.10: Validate Expo Module Structure for Metro Bundler Compatibility

As a developer,
I want to validate that the module structure follows Expo conventions,
So that Metro bundler can correctly resolve the compiled code (prevents Story 3-4 issue).

**Acceptance Criteria:**

**Given** the module has been migrated and compiled (Epic 2 complete)
**When** I run module structure validation script
**Then** the following checks pass:

1. **No Root-Level TypeScript**: No `.ts` files at package root (except config files like `jest.config.ts`)
2. **TypeScript Config**: `tsconfig.json` compiles only from `["./src"]` or `["./src", "./hooks"]`
3. **Package Entry Point**: `package.json` `"main"` points to `"build/index.js"` (compiled)
4. **Compiled Output Exists**: `build/index.js` exists and contains module exports

**And** validation script (`scripts/validate-module-structure.sh`) is created with automated checks

**And** script is added to package.json: `"validate:structure": "./scripts/validate-module-structure.sh"`

**And** documentation explains why structural validation is necessary (Metro bundler compatibility)

**Prerequisites:** Story 3-4 (discovered the structural issue), Story 2-8 (compilation validation)

**Technical Notes:**

- **Why This Story**: Story 3-4 discovered Metro bundler resolves root TypeScript instead of compiled JavaScript, despite zero compilation warnings
- **Relationship to Story 2-8**: Story 2-8 validates type correctness (compilation), this story validates bundler compatibility (structure)
- **Metro Bundler Issue**: With `file:..` dependencies, Metro preferentially resolves TypeScript source over compiled JS
- **Prevention**: Automated structural validation prevents Metro resolution issues before they reach runtime
- **CI/CD**: Story 5-2 should include `npm run validate:structure` in CI pipeline
- **See**: CRITICAL-LEARNINGS-METRO-BUNDLER.md, EPIC-2-RE-EVALUATION.md

---

## Epic 3: Autolinking & Integration Proof

**Epic Goal:** Validate that Expo autolinking works seamlessly on both iOS and Android without manual configuration, and create a working example app that proves the module integrates correctly.

**Value Delivery:** Concrete proof that v0.3.0 eliminates the 9-hour integration hell of v0.2.0.

---

### Story 3.1: Validate iOS Autolinking in Fresh Expo Project

As a developer,
I want to verify iOS autolinking works without manual Podfile edits,
So that iOS integration matches the <30 minute target (FR10).

**Acceptance Criteria:**

**Given** Epic 2 is complete (compiled module with zero warnings)
**When** I create a fresh test directory outside the module repo
**And** I run:

```bash
npx create-expo-app test-install
cd test-install
npm install /path/to/loqa-audio-bridge  # local file install for testing
```

**Then** package.json includes @loqalabs/loqa-audio-bridge in dependencies

**And** when I run `npx expo prebuild --platform ios`
**Then** ios/Podfile is automatically generated
**And** ios/Podfile contains reference to LoqaAudioBridge pod

**And** when I run `npx pod-install` in ios/
**Then** CocoaPods installs LoqaAudioBridge successfully
**And** terminal shows: "Installing LoqaAudioBridge"

**And** when I open ios/\*.xcworkspace in Xcode
**Then** LoqaAudioBridge appears in Pods project
**And** no manual ExpoModulesProvider.swift edits required (FR12)

**And** when I build the project in Xcode
**Then** build succeeds with **zero errors**
**And** module is linked correctly

**And** I document the steps and timing (should be <5 minutes for install)

**Prerequisites:** Epic 2 complete

**Technical Notes:**

- Use `npm install <local-path>` for pre-publish testing
- Verify autolinking detected by checking `npx expo-doctor` output
- Test on clean machine or Docker container for accuracy

---

### Story 3.2: Validate Android Autolinking in Fresh Expo Project

As a developer,
I want to verify Android autolinking works without manual build.gradle edits,
So that Android integration matches the <30 minute target (FR11).

**Acceptance Criteria:**

**Given** Story 3.1 iOS validation passed
**When** I use the same fresh Expo project from Story 3.1
**And** I run `npx expo prebuild --platform android`

**Then** android/settings.gradle is automatically generated
**And** android/settings.gradle includes LoqaAudioBridge module

**And** android/app/build.gradle includes LoqaAudioBridge dependency

**And** when I run `./gradlew :app:build` in android/
**Then** Gradle resolves LoqaAudioBridge module successfully
**And** terminal shows: "Project ':loqaaudiobridge' configured"

**And** when I open android/ in Android Studio
**Then** LoqaAudioBridge module appears in project structure
**And** no manual gradle edits required

**And** when I build the project with `./gradlew assembleDebug`
**Then** build succeeds with **zero errors**
**And** module is linked correctly

**And** I document the steps and timing (should be <5 minutes for install)

**Prerequisites:** Story 3.1

**Technical Notes:**

- Gradle autolinking works via expo-modules-autolinking package
- Verify with `./gradlew :app:dependencies | grep loqaaudiobridge`
- Test on clean Linux VM or Docker for accuracy

---

### Story 3.3: Create Example App Scaffolding

As a developer,
I want an example Expo app with the module installed,
So that consumers can see working integration code (FR30).

**Acceptance Criteria:**

**Given** autolinking validation passed (Stories 3.1-3.2)
**When** I create example/ directory in module root
**And** I run `npx create-expo-app example --template blank-typescript`

**Then** example/package.json is created

**And** I add dependency to parent module:

```json
"dependencies": {
  "@loqalabs/loqa-audio-bridge": "file:.."
}
```

**And** running `npm install` in example/ installs the local module

**And** I configure app.json:

```json
{
  "expo": {
    "name": "LoqaAudioBridge Example",
    "slug": "loqa-audio-bridge-example",
    "platforms": ["ios", "android"],
    "ios": {
      "bundleIdentifier": "com.loqalabs.audiobridge.example",
      "infoPlist": {
        "NSMicrophoneUsageDescription": "This app needs microphone access to demonstrate audio streaming."
      }
    },
    "android": {
      "package": "com.loqalabs.audiobridge.example",
      "permissions": ["RECORD_AUDIO"]
    }
  }
}
```

**And** running `npx expo prebuild` generates native projects

**And** running `npx expo run:ios` builds and launches on simulator

**And** running `npx expo run:android` builds and launches on emulator

**Prerequisites:** Stories 3.1-3.2

**Technical Notes:**

- Example uses file: protocol to reference parent module during development
- Permissions configured for both platforms (microphone access)
- Blank TypeScript template for cleaner starting point

---

### Story 3.4: Implement Example App Audio Streaming Demo

As a developer,
I want the example app to demonstrate basic audio streaming with visualization,
So that consumers understand how to use the module (FR30, FR33).

**Acceptance Criteria:**

**Given** example app scaffolding exists (Story 3.3)
**When** I create example/App.tsx with the following features:

1. **Import Section** (with clear comments):

```typescript
// Import the audio streaming module
import {
  startAudioStream,
  stopAudioStream,
  addAudioSamplesListener,
} from '@loqalabs/loqa-audio-bridge';
import { useState, useEffect } from 'react';
```

2. **Permission Handling**:

- Request microphone permission on mount
- Show permission status to user
- Handle denied permission gracefully

3. **Start/Stop Controls**:

- Button to start audio streaming
- Button to stop streaming
- Visual indicator showing streaming status (green = active, red = stopped)

4. **Real-time Visualization**:

- Display RMS (volume level) from audio samples
- Simple bar chart or numeric display updating in real-time
- Show sample rate and buffer size

5. **Event Handling** (with clear comments):

```typescript
// Listen for audio samples
const subscription = addAudioSamplesListener((event) => {
  // event.samples: Float32Array of audio data
  // event.rms: root mean square (volume level)
  // event.sampleRate: configured sample rate
  setRmsLevel(event.rms);
});
```

**Then** the app UI includes:

- Clear title: "Loqa Audio Bridge Example"
- Permission status display
- Start/Stop buttons with clear labels
- Visual RMS indicator (bar or progress circle)
- Current configuration display (sample rate, buffer size)

**And** when user taps "Start Streaming":

- Microphone permission requested (if not granted)
- Audio streaming begins
- RMS visualization updates in real-time (~8 Hz)
- Status shows "Streaming: Active"

**And** when user taps "Stop Streaming":

- Audio streaming stops
- Visualization freezes at last value
- Status shows "Streaming: Stopped"

**And** all code includes **clear explanatory comments** (FR33):

```typescript
// Configure audio stream: 16kHz sample rate, 2048 buffer size
// This gives ~8 Hz event rate (2048 samples / 16000 Hz = 0.128s per event)
await startAudioStream({
  sampleRate: 16000,
  bufferSize: 2048,
  channels: 1, // Mono
  enableVAD: true, // Enable Voice Activity Detection for battery savings
});
```

**Prerequisites:** Story 3.3

**Technical Notes:**

- Use React hooks for state management (useState, useEffect)
- Demonstrate proper cleanup (unsubscribe listeners on unmount)
- Show error handling for permission denials
- Keep UI simple—focus is on integration code, not polished design

---

### Story 3.5: Add Example App Documentation and Testing

As a developer,
I want the example app fully documented and tested,
So that it serves as reliable integration proof (FR31, FR32).

**Acceptance Criteria:**

**Given** example app implementation exists (Story 3.4)
**When** I create example/README.md with:

1. **Quick Start Section**:

```markdown
# Loqa Audio Bridge Example

## Quick Start

1. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

2. Run on iOS:
   \`\`\`bash
   npx expo run:ios
   \`\`\`

3. Run on Android:
   \`\`\`bash
   npx expo run:android
   \`\`\`
```

2. **What This Example Demonstrates**:

- Basic audio streaming setup
- Event listener patterns
- Real-time visualization
- Permission handling
- Clean cleanup on unmount

3. **Code Walkthrough**:

- Annotated code snippets explaining each integration step
- Links to main module documentation

**Then** example/ includes:

- README.md with clear instructions
- Commented App.tsx showing integration
- package.json with correct scripts

**And** when I test on iOS simulator:

- `npx expo run:ios` builds successfully
- App launches and displays UI
- Tapping "Start" requests permission
- After granting permission, RMS visualization works
- Tapping "Stop" halts streaming
- **No crashes or errors**

**And** when I test on Android emulator:

- `npx expo run:android` builds successfully
- App launches and displays UI
- Tapping "Start" requests permission
- After granting permission, RMS visualization works
- Tapping "Stop" halts streaming
- **No crashes or errors**

**And** I document timing:

- iOS build time: ~3-4 minutes on M-series Mac
- Android build time: ~4-5 minutes
- **Total from npm install to running app: <10 minutes**

**Prerequisites:** Story 3.4

**Technical Notes:**

- Test on both physical devices and simulators
- Verify microphone permissions work correctly on both platforms
- Example app proves FR31 (runs successfully) and FR32 (both platforms)
- This completes FR13 (validate autolinking in fresh project)

---

## Epic 4: Developer Experience & Documentation

**Epic Goal:** Create comprehensive, user-focused documentation that enables developers to integrate the module in <30 minutes and serves as ongoing reference.

**Value Delivery:** Documentation eliminates the confusion and missing information that caused v0.2.0's 9-hour integration time.

---

### Story 4.1: Write README.md with Quick Start

As a developer encountering this package,
I want a README that gets me started in <5 minutes,
So that I can quickly evaluate if the package meets my needs (FR26).

**Acceptance Criteria:**

**Given** the package structure exists
**When** I create README.md in module root
**Then** it includes the following sections:

1. **Header Section**:

```markdown
# @loqalabs/loqa-audio-bridge

Production-grade Expo native module for real-time audio streaming with Voice Activity Detection and battery optimization.

[![npm version](https://badge.fury.io/js/%40loqalabs%2Floqa-audio-bridge.svg)](https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
```

2. **Features List**:

- Real-time audio streaming (8kHz-48kHz)
- Voice Activity Detection (VAD) for battery optimization
- Cross-platform (iOS + Android)
- TypeScript support with full type definitions
- Zero manual configuration (autolinking works out-of-the-box)

3. **Installation Section**:

```markdown
## Installation

\`\`\`bash
npx expo install @loqalabs/loqa-audio-bridge
\`\`\`

That's it! Autolinking handles the rest.
```

4. **Quick Start Code Example** (5-10 lines):

```typescript
import { startAudioStream, addAudioSamplesListener } from '@loqalabs/loqa-audio-bridge';

// Start streaming
await startAudioStream({ sampleRate: 16000, bufferSize: 2048 });

// Listen for audio samples
const subscription = addAudioSamplesListener((event) => {
  console.log('RMS:', event.rms); // Volume level
});
```

5. **Links to Comprehensive Docs**:

- [Full Documentation](./INTEGRATION_GUIDE.md)
- [API Reference](./API.md)
- [Example App](./example)
- [Migration from v0.2.0](./MIGRATION.md)

6. **Platform Requirements**:

- iOS 13.4+
- Android API 24+
- Expo 52+
- React Native 0.72+

7. **License**: MIT

**And** README is <200 lines (scannable in <2 minutes)

**And** code examples are copy-pasteable and work without modification

**And** badges link to npm registry and GitHub repository

**Prerequisites:** Epic 3 complete (example app proves code works)

**Technical Notes:**

- Follow npm README best practices
- Use markdown badges for visual appeal
- Keep technical jargon minimal in README (save for INTEGRATION_GUIDE)
- Focus on "what" and "how to start", not "why" (that's for PRD)

---

### Story 4.2: Write INTEGRATION_GUIDE.md

As a developer integrating this package,
I want step-by-step instructions covering edge cases,
So that I can complete integration without external support (FR27).

**Acceptance Criteria:**

**Given** README.md exists (Story 4.1)
**When** I create INTEGRATION_GUIDE.md
**Then** it includes the following sections:

1. **Prerequisites**:

- Expo version requirements
- React Native version requirements
- macOS requirements for iOS development
- Android Studio requirements for Android development

2. **Step 1: Installation** (detailed):

```markdown
### Installation

1. Install the package:
   \`\`\`bash
   npx expo install @loqalabs/loqa-audio-bridge
   \`\`\`

2. Rebuild native projects:
   \`\`\`bash
   npx expo prebuild --clean
   \`\`\`

3. Verify installation:
   \`\`\`bash
   npx expo-doctor
   \`\`\`

   Expected output: No warnings about loqa-audio-bridge
```

3. **Step 2: iOS Configuration**:

- Add microphone permission to app.json:

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

- Explain why this is required (App Store rejection if missing)
- Show how to customize the permission message

4. **Step 3: Android Configuration**:

- Add microphone permission to app.json:

```json
{
  "expo": {
    "android": {
      "permissions": ["RECORD_AUDIO"]
    }
  }
}
```

- Explain runtime permission handling required for Android 6.0+
- Provide code example for requesting permissions

5. **Step 4: Basic Usage**:

- Full code example with error handling
- Permission request code for both platforms
- Listener setup and cleanup
- Common configuration options explained

6. **Step 5: Testing**:

- How to test on iOS simulator (simulator doesn't have microphone—use device)
- How to test on Android emulator (virtual microphone setup)
- Expected behavior checklist

7. **Troubleshooting Section**:

```markdown
### Common Issues

#### "Cannot find native module LoqaAudioBridge"

**Solution**: Run `npx expo prebuild --clean` and `npx pod-install` (iOS)

#### iOS build fails with CocoaPods error

**Solution**: Clear CocoaPods cache: `cd ios && pod cache clean --all && pod install`

#### Android build fails with "Duplicate class" error

**Solution**: Clear Gradle cache: `cd android && ./gradlew clean`

#### Microphone permission always denied on iOS

**Solution**: Check Info.plist includes NSMicrophoneUsageDescription

#### Audio events not firing

**Solution**: Verify sample rate and buffer size are valid values
```

8. **Advanced Topics**:

- Voice Activity Detection (VAD) configuration
- Battery optimization behavior
- Buffer size tuning for latency vs. CPU tradeoff
- Multi-channel (stereo) configuration

**And** guide is organized with clear headings and table of contents

**And** each step includes **expected outcome** validation

**And** troubleshooting covers 90% of common issues (based on v0.2.0 feedback)

**And** guide enables <30 minute integration (timed on fresh install)

**Prerequisites:** Story 4.1

**Technical Notes:**

- Reference Voiceline integration feedback document for pain points to address
- Use actual error messages in troubleshooting (copy from console output)
- Include iOS and Android side-by-side where they differ
- Link to example app for working reference code

---

### Story 4.3: Migrate API.md Documentation

As a developer using this package,
I want comprehensive API reference documentation,
So that I can understand all configuration options and methods (FR28).

**Acceptance Criteria:**

**Given** v0.2.0 API.md exists (730 lines)
**When** I migrate it to v0.3.0 structure
**Then** I update all references:

- Package name: VoicelineDSP → @loqalabs/loqa-audio-bridge
- Module name: VoicelineDSPModule → LoqaAudioBridgeModule
- Import statements updated to new package name

**And** API.md includes the following sections:

1. **Module Methods**:

- `startAudioStream(config: AudioConfig): Promise<void>`
  - Full parameter documentation
  - Return value/error handling
  - Example usage
  - Platform-specific notes
- `stopAudioStream(): Promise<void>`
- `isStreaming(): boolean`

2. **Event Listeners**:

- `addAudioSamplesListener(callback): Subscription`
  - Event payload structure documented
  - Callback signature with TypeScript types
  - Subscription cleanup explained
- `addStreamStatusListener(callback): Subscription`
- `addStreamErrorListener(callback): Subscription`

3. **React Hook**:

- `useAudioStreaming(config: AudioConfig): AudioStreamingResult`
  - Hook parameters
  - Return value shape
  - Lifecycle behavior (auto-cleanup)
  - Example usage in component

4. **TypeScript Interfaces**:

- `AudioConfig` - all properties documented with defaults
- `AudioSample` - event payload structure
- `StreamStatus` - status enum values
- `StreamError` - error object structure

5. **Configuration Reference Table**:
   | Parameter | Type | Default | Description | Valid Values |
   |-----------|------|---------|-------------|--------------|
   | sampleRate | number | 16000 | Audio sample rate in Hz | 8000, 16000, 32000, 44100, 48000 |
   | bufferSize | number | 2048 | Buffer size in samples | 512-8192 (power of 2 on iOS) |
   | ... | ... | ... | ... | ... |

6. **Code Examples**:

- Basic streaming example
- VAD configuration example
- Error handling example
- Battery-aware configuration example
- React component integration example

**And** all TypeScript code examples compile without errors

**And** examples use v0.3.0 package name and imports

**And** platform-specific behaviors clearly called out (iOS vs Android differences)

**And** migration preserves all v0.2.0 content (FR28: migrate existing 730 lines)

**Prerequisites:** Story 4.1

**Technical Notes:**

- Use existing v0.2.0 API.md as base (already comprehensive)
- Add any new APIs or configuration options introduced in v0.3.0
- Ensure examples match example app implementation
- Cross-reference with TypeScript type definitions for accuracy

---

### Story 4.4: Write MIGRATION.md for v0.2.0 Users

As a developer currently using v0.2.0,
I want clear upgrade instructions,
So that I can migrate to v0.3.0 without breaking my app (FR29).

**Acceptance Criteria:**

**Given** v0.3.0 package is ready for release
**When** I create MIGRATION.md
**Then** it includes the following sections:

1. **Overview**:

```markdown
# Migrating from v0.2.0 to v0.3.0

v0.3.0 is a **packaging and distribution upgrade** with minimal API changes. The core functionality is preserved, but the installation process is dramatically simplified.

**Migration time: ~15-30 minutes**
```

2. **Breaking Changes** (if any):

- List any API changes (expected: none, 100% compatibility)
- Package name change: VoicelineDSP → @loqalabs/loqa-audio-bridge
- Import statement updates required

3. **Step-by-Step Migration**:

```markdown
### Step 1: Remove v0.2.0

1. Delete copied module files from your project
2. Remove manual Podfile entries
3. Remove manual ExpoModulesProvider.swift edits
4. Remove manual build.gradle entries

### Step 2: Install v0.3.0

\`\`\`bash
npx expo install @loqalabs/loqa-audio-bridge
\`\`\`

### Step 3: Update Imports

**Before (v0.2.0):**
\`\`\`typescript
import { startAudioStream } from '../modules/voiceline-dsp';
\`\`\`

**After (v0.3.0):**
\`\`\`typescript
import { startAudioStream } from '@loqalabs/loqa-audio-bridge';
\`\`\`

### Step 4: Rebuild Native Projects

\`\`\`bash
npx expo prebuild --clean
npx pod-install # iOS only
\`\`\`

### Step 5: Test

Run your app and verify audio streaming works as before.
```

4. **API Compatibility Matrix**:
   | Feature | v0.2.0 | v0.3.0 | Status |
   |---------|--------|--------|--------|
   | startAudioStream | ✅ | ✅ | No changes |
   | stopAudioStream | ✅ | ✅ | No changes |
   | VAD | ✅ | ✅ | No changes |
   | ... | ... | ... | ... |

5. **Benefits of Upgrading**:

- ✅ Zero manual configuration (autolinking works)
- ✅ Installable via npm (no more manual file copying)
- ✅ Official releases with semantic versioning
- ✅ Comprehensive documentation
- ✅ Example app for reference
- ✅ CI/CD validation ensures quality

6. **Troubleshooting Migration Issues**:

- Common problems when upgrading
- How to verify migration succeeded
- Rollback instructions if needed

**And** migration guide tested by upgrading a real v0.2.0 integration

**And** timing validated (should be <30 minutes)

**And** guide addresses concerns from Voiceline team's v0.2.0 experience

**Prerequisites:** Story 4.1, 4.2

**Technical Notes:**

- Reference Voiceline integration feedback for pain points to address
- Emphasize simplification benefits to motivate upgrade
- Provide side-by-side code comparisons for clarity
- Include checklist format for easy following

---

## Epic 5: Distribution & CI/CD

**Epic Goal:** Set up automated npm publishing, GitHub Actions CI/CD pipeline, and multi-platform build validation to ensure every release is high quality and installable.

**Value Delivery:** Automated quality gates prevent regressions and make releases reliable and repeatable.

---

### Story 5.1: Configure npm Package for Publishing

As a package maintainer,
I want the package configured for npm publishing,
So that users can install via `npx expo install` (FR21, FR22).

**Acceptance Criteria:**

**Given** all previous epics are complete
**When** I configure package.json for npm publishing
**Then** package.json includes:

```json
{
  "name": "@loqalabs/loqa-audio-bridge",
  "version": "0.3.0",
  "description": "Production-grade Expo native module for real-time audio streaming",
  "main": "build/index.js",
  "types": "build/index.d.ts",
  "files": [
    "build/",
    "src/",
    "ios/",
    "android/",
    "hooks/",
    "expo-module.config.json",
    "LoqaAudioBridge.podspec",
    "README.md",
    "API.md",
    "INTEGRATION_GUIDE.md",
    "MIGRATION.md",
    "CHANGELOG.md",
    "LICENSE"
  ],
  "publishConfig": {
    "access": "public"
  }
}
```

**And** .npmignore includes:

```
__tests__/
*.test.ts
*.test.tsx
*.spec.ts
example/
.github/
tsconfig.json
.eslintrc.js
.prettierrc
ios/Tests/
android/src/test/
android/src/androidTest/
*.tgz
node_modules/
```

**And** when I run `npm pack`:

- Tarball is created: `loqalabs-loqa-audio-bridge-0.3.0.tgz`
- Tarball size is reasonable (<500 KB excluding node_modules)

**And** when I extract tarball and inspect:

- ✅ build/ directory present with compiled JS and .d.ts
- ✅ src/ directory present with TypeScript source
- ✅ ios/ directory present (excluding ios/Tests/)
- ✅ android/ directory present (excluding test directories)
- ✅ Documentation files present (README, API.md, etc.)
- ❌ **tests**/ directory absent
- ❌ example/ directory absent
- ❌ .github/ directory absent
- ❌ No *Tests.swift or *Test.swift files

**Prerequisites:** Epics 1-4 complete

**Technical Notes:**

- "files" whitelist approach ensures only intended files ship
- .npmignore provides additional safety (defense in depth)
- Aligns with architecture Decision 3 (multi-layer test exclusion)
- FR23: package includes all source and native implementations

---

### Story 5.2: Create GitHub Actions CI Pipeline

As a package maintainer,
I want automated CI validation on every PR and push,
So that code quality is maintained and regressions are caught early.

**Acceptance Criteria:**

**Given** GitHub repository exists
**When** I create `.github/workflows/ci.yml`
**Then** workflow triggers on:

- Pull requests to main branch
- Pushes to main branch

**And** workflow includes these jobs:

1. **Lint Job**:

```yaml
lint:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
    - run: npm ci
    - run: npm run lint
    - run: npm run format -- --check
```

2. **TypeScript Tests Job**:

```yaml
test-ts:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
    - run: npm ci
    - run: npm test
    - run: npm run build # Verify TypeScript compiles
```

3. **iOS Build Job**:

```yaml
build-ios:
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v4
    - run: cd ios && pod install
    - run: xcodebuild -workspace ios/LoqaAudioBridge.xcworkspace -scheme LoqaAudioBridge clean build
```

4. **Android Build Job**:

```yaml
build-android:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: '17'
    - run: cd android && ./gradlew clean build
```

5. **Package Validation Job** (implements Decision 3 CI validation):

```yaml
validate-package:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
    - run: npm ci
    - run: npm run build
    - run: npm pack
    - name: Validate no test files in package
      run: |
        tar -xzf loqalabs-loqa-audio-bridge-*.tgz
        cd package
        # Fail if test files found
        if find . -name "*.test.ts" -o -name "*.spec.ts" | grep .; then
          echo "ERROR: Test files found in package!"
          exit 1
        fi
        # Fail if test directories found
        if [ -d "__tests__" ] || [ -d "ios/Tests" ] || [ -d "example" ]; then
          echo "ERROR: Test directories in package!"
          exit 1
        fi
        echo "✅ Package validation passed"
```

**And** all jobs must pass for PR to be mergeable (branch protection)

**And** badge added to README showing CI status

**And** workflow runs complete in <10 minutes total

**Prerequisites:** Story 5.1

**Technical Notes:**

- Use latest GitHub Actions versions (@v4)
- Cache dependencies for faster builds
- Run jobs in parallel for speed
- Use matrix strategy for testing multiple Expo/RN versions (future enhancement)

---

### Story 5.3: Create Automated npm Publishing Workflow

As a package maintainer,
I want automated npm publishing triggered by git tags,
So that releases are repeatable and validated (FR21, FR24).

**Acceptance Criteria:**

**Given** CI pipeline exists (Story 5.2)
**When** I create `.github/workflows/publish-npm.yml`
**Then** workflow triggers on:

- Git tags matching pattern `v*.*.*` (e.g., v0.3.0, v0.3.1)

**And** workflow includes:

```yaml
name: Publish to npm

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          registry-url: 'https://registry.npmjs.org'

      # Run full CI validation first
      - name: Run CI checks
        run: |
          npm ci
          npm run lint
          npm test
          npm run build

      # Validate package contents
      - name: Validate package
        run: |
          npm pack
          # Run validation from Story 5.2

      # Publish to npm
      - name: Publish to npm
        run: npm publish --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}

      # Create GitHub Release
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: loqalabs-loqa-audio-bridge-*.tgz
          generate_release_notes: true
```

**And** when I test publishing workflow:

1. Update version in package.json to 0.3.0
2. Commit: `git commit -m "Release v0.3.0"`
3. Tag: `git tag v0.3.0`
4. Push tag: `git push origin v0.3.0`
5. GitHub Actions runs automatically
6. Package publishes to npm successfully
7. GitHub Release created with tarball attached

**And** NPM_TOKEN secret configured in GitHub repository settings

**And** published package installable via `npx expo install @loqalabs/loqa-audio-bridge`

**Prerequisites:** Story 5.2

**Technical Notes:**

- Requires npm account and authentication token
- Use `npm publish --access public` for scoped packages
- Tag format enforces semantic versioning
- Aligns with architecture Decision 4 (git tag-based publishing)

---

### Story 5.4: Validate EAS Build Compatibility

As a developer using EAS Build,
I want the package to work with Expo Application Services,
So that cloud builds succeed without special configuration (FR38).

**Acceptance Criteria:**

**Given** package is published to npm (Story 5.3)
**When** I create a test Expo project:

```bash
npx create-expo-app eas-test
cd eas-test
npx expo install @loqalabs/loqa-audio-bridge
```

**And** I configure EAS Build (eas.json):

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

**And** I run `eas build --platform ios --profile development`
**Then** EAS cloud build succeeds without errors
**And** build logs show LoqaAudioBridge linking correctly
**And** built IPA installs on device and audio streaming works

**And** I run `eas build --platform android --profile development`
**Then** EAS cloud build succeeds without errors
**And** build logs show LoqaAudioBridge linking correctly
**And** built APK installs on device and audio streaming works

**And** no special eas.json configuration required (standard Expo config works)

**And** I document EAS compatibility in README and INTEGRATION_GUIDE

**Prerequisites:** Story 5.3 (package must be published)

**Technical Notes:**

- EAS Build uses same autolinking as local builds
- Test on both iOS and Android EAS builders
- Verify no custom plugins or config needed
- FR38 requirement: works without special configuration

---

### Story 5.5: Create CHANGELOG.md and Release Process Documentation

As a package maintainer,
I want a changelog and release process documented,
So that version history is tracked and releases are consistent (FR24, FR25).

**Acceptance Criteria:**

**Given** v0.3.0 is ready for release
**When** I create CHANGELOG.md
**Then** it follows Keep a Changelog format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2025-11-13

### Added

- Production-grade npm packaging with autolinking
- Comprehensive documentation (README, INTEGRATION_GUIDE, API.md, MIGRATION.md)
- Working example Expo app demonstrating integration
- Automated CI/CD pipeline with GitHub Actions
- Multi-layered test exclusion strategy (fixes v0.2.0 issue)

### Fixed

- Swift compilation error: Added required keyword to init override
- Deprecated iOS API: Updated .allowBluetooth to .allowBluetoothA2DP
- Test files no longer ship to production (podspec exclusions)

### Changed

- Package renamed from VoicelineDSP to @loqalabs/loqa-audio-bridge
- Module structure regenerated with create-expo-module
- Installation simplified to single command (no manual configuration)

### Migration

- See [MIGRATION.md](./MIGRATION.md) for v0.2.0 → v0.3.0 upgrade guide

## [0.2.0] - 2024-XX-XX (Voiceline Deployment)

### Added

- Initial working implementation with iOS and Android support
- Voice Activity Detection (VAD)
- Adaptive battery optimization
- Event-driven architecture

### Known Issues

- Required manual integration (9-hour process)
- Missing packaging files
- Tests shipped to clients causing build errors
- No official documentation
```

**And** I create RELEASING.md with process documentation:

```markdown
# Release Process

## Version Numbering (Semantic Versioning)

- **MAJOR** (x.0.0): Breaking API changes, Expo Modules API updates
- **MINOR** (0.x.0): New features, non-breaking enhancements
- **PATCH** (0.0.x): Bug fixes, documentation updates

## Pre-Release Checklist

- [ ] All tests passing locally and in CI
- [ ] CHANGELOG.md updated with changes
- [ ] Version bumped in package.json
- [ ] Documentation updated (if needed)
- [ ] Example app tested on both platforms

## Release Steps

1. Update version: `npm version [major|minor|patch]`
2. Push commit: `git push origin main`
3. Push tag: `git push origin v0.3.x`
4. GitHub Actions automatically publishes to npm
5. Verify package on npm: https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge
6. Announce release (optional)

## Post-Release Validation

- [ ] Package installable: `npx expo install @loqalabs/loqa-audio-bridge`
- [ ] Fresh Expo app integration works
- [ ] Example app runs on both platforms
```

**And** package.json includes repository, bugs, and homepage URLs (FR25)

**And** LICENSE file present (MIT license)

**Prerequisites:** Stories 5.1-5.4

**Technical Notes:**

- CHANGELOG.md should be updated with every release
- Follow semantic versioning strictly
- Document breaking changes prominently
- Link to migration guides for major versions

---

## FR Coverage Matrix

| FR   | Requirement                               | Epic   | Story                     |
| ---- | ----------------------------------------- | ------ | ------------------------- |
| FR1  | Regenerate module with create-expo-module | Epic 1 | 1.1                       |
| FR2  | Complete package.json                     | Epic 1 | 1.2                       |
| FR3  | expo-module.config.json                   | Epic 1 | 1.1                       |
| FR4  | voiceline-dsp.podspec                     | Epic 1 | 1.1, 2.3                  |
| FR5  | Android build.gradle                      | Epic 1 | 1.1                       |
| FR6  | Fix Swift required keyword                | Epic 2 | 2.2                       |
| FR7  | Update deprecated iOS API                 | Epic 2 | 2.2                       |
| FR8  | Exclude test files (podspec)              | Epic 2 | 2.3                       |
| FR9  | Zero compilation warnings                 | Epic 2 | 2.8                       |
| FR10 | iOS autolinking                           | Epic 3 | 3.1                       |
| FR11 | Android autolinking                       | Epic 3 | 3.2                       |
| FR12 | Auto-register in ExpoModulesProvider      | Epic 3 | 3.1                       |
| FR13 | Validate autolinking (fresh project)      | Epic 3 | 3.1, 3.2, 3.5             |
| FR14 | Maintain feature parity                   | Epic 2 | 2.1, 2.2, 2.4             |
| FR15 | Preserve VAD                              | Epic 2 | 2.2, 2.4, 2.6, 2.7        |
| FR16 | Preserve Adaptive Processing              | Epic 2 | 2.2, 2.4, 2.6, 2.7        |
| FR17 | Maintain event architecture               | Epic 2 | 2.1, 2.2, 2.4             |
| FR18 | Preserve React hook                       | Epic 2 | 2.1, 2.5                  |
| FR19 | Maintain TypeScript types                 | Epic 2 | 2.1, 2.5                  |
| FR20 | Preserve all tests                        | Epic 2 | 2.5, 2.6, 2.7             |
| FR21 | Publish to npm                            | Epic 5 | 5.1, 5.3                  |
| FR22 | Support npx expo install                  | Epic 5 | 5.1, 5.3                  |
| FR23 | Include source in package                 | Epic 5 | 5.1                       |
| FR24 | Semantic versioning                       | Epic 5 | 5.5                       |
| FR25 | Package metadata                          | Epic 1 | 1.2                       |
| FR26 | README.md                                 | Epic 4 | 4.1                       |
| FR27 | INTEGRATION_GUIDE.md                      | Epic 4 | 4.2                       |
| FR28 | Migrate API.md                            | Epic 4 | 4.3                       |
| FR29 | MIGRATION.md                              | Epic 4 | 4.4                       |
| FR30 | Example app                               | Epic 3 | 3.3, 3.4                  |
| FR31 | Example builds successfully               | Epic 3 | 3.5                       |
| FR32 | Example demonstrates both platforms       | Epic 3 | 3.5                       |
| FR33 | Example has clear comments                | Epic 3 | 3.4                       |
| FR34 | Support Xcode 14+/15+                     | Epic 2 | 2.2, 2.8                  |
| FR35 | Support Gradle 8.x                        | Epic 2 | 2.4, 2.8                  |
| FR36 | Compatible Expo 52-54                     | Epic 1 | 1.1, validated in 3.1-3.2 |
| FR37 | Compatible RN 0.72+                       | Epic 1 | 1.2, validated in 3.1-3.2 |
| FR38 | EAS Build compatible                      | Epic 5 | 5.4                       |

**✅ All 38 FRs mapped to stories. Complete coverage validated.**

---

## Summary

**Epic Breakdown Complete for @loqalabs/loqa-audio-bridge v0.3.0**

**Total Stories:** 27 across 5 epics
**Total FRs Covered:** 38/38 (100% coverage)
**Estimated Timeline:** 6 weeks (one sprint per epic + buffer)

**Sprint Sequencing:**

- **Sprint 1 (Week 1):** Epic 1 - Foundation & Scaffolding
- **Sprints 2-3 (Weeks 2-3):** Epic 2 - Code Migration & Quality (heavy lift)
- **Sprint 4 (Week 4):** Epic 3 - Autolinking & Integration Proof
- **Sprint 5 (Week 5):** Epic 4 - Developer Experience & Documentation
- **Sprint 6 (Week 6):** Epic 5 - Distribution & CI/CD

**Key Milestones:**

- After Epic 3: Working package with validated autolinking (internal testing ready)
- After Epic 4: Fully documented package (beta release ready)
- After Epic 5: Production-ready v0.3.0 on npm (public release)

**Next Steps:**

1. Review and approve epic breakdown
2. Run `/bmad:bmm:workflows:create-story` to generate individual story implementation plans
3. Execute sprints sequentially following story order

---

_For implementation: Use the `create-story` workflow to generate individual story implementation plans from this epic breakdown._

_This document will be updated as implementation progresses and new insights emerge._
