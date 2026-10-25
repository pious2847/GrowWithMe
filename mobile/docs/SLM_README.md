# Nana SLM Documentation

This directory contains comprehensive documentation about the Nana Small Language Model (SLM) integration.

## What is the Nana SLM?

A **fine-tuned Llama 3.2 adapter** (10.85 MB) trained on 55,000 maternal health conversations to enable **offline conversational AI** in the GrowWithMe app.

## Current Status: ⚠️ **INFRASTRUCTURE READY, NOT INTEGRATED**

The model can be:
- ✅ Downloaded from HuggingFace
- ✅ Verified with SHA256 hash
- ✅ Extracted to device storage
- ✅ Shown in UI status

But **cannot yet:**
- ❌ Generate responses
- ❌ Run inference
- ❌ Be used in conversations

## Documentation Files

### 1. **SLM_INTEGRATION_STATUS.md** (Read First)
Comprehensive analysis of:
- What's already built
- What's missing
- Why it doesn't work yet
- Implementation effort estimate
- Key questions before proceeding

**→ Start here to understand the full picture**

---

### 2. **SLM_DECISION_MATRIX.md** (Read Second)
Helps you decide whether to proceed:
- Quick recommendation algorithm
- Detailed pros/cons comparison
- User scenario analysis
- Risk assessment
- Cost-benefit analysis
- Decision tree

**→ Use this to decide: Should I invest time in this?**

---

### 3. **SLM_IMPLEMENTATION_GUIDE.md** (Read Third)
Step-by-step technical guide:
- Add inference library
- Download base model
- Create LLM service wrapper
- Integrate with NanaAssistant
- Test and optimize
- Troubleshooting

**→ Follow this if you decide to implement**

---

## Quick Decision Guide

### ✅ Implement SLM if:
- [ ] 50%+ of users are offline frequently
- [ ] 80%+ of devices have 2GB+ RAM
- [ ] Offline conversational AI is a core value proposition
- [ ] You have 40+ hours for implementation
- [ ] App size can increase to 200MB

### ❌ Skip SLM if:
- [ ] Users mostly online
- [ ] Low-end devices (< 2GB RAM)
- [ ] Current intent-based system sufficient
- [ ] App size is critical
- [ ] Limited development time

### ⚠️ Consider Hybrid if:
- [ ] Mixed user base (online + offline)
- [ ] Want to test before committing
- [ ] Uncertain about value

**→ See SLM_DECISION_MATRIX.md for detailed analysis**

---

## Current AI Architecture

```
┌─────────────────────────────────────┐
│ TIER 1: Backend LLM (NVIDIA NIM)   │ ← Online only
│         Llama 3.1 70B               │   Full conversational AI
└─────────────────────────────────────┘
              ↓ if offline
┌─────────────────────────────────────┐
│ TIER 2: On-Device NLU (TFLite)     │ ← Offline, 17 intents
│         1 MB model                  │   Curated responses only
└─────────────────────────────────────┘
              ↓ if not downloaded
┌─────────────────────────────────────┐
│ TIER 3: Keyword Matching            │ ← Always works
│         Deterministic rules         │   Generic fallbacks
└─────────────────────────────────────┘
```

**SLM would become TIER 1.5** (between Backend LLM and NLU)

---

## What the SLM Provides

### Current Offline Capability (NLU)
```
User: "I want to add a child"
Nana: "Let us add your child together. I will open the form for you."
      [Opens add child screen]

User: "My child is not eating well lately and seems weak"
Nana: "I am Nana, my daughter. You can ask me to add a child, 
       track a pregnancy, tell you today's visits..."
      [Generic fallback - didn't understand nuance]
```

### With SLM Integration
```
User: "I want to add a child"
Nana: "Wonderful! Let me help you register your child. I'll open 
       the registration form for you now, and I'll be here if you 
       need any help filling it."
      [Opens add child screen]

User: "My child is not eating well lately and seems weak"
Nana: "I understand your concern, mama. Let us check this properly 
       right away. Not eating and weakness can be serious in children. 
       I will start a health check so we can see if your child needs 
       to go to the clinic."
      [Opens health check with pre-filled symptoms]
```

**Key Difference:** Natural, contextual responses vs templated phrases

---

## Technical Requirements

### If You Implement SLM

**Flutter Dependencies:**
```yaml
dependencies:
  llama_cpp_dart: ^0.1.0  # or flutter_llama
```

**Additional Files Needed:**
- Base model: `llama-3.2-1b-q4.gguf` (~700 MB)
- Adapter: Already downloaded via `nana-slm` (10.85 MB)

**Device Requirements:**
- RAM: 2GB minimum, 4GB recommended
- Storage: 200MB free space
- CPU: Quad-core minimum for reasonable speed

**Performance Expectations:**
- Cold start: 3-5 seconds (model loading)
- Response time: 2-5 seconds per message
- Battery impact: 5-10% additional drain for active users
- Memory footprint: 500MB-1GB while active

---

## Recommended Approach

### Phase 1: Evaluate (Now)
1. Read all three documentation files
2. Analyze your user base (connectivity, devices)
3. Review product roadmap priorities
4. Make go/no-go decision

### Phase 2: Optional Feature (If Yes)
1. Implement as opt-in "Offline AI (Beta)"
2. Add settings toggle
3. Download base model only if user enables
4. Track metrics for 3 months

### Phase 3: Decision Point
Based on metrics:
- **High adoption, good satisfaction** → Make default
- **Low adoption** → Keep optional or remove
- **High crashes** → Keep optional only

---

## Alternative: Keep Current System

The current 3-tier system is **proven, stable, and works well**:

✅ Full AI when online (best quality)
✅ Intent matching when offline (handles common cases)
✅ Keywords as ultimate fallback (always works)
✅ Small app size (~50MB)
✅ Low battery impact
✅ Works on any device

**Don't fix what isn't broken** unless offline AI is strategically important.

---

## Getting Help

### Questions About Integration?
1. Check SLM_IMPLEMENTATION_GUIDE.md
2. Review troubleshooting section
3. Test on actual device (not emulator)

### Questions About Decision?
1. Review SLM_DECISION_MATRIX.md
2. Run user interviews about offline needs
3. Check device analytics (RAM, connectivity patterns)

### Questions About Current Status?
1. See SLM_INTEGRATION_STATUS.md
2. Check backend/scripts/deploy_slm.js
3. Review mobile/lib/data/model/on_device_model.dart

---

## Quick Commands

### Check Model Status
```bash
# Backend: Verify model in database
mongosh "mongodb://localhost/growwithme"
> db.mlmodels.findOne({name: "nana-slm"})

# Mobile: Check if downloaded
# Settings → Offline AI Status → See "Nana SLM Adapter"
```

### Re-deploy Model
```bash
cd backend
node scripts/update_slm_hash.js \
  "d8996679c3b439ec9a446bb3b3dc0650017973882328ae51c769c8f891e6540f" \
  11379577
```

### Download Base Model (If Implementing)
```bash
cd backend/scripts
node prepare_base_model.js  # Creates llama-3.2-1b-q4.gguf
```

---

## Summary

**The infrastructure exists, but the integration is incomplete.**

You have a **business decision** to make, not a technical one:

- **Need offline conversational AI?** → Invest 40 hours to integrate
- **Current system sufficient?** → Skip it, focus elsewhere
- **Uncertain?** → Try optional feature first

All three approaches are valid depending on your product strategy.

---

**Last Updated:** 2026-08-26
**Model Version:** nana-slm v2
**SHA256:** d8996679c3b439ec9a446bb3b3dc0650017973882328ae51c769c8f891e6540f
