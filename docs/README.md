# VoicelineDSP Module - Documentation Index

**Module Version:** 0.2.0
**Documentation Generated:** 2025-11-13
**Project Root:** `modules/voiceline-dsp/`
**Documentation Type:** Brownfield project analysis (Deep scan)

---

## Quick Reference

| Attribute | Value |
|-----------|-------|
| **Project Type** | Mobile (Expo Native Module) |
| **Repository Structure** | Monolith |
| **Primary Language** | TypeScript + Swift + Kotlin |
| **Platforms** | iOS (13.4+), Android (API 21+) |
| **Architecture** | Native Module with Event-Driven Bridge |
| **Framework** | Expo Modules Core + React Native |
| **Current Status** | v0.2.0 delivered to Voiceline team |
| **Next Version** | v0.3.0 - Production-Grade Foundation (in planning) |

---

## Project Structure

```
modules/voiceline-dsp/
├── index.ts                          # Main API (413 lines)
├── src/
│   ├── types.ts                     # TypeScript types (136 lines)
│   ├── buffer-utils.ts              # Buffer management (255 lines)
│   └── VoicelineDSPModule.ts        # Native module bindings
├── ios/
│   ├── VoicelineDSPModule.swift     # iOS implementation (~500 lines)
│   └── Tests/                       # iOS unit + integration tests
├── android/
│   ├── build.gradle                 # Android build config
│   └── src/
│       ├── main/.../VoicelineDSPModule.kt  # Android implementation
│       ├── test/                    # Android unit tests
│       └── androidTest/             # Android integration tests
├── hooks/
│   └── useAudioStreaming.tsx        # React hook (~150 lines)
├── examples/
│   └── README.md                    # Usage examples
├── __tests__/                       # TypeScript tests
└── API.md                           # Complete API reference (730 lines)
```

---

## Documentation

### Core Documentation

1. **[Project Overview](./project-overview.md)**
   - Executive summary of VoicelineDSP module
   - Technology stack and capabilities
   - Current state (v0.2.0) and known issues
   - Integration status with Voiceline team
   - Next steps for v0.3.0

2. **[Architecture Documentation](./architecture.md)**
   - System architecture and design patterns
   - Platform-specific implementations (iOS + Android)
   - Data flow and event system
   - Performance optimizations (VAD, buffer pooling, adaptive processing)
   - Error handling and testing strategy

### Module Source Documentation

3. **[API Reference](../../modules/voiceline-dsp/API.md)**
   - Complete API documentation (730 lines)
   - Type definitions and interfaces
   - Function reference with examples
   - React hooks usage
   - Error handling guide
   - Performance optimization tips
   - Troubleshooting section

4. **[Usage Examples](../../modules/voiceline-dsp/examples/README.md)**
   - Basic streaming example
   - React hook integration
   - Event handling patterns

### Voiceline Team Collaboration

5. **[Integration Feedback](./collaboration/loqa-integration-feedback.md)**
   - Detailed integration report from Voiceline team
   - Issues encountered during v0.2.0 integration
   - Required configuration files (package.json, expo-module.config.json, .podspec)
   - Autolinking limitations and workarounds
   - Swift compilation errors and fixes
   - Documentation gaps identified
   - Recommendations for v0.3.0

6. **[Handoff Documentation](./collaboration/HANDOFF.md)**
   - Original handoff documentation for v0.2.0
   - Module capabilities and features
   - Performance benchmarks

7. **[All Collaboration Docs](./collaboration/)**
   - Design reviews, API specs, architecture decisions
   - Communication history with Voiceline team

---

## Module Capabilities

### Current Features (v0.2.0)

✅ **Real-Time Audio Streaming**
- Microphone capture with configurable sample rates (8kHz - 48kHz)
- Configurable buffer sizes (512-8192 samples)
- Mono and stereo support
- ~8 Hz event rate at 16kHz/2048 buffer configuration

✅ **Voice Activity Detection (VAD)**
- Native RMS calculation
- Automatic silence detection (threshold: RMS < 0.01)
- Frame skipping during silence for battery savings (30-50%)

✅ **Adaptive Processing**
- Battery level monitoring (iOS + Android)
- Automatic frame rate reduction when battery < 20%
- 20-30% additional power savings on low battery

✅ **Cross-Platform Support**
- iOS: AVAudioEngine integration with interruption handling
- Android: AudioRecord integration with runtime permissions
- Unified TypeScript API hiding platform differences

✅ **Developer Experience**
- Comprehensive TypeScript types
- React hooks for lifecycle management (`useAudioStreaming`)
- Detailed API documentation
- Buffer management utilities

### Known Gaps (v0.2.0 → v0.3.0)

Based on Voiceline integration feedback:

❌ **Missing Configuration Files**
- No `package.json` (module not recognized by npm)
- No `expo-module.config.json` (autolinking not working)
- No `.podspec` file (iOS CocoaPods integration manual)

❌ **Autolinking Not Functional**
- Module requires manual Podfile edits on iOS
- ExpoModulesProvider.swift requires manual registration
- 9-hour integration time (should be <2 hours)

❌ **Code Quality Issues**
- Swift compilation error: Missing `required` keyword on init override
- Deprecated API: `.allowBluetooth` instead of `.allowBluetoothA2DP`
- Test files included in production builds (XCTest import errors)

❌ **Documentation Gaps**
- No step-by-step Expo integration guide
- No troubleshooting for autolinking issues
- Missing migration guide from file-based to npm installation

### Planned for v0.3.0

**VoicelineDSP v0.3.0 - Production-Grade Foundation** project addresses these gaps:

🎯 **Scaffolding & Packaging**
- Use `create-expo-module` for proper Expo module structure
- Generate all required configuration files automatically
- Enable seamless autolinking (no manual steps)

🎯 **Code Quality**
- Fix Swift compilation errors
- Update deprecated APIs
- Exclude test files from production builds
- Zero compiler warnings

🎯 **Distribution**
- npm package publication (@loqalabs scope)
- Semantic versioning
- Automated release workflow

🎯 **Documentation**
- Comprehensive Expo Integration Guide
- Example app demonstrating all features
- Migration guide from v0.2.0 to v0.3.0
- Video walkthrough (optional)

🎯 **Testing & CI**
- Automated testing for both platforms
- CI pipeline for builds and tests
- Integration tests validate autolinking works

---

## Getting Started (Current v0.2.0)

### For Developers Working on VoicelineDSP

**Prerequisites:**
- Node.js 18+
- iOS: Xcode 14+, CocoaPods
- Android: Android Studio, JDK 17

**Development Setup:**
```bash
cd modules/voiceline-dsp
npm install

# iOS
cd ios && pod install

# Android
cd android && ./gradlew build
```

**Run Tests:**
```bash
# TypeScript
npm test

# iOS
xcodebuild test -workspace ios/VoicelineDSP.xcworkspace -scheme VoicelineDSP

# Android
cd android && ./gradlew test
```

### For Integration (Post v0.3.0)

Once v0.3.0 is released, integration will be:

```bash
# Install from npm
npm install @loqalabs/voiceline-dsp

# Or with Expo
npx expo install @loqalabs/voiceline-dsp

# Rebuild native code
npx expo prebuild
npx expo run:ios
npx expo run:android
```

**No manual Podfile edits required!**

---

## Workflow Status

### Current Planning Phase

VoicelineDSP v0.3.0 is currently in the **Planning Phase** of the BMad Method workflow:

**Workflow Tracking:** `docs/bmm-workflow-status.yaml`

**Completed:**
- ✅ workflow-init: Project initialized
- ✅ document-project: This documentation (brownfield analysis)

**Next Steps:**
1. **PRD** (Product Requirements Document)
   - Define v0.3.0 requirements based on integration feedback
   - Specify packaging, scaffolding, and documentation needs
   - Agent: PM (John)

2. **Architecture** (System Design)
   - Design npm packaging strategy
   - Plan create-expo-module migration
   - Design CI/CD pipeline
   - Agent: Architect (Winston)

3. **Sprint Planning** (Story Breakdown)
   - Break PRD into implementable stories
   - Organize into epics
   - Agent: Scrum Master (Bob)

4. **Implementation** (Development)
   - Execute stories
   - Build v0.3.0
   - Agent: Developer (Amelia)

---

## Technology Stack Summary

### JavaScript/TypeScript Layer

| Technology | Version | Purpose |
|-----------|---------|---------|
| TypeScript | 5.x | Type-safe API layer |
| React Native | 0.72+ | JavaScript runtime |
| Expo Modules Core | 1.x | Native module framework |

### iOS Native Layer

| Technology | Version | Purpose |
|-----------|---------|---------|
| Swift | 5.4+ | iOS implementation |
| AVFoundation | System | Audio capture (AVAudioEngine) |
| CocoaPods | - | Dependency management |

### Android Native Layer

| Technology | Version | Purpose |
|-----------|---------|---------|
| Kotlin | 1.8+ | Android implementation |
| android.media.AudioRecord | System | Audio capture |
| Gradle | 8.x | Build system |

---

## Performance Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| **Event Rate** | ~8 Hz | At 16kHz/2048 buffer |
| **Latency** | 32-512ms | Buffer size dependent |
| **CPU Usage** | 2-5% | Per core during streaming |
| **Memory Footprint** | 5-10 MB | Including buffer pool |
| **Battery Impact** | 3-8%/hour | With VAD enabled |
| **JS Bridge Overhead** | <1ms/event | Event marshaling |

---

## Key Files Reference

### Source Code

| File | Lines | Description |
|------|-------|-------------|
| `index.ts` | 413 | Main API, event subscriptions, configuration helpers |
| `src/types.ts` | 136 | TypeScript interfaces and enums |
| `src/buffer-utils.ts` | 255 | Buffer calculations, platform-specific logic |
| `ios/VoicelineDSPModule.swift` | ~500 | iOS AVAudioEngine integration |
| `android/.../VoicelineDSPModule.kt` | ~400 | Android AudioRecord integration |
| `hooks/useAudioStreaming.tsx` | ~150 | React hook for lifecycle management |

### Documentation

| File | Lines | Description |
|------|-------|-------------|
| `API.md` | 730 | Complete API reference with examples |
| `examples/README.md` | - | Usage examples and patterns |
| `docs/voiceline/loqa-integration-feedback.md` | 360 | Voiceline integration report |

---

## Contact and Support

### For VoicelineDSP v0.3.0 Planning

- **Product Manager**: John (pm agent)
- **Architect**: Winston (architect agent)
- **Scrum Master**: Bob (sm agent)
- **Developer**: Amelia (dev agent)

### For Voiceline Team

- **Integration Questions**: Refer to `docs/voiceline/loqa-integration-feedback.md`
- **API Questions**: Refer to `modules/voiceline-dsp/API.md`
- **Issues**: Open issue in Loqa monorepo

---

## Document Navigation

### Primary Documentation (Start Here)

1. **[Project Overview](./project-overview.md)** ← Start here for high-level understanding
2. **[Architecture](./architecture.md)** ← Dive deep into technical design

### Detailed References

3. **[API Reference](../../modules/voiceline-dsp/API.md)** ← Complete function and type reference
4. **[Integration Feedback](./collaboration/loqa-integration-feedback.md)** ← v0.2.0 integration lessons
5. **[Examples](../../modules/voiceline-dsp/examples/README.md)** ← Code examples

### Planning Documents

6. **[BMM Workflow Status](./bmm-workflow-status.yaml)** ← Track v0.3.0 progress
7. **[PRD]** ← To be created (next workflow)
8. **[Collaboration History](./collaboration/)** ← All Voiceline team communication

---

**Documentation Version**: 1.0
**Last Updated**: 2025-11-13
**Generated By**: BMad document-project workflow (deep scan)
**Scan Mode**: Deep (selective file reading in critical directories)
**Project Root**: `/Users/anna/code/loqalabs/loqa/modules/voiceline-dsp`
**Output Folder**: `/Users/anna/code/loqalabs/loqa/docs`
