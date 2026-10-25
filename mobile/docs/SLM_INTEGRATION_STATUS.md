# Nana SLM Integration Status & Implementation Guide

## Current Status: ⚠️ **INFRASTRUCTURE READY, BUT NOT INTEGRATED**

The Nana SLM (Small Language Model) infrastructure is in place, but the model **cannot actually be used yet**. Here's what exists and what's missing:

---

## ✅ What's Already Built

### 1. **Model Distribution System**
- ✅ Model registered in database (`nana-slm` v2)
- ✅ Hosted on HuggingFace (10.85 MB)
- ✅ Correct SHA256 hash verified: `d8996679c3b439ec9a446bb3b3dc0650017973882328ae51c769c8f891e6540f`
- ✅ Download & verification system in `OnDeviceModel` class
- ✅ Unzips to `models/nana-slm/` folder structure
- ✅ Status UI in "Offline AI Status" dialog

### 2. **Model Details**
- **Base Model**: Llama 3.2
- **Training**: Fine-tuned LoRA adapter on 55k synthetic maternal health conversations
- **Size**: 10.85 MB (compressed)
- **Format**: Adapter weights + tokenizer (requires base model)
- **Purpose**: Natural conversation generation for offline maternal health support

### 3. **Current AI Architecture**

The app has **3-tier fallback** for intelligence:

```
┌─────────────────────────────────────────────────────┐
│ TIER 1: Backend LLM (NVIDIA NIM API - Llama 3.1)   │ ← ONLINE ONLY
│ - Full conversational AI                            │
│ - Context-aware responses                           │
│ - Action generation                                 │
└─────────────────────────────────────────────────────┘
                    ↓ (if offline)
┌─────────────────────────────────────────────────────┐
│ TIER 2: On-Device NLU (TFLite, 1 MB)               │ ← WORKS OFFLINE
│ - Intent classification only                        │
│ - Curated (hardcoded) responses                     │
│ - 17 intents recognized                             │
└─────────────────────────────────────────────────────┘
                    ↓ (if NLU not downloaded)
┌─────────────────────────────────────────────────────┐
│ TIER 3: Keyword Matching (deterministic)            │ ← ALWAYS WORKS
│ - Simple string matching                            │
│ - Generic fallback responses                        │
└─────────────────────────────────────────────────────┘
```

**The Nana SLM is intended to be TIER 1.5** - between backend LLM and on-device NLU:
- More capable than NLU (can generate natural responses)
- Less capable than backend LLM (smaller model)
- Works offline like NLU
- Uses more resources than NLU

---

## ❌ What's Missing (Why It Doesn't Work Yet)

### 1. **No LLM Inference Library**

Flutter doesn't have built-in support for running LLMs. You need to add one:

**Option A: llama.cpp via FFI** (Recommended)
- Native performance
- Supports LoRA adapters
- ~50-100 MB additional size for base model
- Packages: `llama_cpp_dart` or `flutter_llama`

**Option B: MediaPipe LLM** (Google's solution)
- Official Google support
- Simpler integration
- Requires converting model to MediaPipe format
- Package: `mediapipe_llm`

**Option C: ONNX Runtime**
- Cross-platform
- Requires model conversion to ONNX
- Package: `onnxruntime`

### 2. **No Model Loading Code**

The `OnDeviceModel` class downloads and extracts the ZIP, but doesn't load it into memory:

```dart
// Current code (on_device_model.dart):
if (isLlm) {
  final folder = Directory('${file.parent.path}/$targetName');
  if (!await folder.exists()) return;
  _manifest = manifest;  // ❌ Only saves metadata, doesn't load model
}
```

**What's needed:**
```dart
// Initialize inference engine
late LlamaCpp _llamaEngine;

// Load base model + adapter
_llamaEngine = await LlamaCpp.load(
  baseModelPath: await _downloadBaseModel(), // Llama 3.2 base
  adapterPath: '$folderPath/adapter_model.safetensors',
  tokenizerPath: '$folderPath/tokenizer.json',
);
```

### 3. **No Base Model**

The 10.85 MB ZIP contains only the **LoRA adapter** (fine-tuned weights), not the full Llama model.

You need:
- Base Llama 3.2 model (~50-100 MB quantized)
- Options:
  - Bundle with app (increases APK size)
  - Download separately from HuggingFace
  - Use Llama 3.2 1B or 3B quantized

### 4. **No Inference Integration**

Even if the model loads, `NanaAssistant` doesn't call it:

```dart
// Current code (nana_assistant.dart):
Future<NanaReply> localIntent(String text) async {
  // Uses NLU or keywords, never touches SLM
  final understood = _nlu?.classify(text);
  // ...
}
```

**What's needed:**
```dart
Future<NanaReply> localIntent(String text) async {
  // Try SLM first if loaded
  if (_slm?.ready == true) {
    try {
      final response = await _slm!.generate(
        prompt: _buildPrompt(text),
        maxTokens: 150,
      );
      return NanaReply(response, source: 'slm-offline');
    } catch (e) {
      // Fall back to NLU
    }
  }
  
  // Existing NLU/keyword fallback
  final understood = _nlu?.classify(text);
  // ...
}
```

### 5. **No Prompt Engineering**

LLMs need carefully crafted prompts. The backend uses structured prompts (see `nanaService.js`), but there's no offline equivalent.

**Example needed:**
```dart
String _buildPrompt(String userMessage) {
  return '''<|system|>
You are Nana, a maternal health assistant in Northern Ghana. Answer in simple English.
Rules:
- Never diagnose or prescribe
- Direct danger signs to health facility
- Be warm and encouraging
- Reference GHS guidelines

Context:
${_buildContext()}

<|user|>
$userMessage

<|assistant|>
''';
}
```

---

## 📊 Implementation Effort Estimate

| Task | Difficulty | Time Estimate |
|------|-----------|---------------|
| 1. Add LLM inference library | Medium | 2-4 hours |
| 2. Implement model loading | Medium | 3-5 hours |
| 3. Download/bundle base model | Easy | 1-2 hours |
| 4. Integrate with NanaAssistant | Medium | 4-6 hours |
| 5. Create prompt templates | Easy | 2-3 hours |
| 6. Test & optimize inference | Hard | 8-12 hours |
| 7. Handle memory/battery impact | Hard | 4-8 hours |
| **TOTAL** | **Medium-Hard** | **24-40 hours** |

---

## 🎯 Recommended Next Steps

### Option 1: **Complete SLM Integration** (If you want truly offline AI)

1. **Choose inference library**: `llama_cpp_dart` recommended
2. **Get base model**: Download quantized Llama 3.2 1B (Q4_K_M ~700MB or Q2_K ~400MB)
3. **Implement loading in OnDeviceModel**
4. **Add inference method** with streaming support
5. **Create prompt templates** based on backend's proven prompts
6. **Integrate into NanaAssistant** as fallback between backend and NLU
7. **Test on low-end devices** (memory, battery, latency)

### Option 2: **Use Current System** (Simpler, proven)

The current 3-tier system works well:
- ✅ Backend LLM for rich online conversations
- ✅ On-device NLU for common offline requests  
- ✅ Keywords for ultimate fallback

**Pros:**
- Already working
- Less battery/memory impact
- Faster response times
- Smaller app size

**Cons:**
- Limited offline conversational ability
- Fixed responses for NLU intents

### Option 3: **Hybrid Approach** (Recommended)

Keep current system but add **cloud-based caching**:
- Backend generates responses online
- Cache frequent conversations locally
- Replay cached responses when offline
- Much simpler than full LLM integration
- Better UX than generated responses on slow devices

---

## 🔍 Key Questions Before Proceeding

1. **Device constraints**: What's your target device specs?
   - Low-end: < 2GB RAM → SLM may be too heavy
   - Mid-range: 2-4GB RAM → Possible with optimization
   - High-end: > 4GB RAM → Should work fine

2. **Offline priority**: How critical is offline conversational AI?
   - Critical (rural, no connectivity) → Worth the effort
   - Nice to have → Current system may suffice

3. **Battery concerns**: LLM inference drains battery
   - Each response: ~2-5 seconds CPU time
   - Can add 5-10% battery drain for active users

4. **App size**: Base model adds 50-100 MB
   - Acceptable? → Proceed
   - Too large? → Consider server-side only

---

## 📝 Current Code References

- **Model download**: `mobile/lib/data/model/on_device_model.dart`
- **AI orchestration**: `mobile/lib/data/assistant/nana_assistant.dart`
- **Backend LLM**: `backend/src/services/nanaService.js`
- **Model registration**: `backend/scripts/deploy_slm.js`
- **Chat UI**: `mobile/lib/features/nana/nana_chat_screen.dart`

---

## 💡 Conclusion

The Nana SLM infrastructure is **80% complete** but the crucial **20% (actual inference)** is missing. The model can be downloaded and verified, but cannot generate responses yet.

**Decision needed**: Is full offline LLM worth the complexity, or is the current online/NLU/keyword system sufficient for your use case?
