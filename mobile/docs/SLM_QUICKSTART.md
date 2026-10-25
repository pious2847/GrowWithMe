# Nana SLM Quick Start Guide
## Get Your Fine-Tuned Model Running on Mobile in 1 Day

**Your Model:** `abdulhafis/growwithme-nana-slm` (PEFT/LoRA on Llama 3.2 1B)  
**Goal:** Enable offline conversational AI in the GrowWithMe Flutter app

---

## Prerequisites

- ✅ Your model trained and on HuggingFace
- ✅ Python 3.8+ installed
- ✅ 8GB+ RAM on your computer
- ✅ 10GB free disk space
- ✅ Flutter dev environment set up

**Time Required:** 4-6 hours

---

## Part 1: Convert Model (1-2 hours)

### Step 1: Set Up Environment

```bash
# Navigate to backend scripts
cd backend/scripts

# Create Python environment
python -m venv llm-env

# Activate it
# Linux/Mac:
source llm-env/bin/activate
# Windows:
llm-env\Scripts\activate

# Install dependencies
pip install transformers peft torch huggingface_hub
```

### Step 2: Clone llama.cpp

```bash
# In backend/scripts directory
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

# Build it
# Linux/Mac:
make
# Windows (requires CMake):
cmake .
cmake --build . --config Release

cd ..
```

### Step 3: Run Conversion Script

```bash
# Make sure you're in backend/scripts with llm-env activated
python merge_and_convert_slm.py

# This will:
# 1. Download base Llama 3.2 1B (~1.3GB)
# 2. Download your LoRA adapter (~10MB)
# 3. Merge them
# 4. Convert to GGUF Q4_K_M (~400MB)
# 5. Test the model
# 6. Show SHA256 hash

# Wait 30-60 minutes...
```

**Expected Output:**
```
======================================================================
CONVERSION COMPLETE!
======================================================================

📄 Output file: ./nana-slm-q4-k-m.gguf
📊 File size: 387.42 MB
🔐 SHA256: a1b2c3d4e5f6...
```

**Copy that SHA256!** You'll need it soon.

---

## Part 2: Upload Model (30 minutes)

### Option A: HuggingFace (Recommended)

```bash
# Install HF CLI if needed
pip install huggingface-cli

# Login
huggingface-cli login

# Create repo (or use existing)
huggingface-cli repo create growwithme-nana-slm-gguf --type model

# Upload GGUF file
huggingface-cli upload \
  abdulhafis/growwithme-nana-slm-gguf \
  nana-slm-q4-k-m.gguf \
  --repo-type model

# Wait for upload...
```

**Your model URL will be:**
```
https://huggingface.co/abdulhafis/growwithme-nana-slm-gguf/resolve/main/nana-slm-q4-k-m.gguf
```

### Option B: Your Server

```bash
# Upload to your server
scp nana-slm-q4-k-m.gguf user@yourserver:/var/www/models/

# Make sure it's publicly accessible
curl -I https://yourserver.com/models/nana-slm-q4-k-m.gguf
```

---

## Part 3: Update Backend (15 minutes)

### Update Model Registry

**Edit `backend/scripts/deploy_slm.js`:**

Find the `MANIFEST` object and update:

```javascript
const MANIFEST = {
  name: 'nana-slm',
  version: 3,  // Increment from current
  kind: 'llm',
  
  // UPDATE THIS: Your GGUF file URL
  url: 'https://huggingface.co/abdulhafis/growwithme-nana-slm-gguf/resolve/main/nana-slm-q4-k-m.gguf',
  
  // UPDATE THIS: SHA256 from conversion script
  sha256: 'PASTE_SHA256_FROM_STEP_3_HERE',
  
  // UPDATE THIS: File size from conversion script  
  sizeBytes: 406134784,  // Replace with actual bytes
  
  active: true,
  
  meta: {
    trainedOn: 'Llama 3.2 1B + 55k maternal health conversations',
    disclaimer: 'On-device LLM for offline conversations',
    source: 'HuggingFace GGUF',
    format: 'GGUF Q4_K_M',
  },
};
```

### Deploy to Database

```bash
cd backend
node scripts/deploy_slm.js
```

**Expected Output:**
```
Published nana-slm v3 to Local MongoDB
Active: true
URL: https://huggingface.co/...
```

---

## Part 4: Integrate in Flutter (2-3 hours)

### Step 1: Add fllama Package

**Edit `mobile/pubspec.yaml`:**

```yaml
dependencies:
  # ... existing dependencies ...
  
  fllama: ^0.2.0  # Add this line
```

```bash
cd mobile
flutter pub get
```

### Step 2: Copy Integration Files

I've prepared all the code. Just copy these files:

**Create these new files:**

1. **`mobile/lib/data/model/llama_service.dart`**
   - Wraps llama.cpp inference
   - See SLM_COMPLETE_INTEGRATION_PLAN.md section 3.2

2. **`mobile/lib/data/assistant/nana_prompts.dart`**
   - Prompt templates for Llama 3.2
   - See SLM_COMPLETE_INTEGRATION_PLAN.md section 3.4

**Modify these existing files:**

3. **`mobile/lib/data/model/on_device_model.dart`**
   - Add GGUF loading support
   - See SLM_COMPLETE_INTEGRATION_PLAN.md section 3.3

4. **`mobile/lib/data/assistant/nana_assistant.dart`**
   - Integrate SLM into conversation flow
   - See SLM_COMPLETE_INTEGRATION_PLAN.md section 3.5

5. **`mobile/lib/core/providers.dart`**
   - Pass SLM to NanaAssistant
   - See SLM_COMPLETE_INTEGRATION_PLAN.md section 3.6

**All code is ready in `SLM_COMPLETE_INTEGRATION_PLAN.md`** - just copy/paste!

### Step 3: Build and Test

```bash
# Clean build
flutter clean
flutter pub get

# Build debug APK
flutter build apk --debug

# Or run on device
flutter run
```

---

## Part 5: Test It! (30 minutes)

### Test 1: Check Model Download

1. Open app
2. Go to Nana chat
3. Tap status icon (top right)
4. See "Nana SLM Adapter" status
5. Tap "Check now"
6. **Wait 3-5 minutes** for download (~400 MB)
7. Should show "Loaded" with version 3

### Test 2: Try Offline Mode

1. Enable airplane mode
2. Go to Nana chat
3. Send: "Hello Nana, how are you?"
4. **Wait 3-8 seconds** (first load is slow)
5. Should get natural response!
6. Check response says `(slm-offline)` in code

### Test 3: Conversation Flow

```
You: "What foods should I eat while pregnant?"
Nana: [Natural response about nutrition]

You: "What about vegetables?"
Nana: [Continues conversation naturally]

You: "My baby has fever"
Nana: "Let us check this properly right now."
[Opens health check]
```

**If working:** ✅ Integration complete!

---

## Troubleshooting

### "Model failed to download"
```bash
# Check URL is accessible
curl -I https://huggingface.co/abdulhafis/growwithme-nana-slm-gguf/resolve/main/nana-slm-q4-k-m.gguf

# Check database
mongosh "mongodb://localhost/growwithme"
> db.mlmodels.findOne({name: "nana-slm"})
```

### "Checksum mismatch"
```bash
# Recalculate SHA256
sha256sum nana-slm-q4-k-m.gguf

# Update database
node scripts/deploy_slm.js
```

### "Model won't load in app"
- Check device has 2GB+ free RAM
- Check storage has 500MB+ free
- Try restarting app
- Check logs: `flutter logs`

### "Responses are gibberish"
- Check prompt format in `nana_prompts.dart`
- Verify you're using Llama 3.2 chat template
- Try adjusting temperature (0.6-0.8)

### "Too slow"
- Use Q2_K quantization (200MB, faster)
- Reduce `maxTokens` to 80
- Increase `nThreads` to 6

---

## Performance Tuning

### If model is too large (>400MB):

```bash
# Convert with Q2_K instead
python merge_and_convert_slm.py --quantization Q2_K

# Output will be ~200MB
# Upload and update deploy_slm.js
```

### If responses are too slow:

**Edit `llama_service.dart`:**

```dart
_model = await Llama.load(
  model: modelPath,
  nContext: 1024,  // Reduce from 2048
  nBatch: 256,     // Reduce from 512
  nThreads: 6,     // Increase from 4
);
```

### If running out of memory:

```dart
// Add memory monitoring
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    slm.llamaService?.dispose();  // Free memory
  }
}
```

---

## Success Checklist

- [ ] Conversion script completed successfully
- [ ] GGUF file uploaded to HuggingFace
- [ ] Backend database updated with correct SHA256
- [ ] fllama package added to pubspec.yaml
- [ ] All 5 Flutter files created/modified
- [ ] App builds without errors
- [ ] Model downloads in app
- [ ] Model shows as "Loaded" in status
- [ ] Offline responses work
- [ ] Response quality is acceptable
- [ ] Performance is acceptable (< 10s per response)

---

## What's Next?

### Monitor Usage

Add analytics to track:
- How often SLM is used vs backend
- Average response time
- User satisfaction ratings
- Crash rates

### Optimize

- Benchmark on different devices
- Fine-tune temperature/sampling
- Cache common responses
- Reduce token count

### Iterate

- Collect user feedback
- Retrain with better data
- Try different quantizations
- A/B test vs current system

---

## Need Help?

1. **Conversion issues:** Check `backend/scripts/merge_and_convert_slm.py` error messages
2. **Flutter integration:** See full code in `SLM_COMPLETE_INTEGRATION_PLAN.md`
3. **Performance:** See optimization section above
4. **Other:** Open an issue with logs

---

## Summary

**You will:**
1. Convert your PEFT model to GGUF (1-2 hours)
2. Upload to HuggingFace (30 min)
3. Update backend registry (15 min)
4. Integrate in Flutter (2-3 hours)
5. Test on device (30 min)

**Total: 4-6 hours**

**Result:** Fully offline conversational AI in your maternal health app! 🎉

---

**Ready?** Start with Part 1! The conversion script is in:
```
backend/scripts/merge_and_convert_slm.py
```

Good luck! 🚀
