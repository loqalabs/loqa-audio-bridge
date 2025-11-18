# Voiceline-Loqa Architecture Collaboration Document

**Date:** November 7, 2025  
**From:** Voiceline BMAD Team  
**To:** Loqa BMAD Team  
**Subject:** Architecture Clarification & Privacy Messaging Alignment  
**Collaboration Method:** Documentation-Based (BMAD Workflow)

---

## 🎯 **Executive Summary**

We're seeking clarification on the Voiceline-Loqa integration architecture to ensure accurate privacy messaging and optimal user experience. Current documentation contains inconsistencies about where the Loqa backend runs and what this means for user privacy claims.

**Key Question**: Does Loqa run on the user's mobile device (localhost) or on a separate device like a laptop/desktop?

---

## 📋 **Current Documentation Issues**

### **Inconsistent Claims Found:**

1. **Privacy Messaging**: "Your voice data never leaves your device"
2. **Backend Location**: Described as both "localhost:3000" and "macOS/Linux server"
3. **Network Model**: Unclear if communication is truly localhost or local network

### **Impact on User Trust:**

For a trauma-informed voice training app, accurate privacy communication is **critical**. Users need to understand exactly where their sensitive voice data goes to make informed consent decisions.

---

## 🏗️ **Proposed Architecture (Please Validate)**

### **Our Current Understanding:**

```
📱 Mobile Device (iPhone/Android)
├── Real-time audio processing (< 100ms latency)
├── Basic visual feedback (voice flowers)
├── Session storage for offline use
└── Network connection to Loqa server

🖥️ Loqa Server (User's Laptop/Desktop)
├── Advanced ML voice analysis
├── Voice profile management
├── Session recording & analysis
└── Progress analytics

🌐 Communication
├── Local network (WiFi/Ethernet)
├── HTTP/JSON API calls
└── Graceful degradation when offline
```

### **Updated Privacy Model:**

✅ **Accurate Claims:**

- "Your voice is processed in real-time on your device"
- "Advanced analysis optionally sent to your personal Loqa server"
- "No voice data sent to external companies or cloud services"
- "You control when and if to connect to your Loqa server"

❌ **Claims to Remove:**

- ~~"Your voice data never leaves your device"~~ (inaccurate if sent to Loqa)
- ~~"All processing happens entirely on your device"~~ (if Loqa provides advanced analysis)

---

## ❓ **Critical Questions for Loqa Team**

### **🔧 Technical Feasibility**

**1. Hardware Requirements:**

- What are Loqa's minimum system requirements (CPU, RAM, GPU)?
- Can it realistically run on average consumer laptops?
- What's the performance impact/battery drain during analysis?

**2. Mobile Deployment Possibility:**

- Could Loqa voice analysis run on high-end mobile devices (iPad Pro, Android flagship)?
- Are there lightweight model variants for mobile deployment?
- What would be the accuracy/speed trade-offs on mobile vs desktop?

**3. Analysis Performance:**

- Typical processing time for 5-second audio clip?
- Processing time for 30-minute practice session?
- Can it run in background without significantly impacting system performance?

### **📡 Network & Integration**

**4. Discovery & Connection:**

- How should mobile app discover Loqa servers? (mDNS/Bonjour/manual IP?)
- Preferred communication protocol? (REST API, WebSocket, gRPC?)
- Should we support multiple Loqa instances on same network?

**5. API Specifications:**

- Are the Epic 2C endpoints still accurate? (`/voice/analyze`, `/voice/session`, etc.)
- Expected request/response formats for voice analysis?
- Rate limiting or concurrent connection restrictions?

**6. Error Handling:**

- What happens when Loqa server is unavailable?
- Expected error codes and graceful degradation strategies?
- How should mobile app detect Loqa server status?

### **🛡️ Privacy & Security**

**7. Data Storage & Retention:**

- How does Loqa store voice analysis data? (files, database, memory only?)
- What's the data retention policy? (persistent vs temporary?)
- Can users control data deletion and retention settings?

**8. Privacy Validation:**

- Can you confirm no voice data is sent to external services?
- Any telemetry, analytics, or cloud dependencies?
- How should we communicate Loqa's privacy guarantees to users?

**9. Network Security:**

- Do we need TLS for local network communication?
- Authentication mechanism between mobile app and Loqa?
- Considerations for firewalls or network security?

### **🚀 Deployment & User Experience**

**10. Installation Process:**

- What's the simplest way for users to install and run Loqa?
- Can we create bundled installers (mobile app + Loqa backend)?
- What technical expertise should we assume from users?

**11. Future Extensibility:**

- For advanced features (stress detection, emotion analysis), where would processing happen?
- Which features require Loqa vs can work on-device?
- Any plans for cloud-hosted Loqa instances (with user consent)?

**12. Session Management:**

- Can Loqa handle multiple mobile app connections simultaneously?
- Should each mobile app have unique identifiers?
- How to handle concurrent analysis requests?

---

## 🎨 **Trauma-Informed Design Requirements**

### **Core Principles:**

1. **User Agency**: Users must feel in control of their voice data
2. **Transparent Communication**: No hidden data sharing or processing
3. **No Pressure**: App works excellently without Loqa connection
4. **Trust Building**: Setup process feels safe and empowering

### **UX Implications:**

- Loqa connection should feel like an **enhancement**, not a requirement
- Privacy explanations must be accurate and understandable
- Users need clear controls over when/if voice data is shared
- Technical setup should not feel intimidating

---

## 📅 **Timeline & Urgency**

### **Immediate (This Week):**

- **Story 1.2**: Finalizing permission request language with accurate privacy claims
- **Architecture Documentation**: Updating all docs to reflect correct deployment model

### **Short Term (Next 2-3 Weeks):**

- **Story 1.3**: Implementing audio input stream (foundation for Loqa integration)
- **Epic 5 Planning**: Defining exact API integration requirements

### **Medium Term (Next Month):**

- **Epic 5 Implementation**: Full Loqa integration
- **User Testing**: Validating setup flow and privacy communication

---

## 🤝 **Documentation-Based Collaboration Proposal**

### **Immediate Documentation Updates Needed:**

1. **Architecture Specification Document**: Clear deployment model (mobile vs desktop Loqa)
2. **API Integration Specification**: Updated Epic 2C endpoints with request/response examples
3. **Privacy & Security Documentation**: Joint privacy model documentation for user communication

### **Suggested Documentation Workflow:**

- **Response Document**: Loqa team creates response document addressing the 12 critical questions
- **Architecture Alignment**: Both teams update respective architecture docs to match agreed model
- **API Contract**: Collaborative API specification document for Epic 5 integration
- **Cross-References**: Ensure consistent messaging across both project documentation sets

---

## 🎯 **Success Criteria**

### **Technical Success:**

- Clear, accurate architecture documentation
- Robust mobile-Loqa communication protocol
- Graceful degradation when Loqa unavailable

### **User Experience Success:**

- Users understand exactly where their voice data goes
- Loqa setup feels empowering, not intimidating
- Enhanced features feel valuable without basic features feeling insufficient

### **Privacy Success:**

- All privacy claims are technically accurate
- Users have granular control over data sharing
- No surprises or hidden data transmission

---

## 📬 **Response Format & Next Steps**

Since both teams work through BMAD documentation workflows, we propose the following documentation-based collaboration:

### **Requested Response Document:**

Please create a response document addressing the 12 critical questions above. This will help both teams align on the technical architecture and integration approach.

**Suggested Response Structure:**

- **Technical Feasibility Answers** (Questions 1-3)
- **Network & Integration Specifications** (Questions 4-6)
- **Privacy & Security Model** (Questions 7-9)
- **Deployment & UX Guidelines** (Questions 10-12)

### **Documentation Cross-References:**

Once we have your responses, both teams can update their respective documentation to ensure consistent architecture and privacy messaging.

**Preferred Timeline:** Response documentation by end of this week to finalize Story 1.2 privacy messaging and begin Epic 5 planning.

**Documentation Repository References:**

- **Voiceline Documentation**: [github.com/annabarnes1138/voiceline/docs](https://github.com/annabarnes1138/voiceline/docs)
- **Loqa Documentation**: [Please provide your docs location for cross-referencing]

Thank you for the documentation-based collaboration! This approach should work well for both BMAD teams. 🚀

---

**Appendix: Current Architecture References**

- [Voiceline Scale Adaptive Architecture](./voiceline-scale-adaptive-architecture.md)
- [Product Requirements Document](./PRD.md)
- [Epic 5: Loqa Backend Integration](./epics.md#epic-5-loqa-backend-integration)
- [Story 1.2: Audio Permissions Implementation](./stories/1-2-implement-audio-permissions-and-microphone-access.md)
