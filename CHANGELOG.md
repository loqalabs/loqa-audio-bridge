# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1] - 2025-11-20

### Fixed

- **Critical: Module Resolution Error**: Fixed package.json entry points to correctly point to `build/src/index.js` instead of `build/index.js`. The v0.3.0 package was unusable due to Metro bundler being unable to resolve the module. This patch makes the package installable and functional. (Issue reported by Voiceline team)

## [0.3.0] - 2025-11-13

### Added

- **Production npm Package**: Published to npm registry as [@loqalabs/loqa-audio-bridge](https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge)
- **One-Command Installation**: Install via `npx expo install @loqalabs/loqa-audio-bridge`
- **Comprehensive Documentation**:
  - [README.md](README.md): Quick start guide for <5 minute package evaluation
  - [API.md](API.md): Complete API reference with React hook examples
  - [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md): Step-by-step integration guide for <30 minute setup
- **Multi-Layer Test Exclusion**: Four-layer defense preventing test files from shipping to production
  - Layer 1: iOS Podspec exclusions
  - Layer 2: Android Gradle auto-exclusion
  - Layer 3: .npmignore exclusions
  - Layer 4: CI validation pipeline
- **GitHub Actions CI/CD Pipeline**:
  - Automated linting, TypeScript tests, and build validation
  - iOS build validation (Xcode on macOS runners)
  - Android build validation (Gradle on Ubuntu runners)
  - Package validation job enforcing test exclusion policies
- **Automated npm Publishing**: Git tag-based publishing workflow with GitHub Actions
- **Example App**: Fully functional audio streaming demo in `/example` directory
  - Microphone permissions handling
  - Real-time RMS visualization
  - Audio streaming controls
  - Error handling demonstrations
- **EAS Build Compatibility**: Validated to work with Expo Application Services cloud builds without special configuration
- **Module Structure Validation**: Custom validation script ensuring Metro bundler compatibility

### Fixed

- **iOS Swift Syntax**: Added `required` keyword to `ModuleDefinition` initializer (Swift 5.4+ requirement)
- **iOS Audio Format Conversion**: Implemented hardware format detection (48kHz) with AVAudioConverter downsampling to 16kHz
- **iOS Deprecated API**: Replaced `.allowBluetoothA2DP` with `.allowBluetooth` (iOS 10+ compatibility)
- **Test File Shipping**: Prevented test files from being included in npm package (resolves v0.2.0 XCTest import errors)
- **Metro Bundler Resolution**: Fixed example app to correctly resolve module files from parent directory
- **Package Entry Points**: Corrected package.json paths to point to `build/index.js` for Metro compatibility

### Changed

- **Package Name**: Renamed from `voiceline-expo-audio-bridge` to `@loqalabs/loqa-audio-bridge`
- **Package Structure**: Regenerated with `create-expo-module` for production-grade scaffolding
- **Installation Process**: Simplified from 9-hour manual integration to <30 minute automated setup
- **Build System**: Migrated to TypeScript 5.3+ with comprehensive type definitions
- **Code Quality**: Achieved zero compilation warnings across TypeScript, iOS (Swift), and Android (Kotlin)
- **Testing Infrastructure**:
  - 21/21 unit tests passing (buffer-utils: 11, type contracts: 10)
  - iOS tests migrated (48 tests, 1,153 lines)
  - Android tests migrated (41 tests, 1,371 lines)

## [0.2.0] - 2024-03-01

### Added

- Initial working implementation for Voiceline deployment
- Real-time audio streaming from device microphone
- Voice Activity Detection (VAD) for speech detection
- Battery optimization for continuous audio streaming
- React Native TypeScript API layer
- iOS Swift native module implementation
- Android Kotlin native module implementation
- Basic buffer utilities and type contracts

### Known Issues

- **Manual Integration Required**: 9-hour integration process due to missing autolinking
- **Test Files Shipped**: Test files included in deployment causing XCTest import errors
- **Missing Documentation**: No README, API docs, or integration guide
- **No CI/CD**: Manual build and deployment process
- **Package Not Published**: Not available on npm registry

---

## Migration Guides

For detailed upgrade instructions between major versions, see:

- **v0.2.0 → v0.3.0**: Complete rewrite with breaking changes. See [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) for fresh integration steps. Previous manual integration steps no longer apply.

## Links

- [npm Package](https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge)
- [GitHub Repository](https://github.com/loqalabs/loqa-audio-bridge)
- [Issue Tracker](https://github.com/loqalabs/loqa-audio-bridge/issues)
