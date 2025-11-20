# Audio Streaming Architecture Decision - Summary

**Date:** November 11, 2025
**Updated:** November 11, 2025 (Resource Allocation Clarification)
**Decision Status:** ✅ **APPROVED**
**Teams:** Loqa ↔ Voiceline

---

## 🎯 Executive Decision

### Adopt Option 1 (Native VoicelineDSP Streaming) with Sequential Development

**Decision:** Extend VoicelineDSP native module with audio streaming capabilities. Do NOT use third-party streaming library (expo-audio-studio).

**Rationale:**

- Single cohesive native module for capture + analysis
- Optimal performance and battery efficiency
- No temporary dependencies to remove later
- Clean architecture from the start

### Resource Allocation

Since both teams share the same developer (Anna), development will be **sequential**:

1. **Priority 1:** Complete Loqa Epic 2C (voice intelligence backend) - 2-3 weeks
2. **Priority 2:** Implement VoicelineDSP audio streaming - 3-4 weeks (after Epic 2C)

**Impact:** Voiceline Story 2.3 remains blocked until VoicelineDSP audio streaming is complete (~5-7 weeks total)

---

## ⚡ Immediate Action Items

### For Voiceline Team

**Status:** 🛑 **BLOCKED** - Waiting for VoicelineDSP audio streaming implementation

**Next Actions:**

1. **Wait for Loqa Epic 2C completion** (2-3 weeks)
2. **Wait for VoicelineDSP audio streaming** (3-4 weeks after Epic 2C)
3. **Then integrate native audio streaming** with PracticeScreen

**Story 2.3 Unblock Date:** Estimated 5-7 weeks from now (after both Loqa phases complete)

### For Loqa Team (Current Priority)

**Status:** 🚀 **ACTIVE** - Epic 2C in progress

1. ✅ Review architectural response document
2. 🔄 **Complete Epic 2C stories 2C.2 through 2C.8** (2-3 weeks)
   - Story 2C.2: Create loqa-voice-intelligence crate
   - Story 2C.3: Implement voice analysis API
   - Story 2C.4: Build voice profile API
   - Story 2C.5: Implement training session recording
   - Story 2C.6: Add progress analytics API
   - Story 2C.7: Add breakthrough moment tagging
   - Story 2C.8: API documentation and testing
3. ⏳ Plan VoicelineDSP v0.2.0 audio streaming (after Epic 2C complete)

---

## 📅 Timeline

| Phase                     | Timeframe                  | Deliverable                           | Status     |
| ------------------------- | -------------------------- | ------------------------------------- | ---------- |
| **Loqa Epic 2C**          | Week 1-3 (Nov 11 - Dec 6)  | Voice intelligence backend complete   | 🚀 Active  |
| **VoicelineDSP Planning** | Week 4 (Dec 9-13)          | Audio streaming design spec           | ⏳ Pending |
| **VoicelineDSP iOS**      | Week 5-6 (Dec 16-27)       | iOS native streaming                  | ⏳ Pending |
| **VoicelineDSP Android**  | Week 7-8 (Dec 30 - Jan 10) | Android native streaming              | ⏳ Pending |
| **Integration & Testing** | Week 9-10 (Jan 13-24)      | Cross-platform validation             | ⏳ Pending |
| **Voiceline Story 2.3**   | Week 10+ (Jan 27+)         | Voice-to-flower visualization working | 🛑 Blocked |

---

## 🔧 Technical Configuration

### Audio Stream Configuration

```typescript
const streamConfig = {
  sampleRate: 16000, // Hz (optimized for voice)
  bufferSize: 2048, // samples (128ms at 16kHz)
  channels: 1, // mono
  encoding: 'pcm_float', // Float32 (-1.0 to 1.0)
};
```

### Performance Targets

- **End-to-end latency:** <100ms (mic → visual update)
- **Battery impact:** <5% per 30-minute session
- **Frame rate:** 60fps for Skia rendering
- **Audio processing rate:** 30-60Hz adaptive

---

## 📋 Key Architectural Decisions

### 1. Real-Time Audio Streaming is Within VoicelineDSP Scope ✅

- Tight coupling of capture + analysis for optimal performance
- Unified API reduces integration complexity
- Battery efficiency through native optimizations

### 2. Use Expo EventEmitter Pattern for Streaming Events

```typescript
const subscription = VoicelineDSP.addAudioSampleListener((event) => {
  AudioStreamService.processAudioSamples(new Float32Array(event.samples));
});
```

### 3. Recommended Buffer Management

- **Buffer size:** 2048 samples (128ms at 16kHz)
- **Rationale:** Optimal for YIN pitch detection (requires 100-200ms windows)
- **Trade-off:** Balance between latency and analysis accuracy

### 4. Native Performance Optimizations

- Voice Activity Detection (VAD) to skip silent frames
- Adaptive processing rate during low battery
- Pre-compute RMS amplitude at native layer

---

## 🎯 Success Criteria

### Loqa Epic 2C Success

- ✅ All 6 voice intelligence API endpoints implemented and tested
- ✅ Voice profile storage working (file-based, atomic writes)
- ✅ Session recording and analysis functional
- ✅ Progress analytics calculating correctly
- ✅ API documentation complete

### VoicelineDSP Native Streaming Success

- ✅ iOS AVAudioEngine implementation complete
- ✅ Android AudioRecord implementation complete
- ✅ Event system working (audio samples streaming to JS)
- ✅ Latency <100ms end-to-end
- ✅ Battery impact <5% per 30-minute session
- ✅ Cross-platform parity (iOS + Android consistent behavior)

---

## 📞 Questions or Blockers?

**Voiceline Team:**

- Anna (Product/Technical Lead)
- Status: Blocked on Loqa development

**Loqa Team:**

- Winston (Architect) - Available for design review
- Anna (Lead) - Actively working on Epic 2C

**Communication Channels:**

- Technical questions → GitHub issues or collaboration docs
- Design review → Joint architecture meeting (after Epic 2C)
- Timeline updates → Async via docs

---

## 📚 Full Documentation

For detailed implementation guidance, API specifications, and code examples:

👉 **[Complete Architecture Response](./loqa-audio-streaming-architecture-response.md)**

---

**Next Step:** Anna completes Loqa Epic 2C (Stories 2C.2 through 2C.8) 🚀
