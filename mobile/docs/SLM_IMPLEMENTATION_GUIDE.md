# Nana SLM Implementation Guide

This guide provides step-by-step instructions to integrate the Nana SLM for offline conversational AI.

## Prerequisites

- Nana SLM adapter already downloaded (handled automatically)
- Target devices: 2GB+ RAM recommended
- Storage: ~150-200 MB additional space needed

---

## Step 1: Choose and Add Inference Library

### Option A: llama.cpp (Recommended)

Best performance, supports LoRA adapters natively.

**Add to pubspec.yaml:**
```yaml
dependencies:
  llama_cpp_dart: ^0.1.0  # Check pub.dev for latest
  # OR
  flutter_llama: ^0.2.0   # Alternative binding
```

### Option B: MediaPipe LLM (Easier but requires conversion)

```yaml
dependencies:
  mediapipe_llm: ^0.1.0
```

**For this guide, we'll use llama.cpp approach.**

---

## Step 2: Download Base Llama 3.2 Model

Create a script to download the quantized base model:

**File: `backend/scripts/prepare_base_model.js`**

```javascript
const https = require('https');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Llama 3.2 1B quantized (Q4_K_M format - good balance)
const BASE_MODEL_URL = 'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf';
const OUTPUT_PATH = path.join(__dirname, 'llama-3.2-1b-q4.gguf');

async function download() {
  console.log('Downloading Llama 3.2 1B base model...');
  console.log('This may take 10-15 minutes (file is ~700 MB)');
  
  const file = fs.createWriteStream(OUTPUT_PATH);
  
  return new Promise((resolve, reject) => {
    https.get(BASE_MODEL_URL, (response) => {
      if (response.statusCode === 302 || response.statusCode === 301) {
        https.get(response.headers.location, (r) => {
          const total = parseInt(r.headers['content-length'] || '0');
          let downloaded = 0;
          
          r.on('data', (chunk) => {
            downloaded += chunk.length;
            const pct = ((downloaded / total) * 100).toFixed(1);
            process.stdout.write(`\rDownloading: ${pct}%`);
          });
          
          r.pipe(file);
          
          file.on('finish', () => {
            file.close();
            console.log('\n\nDownload complete!');
            
            // Calculate SHA256
            const buffer = fs.readFileSync(OUTPUT_PATH);
            const hash = crypto.createHash('sha256').update(buffer).digest('hex');
            
            console.log(`\nFile: ${OUTPUT_PATH}`);
            console.log(`Size: ${(buffer.length / 1024 / 1024).toFixed(2)} MB`);
            console.log(`SHA256: ${hash}`);
            
            resolve();
          });
        }).on('error', reject);
      }
    }).on('error', reject);
  });
}

download().catch(console.error);
```

**Upload to Cloudinary or serve from backend:**

If model is too large for Cloudinary, host it on your server or keep on HuggingFace.

---

## Step 3: Create LLM Service Wrapper

**File: `mobile/lib/data/model/llm_service.dart`**

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
// Adjust import based on chosen library

class LlmService {
  LlmService();

  LlamaCpp? _engine;
  bool _isLoading = false;
  
  bool get ready => _engine != null;
  bool get isLoading => _isLoading;

  /// Initialize the LLM with base model and adapter
  Future<bool> initialize({
    required String baseModelPath,
    required String adapterPath,
  }) async {
    if (_isLoading || ready) return ready;
    
    _isLoading = true;
    try {
      _engine = await LlamaCpp.load(
        modelPath: baseModelPath,
        // LoRA adapter configuration
        loraAdapter: adapterPath,
        // Performance tuning
        contextSize: 2048,        // Context window
        numThreads: 4,            // CPU threads
        batchSize: 512,           // Batch processing
        useGpu: false,            // Mobile typically CPU-only
        // Memory optimization
        useMmap: true,            // Memory-map the file
        useMlock: false,          // Don't lock in RAM on mobile
      );
      
      return true;
    } catch (e) {
      print('[LLM] Failed to load: $e');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Generate a response from a prompt
  Future<String> generate({
    required String prompt,
    int maxTokens = 150,
    double temperature = 0.7,
    List<String> stopSequences = const ['<|user|>', '<|endoftext|>'],
  }) async {
    if (_engine == null) {
      throw StateError('LLM not initialized');
    }

    try {
      final response = await _engine!.complete(
        prompt: prompt,
        maxTokens: maxTokens,
        temperature: temperature,
        stopSequences: stopSequences,
        // Sampling parameters
        topP: 0.9,
        topK: 40,
        repeatPenalty: 1.1,
      );
      
      return response.trim();
    } catch (e) {
      print('[LLM] Generation failed: $e');
      rethrow;
    }
  }

  /// Stream tokens as they're generated (better UX)
  Stream<String> generateStream({
    required String prompt,
    int maxTokens = 150,
    double temperature = 0.7,
  }) async* {
    if (_engine == null) {
      throw StateError('LLM not initialized');
    }

    await for (final token in _engine!.completeStream(
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
    )) {
      yield token;
    }
  }

  /// Clean up resources
  void dispose() {
    _engine?.dispose();
    _engine = null;
  }
}
```

---

## Step 4: Extend OnDeviceModel for LLM Loading

**Update: `mobile/lib/data/model/on_device_model.dart`**

Add to the class:

```dart
import 'llm_service.dart';

class OnDeviceModel {
  // ... existing code ...
  
  LlmService? _llmService;
  
  bool get ready => _manifest != null && 
    (_manifest?['kind'] == 'llm' 
      ? _llmService?.ready == true 
      : _interpreter != null);

  /// Get the LLM service (only for LLM models)
  LlmService? get llmService => _llmService;

  Future<void> _loadFromDisk() async {
    final file = await _modelFile();
    final mf = await _manifestFile();
    if (!await mf.exists()) return;
    
    final manifest = jsonDecode(await mf.readAsString()) as Map<String, dynamic>;
    final isLlm = manifest['kind'] == 'llm';

    if (isLlm) {
      final targetName = name.startsWith('nana-slm') ? 'nana-slm' : name;
      final folder = Directory('${file.parent.path}/$targetName');
      if (!await folder.exists()) return;
      
      _manifest = manifest;
      
      // NEW: Actually load the LLM
      await _loadLlm(folder.path);
    } else {
      // Existing TFLite loading code
      if (!await file.exists()) return;
      final digest = sha256.convert(await file.readAsBytes()).toString();
      if (digest != manifest['sha256']) {
        await file.delete();
        return;
      }
      _interpreter?.close();
      _interpreter = Interpreter.fromFile(file);
      _manifest = manifest;
    }
  }

  /// Load LLM with base model and adapter
  Future<void> _loadLlm(String adapterPath) async {
    try {
      // Get base model path
      final baseModelPath = await _ensureBaseModel();
      
      // Initialize LLM service
      _llmService = LlmService();
      final success = await _llmService!.initialize(
        baseModelPath: baseModelPath,
        adapterPath: '$adapterPath/adapter_model.safetensors',
      );
      
      if (!success) {
        _llmService = null;
        throw Exception('Failed to initialize LLM');
      }
      
      print('[OnDeviceModel] LLM loaded successfully');
    } catch (e) {
      print('[OnDeviceModel] LLM loading failed: $e');
      _llmService = null;
    }
  }

  /// Ensure base Llama model exists, download if needed
  Future<String> _ensureBaseModel() async {
    final dir = await getApplicationSupportDirectory();
    final baseModelFile = File('${dir.path}/models/llama-3.2-1b-q4.gguf');
    
    if (await baseModelFile.exists()) {
      return baseModelFile.path;
    }
    
    // Download base model (you'll need to implement this)
    // For now, throw if missing
    throw Exception(
      'Base model not found. Please download llama-3.2-1b-q4.gguf'
    );
  }
}
```

---

## Step 5: Create Prompt Templates

**File: `mobile/lib/data/assistant/nana_prompts.dart`**

```dart
/// Prompt templates for offline LLM inference
class NanaPrompts {
  /// System prompt defining Nana's role and constraints
  static const String systemPrompt = '''You are Nana, a warm and knowledgeable maternal health assistant in Northern Ghana. You help pregnant women, new mothers, and caregivers with health education and app navigation.

CORE RULES:
1. NEVER diagnose, prescribe medication, or classify risk levels
2. For ANY danger signs → direct to immediate health check or facility
3. Use simple English (Grade 6 reading level)
4. Be warm, encouraging, and culturally aware
5. Reference Ghana Health Service (GHS) guidelines
6. Keep responses under 100 words

DANGER SIGNS (always escalate):
- Pregnant: bleeding, severe headache, vision changes, swollen face/hands, fever, strong belly pain, waters breaking early, baby not moving
- Baby/Child: convulsions, cannot drink/breastfeed, vomits everything, very sleepy, fast breathing, blood in stool

You can:
- Share GHS-approved health education
- Guide users through the app
- Suggest diet improvements from local foods
- Encourage clinic attendance
- Provide emotional support''';

  /// Build a chat prompt with context
  static String buildChatPrompt({
    required String userMessage,
    required String context,
    List<Map<String, String>>? history,
  }) {
    final historyText = history
        ?.take(5) // Last 5 messages only
        .map((m) => '${m['role'] == 'user' ? 'User' : 'Nana'}: ${m['content']}')
        .join('\n') ?? '';

    return '''<|system|>
$systemPrompt

CAREGIVER CONTEXT:
$context

${historyText.isNotEmpty ? 'RECENT CONVERSATION:\n$historyText\n' : ''}
<|user|>
$userMessage

<|assistant|>
''';
  }

  /// Prompt for check-in questions
  static String buildCheckinPrompt(String context) {
    return '''<|system|>
$systemPrompt

You generate 4-6 pregnancy check-in questions for a mother in Northern Ghana. Questions must:
- Be answerable with YES or NO
- Use very simple English that reads well aloud
- Follow up on symptoms she reported before
- Cover danger signs and common pregnancy concerns

Return ONLY a JSON array:
[
  {"text": "question text", "category": "danger|caution|info"},
  ...
]

CAREGIVER CONTEXT:
$context

<|assistant|>
[''';
  }
}
```

---

## Step 6: Integrate into NanaAssistant

**Update: `mobile/lib/data/assistant/nana_assistant.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/on_device_model.dart';
import 'nana_prompts.dart';

class NanaAssistant {
  NanaAssistant(this._db, this._api, [this._nlu, this._slm]);

  final AppDatabase _db;
  final ApiClient _api;
  final NluService? _nlu;
  final OnDeviceModel? _slm;  // NEW: SLM parameter

  Future<NanaReply> send(
      String text, List<Map<String, String>> history) async {
    final context = await buildContext();
    
    // Try backend LLM first (best quality)
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
    
    // Backend failed → try local inference
    return localIntent(text, history, context);
  }

  /// Offline fallback with SLM integration
  Future<NanaReply> localIntent(
    String text,
    List<Map<String, String>> history,
    String context,
  ) async {
    final t = text.toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName') ?? '';
    final greetingName = name.isNotEmpty ? name : 'my daughter';

    // 1. ALWAYS check danger signs first (deterministic)
    const symptomWords = [
      'sick', 'fever', 'ill', 'vomit', 'bleed', 'convuls', 'fit',
      'diarrh', 'cough', 'pain', 'weak', 'not moving', 'unwell', 'hot body',
    ];
    if (symptomWords.any(t.contains)) {
      return NanaReply(
        'I hear you, $greetingName. Let us check this properly and safely right now.',
        action: const NanaAction('start_health_check', {}),
      );
    }

    // 2. Try SLM if loaded (NEW)
    if (_slm?.ready == true) {
      try {
        final prompt = NanaPrompts.buildChatPrompt(
          userMessage: text,
          context: context,
          history: history,
        );
        
        final response = await _slm!.llmService!.generate(
          prompt: prompt,
          maxTokens: 150,
          temperature: 0.7,
        );
        
        // TODO: Parse for actions if response contains JSON
        return NanaReply(response, source: 'slm-offline');
      } catch (e) {
        print('[NanaAssistant] SLM generation failed: $e');
        // Fall through to NLU
      }
    }

    // 3. Try on-device NLU (existing)
    final understood = _nlu?.classify(text);
    if (understood != null) {
      final reply = await _replyForIntent(understood, greetingName);
      if (reply != null) {
        return NanaReply(reply.say, action: reply.action, source: 'nlu');
      }
    }

    // 4. Last resort: keywords (existing)
    return _keywordIntent(t, greetingName);
  }
  
  // ... rest of existing code ...
}
```

---

## Step 7: Update Provider

**Update: `mobile/lib/core/providers.dart`**

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

## Step 8: Testing

### Test 1: Model Loading
```dart
final slm = ref.read(slmServiceProvider);
await slm.ensureLatest();
print('SLM ready: ${slm.ready}');
```

### Test 2: Simple Generation
```dart
if (slm.ready) {
  final response = await slm.llmService!.generate(
    prompt: 'Hello, I am Nana. How can I help you today?',
    maxTokens: 50,
  );
  print('Response: $response');
}
```

### Test 3: Full Conversation
```dart
final assistant = ref.read(nanaAssistantProvider);
final reply = await assistant.send(
  'What foods should I eat while pregnant?',
  [],
);
print('Nana: ${reply.say}');
print('Source: ${reply.source}');
```

---

## Performance Optimization

### Memory Management
```dart
// In OnDeviceModel
void unloadLlm() {
  _llmService?.dispose();
  _llmService = null;
}

// Call when app goes to background
WidgetsBinding.instance.addObserver(
  LifecycleEventHandler(
    suspendingCallBack: () async => slm.unloadLlm(),
    resumeCallBack: () async => await slm._loadFromDisk(),
  ),
);
```

### Caching Responses
```dart
// Cache common queries
final _responseCache = <String, String>{};

Future<String> generate({required String prompt}) async {
  final cacheKey = prompt.hashCode.toString();
  if (_responseCache.containsKey(cacheKey)) {
    return _responseCache[cacheKey]!;
  }
  
  final response = await _engine!.complete(prompt: prompt);
  _responseCache[cacheKey] = response;
  return response;
}
```

---

## Troubleshooting

### Issue: Out of Memory
**Solution**: Use smaller quantization (Q2_K instead of Q4_K_M)

### Issue: Slow Generation
**Solution**: Reduce maxTokens, increase numThreads, use GPU if available

### Issue: Model Not Loading
**Solution**: Check file permissions, verify SHA256 hash, check available storage

---

## Next Steps

1. Test on actual device (not emulator)
2. Measure battery impact over 1 hour of use
3. Benchmark response times (target: < 3 seconds)
4. A/B test: SLM vs NLU user satisfaction
5. Monitor crash rates (LLM can be unstable on low-end devices)

---

## Resources

- [llama.cpp](https://github.com/ggerganov/llama.cpp)
- [Hugging Face GGUF Models](https://huggingface.co/models?library=gguf)
- [Flutter FFI Guide](https://dart.dev/guides/libraries/c-interop)
- [LoRA Adapters](https://huggingface.co/docs/peft/conceptual_guides/lora)
