# Architecture Document: @loqalabs/loqa-audio-bridge v0.3.0

**Project**: Production-Grade Foundation for loqa-audio-bridge
**Type**: Brownfield Refactoring (v0.2.0 → v0.3.0)
**Date**: 2025-11-13
**Status**: Solution Architecture

---

## Executive Summary

This document captures the architectural decisions for transforming the VoicelineDSP v0.2.0 working prototype into **@loqalabs/loqa-audio-bridge v0.3.0**, a production-grade npm package. The architecture focuses on proper Expo module packaging, automated distribution, comprehensive testing infrastructure, and zero-friction integration for Expo/React Native applications.

**Key Transformation**:

- **v0.2.0**: Working code, manual integration (9 hours to integrate)
- **v0.3.0**: Production package with autolinking (<30 minutes to integrate)

**Package Naming Decision**: Changed from `@loqalabs/voiceline-dsp` to `@loqalabs/loqa-audio-bridge` to:

1. Align with Loqa Labs branding
2. Distinguish from existing `loqa-voice-dsp` Rust crate (DSP algorithms)
3. Clarify purpose: Audio I/O streaming bridge (not DSP algorithms)

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Critical Architectural Decisions](#2-critical-architectural-decisions)
3. [Project Structure](#3-project-structure)
4. [Build & Distribution](#4-build--distribution)
5. [Test Architecture](#5-test-architecture)
6. [CI/CD Pipeline](#6-cicd-pipeline)
7. [Integration Architecture](#7-integration-architecture)
8. [Risk Mitigation](#8-risk-mitigation)
9. [Dependencies](#9-dependencies)
10. [Future Considerations](#10-future-considerations)

---

## 1. System Overview

### 1.1 Purpose

**@loqalabs/loqa-audio-bridge** is an Expo native module that provides real-time audio streaming from device microphones to React Native/Expo applications. It bridges native iOS (AVAudioEngine) and Android (AudioRecord) APIs to JavaScript with event-driven audio sample delivery.

### 1.2 Distinction from loqa-voice-dsp

| Package                         | Purpose                                                  | Language                | Scope                                   |
| ------------------------------- | -------------------------------------------------------- | ----------------------- | --------------------------------------- |
| **loqa-voice-dsp**              | DSP algorithms (pitch, formants, FFT, spectral analysis) | Rust                    | Algorithm library with FFI/JNI bindings |
| **@loqalabs/loqa-audio-bridge** | Audio I/O streaming bridge                               | TypeScript/Swift/Kotlin | React Native event-driven audio capture |

**Relationship**: `loqa-audio-bridge` captures audio samples; `loqa-voice-dsp` analyzes them. They are complementary but independent packages.

### 1.3 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Expo/React Native Application              │
│  ┌──────────────────────────────────────────────────┐   │
│  │   @loqalabs/loqa-audio-bridge (JavaScript)       │   │
│  │   - index.ts (API)                               │   │
│  │   - useAudioStreaming() hook                     │   │
│  │   - TypeScript types                             │   │
│  └────────────┬─────────────────────────────────────┘   │
└───────────────┼──────────────────────────────────────────┘
                │ Expo Modules Core (EventEmitter)
       ┌────────┴────────┐
       │                 │
┌──────▼──────┐   ┌──────▼──────┐
│ iOS (Swift) │   │Android(Kt)  │
│AVAudioEngine│   │ AudioRecord │
│    + VAD    │   │    + VAD    │
└─────────────┘   └─────────────┘
```

### 1.4 Core Capabilities

1. **Real-time audio streaming** - 8Hz event rate, 16kHz/2048 buffer default
2. **Voice Activity Detection (VAD)** - Native RMS-based silence detection
3. **Adaptive battery optimization** - Automatic frame rate reduction on low battery
4. **Cross-platform API** - Unified TypeScript interface for iOS/Android
5. **Event-driven design** - Non-blocking audio sample delivery

---

## 2. Critical Architectural Decisions

### Decision 1: Foundation Strategy

**Selected**: **Option B - Use `create-expo-module` as starter template**

**Rationale**:

- Official Expo scaffolding ensures correct structure
- Includes autolinking configuration out-of-the-box
- Provides proper `expo-module.config.json` and `.podspec` templates
- Reduces risk of missing critical packaging files (root cause of v0.2.0 failures)

**Action Items**:

1. Run `npx create-expo-module@latest loqa-audio-bridge`
2. Copy v0.2.0 implementation code into scaffolded structure
3. Validate autolinking works with fresh Expo app

**Rejected Options**:

- A) Manually add config files to v0.2.0 (too error-prone)
- C) Use third-party template (not officially maintained)

---

### Decision 2: Version Strategy & Compatibility

**Selected**: **Single version with broad peer dependencies**

**Configuration**:

```json
{
  "name": "@loqalabs/loqa-audio-bridge",
  "version": "0.3.0",
  "peerDependencies": {
    "expo": ">=52.0.0",
    "react": ">=18.0.0",
    "react-native": ">=0.72.0"
  }
}
```

**Rationale**:

- Expo 52+ provides stable Modules API
- React Native 0.72+ covers 95% of active projects
- Single package simplifies maintenance
- Semantic versioning provides clear upgrade paths

**Breaking Change Policy**:

- MAJOR: Expo Modules API changes, TypeScript API breaking changes
- MINOR: New features, non-breaking enhancements
- PATCH: Bug fixes, documentation updates

---

### Decision 3: Test Architecture & Build Exclusion

**Problem**: v0.2.0 shipped test files to clients, causing XCTest import errors during integration.

**Selected**: **Multi-layered test exclusion with CI validation**

#### 3.1 Test Organization

```
@loqalabs/loqa-audio-bridge/
├── __tests__/                     # TypeScript unit tests (EXCLUDED)
│   ├── index.test.ts
│   └── buffer-utils.test.ts
├── ios/
│   ├── LoqaAudioBridgeModule.swift
│   └── Tests/                     # iOS tests (EXCLUDED)
│       ├── LoqaAudioBridgeTests.swift
│       └── LoqaAudioBridgeIntegrationTests.swift
├── android/
│   └── src/
│       ├── main/java/...          # Production code (INCLUDED)
│       ├── test/...               # Android unit tests (AUTO-EXCLUDED)
│       └── androidTest/...        # Android integration tests (AUTO-EXCLUDED)
└── example/                       # Example app (EXCLUDED)
    └── __tests__/
```

#### 3.2 Build Exclusion Strategy (Multi-Layered Defense)

**Layer 1: iOS Podspec Exclusion**

```ruby
Pod::Spec.new do |s|
  # ... other config ...

  s.source_files = "ios/**/*.{h,m,mm,swift}"

  # CRITICAL: Exclude all test files
  s.exclude_files = [
    "ios/Tests/**/*",
    "ios/**/*Tests.swift",
    "ios/**/*Test.swift"
  ]

  # Only test_spec should reference test files
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = "ios/Tests/**/*.{h,m,swift}"
  end
end
```

**Layer 2: Android Gradle (Auto-Exclusion)**

```gradle
// Gradle automatically excludes src/test/ and src/androidTest/
// No explicit configuration needed - this is Gradle convention
```

**Layer 3: npm Package Exclusion (.npmignore)**

```
# Test files
__tests__/
*.test.ts
*.test.tsx
*.spec.ts
*.spec.tsx

# iOS tests
ios/Tests/

# Android tests (redundant with Gradle, but defensive)
android/src/test/
android/src/androidTest/

# Example app
example/

# CI/CD
.github/
```

**Layer 4: TypeScript Compilation (tsconfig.json)**

```json
{
  "exclude": [
    "__tests__",
    "**/*.test.ts",
    "**/*.spec.ts",
    "example",
    "ios/Tests",
    "android/src/test",
    "android/src/androidTest"
  ]
}
```

#### 3.3 CI Validation Pipeline

**Pre-Publish Validation** (GitHub Actions):

```yaml
name: Validate Distribution Package

on:
  pull_request:
  push:
    branches: [main]

jobs:
  validate-package:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Build package
      - run: npm ci
      - run: npm run build

      # Create tarball (dry-run publish)
      - run: npm pack

      # Extract and validate
      - name: Validate no tests in package
        run: |
          tar -xzf loqalabs-loqa-audio-bridge-*.tgz
          cd package

          # FAIL if any test files found
          if find . -name "*.test.ts" -o -name "*.spec.ts" | grep .; then
            echo "ERROR: Test files found in npm package!"
            exit 1
          fi

          # FAIL if test directories exist
          if [ -d "ios/Tests" ] || [ -d "__tests__" ] || [ -d "example" ]; then
            echo "ERROR: Test directories found in npm package!"
            exit 1
          fi

          # FAIL if Swift test files found
          if find ios -name "*Tests.swift" -o -name "*Test.swift" | grep .; then
            echo "ERROR: Swift test files found in package!"
            exit 1
          fi

      # Validate podspec has exclusions
      - name: Validate podspec exclusions
        run: |
          if ! grep -q "exclude_files.*Tests" LoqaAudioBridge.podspec; then
            echo "ERROR: Podspec missing test exclusions!"
            exit 1
          fi

      # Test fresh installation
      - name: Test installation
        run: |
          mkdir -p /tmp/test-install
          cd /tmp/test-install
          npm init -y
          npm install $OLDPWD/loqalabs-loqa-audio-bridge-*.tgz
```

**Success Criteria**:

- ✅ No `*.test.ts`, `*.spec.ts`, `*Tests.swift` files in tarball
- ✅ No `ios/Tests/`, `__tests__/`, `example/` directories in tarball
- ✅ Podspec contains `exclude_files` for tests
- ✅ Fresh install completes without errors

---

### Decision 4: CI/CD & npm Publishing Strategy

**Selected**: **GitHub Actions with manual trigger (git tag-based)**

**Workflow**:

```yaml
# .github/workflows/publish-npm.yml
name: Publish to npm

on:
  push:
    tags:
      - 'v*.*.*' # Trigger on version tags (e.g., v0.3.0)

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Run validation (from Decision 3)
      - name: Validate package
        run: npm run validate-package

      # Build
      - run: npm ci
      - run: npm run build

      # Publish to npm
      - uses: JS-DevTools/npm-publish@v3
        with:
          token: ${{ secrets.NPM_TOKEN }}
          access: public
```

**Publishing Process**:

1. Update version in `package.json` (e.g., `0.3.0`)
2. Commit: `git commit -m "Release v0.3.0"`
3. Tag: `git tag v0.3.0`
4. Push tag: `git push origin v0.3.0`
5. GitHub Actions automatically publishes to npm

**Rationale**:

- Git tags provide version audit trail
- Manual trigger prevents accidental publishes
- Automated validation ensures quality gate
- Aligns with Loqa monorepo patterns

---

### Decision 5: TypeScript Configuration

**Selected**: **Strict mode with ESNext targeting**

**Configuration** (`tsconfig.json`):

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2020"],
    "strict": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "declaration": true,
    "declarationMap": true,
    "outDir": "./build"
  },
  "include": ["src/**/*", "index.ts"],
  "exclude": ["__tests__", "**/*.test.ts", "example", "ios/Tests", "android/src/test"]
}
```

**Rationale**:

- `strict: true` catches type errors early
- ES2020 targets modern RN versions (0.72+)
- `declaration: true` generates `.d.ts` for TypeScript consumers
- Aligns with Expo module best practices

---

### Decision 6: Linting & Formatting

**Selected**: **ESLint + Prettier (Expo recommended configs)**

**Configuration**:

**ESLint** (`.eslintrc.js`):

```javascript
module.exports = {
  extends: ['expo', 'prettier'],
  plugins: ['prettier'],
  rules: {
    'prettier/prettier': 'error',
  },
};
```

**Prettier** (`.prettierrc`):

```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2
}
```

**Rationale**:

- `@expo/eslint-config` optimized for Expo modules
- Prettier ensures consistent formatting
- Pre-commit hooks optional (not enforced in v0.3.0 to reduce friction)

---

## 3. Project Structure

### 3.1 Final Directory Layout

```
@loqalabs/loqa-audio-bridge/
├── package.json
├── tsconfig.json
├── .npmignore
├── .eslintrc.js
├── .prettierrc
├── README.md
├── CHANGELOG.md
├── LICENSE (MIT)
│
├── expo-module.config.json    # Expo autolinking config
├── LoqaAudioBridge.podspec    # iOS CocoaPods config
│
├── index.ts                   # Main API entry (re-exports from src/)
├── src/
│   ├── LoqaAudioBridgeModule.ts   # Native module bindings
│   ├── types.ts                    # TypeScript type definitions
│   └── buffer-utils.ts             # Buffer management utilities
│
├── ios/
│   ├── LoqaAudioBridgeModule.swift    # iOS native implementation
│   ├── LoqaAudioBridge.xcodeproj      # (Generated by create-expo-module)
│   └── Tests/                          # iOS tests (EXCLUDED from podspec)
│       ├── LoqaAudioBridgeTests.swift
│       └── LoqaAudioBridgeIntegrationTests.swift
│
├── android/
│   ├── build.gradle
│   └── src/
│       ├── main/java/expo/modules/loqaaudiobridge/
│       │   └── LoqaAudioBridgeModule.kt   # Android native implementation
│       ├── test/                           # Android unit tests (auto-excluded)
│       └── androidTest/                    # Android integration tests (auto-excluded)
│
├── hooks/
│   └── useAudioStreaming.tsx   # React hook for lifecycle management
│
├── example/                    # Example Expo app (EXCLUDED from npm)
│   ├── package.json
│   ├── App.tsx
│   └── __tests__/
│
├── __tests__/                  # TypeScript unit tests (EXCLUDED from npm)
│   ├── index.test.ts
│   └── buffer-utils.test.ts
│
└── .github/
    └── workflows/
        ├── validate-package.yml    # Pre-publish validation
        └── publish-npm.yml         # Automated publishing
```

### 3.2 Critical Files

| File                                   | Purpose                            | Generated By         | Must Edit                                 |
| -------------------------------------- | ---------------------------------- | -------------------- | ----------------------------------------- |
| `package.json`                         | npm package metadata, dependencies | `create-expo-module` | ✅ Yes                                    |
| `expo-module.config.json`              | Expo autolinking configuration     | `create-expo-module` | ✅ Yes (platforms, iOS deployment target) |
| `LoqaAudioBridge.podspec`              | CocoaPods specification for iOS    | `create-expo-module` | ✅ Yes (add `exclude_files`)              |
| `tsconfig.json`                        | TypeScript compiler configuration  | Manual               | ✅ Yes                                    |
| `.npmignore`                           | Files to exclude from npm package  | Manual               | ✅ Yes (add test exclusions)              |
| `index.ts`                             | Main API entry point               | Copy from v0.2.0     | ✅ Yes                                    |
| `ios/LoqaAudioBridgeModule.swift`      | iOS native implementation          | Copy from v0.2.0     | ✅ Yes                                    |
| `android/.../LoqaAudioBridgeModule.kt` | Android native implementation      | Copy from v0.2.0     | ✅ Yes                                    |

---

## 4. Build & Distribution

### 4.1 Build Process

**TypeScript Compilation**:

```bash
npx tsc
# Outputs: build/*.js, build/*.d.ts
```

**iOS Build** (via CocoaPods):

```bash
cd ios
pod install
xcodebuild -workspace LoqaAudioBridge.xcworkspace -scheme LoqaAudioBridge
```

**Android Build**:

```bash
cd android
./gradlew build
```

### 4.2 npm Package Contents

**Included**:

- `package.json`
- `index.js` (compiled from `index.ts`)
- `src/*.js` (compiled TypeScript)
- `*.d.ts` (type definitions)
- `ios/*.swift` (excluding `ios/Tests/`)
- `android/src/main/` (excluding `src/test/`, `src/androidTest/`)
- `hooks/useAudioStreaming.tsx`
- `README.md`, `CHANGELOG.md`, `LICENSE`
- `expo-module.config.json`
- `LoqaAudioBridge.podspec`

**Excluded** (via `.npmignore`):

- `__tests__/`
- `*.test.ts`, `*.spec.ts`
- `ios/Tests/`
- `android/src/test/`, `android/src/androidTest/`
- `example/`
- `.github/`
- `tsconfig.json`, `.eslintrc.js`, `.prettierrc`

### 4.3 Installation (Consumer Perspective)

**For Expo Managed Workflow**:

```bash
npx expo install @loqalabs/loqa-audio-bridge
# Autolinking happens automatically
```

**For React Native CLI**:

```bash
npm install @loqalabs/loqa-audio-bridge
cd ios && pod install  # iOS only
# Android: Gradle autolinking via settings.gradle
```

**Expected Result**: Zero manual configuration required. Module autolinks and works immediately.

---

## 5. Test Architecture

### 5.1 Test Types & Locations

| Test Type               | Location                            | Purpose                     | Run Command                      | Excluded from npm? |
| ----------------------- | ----------------------------------- | --------------------------- | -------------------------------- | ------------------ |
| **TypeScript Unit**     | `__tests__/*.test.ts`               | API contracts, buffer utils | `npm test`                       | ✅ Yes             |
| **iOS Unit**            | `ios/Tests/*Tests.swift`            | Native module logic         | `xcodebuild test`                | ✅ Yes             |
| **iOS Integration**     | `ios/Tests/*IntegrationTests.swift` | Audio engine, events        | `xcodebuild test`                | ✅ Yes             |
| **Android Unit**        | `android/src/test/`                 | Native module logic         | `./gradlew test`                 | ✅ Yes (auto)      |
| **Android Integration** | `android/src/androidTest/`          | AudioRecord, permissions    | `./gradlew connectedAndroidTest` | ✅ Yes (auto)      |
| **Example App**         | `example/__tests__/`                | End-to-end integration      | `npm test` (in example/)         | ✅ Yes             |

### 5.2 Test Coverage Goals

**v0.3.0 Baseline**:

- TypeScript: 80% coverage (API, buffer utils)
- iOS: 70% coverage (core streaming logic)
- Android: 70% coverage (core streaming logic)

**Future (v0.4.0+)**:

- Increase to 90%+ with platform-specific edge cases

### 5.3 Test Exclusion Validation

**Pre-Commit Hook** (optional, not enforced):

```bash
#!/bin/bash
# Warn if test files modified without updating exclusions
if git diff --cached --name-only | grep -E "Tests\.swift|\.test\.ts"; then
  echo "Warning: Test files modified. Ensure .npmignore and podspec exclusions are up-to-date."
fi
```

**CI Validation** (enforced):

- See Decision 3.3 - runs on every PR and push to main

---

## 6. CI/CD Pipeline

### 6.1 Continuous Integration

**Trigger**: Every PR and push to `main`

**Jobs**:

1. **Lint**: `npm run lint`
2. **TypeScript Tests**: `npm test`
3. **iOS Build**: `xcodebuild build`
4. **Android Build**: `./gradlew build`
5. **Package Validation**: Validate no tests in tarball (Decision 3.3)

**Success Criteria**: All jobs pass before merge

### 6.2 Continuous Deployment

**Trigger**: Git tag push (e.g., `v0.3.0`)

**Jobs**:

1. **Validation**: Run CI pipeline
2. **Build**: Compile TypeScript, native modules
3. **Publish**: `npm publish` to public registry
4. **GitHub Release**: Create release notes from CHANGELOG.md

**Rollback**: If publish fails, delete git tag and fix issues

---

## 7. Integration Architecture

### 7.1 Autolinking Configuration

**expo-module.config.json**:

```json
{
  "platforms": ["ios", "android"],
  "ios": {
    "deploymentTarget": "13.4"
  },
  "android": {
    "compileSdkVersion": 34,
    "minSdkVersion": 24
  }
}
```

**iOS Autolinking** (via CocoaPods):

- Expo CLI reads `LoqaAudioBridge.podspec`
- Automatically adds to `Podfile`
- `pod install` links native Swift code

**Android Autolinking** (via Gradle):

- Expo CLI modifies `settings.gradle`
- Adds module to `build.gradle` dependencies
- Gradle links native Kotlin code

### 7.2 Consumer Integration Flow

**Step 1**: Install package

```bash
npx expo install @loqalabs/loqa-audio-bridge
```

**Step 2**: Import and use (no manual linking!)

```typescript
import { startAudioStream, addAudioSamplesListener } from '@loqalabs/loqa-audio-bridge';

// Start streaming
await startAudioStream({ sampleRate: 16000, bufferSize: 2048 });

// Listen for audio samples
const subscription = addAudioSamplesListener((event) => {
  console.log('Samples:', event.samples);
  console.log('RMS:', event.rms);
});
```

**Step 3**: Run app

```bash
npx expo run:ios
npx expo run:android
```

**Expected Time**: <30 minutes from `npm install` to running app (vs. 9 hours in v0.2.0)

---

## 8. Risk Mitigation

### 8.1 Identified Risks

| Risk                                       | Probability | Impact | Mitigation                                           |
| ------------------------------------------ | ----------- | ------ | ---------------------------------------------------- |
| **Tests ship to clients** (v0.2.0 failure) | Medium      | High   | Multi-layered exclusion + CI validation (Decision 3) |
| **Autolinking fails**                      | Low         | High   | Use `create-expo-module` scaffolding (Decision 1)    |
| **Breaking API changes**                   | Low         | Medium | Semantic versioning + deprecation warnings           |
| **Platform-specific bugs**                 | Medium      | Medium | Comprehensive test suite + example app testing       |
| **Dependency conflicts**                   | Low         | Low    | Broad peer dependencies (Decision 2)                 |

### 8.2 Rollback Plan

If v0.3.0 has critical issues:

1. Publish patch version (e.g., `0.3.1`) with fix
2. If unfixable, deprecate on npm: `npm deprecate @loqalabs/loqa-audio-bridge@0.3.0 "Critical bug, use 0.3.1"`
3. Communicate on GitHub Issues and Voiceline Slack

---

## 9. Dependencies

### 9.1 Production Dependencies

| Dependency     | Version    | Purpose                                |
| -------------- | ---------- | -------------------------------------- |
| `expo`         | `>=52.0.0` | Expo Modules Core (peer dependency)    |
| `react`        | `>=18.0.0` | React library (peer dependency)        |
| `react-native` | `>=0.72.0` | React Native runtime (peer dependency) |

**Note**: All are peer dependencies - consumers provide these.

### 9.2 Development Dependencies

| Dependency                      | Version   | Purpose                        |
| ------------------------------- | --------- | ------------------------------ |
| `typescript`                    | `^5.3.0`  | TypeScript compiler            |
| `@types/react`                  | `^18.0.0` | React type definitions         |
| `eslint`                        | `^8.0.0`  | Code linting                   |
| `prettier`                      | `^3.0.0`  | Code formatting                |
| `jest`                          | `^29.0.0` | TypeScript testing             |
| `@testing-library/react-native` | `^12.0.0` | React Native testing utilities |

### 9.3 Native Dependencies (iOS)

**CocoaPods** (`LoqaAudioBridge.podspec`):

```ruby
s.dependency 'ExpoModulesCore'
# No other iOS dependencies (uses native AVAudioEngine)
```

### 9.4 Native Dependencies (Android)

**Gradle** (`android/build.gradle`):

```gradle
dependencies {
  implementation project(':expo-modules-core')
  // No other Android dependencies (uses native AudioRecord)
}
```

---

## 10. Future Considerations

### 10.1 v0.4.0+ Roadmap

**Potential Features** (not committed):

1. **Audio Processing Pipeline**: Allow consumers to chain DSP processors
2. **WebRTC Integration**: Provide stream to WebRTC for real-time communication
3. **Background Audio**: Support background audio capture (requires permissions changes)
4. **Audio File Export**: Save audio buffers to WAV/MP3 files
5. **Multi-microphone Support**: Use external microphones (e.g., Bluetooth)

### 10.2 Maintenance Strategy

**Long-term Support**:

- v0.3.x: Maintain for 12 months after v0.4.0 release
- Security patches: Backport critical fixes to v0.3.x
- Deprecation policy: 6-month notice before removing features

### 10.3 Community Contribution

**Open Source**:

- License: MIT (permissive)
- Contributions welcome via GitHub PRs
- Issue tracker: GitHub Issues
- Documentation: README.md + API.md

---

## Appendix A: Architecture Decision Records (ADRs)

### ADR-001: Use create-expo-module as Foundation

- **Date**: 2025-11-13
- **Status**: Accepted
- **Context**: v0.2.0 failed due to missing packaging files
- **Decision**: Use official Expo scaffolding to ensure correct structure
- **Consequences**: Reduces risk but requires code migration from v0.2.0

### ADR-002: Rename to @loqalabs/loqa-audio-bridge

- **Date**: 2025-11-13
- **Status**: Accepted
- **Context**: Confusion with existing `loqa-voice-dsp` Rust crate
- **Decision**: Rename to clarify purpose (audio I/O, not DSP algorithms)
- **Consequences**: Clear naming but requires updating all documentation

### ADR-003: Multi-Layered Test Exclusion

- **Date**: 2025-11-13
- **Status**: Accepted
- **Context**: v0.2.0 shipped tests causing XCTest import errors
- **Decision**: 4-layer exclusion (podspec, npm, tsconfig, CI validation)
- **Consequences**: Complex but prevents repeat failures

### ADR-004: Git Tag-Based Publishing

- **Date**: 2025-11-13
- **Status**: Accepted
- **Context**: Need balance between automation and manual control
- **Decision**: GitHub Actions triggered by git tags
- **Consequences**: Manual version management but automated quality gates

---

## Appendix B: Key Learnings from v0.2.0

### What Worked

1. Event-driven architecture (8Hz streaming)
2. Native VAD implementation (30-50% battery savings)
3. Cross-platform API design
4. React hook (`useAudioStreaming`)

### What Failed

1. **No packaging files** → Manual integration required
2. **Tests shipped to clients** → XCTest import errors
3. **Missing documentation** → 9-hour integration time
4. **No example app** → Hard to validate integration

### How v0.3.0 Addresses Failures

1. **Packaging**: `create-expo-module` scaffolding + autolinking
2. **Tests**: Multi-layered exclusion + CI validation (Decision 3)
3. **Documentation**: Comprehensive README + API.md + example app
4. **Example app**: Full working Expo app in `example/` directory

---

## Document Change History

| Version | Date       | Author                                   | Changes                       |
| ------- | ---------- | ---------------------------------------- | ----------------------------- |
| 1.0     | 2025-11-13 | Claude (bmad:bmm:workflows:architecture) | Initial architecture document |

---

**Next Steps**:

1. Execute Epic 1: Project Scaffolding (run `create-expo-module`)
2. Migrate v0.2.0 code into scaffolded structure
3. Implement test exclusion layers (podspec, .npmignore, tsconfig)
4. Set up CI/CD pipelines (validate-package, publish-npm)
5. Create example app and validate end-to-end integration

**Approval Required**: Product Manager (PM) sign-off before proceeding to implementation phase.
