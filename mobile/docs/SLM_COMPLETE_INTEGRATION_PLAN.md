# Complete Nana SLM Integration Plan
## From PEFT/LoRA to Working On-Device Inference

Based on your HuggingFace model: `abdulhafis/growwithme-nana-slm`

---

## Understanding Your Model

Your model is a **PEFT (LoRA) adapter** trained on Llama 3.2 1B Instruct:

```
Base Model: meta-llama/Llama-3.2-1B-Instruct (~1.3 GB full precision)
+ Your Adapter: abdulhafis/growwithme-nana-slm (~10-22 MB)
= Fine-tuned Model for Maternal Health
```

**Key Challenge:** Mobile devices cannot run Python/PyTorch/Transformers directly.  
**Solution:** Convert to GGUF format and use llama.cpp

---

## The Complete Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Convert Model (On Your Computer)                   │
├─────────────────────────────────────────────────────────────┤
│ HuggingFace PEFT → Merged PyTorch → GGUF (llama.cpp)      │
│ ~1.3 GB full → ~400-700 MB quantized                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Upload to HuggingFace/Cloudinary                   │
├─────────────────────────────────────────────────────────────┤
│ Host the GGUF file for mobile app to download              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Integrate fllama in Flutter                        │
├─────────────────────────────────────────────────────────────┤
│ Download GGUF → Load with llama.cpp → Generate responses   │
└─────────────────────────────────────────────────────────────┘
```

---

## STEP 1: Convert Your Model to GGUF

### 1.1 Install Requirements

```bash
# Create Python environment
python -m venv llm-env
source llm-env/bin/activate  # Windows: llm-env\Scripts\activate

# Install dependencies
pip install transformers peft torch huggingface_hub
pip install llama-cpp-python

# Clone llama.cpp for conversion scripts
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
```

### 1.2 Merge LoRA Adapter with Base Model

Create `merge_lora.py`:

```python
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel
import torch

# Load base model
print("Loading base Llama 3.2 1B...")
base_model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-3.2-1B-Instruct",
    torch_dtype=torch.float16,
    device_map="cpu",  # Keep on CPU to save VRAM
)

# Load your LoRA adapter
print("Loading your LoRA adapter...")
model = PeftModel.from_pretrained(
    base_model,
    "abdulhafis/growwithme-nana-slm"
)

# Merge adapter into base model
print("Merging adapter with base model...")
merged_model = model.merge_and_unload()

# Save merged model
output_dir = "./nana-slm-merged"
print(f"Saving merged model to {output_dir}...")
merged_model.save_pretrained(output_dir)

# Save tokenizer
tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-3.2-1B-Instruct")
tokenizer.save_pretrained(output_dir)

print("✓ Merge complete! Merged model saved to:", output_dir)
```

Run it:
```bash
python merge_lora.py
```

This creates a **standalone PyTorch model** (~1.3 GB) in `./nana-slm-merged/`

### 1.3 Convert to GGUF Format

```bash
cd llama.cpp

# Convert to FP16 GGUF (intermediate format)
python convert_hf_to_gguf.py ../nana-slm-merged/ \
  --outfile ../nana-slm-f16.gguf \
  --outtype f16

# Quantize to smaller size (choose ONE)

# Option A: Q4_K_M (recommended) - ~400 MB, good quality
./llama-quantize ../nana-slm-f16.gguf ../nana-slm-q4-k-m.gguf Q4_K_M

# Option B: Q5_K_M - ~500 MB, better quality
./llama-quantize ../nana-slm-f16.gguf ../nana-slm-q5-k-m.gguf Q5_K_M

# Option C: Q2_K - ~200 MB, acceptable quality for mobile
./llama-quantize ../nana-slm-f16.gguf ../nana-slm-q2-k.gguf Q2_K
```

**Output:** `nana-slm-q4-k-m.gguf` (~400 MB) - ready for mobile!

### 1.4 Test Locally (Optional but Recommended)

```bash
# Test the GGUF model works
./llama-cli -m ../nana-slm-q4-k-m.gguf \
  -p "You are Nana, a maternal health assistant. A mother asks: My baby has fever. What should I do?" \
  -n 128 \
  -c 2048
```

If it generates reasonable responses → proceed!

---

## STEP 2: Upload GGUF Model

### Option A: HuggingFace (Recommended)

```bash
# Upload to your HuggingFace repo
huggingface-cli login

# Create a new repo or use existing
huggingface-cli repo create growwithme-nana-slm-gguf --type model

# Upload the GGUF file
huggingface-cli upload abdulhafis/growwithme-nana-slm-gguf \
  nana-slm-q4-k-m.gguf \
  --repo-type model
```

**URL will be:**
```
https://huggingface.co/abdulhafis/growwithme-nana-slm-gguf/resolve/main/nana-slm-q4-k-m.gguf
```

### Option B: Your Own Server

If file is too large for HuggingFace free tier:

```bash
# Upload to your backend server
scp nana-slm-q4-k-m.gguf user@yourserver.com:/var/www/models/

# Serve via nginx or similar
# URL: https://yourserver.com/models/nana-slm-q4-k-m.gguf
```

---

## STEP 3: Integrate in Flutter

### 3.1 Add fllama Dependency

**Update `mobile/pubspec.yaml`:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies...
  
  # Add fllama for llama.cpp integration
  fllama: ^0.2.0  # Check pub.dev for latest version
```

Run:
```bash
cd mobile
flutter pub get
```

### 3.2 Create LLM Service

**Create `mobile/lib/data/model/llama_service.dart`:**

```dart
import 'dart:io';
import 'package:fllama/fllama.dart';
import 'package:path_provider/path_provider.dart';

class LlamaService {
  LlamaService();

  Llama? _model;
  bool _isLoading = false;
  
  bool get ready => _model != null;
  bool get isLoading => _isLoading;

  /// Initialize Llama model from GGUF file
  Future<bool> initialize(String modelPath) async {
    if (_isLoading || ready) return ready;
    
    _isLoading = true;
    try {
      print('[Llama] Loading model from: $modelPath');
      
      _model = await Llama.load(
        model: modelPath,
        // Performance tuning for mobile
        useGpu: false,          // CPU-only on most Android devices
        nContext: 2048,         // Context window size
        nBatch: 512,            // Batch size
        nThreads: 4,            // CPU threads (adjust based on device)
        useMlock: false,        // Don't lock memory on mobile
        useMmap: true,          // Memory-map the file
      );
      
      print('[Llama] Model loaded successfully');
      return true;
    } catch (e) {
      print('[Llama] Failed to load: $e');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Generate a response from prompt
  Future<String> generate({
    required String prompt,
    int maxTokens = 150,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
    double repeatPenalty = 1.1,
    List<String> stopSequences = const [],
  }) async {
    if (_model == null) {
      throw StateError('Model not loaded');
    }

    try {
      final response = await _model!.complete(
        prompt: prompt,
        nPredict: maxTokens,
        temperature: temperature,
        topP: topP,
        topK: topK,
        repeatPenalty: repeatPenalty,
        stop: stopSequences,
      );
      
      return response.trim();
    } catch (e) {
      print('[Llama] Generation failed: $e');
      rethrow;
    }
  }

  /// Stream tokens as they're generated (better UX)
  Stream<String> generateStream({
    required String prompt,
    int maxTokens = 150,
    double temperature = 0.7,
  }) async* {
    if (_model == null) {
      throw StateError('Model not loaded');
    }

    await for (final token in _model!.completeStream(
      prompt: prompt,
      nPredict: maxTokens,
      temperature: temperature,
    )) {
      yield token;
    }
  }

  /// Unload model to free memory
  void dispose() {
    _model?.dispose();
    _model = null;
  }
}
```

### 3.3 Update OnDeviceModel for GGUF

**Update `mobile/lib/data/model/on_device_model.dart`:**

```dart
import 'llama_service.dart';

class OnDeviceModel {
  // ... existing code ...
  
  LlamaService? _llamaService;
  
  bool get ready => _manifest != null && 
    (_manifest?['kind'] == 'llm' 
      ? _llamaService?.ready == true 
      : _interpreter != null);

  LlamaService? get llamaService => _llamaService;

  Future<void> _loadFromDisk() async {
    final file = await _modelFile();
    final mf = await _manifestFile();
    if (!await mf.exists()) return;
    
    final manifest = jsonDecode(await mf.readAsString()) as Map<String, dynamic>;
    final isLlm = manifest['kind'] == 'llm';

    if (isLlm) {
      _manifest = manifest;
      
      // NEW: Load GGUF model
      await _loadGgufModel(file.path);
    } else {
      // Existing TFLite code...
    }
  }

  Future<void> _loadGgufModel(String modelFilePath) async {
    // For GGUF, the file itself is the model (not a folder)
    final ggufFile = File(modelFilePath.replaceAll('.tflite', '.gguf'));
    
    if (!await ggufFile.exists()) {
      print('[OnDeviceModel] GGUF file not found: ${ggufFile.path}');
      return;
    }

    try {
      _llamaService = LlamaService();
      final success = await _llamaService!.initialize(ggufFile.path);
      
      if (!success) {
        _llamaService = null;
        throw Exception('Failed to load GGUF model');
      }
      
      print('[OnDeviceModel] GGUF model loaded successfully');
    } catch (e) {
      print('[OnDeviceModel] GGUF loading failed: $e');
      _llamaService = null;
    }
  }

  Future<void> _download(Map<String, dynamic> manifest) async {
    final isLlm = manifest['kind'] == 'llm';
    final url = manifest['url'] as String;
    
    print('[OnDeviceModel] Downloading from: $url');
    
    final bytes = (await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    )).data!;
    
    final digest = sha256.convert(bytes).toString();
    if (digest != manifest['sha256']) {
      throw StateError('model checksum mismatch');
    }
    
    final file = await _modelFile();
    await file.parent.create(recursive: true);

    if (isLlm) {
      // Save as .gguf file
      final ggufFile = File(file.path.replaceAll('.tflite', '.gguf'));
      await ggufFile.writeAsBytes(bytes, flush: true);
      print('[OnDeviceModel] GGUF saved to: ${ggufFile.path}');
    } else {
      // Existing TFLite code...
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
    }
    
    await (await _manifestFile()).writeAsString(jsonEncode(manifest));
  }
}
```

### 3.4 Create Prompt Templates

**Create `mobile/lib/data/assistant/nana_prompts.dart`:**

```dart
class NanaPrompts {
  /// System prompt for Nana's personality and rules
  static const String systemPrompt = '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You are Nana, a warm maternal health assistant in Northern Ghana. You help pregnant women, mothers, and caregivers with health education.

RULES:
1. NEVER diagnose or prescribe - only educate
2. For danger signs → direct to health facility immediately
3. Use simple English (6th grade level)
4. Be encouraging and culturally sensitive
5. Keep responses under 80 words

DANGER SIGNS (always escalate):
Pregnant: bleeding, severe headache, vision changes, swollen face, fever, belly pain, baby not moving
Baby: convulsions, won't drink, vomits all, very sleepy, fast breathing, blood in stool

<|eot_id|>''';

  /// Build chat prompt with context
  static String buildChatPrompt({
    required String userMessage,
    required String context,
    List<Map<String, String>>? history,
  }) {
    final buffer = StringBuffer(systemPrompt);
    
    // Add caregiver context
    buffer.write('<|start_header_id|>system<|end_header_id|>\n\n');
    buffer.write('CAREGIVER INFO:\n$context\n<|eot_id|>');
    
    // Add conversation history (last 3 exchanges)
    if (history != null && history.isNotEmpty) {
      for (final msg in history.take(6)) {  // Last 3 exchanges (6 messages)
        final role = msg['role'] == 'user' ? 'user' : 'assistant';
        buffer.write('<|start_header_id|>$role<|end_header_id|>\n\n');
        buffer.write('${msg['content']}<|eot_id|>');
      }
    }
    
    // Add current user message
    buffer.write('<|start_header_id|>user<|end_header_id|>\n\n');
    buffer.write('$userMessage<|eot_id|>');
    buffer.write('<|start_header_id|>assistant<|end_header_id|>\n\n');
    
    return buffer.toString();
  }
}
```

### 3.5 Integrate into NanaAssistant

**Update `mobile/lib/data/assistant/nana_assistant.dart`:**

```dart
import '../model/on_device_model.dart';
import 'nana_prompts.dart';

class NanaAssistant {
  NanaAssistant(this._db, this._api, [this._nlu, this._slm]);

  final AppDatabase _db;
  final ApiClient _api;
  final NluService? _nlu;
  final OnDeviceModel? _slm;

  Future<NanaReply> send(
      String text, List<Map<String, String>> history) async {
    final context = await buildContext();
    
    // Try backend LLM first
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _api.dio.post('/assistant/chat', data: {
          'messages': [...history, {'role': 'user', 'content': text}],
          'context': context,
        });
        final reply = res.data['reply'] as Map<String, dynamic>;
        final actionJson = reply['action'] as Map<String, dynamic>?;
        return NanaReply(
          reply['say'] as String? ?? '',
          action: actionJson == null
              ? null
              : NanaAction(actionJson['name'] as String? ?? '',
                  (actionJson['params'] as Map<String, dynamic>?) ?? {}),
          source: 'llm',
        );
      } catch (_) {
        _api.invalidateBaseUrl();
      }
    }
    
    // Backend failed → local inference
    return localIntent(text, history, context);
  }

  Future<NanaReply> localIntent(
    String text,
    List<Map<String, String>> history,
    String context,
  ) async {
    // 1. Check danger signs first (deterministic)
    final dangerReply = _checkDangerSigns(text);
    if (dangerReply != null) return dangerReply;

    // 2. Try on-device LLM (NEW!)
    if (_slm?.ready == true) {
      try {
        final prompt = NanaPrompts.buildChatPrompt(
          userMessage: text,
          context: context,
          history: history,
        );
        
        final response = await _slm!.llamaService!.generate(
          prompt: prompt,
          maxTokens: 120,
          temperature: 0.7,
          stopSequences: ['<|eot_id|>', '<|start_header_id|>'],
        );
        
        return NanaReply(response.trim(), source: 'slm-offline');
      } catch (e) {
        print('[NanaAssistant] SLM failed: $e');
        // Fall through to NLU
      }
    }

    // 3. Try NLU (existing)
    final understood = _nlu?.classify(text);
    if (understood != null) {
      final reply = await _replyForIntent(understood, '');
      if (reply != null) {
        return NanaReply(reply.say, action: reply.action, source: 'nlu');
      }
    }

    // 4. Keyword fallback (existing)
    return _keywordIntent(text.toLowerCase(), '');
  }

  NanaReply? _checkDangerSigns(String text) {
    final t = text.toLowerCase();
    const symptoms = [
      'sick', 'fever', 'ill', 'vomit', 'bleed', 'convuls',
      'diarrh', 'cough', 'pain', 'weak', 'not moving',
    ];
    
    if (symptoms.any(t.contains)) {
      return NanaReply(
        'I hear you. Let us check this properly right now.',
        action: const NanaAction('start_health_check', {}),
      );
    }
    return null;
  }
  
  // ... rest of existing code ...
}
```

### 3.6 Update Provider

**Update `mobile/lib/core/providers.dart`:**

```dart
final slmServiceProvider =
    Provider<OnDeviceModel>((ref) => OnDeviceModel(
      ref.watch(apiClientProvider), 
      'nana-slm',
    ));

final nanaAssistantProvider = Provider<NanaAssistant>((ref) => NanaAssistant(
    ref.watch(dbProvider),
    ref.watch(apiClientProvider),
    ref.watch(nluServiceProvider),
    ref.watch(slmServiceProvider),  // Pass SLM
));
```

---

## STEP 4: Update Backend Model Registry

### 4.1 Calculate GGUF SHA256

```bash
# Get hash of your GGUF file
sha256sum nana-slm-q4-k-m.gguf
# Or on Windows:
certutil -hashfile nana-slm-q4-k-m.gguf SHA256
```

### 4.2 Update Database

**Update `backend/scripts/deploy_slm.js`:**

```javascript
const MANIFEST = {
  name: 'nana-slm',
  version: 3,  // Increment version
  kind: 'llm',
  
  // Your GGUF file URL
  url: 'https://huggingface.co/abdulhafis/growwithme-nana-slm-gguf/resolve/main/nana-slm-q4-k-m.gguf',
  
  // SHA256 from step 4.1
  sha256: 'YOUR_GGUF_SHA256_HERE',
  
  // File size in bytes
  sizeBytes: 400000000,  // ~400 MB, adjust to actual
  
  active: true,
  
  meta: {
    trainedOn: 'Llama 3.2 1B + 55k maternal health conversations',
    disclaimer: 'On-device LLM for offline maternal health education',
    source: 'HuggingFace - abdulhafis/growwithme-nana-slm-gguf',
    format: 'GGUF Q4_K_M',
    baseModel: 'Llama 3.2 1B Instruct',
  },
};
```

Run:
```bash
node scripts/deploy_slm.js
```

---

## STEP 5: Testing

### 5.1 Test Download

```dart
// In your Flutter app
final slm = ref.read(slmServiceProvider);
await slm.ensureLatest();

print('SLM ready: ${slm.ready}');
print('Version: ${slm.version}');
print('Size: ${(slm.sizeBytes ?? 0) / 1024 / 1024} MB');
```

### 5.2 Test Generation

```dart
if (slm.ready && slm.llamaService != null) {
  final response = await slm.llamaService!.generate(
    prompt: NanaPrompts.buildChatPrompt(
      userMessage: 'What foods should I eat while pregnant?',
      context: 'Caregiver: 25 years old, pregnant, 20 weeks',
    ),
    maxTokens: 100,
  );
  
  print('Nana: $response');
}
```

### 5.3 Test Full Conversation

```dart
final assistant = ref.read(nanaAssistantProvider);

final reply1 = await assistant.send('Hello Nana', []);
print('Nana: ${reply1.say} (${reply1.source})');

final reply2 = await assistant.send(
  'My baby has diarrhea',
  [{'role': 'user', 'content': 'Hello Nana'}],
);
print('Nana: ${reply2.say} (${reply2.source})');
```

---

## Performance Optimization

### Memory Management

```dart
// Unload model when app backgrounded
class LifecycleManager extends WidgetsBindingObserver {
  final OnDeviceModel slm;
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      slm.llamaService?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      slm._loadFromDisk();
    }
  }
}
```

### Response Caching

```dart
// Cache common queries
final _cache = <int, String>{};

Future<String> generateCached(String prompt) async {
  final key = prompt.hashCode;
  if (_cache.containsKey(key)) {
    return _cache[key]!;
  }
  
  final response = await generate(prompt: prompt);
  _cache[key] = response;
  return response;
}
```

---

## Expected Performance

| Device | RAM | Load Time | Response Time | Battery Impact |
|--------|-----|-----------|---------------|----------------|
| Low-end | 2GB | 5-8s | 8-15s | High (10-15%) |
| Mid-range | 3-4GB | 3-5s | 4-8s | Medium (5-10%) |
| High-end | 6GB+ | 2-3s | 2-4s | Low (3-5%) |

**Note:** Q2_K quantization is faster but lower quality. Q4_K_M is recommended balance.

---

## Troubleshooting

### "Model failed to load"
- Check file isn't corrupted (verify SHA256)
- Ensure enough RAM (close other apps)
- Try Q2_K quantization (smaller)

### "Out of memory"
- Reduce `nContext` to 1024 or 512
- Use Q2_K instead of Q4_K_M
- Unload other models (NLU, Risk)

### "Responses are slow"
- Increase `nThreads` (4-6 on good CPUs)
- Reduce `maxTokens` to 80-100
- Cache common responses

### "Responses are poor quality"
- Check prompt format matches Llama 3.2 template
- Adjust temperature (0.6-0.8 range)
- Try Q4_K_M or Q5_K_M (better quality)

---

## Summary Checklist

- [ ] Merge LoRA with base model (Python)
- [ ] Convert to GGUF Q4_K_M (~400 MB)
- [ ] Test GGUF locally with llama-cli
- [ ] Upload to HuggingFace
- [ ] Add fllama dependency
- [ ] Implement LlamaService
- [ ] Update OnDeviceModel for GGUF
- [ ] Create prompt templates
- [ ] Integrate into NanaAssistant
- [ ] Update backend model registry
- [ ] Test download & generation
- [ ] Performance test on real devices
- [ ] Deploy to production

---

**Estimated Total Time:** 8-12 hours (if you follow this guide exactly)

**Key Files to Create/Modify:**
1. `merge_lora.py` (new - one-time conversion)
2. `mobile/lib/data/model/llama_service.dart` (new)
3. `mobile/lib/data/assistant/nana_prompts.dart` (new)
4. `mobile/lib/data/model/on_device_model.dart` (modify)
5. `mobile/lib/data/assistant/nana_assistant.dart` (modify)
6. `mobile/lib/core/providers.dart` (modify)
7. `backend/scripts/deploy_slm.js` (modify)

Ready to start? Begin with STEP 1! 🚀
