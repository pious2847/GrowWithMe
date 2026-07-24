import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';
import 'profile_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _resendCooldown = 60;

  final _codeController = TextEditingController();
  bool _busy = false;
  bool _resending = false;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsLeft -= 1;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).requestOtp(widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent by SMS')));
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not resend the code. Check your connection.')));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyOtp(widget.phone, _codeController.text.trim());
      if (result.isNewUser) {
        // Fresh account on this server — make any existing local data
        // upload so nothing is lost when switching backends.
        await ref.read(dbProvider).resetSyncFlags();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(kLastPulledAtKey);
      }
      if (!mounted) return;
      if (result.isNewUser) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProfileScreen()));
      } else {
        ref.read(authControllerProvider.notifier).signedIn();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect or expired code')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft <= 0 && !_resending;

    return Scaffold(
      appBar: AppBar(title: const Text('Enter code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('We sent a 6-digit code by SMS to ${widget.phone}.'),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: const InputDecoration(
                counterText: '',
                border: OutlineInputBorder(),
                hintText: '••••••',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify'),
            ),
            const SizedBox(height: 12),
            Center(
              child: canResend
                  ? TextButton(
                      onPressed: _resend,
                      child: const Text('Resend code'),
                    )
                  : Text(
                      _resending
                          ? 'Sending a new code…'
                          : 'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
