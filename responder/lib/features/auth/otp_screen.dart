import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_widgets.dart';
import '../../main.dart' show routeForUser;

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  String? _error;
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
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      await Api.I.dio.post('/auth/request-otp', data: {'phone': widget.phone});
      _startCountdown();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not resend. Try again in a moment.');
      }
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    final code = _code.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Enter the full code from the SMS.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await Api.I.dio.post('/auth/verify-otp',
          data: {'phone': widget.phone, 'code': code});
      await Api.I.saveTokens(res.data['tokens'] as Map<String, dynamic>);
      final user = res.data['user'] as Map<String, dynamic>;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => routeForUser(user)), (_) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'That code is wrong or has expired.');
      _code.clear();
      _focus.requestFocus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _RoundButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    const ResponderMark(size: 34, showShadow: false),
                  ],
                ),
                const SizedBox(height: 40),
                Text('One last step.',
                    style: t.displaySmall
                        ?.copyWith(color: AppColors.forestDeep, height: 1.05)),
                const SizedBox(height: 10),
                Text(
                  'We sent a code by SMS to ${widget.phone}. Enter it below '
                  'to open your responder dashboard.',
                  style: t.bodyMedium
                      ?.copyWith(color: AppColors.muted, height: 1.55),
                ),
                const SizedBox(height: 28),
                SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _code,
                        focusNode: _focus,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 8,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (_error != null) setState(() => _error = null);
                          if (value.length >= 6) _verify();
                        },
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 14,
                          color: AppColors.forestDeep,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: '••••••',
                          hintStyle: TextStyle(
                            fontSize: 26,
                            letterSpacing: 12,
                            color: AppColors.faint,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.coral,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      LimeButton(
                        label: _busy ? 'Checking' : 'Open my dashboard',
                        icon: Icons.arrow_forward_rounded,
                        busy: _busy,
                        onPressed: _busy ? null : _verify,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: _resendIn > 0
                      ? Text(
                          'Didn’t get it? Resend in ${_resendIn}s',
                          style: t.bodySmall?.copyWith(color: AppColors.muted),
                        )
                      : TextButton.icon(
                          onPressed: _resend,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Resend the code'),
                        ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Standard SMS rates may apply.',
                    style: t.bodySmall?.copyWith(
                      color: AppColors.faint,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 21, color: AppColors.ink),
        ),
      ),
    );
  }
}
