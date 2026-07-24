import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';

/// Onboarding profile + consent. Consent must be explicit (MEST policy):
/// data processing is required to use the app; location-on-urgent and SMS
/// reminders are optional.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _communityController = TextEditingController();
  final _districtController = TextEditingController();
  String _language = 'en';
  bool _consentData = false;
  bool _consentLocation = true;
  bool _consentSms = true;
  bool _busy = false;

  Future<void> _finish() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    if (!_consentData) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Consent to data processing is needed to use GrowWithMe')));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile({
        'name': _nameController.text.trim(),
        'language': _language,
        'community': _communityController.text.trim(),
        'district': _districtController.text.trim(),
        'consent': {
          'dataProcessing': _consentData,
          'locationOnUrgent': _consentLocation,
          'smsReminders': _consentSms,
        },
      });
      ref.read(authControllerProvider.notifier).signedIn();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save profile. Try again.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About you')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
                labelText: 'Your name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: const InputDecoration(
                labelText: 'Preferred language', border: OutlineInputBorder()),
            items: [
              for (final e in kLanguages.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _language = v ?? 'en'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _districtController,
            decoration: const InputDecoration(
                labelText: 'District (e.g. Tamale Metropolitan)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _communityController,
            decoration: const InputDecoration(
                labelText: 'Community / area', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          Text('Your consent', style: Theme.of(context).textTheme.titleMedium),
          CheckboxListTile(
            value: _consentData,
            onChanged: (v) => setState(() => _consentData = v ?? false),
            title: const Text('I agree to my health data being stored securely (required)'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _consentLocation,
            onChanged: (v) => setState(() => _consentLocation = v ?? false),
            title: const Text(
                'Share my location ONLY during an urgent alert, so a volunteer can find me'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _consentSms,
            onChanged: (v) => setState(() => _consentSms = v ?? false),
            title: const Text('Send me SMS reminders for clinic visits'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _finish,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Get started'),
          ),
        ],
      ),
    );
  }
}
