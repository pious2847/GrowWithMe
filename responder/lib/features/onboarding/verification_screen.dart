import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../home/home_shell.dart';
import 'documents_screen.dart';

/// Registration step 4 — live verification status. Auto-refreshes while an
/// admin reviews the documents. Pending responders may start working (they
/// rank lowest in routing until verified); rejected ones see the admin's note
/// and can re-submit fresh documents.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late Map<String, dynamic> _user = widget.user;
  Timer? _timer;

  String get _status => _user['credentials']?['status'] as String? ?? 'pending';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final res = await Api.I.dio.get('/users/me');
      if (!mounted) return;
      setState(() => _user = res.data['user'] as Map<String, dynamic>);
    } catch (_) {}
  }

  void _continueToApp() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeShell(user: _user)), (_) => false);
  }

  void _reupload() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DocumentsScreen(user: _user)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = _user['credentials']?['note'] as String?;

    final (icon, color, title, message) = switch (_status) {
      'verified' => (
          Icons.verified,
          Colors.green.shade600,
          'You are verified!',
          'An administrator confirmed your documents. Verified responders are '
              'trusted first when urgent cases are routed.'
        ),
      'rejected' => (
          Icons.cancel,
          Colors.red.shade600,
          'Verification was not approved',
          note == null || note.isEmpty
              ? 'Your documents could not be confirmed. Please re-submit clear '
                  'photos of your Ghana Card and professional license.'
              : 'Reviewer\'s note: $note'
        ),
      _ => (
          Icons.hourglass_top,
          Colors.orange.shade600,
          'Documents under review',
          'An administrator is checking your Ghana Card and credentials. This '
              'screen updates automatically — you can also start working now; '
              'unverified responders simply rank lower when cases are routed.'
        ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
            if (_status == 'pending') ...[
              const SizedBox(height: 18),
              const Center(
                child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ],
            const Spacer(flex: 2),
            if (_status == 'rejected')
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _reupload,
                icon: const Icon(Icons.upload_file),
                label: const Text('Re-submit documents'),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _continueToApp,
                child: Text(_status == 'verified'
                    ? 'Continue to the app'
                    : 'Start working while I wait'),
              ),
          ],
        ),
      ),
    );
  }
}
