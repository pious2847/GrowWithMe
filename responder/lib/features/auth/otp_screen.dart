import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../main.dart' show routeForUser;

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  int _resendIn = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_resendIn <= 0) return t.cancel();
      setState(() => _resendIn -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    try {
      await Api.I.dio.post('/auth/request-otp', data: {'phone': widget.phone});
      _startCountdown();
    } catch (_) {}
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length < 4) return;
    setState(() => _busy = true);
    try {
      final res = await Api.I.dio.post('/auth/verify-otp',
          data: {'phone': widget.phone, 'code': code});
      await Api.I.saveTokens(res.data['tokens'] as Map<String, dynamic>);
      final user = res.data['user'] as Map<String, dynamic>;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => routeForUser(user)), (_) => false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wrong or expired code. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter the code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('We sent an SMS code to ${widget.phone}.'),
            const SizedBox(height: 20),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 28, letterSpacing: 12),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '······',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _busy ? null : _verify,
              child: _busy
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify'),
            ),
            TextButton(
              onPressed: _resendIn > 0 ? null : _resend,
              child: Text(_resendIn > 0 ? 'Resend code in ${_resendIn}s' : 'Resend code'),
            ),
          ],
        ),
      ),
    );
  }
}
