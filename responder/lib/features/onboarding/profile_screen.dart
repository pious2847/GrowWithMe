import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import 'documents_screen.dart';

/// "I am a responder" — name, professional tier, area and license number.
/// Saving switches the account's role to volunteer on the backend.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user['name'] as String? ?? '');
  late final _region = TextEditingController(text: widget.user['region'] as String? ?? '');
  late final _district = TextEditingController(text: widget.user['district'] as String? ?? '');
  late final _license = TextEditingController(
      text: widget.user['credentials']?['licenseNumber'] as String? ?? '');
  String _tier = 'volunteer';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.user['credentials']?['tier'] as String?;
    if (saved != null && kTiers.containsKey(saved)) _tier = saved;
  }

  // Medical professionals must provide their license number (and later the
  // license document); volunteers and CHWs may leave it blank.
  bool get _needsLicense => const ['nurse', 'midwife', 'doctor'].contains(_tier);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final res = await Api.I.dio.post('/responder/profile', data: {
        'name': _name.text.trim(),
        'tier': _tier,
        'region': _region.text.trim(),
        'district': _district.text.trim(),
        if (_license.text.trim().isNotEmpty) 'licenseNumber': _license.text.trim(),
      });
      final user = res.data['user'] as Map<String, dynamic>;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DocumentsScreen(user: user)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save your profile. Check your connection.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('I am a responder')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Tell us who you are. Your professional tier decides which urgent '
              'cases are routed to you first.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: _dec('Full name', Icons.person),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Your name is required' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _tier,
              decoration: _dec('I am a…', Icons.medical_services),
              items: [
                for (final e in kTiers.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _tier = v ?? 'volunteer'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _region,
              textCapitalization: TextCapitalization.words,
              decoration: _dec('Region', Icons.public),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _district,
              textCapitalization: TextCapitalization.words,
              decoration: _dec('District', Icons.location_city),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _license,
              decoration: _dec(
                  _needsLicense ? 'Professional license number' : 'License number (optional)',
                  Icons.badge),
              validator: (v) => _needsLicense && (v == null || v.trim().isEmpty)
                  ? 'License number is required for ${kTiers[_tier]!.toLowerCase()}s'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );
}
