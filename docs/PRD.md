# @loqalabs/loqa-audio-bridge v0.3.0 - Product Requirements Document

**Author:** Anna
**Date:** 2025-11-13
**Version:** 1.0
**Project:** @loqalabs/loqa-audio-bridge v0.3.0 - Production-Grade Foundation
**Package Name:** @loqalabs/loqa-audio-bridge (formerly VoicelineDSP)

---

## Executive Summary

**@loqalabs/loqa-audio-bridge** v0.3.0 transforms a functional but difficult-to-integrate native module into a production-grade, npm-installable Expo package with zero manual setup. This version addresses critical integration pain points discovered during v0.2.0 deployment (when named VoicelineDSP), where a 9-hour integration process revealed missing configuration files, non-functional autolinking, and inadequate documentation. The goal is to reduce integration time from 9 hours to under 30 minutes while maintaining the module's excellent performance characteristics (2-5% CPU usage, 3-8%/hour battery impact with VAD).

**Package Naming**: Renamed from `VoicelineDSP` to `@loqalabs/loqa-audio-bridge` to align with Loqa Labs branding and distinguish from the existing `loqa-voice-dsp` Rust crate (which provides DSP algorithms like pitch detection and formant extraction, while this package provides audio I/O streaming).

### What Makes This Special

**Eliminating Integration Friction for Developer Tools**

Most native modules focus on technical features but overlook the integration experience. @loqalabs/loqa-audio-bridge v0.3.0 prioritizes developer experience by making the module "just work" out of the box - no manual Podfile edits, no ExpoModulesProvider modifications, no hunting for missing configuration files. This reflects a philosophy that excellent technology is only valuable when it's accessible. By using proper Expo module scaffolding (via `create-expo-module`) and comprehensive documentation, we're transforming from a powerful-but-challenging module into a delightful developer experience that sets the standard for React Native audio processing.

---

## Project Classification

**Technical Type:** Mobile (Expo Native Module - Developer SDK/Library)
**Domain:** General (Audio/DSP - Media Processing)
**Complexity:** Medium-High

**Project Context:**

This is a **brownfield refactoring and packaging project** for an existing, functional native module (v0.2.0, previously named VoicelineDSP). The core technology - real-time audio streaming with Voice Activity Detection (VAD), adaptive battery optimization, and cross-platform support (iOS Swift + Android Kotlin) - is already implemented and tested. The v0.3.0 release focuses exclusively on **production-grade packaging, distribution infrastructure, and developer experience** to enable seamless integration into Expo applications.

**Key Attributes:**
- **Existing Codebase**: ~1,500 lines of production-quality Swift/Kotlin/TypeScript
- **Proven Technology**: Successfully deployed to Voiceline team (v0.2.0)
- **Integration Feedback**: Detailed 360-line feedback document identifies exact issues
- **Target Framework**: Expo 52-54+ with React Native 0.72+

---

## Success Criteria

Success for @loqalabs/loqa-audio-bridge v0.3.0 is measured by **developer experience metrics** and **integration time reduction**, not feature additions:

### Primary Success Criteria

**Integration Time Reduction**
- **Current State (v0.2.0)**: 9-hour integration requiring manual configuration
- **Target State (v0.3.0)**: <30 minutes from `npm install` to working audio stream
- **Measurement**: Time from package installation to successful `startAudioStream()` call
- **Validation**: Fresh Expo project, no prior knowledge of module, following only README

**Zero Manual Steps**
- No manual Podfile edits required
- No manual ExpoModulesProvider.swift modifications
- No post-prebuild scripts or sed commands needed
- Autolinking works seamlessly on both iOS and Android

**Developer Confidence**
- Example app demonstrates all features and runs immediately after installation
- Clear error messages with actionable solutions (not "Cannot find native module")
- Documentation answers integration questions before developers ask them
- Troubleshooting guide covers 90% of common issues

### Secondary Success Criteria

**Code Quality & Maintainability**
- Zero Swift/Kotlin compilation warnings or errors
- CI/CD pipeline validates builds on every commit
- Semantic versioning with automated release process
- Test coverage maintained at v0.2.0 levels (unit + integration tests)

**Distribution & Accessibility**
- Published to npm registry (@loqalabs/loqa-audio-bridge)
- GitHub releases with changelogs and migration guides
- Installation via single command: `npx expo install @loqalabs/loqa-audio-bridge`

### What Success Looks Like

**Developer Journey (v0.3.0):**
1. Developer runs: `npx expo install @loqalabs/loqa-audio-bridge`
2. Module installs, autolinking configures both platforms automatically
3. Developer runs: `npx expo run:ios` (or run:android)
4. App builds successfully with zero manual steps
5. Developer imports and uses API from documentation examples
6. Audio streaming works immediately

**Contrast with v0.2.0:**
1. Developer copies module files into project
2. Creates package.json, expo-module.config.json, and .podspec manually
3. Edits Podfile to add manual entry
4. Runs `npx expo prebuild`
5. Edits ExpoModulesProvider.swift to register module
6. Fixes Swift compilation errors (missing `required` keyword, deprecated Bluetooth API)
7. Excludes test files from podspec
8. Runs build again, finally succeeds
9. **Total: 9 hours of frustration**

---

## Product Scope

### MVP - Minimum Viable Product (v0.3.0 Core)

**Essential Deliverables for Production Release:**

**1. Proper Expo Module Scaffolding**
- Regenerate module structure using `create-expo-module` CLI
- All required configuration files automatically generated:
  - `package.json` with proper metadata and peerDependencies
  - `expo-module.config.json` with platform-specific module names
  - `voiceline-dsp.podspec` for iOS CocoaPods integration
  - `build.gradle` for Android module configuration
- Expo autolinking functional out of the box (no manual Podfile edits)

**2. Code Quality & Compilation Fixes**
- Fix Swift compilation error: Add `required` keyword to init override
- Update deprecated iOS API: Change `.allowBluetooth` to `.allowBluetoothA2DP`
- Exclude test files from production builds (update podspec)
- Achieve zero compilation warnings on both platforms

**3. npm Package Distribution**
- Publish to npm registry as `@loqalabs/loqa-audio-bridge`
- Semantic versioning (v0.3.0 initial release)
- Package includes all source code, TypeScript types, and platform implementations
- Installation via: `npx expo install @loqalabs/loqa-audio-bridge`

**4. Core Functionality Preservation**
- Maintain 100% of v0.2.0 features (no feature regression):
  - Real-time audio streaming (8kHz-48kHz configurable sample rates)
  - Voice Activity Detection (VAD) with battery optimization
  - Adaptive processing (battery-aware frame rate reduction)
  - Cross-platform support (iOS AVAudioEngine + Android AudioRecord)
  - Event-driven architecture with TypeScript API
  - React hooks (`useAudioStreaming`)
- Preserve all existing tests (TypeScript, Swift, Kotlin)

**5. Essential Documentation**
- **README.md**: Installation, quick start, basic usage examples
- **INTEGRATION_GUIDE.md**: Step-by-step Expo integration instructions
- **API.md**: Migrate existing 730-line API reference (already excellent)
- **MIGRATION.md**: v0.2.0 → v0.3.0 migration guide for existing users

**6. Working Example App**
- Minimal Expo app demonstrating:
  - Module installation and setup
  - Basic audio streaming with visualization
  - Event handling (onAudioSamples, onStreamStatusChange, onStreamError)
  - React hook usage pattern
- Runs successfully with: `npm install && npx expo run:ios`

### Growth Features (Post-v0.3.0)

**Features to consider after successful MVP launch:**

**1. Advanced Documentation & DX**
- Video walkthrough of installation and usage (5-minute screencast)
- Interactive documentation website (Docusaurus or similar)
- Troubleshooting flowcharts for common issues
- Performance tuning guide for different use cases

**2. CI/CD & Automation**
- Automated testing on GitHub Actions (iOS + Android builds)
- Automated npm publishing via GitHub Releases
- Integration test suite validating autolinking works
- Pre-commit hooks for code quality (linting, type checking)

**3. Enhanced Example Apps**
- Advanced example: Real-time pitch detection visualization
- Advanced example: Voice activity monitoring with waveform display
- Advanced example: Multi-configuration testing app
- Expo Snack for quick browser-based demos

**4. Developer Tooling**
- CLI tool for module configuration validation
- Debug mode with verbose logging
- Performance profiling utilities
- Test harness for VAD and adaptive processing

### Vision (Future - v0.4.0+)

**Long-term enhancements aligned with audio processing roadmap:**

**1. Native DSP Features** (v0.4.0)
- Native FFT computation for frequency domain analysis
- Real-time pitch detection (fundamental frequency extraction)
- Formant analysis for vocal tract resonance
- Spectrogram data generation for visualization

**2. Recording & Playback** (v0.4.0)
- Audio recording to file (WAV, AAC formats)
- Real-time audio playback with DSP effects
- Audio file processing and analysis

**3. Advanced Audio Features** (v0.5.0)
- Multi-channel support (stereo, multi-mic arrays)
- Audio source switching (microphone, line-in, Bluetooth)
- Real-time audio effects (reverb, echo, filters)
- WebRTC integration for voice communication

**4. Ecosystem Integration** (v0.5.0+)
- TensorFlow Lite integration for ML audio models
- Cloud audio processing pipeline connectors
- Audio visualization libraries (waveform, spectrogram)
- Voice recognition API integrations

---

## Mobile (Expo Native Module) Specific Requirements

### Platform Requirements

**iOS Platform:**
- **Minimum Version**: iOS 13.4+
- **Swift Version**: 5.4+
- **Framework**: AVFoundation (AVAudioEngine, AVAudioSession)
- **Build System**: CocoaPods via Expo autolinking
- **Capabilities Required**:
  - Microphone usage permission (NSMicrophoneUsageDescription in Info.plist)
  - Background audio capability (optional, for background streaming)

**Android Platform:**
- **Minimum SDK**: API 21 (Android 5.0 Lollipop)
- **Target SDK**: API 34+ (Android 14+)
- **Language**: Kotlin 1.8+
- **Framework**: android.media.AudioRecord
- **Build System**: Gradle 8.x via Expo autolinking
- **Permissions Required**:
  - `android.permission.RECORD_AUDIO` (runtime permission)
  - Optional: `android.permission.MODIFY_AUDIO_SETTINGS`

### Expo Framework Requirements

**Expo Version Compatibility:**
- **Minimum**: Expo 52 (with Expo Modules Core 1.x)
- **Recommended**: Expo 54+ (with React Native 0.81+)
- **Build System**: EAS Build compatible

**Module Configuration:**
- Expo config plugin (optional enhancement for app.json integration)
- Autolinking via expo-module.config.json
- No ejection required (works with managed workflow)

### React Native Requirements

**React Native Version:**
- **Minimum**: React Native 0.72
- **Recommended**: React Native 0.81+
- **JavaScript Engine**: Hermes or JSC compatible
- **Event System**: Expo Modules Core EventEmitter

### Package Distribution

**npm Package Structure:**
- **Package Name**: `@loqalabs/loqa-audio-bridge`
- **Scope**: Organization-scoped (@loqalabs)
- **Installation Method**: `npx expo install @loqalabs/loqa-audio-bridge`
- **Peer Dependencies**:
  - expo (*)
  - expo-modules-core (*)
  - react (^18.0.0)
  - react-native (>=0.72.0)

### Autolinking Requirements

**iOS Autolinking:**
- Podspec file must be present in module root
- Module name in podspec matches Expo config
- CocoaPods discovers module via Expo autolinking scanner
- No manual Podfile edits required

**Android Autolinking:**
- build.gradle properly configured with module package name
- AndroidManifest.xml included with permissions templates
- Expo autolinking discovers gradle module automatically
- No manual settings.gradle edits required

### Module File Structure

```
@loqalabs/loqa-audio-bridge/
├── package.json                    # npm metadata
├── expo-module.config.json         # Expo module configuration
├── voiceline-dsp.podspec          # iOS CocoaPods spec
├── index.ts                        # Main TypeScript API export
├── src/
│   ├── types.ts                   # TypeScript type definitions
│   ├── buffer-utils.ts            # Utility functions
│   └── VoicelineDSPModule.ts      # Native module bindings
├── ios/
│   ├── VoicelineDSPModule.swift   # iOS native implementation
│   └── VoicelineDSPModule.podspec (if separate)
├── android/
│   ├── build.gradle               # Android build configuration
│   └── src/main/java/expo/modules/voicelinedsp/
│       └── VoicelineDSPModule.kt  # Android native implementation
├── hooks/
│   └── useAudioStreaming.tsx      # React hook
├── __tests__/                     # TypeScript tests
├── example/                       # Example Expo app
│   ├── package.json
│   ├── app.json
│   └── App.tsx
├── README.md                      # Installation and quick start
├── API.md                         # Comprehensive API docs
├── INTEGRATION_GUIDE.md           # Step-by-step integration
└── MIGRATION.md                   # v0.2.0 → v0.3.0 guide
```

### Testing Requirements

**Unit Tests (Existing - must be preserved):**
- TypeScript API tests (__tests__/)
- iOS native tests (ios/Tests/ - excluded from builds)
- Android native tests (android/src/test/)

**Integration Tests:**
- Autolinking validation test (confirm module loads without manual steps)
- Fresh Expo project installation test
- Both platforms build successfully test
- Example app runs test

**Compatibility Testing:**
- Expo 52, 53, 54 versions
- React Native 0.72, 0.76, 0.81
- iOS 13.4, 14.0, 15.0, 16.0, 17.0
- Android API 21, 26, 29, 31, 34

### Device Feature Requirements

**Microphone Access:**
- Runtime permission handling (iOS + Android)
- Clear user-facing permission prompts
- Graceful degradation if permission denied
- Permission status checking API

**Battery Optimization:**
- Battery level monitoring (both platforms)
- Adaptive frame rate reduction when battery < 20%
- VAD (Voice Activity Detection) for silence skipping
- Battery usage transparency in documentation

**Audio Session Management (iOS):**
- Proper AVAudioSession category configuration
- Interruption handling (phone calls, Siri, alarms)
- Route change handling (headphones, Bluetooth)
- Background audio support (optional capability)

### Build System Requirements

**iOS Build:**
- Compatible with Xcode 14+ and 15+
- CocoaPods integration via .podspec
- Swift compilation with zero warnings
- Static framework configuration
- Test files excluded from production builds

**Android Build:**
- Compatible with Android Studio Flamingo+
- Gradle 8.x build system
- Kotlin 1.8+ compilation
- AAR library output
- ProGuard/R8 rules (if needed for minification)

### Distribution & Release

**npm Registry:**
- Public package on npm registry
- Scoped to @loqalabs organization
- Semantic versioning (MAJOR.MINOR.PATCH)
- Automated publishing via CI/CD

**GitHub Releases:**
- Tagged releases (v0.3.0, v0.3.1, etc.)
- Release notes with changelogs
- Migration guides for breaking changes
- Source code archives

**EAS Build Compatibility:**
- Works with Expo Application Services (EAS) cloud builds
- No special configuration required for EAS
- Validated on both iOS and Android EAS builds

---

## Functional Requirements

### Packaging & Scaffolding

**FR1**: System shall regenerate module structure using `create-expo-module` CLI to ensure proper Expo module scaffolding

**FR2**: System shall include complete package.json with:
- Package name: @loqalabs/loqa-audio-bridge
- Proper semantic version (0.3.0)
- Peer dependencies for expo, expo-modules-core, react, react-native
- Main entry point and TypeScript types declarations

**FR3**: System shall include expo-module.config.json specifying:
- Supported platforms (iOS, Android)
- iOS module name: VoicelineDSPModule
- Android module package: expo.modules.voicelinedsp.VoicelineDSPModule

**FR4**: System shall include voiceline-dsp.podspec for iOS with:
- Dynamic version reading from package.json
- ExpoModulesCore dependency
- Test file exclusions (ios/Tests/**/*)
- Swift 5.4+ requirement

**FR5**: System shall include Android build.gradle with:
- Proper module package configuration
- Kotlin 1.8+ compilation settings
- Expo Modules Core integration

### Code Quality & Compilation

**FR6**: System shall fix Swift compilation error by adding `required` keyword to init override in VoicelineDSPModule.swift

**FR7**: System shall update deprecated iOS API from `.allowBluetooth` to `.allowBluetoothA2DP` in AVAudioSession configuration

**FR8**: System shall exclude test files from production builds via podspec `s.exclude_files` directive

**FR9**: System shall compile with zero warnings on both iOS (Swift) and Android (Kotlin) platforms

### Autolinking & Integration

**FR10**: System shall enable automatic module discovery via Expo autolinking on iOS without manual Podfile edits

**FR11**: System shall enable automatic module discovery via Expo autolinking on Android without manual build.gradle edits

**FR12**: System shall register module automatically in ExpoModulesProvider.swift without manual code modifications

**FR13**: System shall validate autolinking works correctly in fresh Expo project installation

### Core Functionality Preservation

**FR14**: System shall maintain 100% feature parity with v0.2.0 including:
- Real-time audio streaming API (startAudioStream, stopAudioStream, isStreaming)
- Configurable sample rates (8kHz, 16kHz, 32kHz, 44.1kHz, 48kHz)
- Configurable buffer sizes (512-8192 samples, power-of-2 on iOS)
- Mono and stereo channel support

**FR15**: System shall preserve Voice Activity Detection (VAD) functionality:
- Native RMS calculation
- Silence detection (RMS < 0.01 threshold)
- Automatic frame skipping during silence
- Battery savings of 30-50% when silent

**FR16**: System shall preserve Adaptive Processing functionality:
- Battery level monitoring on both platforms
- Frame rate reduction from 8Hz to 4Hz when battery < 20%
- 20-30% additional power savings on low battery

**FR17**: System shall maintain event-driven architecture with three event types:
- onAudioSamples: Audio data with samples, sampleRate, frameLength, timestamp, RMS
- onStreamStatusChange: Status updates (streaming/stopped/paused/battery_optimized)
- onStreamError: Error notifications with code, message, platform, timestamp

**FR18**: System shall preserve React hook (useAudioStreaming) with lifecycle management

**FR19**: System shall maintain all existing TypeScript type definitions and interfaces

**FR20**: System shall preserve all existing unit and integration tests:
- TypeScript API tests
- iOS Swift tests
- Android Kotlin tests

### npm Package Distribution

**FR21**: System shall publish package to npm registry as @loqalabs/loqa-audio-bridge

**FR22**: System shall support installation via `npx expo install @loqalabs/loqa-audio-bridge`

**FR23**: System shall include all source code, TypeScript types, and native implementations in npm package

**FR24**: System shall follow semantic versioning (MAJOR.MINOR.PATCH)

**FR25**: System shall include package metadata: description, author, license, repository, keywords

### Documentation

**FR26**: System shall provide README.md with:
- Installation instructions (single command)
- Quick start example (5-10 lines of code)
- Basic usage examples
- Link to comprehensive documentation

**FR27**: System shall provide INTEGRATION_GUIDE.md with:
- Step-by-step Expo integration instructions
- Prerequisites (Expo version, React Native version)
- Troubleshooting common issues
- Permission handling (iOS + Android)

**FR28**: System shall migrate existing API.md (730 lines) to new package structure

**FR29**: System shall provide MIGRATION.md with:
- v0.2.0 → v0.3.0 upgrade guide
- Breaking changes (if any)
- Migration steps for existing users
- Deprecated API warnings

### Example Application

**FR30**: System shall include working example/ directory with Expo app demonstrating:
- Basic audio streaming setup
- Event handling pattern
- React hook usage
- Audio visualization (waveform or simple bar chart)

**FR31**: Example app shall build and run successfully with `npm install && npx expo run:ios`

**FR32**: Example app shall demonstrate both iOS and Android platforms

**FR33**: Example app shall include clear code comments explaining each integration step

### Build & Release

**FR34**: System shall support iOS builds with Xcode 14+ and 15+

**FR35**: System shall support Android builds with Gradle 8.x

**FR36**: System shall be compatible with Expo 52, 53, and 54

**FR37**: System shall be compatible with React Native 0.72+

**FR38**: System shall work with EAS Build (Expo Application Services) without special configuration

---

## Non-Functional Requirements

### Performance

**NFR1**: Integration time shall be reduced from 9 hours (v0.2.0) to under 30 minutes (v0.3.0)

**NFR2**: Module installation via `npx expo install` shall complete in under 60 seconds on standard internet connection

**NFR3**: Example app shall build successfully in under 5 minutes on standard Mac hardware (M-series or recent Intel)

**NFR4**: Runtime performance shall match v0.2.0 benchmarks:
- CPU usage: 2-5% per core during active streaming
- Memory footprint: 5-10 MB including buffer pool
- Battery impact: 3-8%/hour with VAD enabled
- Event rate: ~8 Hz at 16kHz/2048 buffer configuration

### Reliability

**NFR5**: Autolinking shall work successfully in 100% of fresh Expo project installations (validated by CI tests)

**NFR6**: Module shall compile with zero errors on both platforms (iOS + Android)

**NFR7**: All existing v0.2.0 tests shall pass without modification (unit + integration tests)

**NFR8**: Example app shall run successfully on first launch after installation

### Usability & Developer Experience

**NFR9**: Developers shall achieve working audio stream within 30 minutes following only README.md

**NFR10**: Documentation shall answer 90% of integration questions without external support

**NFR11**: Error messages shall provide actionable solutions (e.g., "Run `npx pod-install`" instead of "Cannot find native module")

**NFR12**: Troubleshooting guide shall cover common issues with clear resolution steps

### Maintainability

**NFR13**: Codebase shall maintain v0.2.0 architecture and patterns (no major refactoring)

**NFR14**: All code shall follow Expo module best practices and conventions

**NFR15**: TypeScript types shall have 100% coverage for public API surface

**NFR16**: Documentation shall be versioned and synchronized with package releases

### Compatibility

**NFR17**: Module shall support iOS 13.4+ through iOS 17.0+

**NFR18**: Module shall support Android API 21 (Lollipop) through API 34 (Android 14)

**NFR19**: Module shall work with both Hermes and JSC JavaScript engines

**NFR20**: Module shall support both managed and bare Expo workflows

### Security & Privacy

**NFR21**: Module shall request microphone permissions appropriately on both platforms

**NFR22**: Module shall handle permission denials gracefully without crashes

**NFR23**: Module shall not include any analytics, telemetry, or external network calls

**NFR24**: Module shall clearly document data handling (all audio processing is local)

---

## Implementation Planning

### Epic Breakdown Required

The implementation of VoicelineDSP v0.3.0 will be organized into the following epics:

**Epic 1: Module Scaffolding & Configuration**
- Regenerate module structure with create-expo-module
- Create all required configuration files
- Set up proper package.json and npm metadata
- Configure autolinking for both platforms

**Epic 2: Code Migration & Quality Fixes**
- Migrate v0.2.0 code into new scaffolding
- Fix Swift compilation errors
- Update deprecated APIs
- Exclude test files from builds
- Achieve zero compilation warnings

**Epic 3: Documentation & Integration Guide**
- Write README.md with quick start
- Create comprehensive INTEGRATION_GUIDE.md
- Migrate existing API.md
- Write MIGRATION.md for v0.2.0 users

**Epic 4: Example Application**
- Create example Expo app
- Implement audio streaming demo
- Add visualization component
- Document integration steps

**Epic 5: Testing & Validation**
- Validate autolinking on fresh projects
- Run all existing v0.2.0 tests
- Test on multiple Expo/RN versions
- EAS Build validation

**Epic 6: Distribution & Release**
- Set up npm publishing
- Create GitHub release workflow
- Publish v0.3.0 to npm registry
- Create release notes and changelog

**Next Step:** Run `/bmad:bmm:workflows:create-epics-and-stories` to create detailed epic breakdown and user stories.

---

## References

### Source Documentation

- [Project Overview](./project-overview.md) - Executive summary of v0.2.0 module
- [Architecture Documentation](./architecture.md) - Technical design and patterns
- [Integration Feedback](./collaboration/loqa-integration-feedback.md) - Detailed v0.2.0 integration issues
- [API Reference](../../modules/voiceline-dsp/API.md) - Comprehensive API documentation

### External Resources

- [Expo Modules API Documentation](https://docs.expo.dev/modules/)
- [create-expo-module CLI Guide](https://docs.expo.dev/modules/get-started/)
- [Expo Autolinking Documentation](https://docs.expo.dev/modules/autolinking/)
- [React Native Core Principles](https://reactnative.dev/docs/getting-started)

---

## Next Steps

1. **Review & Approval**: Validate PRD captures all v0.3.0 requirements
2. **Epic Breakdown**: Run epic creation workflow to decompose requirements into stories
3. **Architecture**: Define technical architecture for npm packaging and CI/CD
4. **Sprint Planning**: Organize epics into development sprints
5. **Implementation**: Execute stories to build v0.3.0

---

**Document Version**: 1.0
**Last Updated**: 2025-11-13
**Created By**: Anna (BMad PRD Workflow)
**Project Track**: BMad Method (Brownfield Refactoring)

