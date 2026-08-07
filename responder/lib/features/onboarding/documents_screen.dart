import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import 'verification_screen.dart';

/// Registration step 3 — verification documents. Everyone uploads a Ghana
/// Card; anyone claiming a medical profession (nurse, midwife, doctor) MUST
/// also upload their professional license. Photos go to Cloudinary via the
/// backend; once the tier's requirements are on file the account enters the
/// admin review queue.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _picker = ImagePicker();
  late Map<String, dynamic> _user = widget.user;
  String? _uploadingKind;

  List<Map<String, dynamic>> get _docs =>
      ((_user['credentials']?['documents'] as List?) ?? [])
          .cast<Map<String, dynamic>>();

  bool _has(String kind) => _docs.any((d) => d['kind'] == kind);

  /// Medical professionals cannot skip the license upload.
  bool get _needsLicense => const ['nurse', 'midwife', 'doctor']
      .contains(_user['credentials']?['tier'] as String?);

  Future<void> _pickAndUpload(String kind) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(
        source: source, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingKind = kind);
    try {
      final form = FormData.fromMap({
        'kind': kind,
        'file': await MultipartFile.fromFile(picked.path,
            filename: picked.name.isEmpty ? 'document.jpg' : picked.name),
      });
      final res = await Api.I.dio.post('/responder/documents', data: form);
      setState(() => _user = res.data['user'] as Map<String, dynamic>);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Upload failed. Check your connection and try again.')));
      }
    } finally {
      if (mounted) setState(() => _uploadingKind = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = _has('ghana_card') && (!_needsLicense || _has('license'));
    final String blocker;
    if (!_has('ghana_card')) {
      blocker = 'Upload your Ghana Card to continue';
    } else if (_needsLicense && !_has('license')) {
      blocker = 'Upload your professional license to continue';
    } else {
      blocker = 'Continue';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your identity')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _needsLicense
                ? 'You registered as a medical professional, so both your '
                    'Ghana Card and your professional license are required. '
                    'An administrator reviews them before you are verified.'
                : 'Upload a photo of your Ghana Card. An administrator reviews '
                    'it — verified responders are trusted first with urgent cases.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _DocTile(
            title: 'Ghana Card',
            subtitle: 'Required — front of the card',
            icon: Icons.credit_card,
            done: _has('ghana_card'),
            uploading: _uploadingKind == 'ghana_card',
            onTap: () => _pickAndUpload('ghana_card'),
          ),
          const SizedBox(height: 12),
          _DocTile(
            title: 'Professional license',
            subtitle: _needsLicense
                ? 'Required for your professional tier'
                : 'Optional for volunteers and CHWs',
            icon: Icons.badge,
            done: _has('license'),
            uploading: _uploadingKind == 'license',
            onTap: () => _pickAndUpload('license'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: ready
                ? () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => VerificationScreen(user: _user)))
                : null,
            child: Text(blocker),
          ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.done,
    required this.uploading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: done ? Colors.green.shade50 : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: done ? Colors.green.shade300 : theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: uploading ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: done ? Colors.green.shade700 : null),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(done ? 'Uploaded — tap to replace' : subtitle),
        trailing: uploading
            ? const SizedBox(
                height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(done ? Icons.check_circle : Icons.upload,
                color: done ? Colors.green.shade700 : null),
      ),
    );
  }
}
