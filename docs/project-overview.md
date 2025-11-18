# VoicelineDSP Module - Project Overview

**Version:** 0.2.0
**Type:** Expo Native Module (Mobile)
**Location:** `modules/voiceline-dsp/`
**Platforms:** iOS (Swift), Android (Kotlin)
**Primary Language:** TypeScript

---

## Executive Summary

VoicelineDSP is a React Native/Expo native module providing real-time audio streaming and voice DSP analysis capabilities. It bridges native iOS (AVAudioEngine) and Android (AudioRecord) APIs to JavaScript, enabling low-latency audio capture with event-driven sample delivery.

**Current State (v0.2.0):**
- ✅ Real-time audio streaming from device microphone
- ✅ Cross-platform support (iOS + Android)
- ✅ Event-based audio sample delivery (~8 Hz)
- ✅ Voice Activity Detection (VAD) for battery optimization
- ✅ Adaptive processing for low-battery scenarios
- ✅ Comprehensive TypeScript API
- ✅ React hooks for lifecycle management

**Integration Status:**
- Delivered to Voiceline team as v0.2.0
- Integration feedback received (see `docs/voiceline/loqa-integration-feedback.md`)
- Requires packaging improvements for v0.3.0 (see PRD workflow)

---

## Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **API Layer** | TypeScript | 5.x | JavaScript interface and type definitions |
| **iOS Native** | Swift | 5.4+ | AVAudioEngine integration for iOS |
| **Android Native** | Kotlin | 1.8+ | AudioRecord integration for Android |
| **Framework** | Expo Modules | Latest | Native module infrastructure |
| **Build (iOS)** | CocoaPods | - | iOS dependency management |
| **Build (Android)** | Gradle | 8.x | Android build system |

---

## Architecture Pattern

**Native Module with Event-Driven Bridge**

```
┌─────────────────────────────────────────────────────────┐
│                  JavaScript/TypeScript                  │
│  ┌──────────────┐  ┌─────────────┐  ┌───────────────┐  │
│  │   index.ts   │  │  types.ts   │  │ buffer-utils  │  │
│  │  (Main API)  │  │ (TypeDefs)  │  │  (Utilities)  │  │
│  └──────────────┘  └─────────────┘  └───────────────┘  │
└────────────┬────────────────────────────────────────────┘
             │ Expo Modules Core (Event Emitter)
             ├─────────────────┬──────────────────────────
             │                 │
     ┌───────▼──────┐   ┌──────▼───────┐
     │   iOS Swift  │   │Android Kotlin│
     │ AVAudioEngine│   │ AudioRecord  │
     └──────────────┘   └──────────────┘
           Native Modules
```

**Key Architectural Decisions:**
1. **Event-driven design**: Audio samples delivered via events, not polling
2. **Buffer pooling**: Reuse Float arrays to reduce GC pressure
3. **Native processing**: RMS calculation and VAD done natively for performance
4. **Adaptive optimization**: Battery-aware frame rate reduction
5. **Cross-platform API**: Unified TypeScript interface hiding platform differences

---

## Project Structure

```
modules/voiceline-dsp/
├── index.ts                    # Main API entry point (413 lines)
├── src/
│   ├── types.ts               # TypeScript type definitions (136 lines)
│   ├── buffer-utils.ts        # Buffer management utilities (255 lines)
│   └── VoicelineDSPModule.ts  # Native module bindings (minimal)
├── ios/
│   ├── VoicelineDSPModule.swift  # iOS native implementation (~500 lines)
│   └── Tests/
│       ├── VoicelineDSPTests.swift
│       └── VoicelineDSPIntegrationTests.swift
├── android/
│   ├── build.gradle
│   └── src/
│       ├── main/java/expo/modules/voicelinedsp/
│       │   └── VoicelineDSPModule.kt  # Android native implementation
│       ├── test/                      # Unit tests
│       └── androidTest/               # Integration tests
├── hooks/
│   └── useAudioStreaming.tsx    # React hook for lifecycle management
├── examples/
│   └── README.md                # Usage examples
├── __tests__/
│   └── (TypeScript tests)
└── API.md                       # Comprehensive API documentation (730 lines)
```

---

## Core Capabilities

### 1. Audio Streaming
- Real-time microphone capture
- Configurable sample rates (8kHz - 48kHz)
- Configurable buffer sizes (512-8192 samples)
- Mono and stereo support
- ~8 Hz event rate at 16kHz/2048 buffer

### 2. Voice Activity Detection (VAD)
- Native RMS calculation
- Silence detection (threshold: RMS < 0.01)
- Automatic frame skipping during silence
- 30-50% battery savings when silent

### 3. Adaptive Processing
- Battery level monitoring (iOS/Android)
- Automatic frame rate reduction (8Hz → 4Hz when battery < 20%)
- 20-30% additional power savings on low battery
- Transparent to JavaScript layer

### 4. Cross-Platform Buffer Management
- iOS: Power-of-2 buffer sizes (AVAudioEngine requirement)
- Android: Flexible buffer sizes
- Automatic buffer size validation
- Sample rate fallback for iOS (16kHz, 44.1kHz, 48kHz)
- Buffer pool for reduced allocations

---

## Key Files and Responsibilities

| File | Lines | Responsibility |
|------|-------|----------------|
| `index.ts` | 413 | Main API, event subscriptions, configuration helpers |
| `src/types.ts` | 136 | TypeScript interfaces and enums |
| `src/buffer-utils.ts` | 255 | Buffer calculations, validations, platform-specific logic |
| `ios/VoicelineDSPModule.swift` | ~500 | iOS AVAudioEngine integration, audio tap, interruption handling |
| `android/.../VoicelineDSPModule.kt` | ~400 | Android AudioRecord integration, permission handling |
| `hooks/useAudioStreaming.tsx` | ~150 | React hook for lifecycle management |
| `API.md` | 730 | Complete API reference documentation |

---

## Integration Points

### JavaScript ← → Native Events

| Event | Direction | Frequency | Payload |
|-------|-----------|-----------|---------|
| `onAudioSamples` | Native → JS | ~8 Hz | Float32 samples, RMS, timestamp |
| `onStreamStatusChange` | Native → JS | On change | Status (streaming/stopped/paused) |
| `onStreamError` | Native → JS | On error | Error code, message, platform |

### JavaScript → Native Functions

| Function | Platform | Purpose |
|----------|----------|---------|
| `startAudioStream(config)` | Both | Initialize and start audio capture |
| `stopAudioStream()` | Both | Stop capture and release resources |
| `isStreaming()` | Both | Query current streaming state |

---

## Development Setup

**Prerequisites:**
- Node.js 18+ and npm/yarn
- iOS: Xcode 14+, CocoaPods
- Android: Android Studio, JDK 17

**Installation:**
```bash
cd modules/voiceline-dsp
npm install
```

**Build:**
```bash
# iOS
cd ios && pod install

# Android
cd android && ./gradlew build
```

**Test:**
```bash
# TypeScript tests
npm test

# iOS tests
xcodebuild test -workspace ios/VoicelineDSP.xcworkspace -scheme VoicelineDSP

# Android tests
cd android && ./gradlew test
```

---

## Testing Infrastructure

| Test Type | Location | Coverage |
|-----------|----------|----------|
| **TypeScript Unit** | `__tests__/` | API contracts, buffer utils, type safety |
| **iOS Unit** | `ios/Tests/VoicelineDSPTests.swift` | Native module logic |
| **iOS Integration** | `ios/Tests/VoicelineDSPIntegrationTests.swift` | Audio engine, event delivery |
| **Android Unit** | `android/src/test/` | Native module logic |
| **Android Integration** | `android/src/androidTest/` | AudioRecord, permissions |

---

## Known Issues and Gaps (v0.2.0)

Based on Voiceline integration feedback (see `docs/voiceline/loqa-integration-feedback.md`):

1. **Missing Configuration Files**: No `package.json`, `expo-module.config.json`, `.podspec`
2. **Autolinking Not Working**: Module not discovered by Expo's autolinking system
3. **Swift Compilation Errors**: Missing `required` keyword, deprecated Bluetooth API
4. **Test Files Included in Build**: Integration tests cause XCTest import errors
5. **Documentation Gaps**: No step-by-step Expo integration guide

**Impact**: 9-hour integration time for Voiceline team (should be <2 hours)

**Resolution**: VoicelineDSP v0.3.0 will address these issues (see PRD workflow)

---

## Next Steps (v0.3.0 Planning)

VoicelineDSP v0.3.0 - Production-Grade Foundation project is tracked in:
- **Workflow Status**: `docs/bmm-workflow-status.yaml`
- **Integration Feedback**: `docs/voiceline/loqa-integration-feedback.md`
- **Upcoming PRD**: Will define requirements for production packaging

**Goal**: Transform from working module into production-grade, npm-installable package with:
- Proper Expo module scaffolding (via `create-expo-module`)
- Automated autolinking
- Complete documentation
- Example app
- CI/CD integration
- Zero manual integration steps

---

## References

- **API Documentation**: `modules/voiceline-dsp/API.md`
- **Integration Feedback**: `docs/voiceline/loqa-integration-feedback.md`
- **Examples**: `modules/voiceline-dsp/examples/`
- **Voiceline Handoff Docs**: `docs/voiceline/HANDOFF.md`

---

**Last Updated**: 2025-11-13
**Documentation Generated By**: BMad document-project workflow
