import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_widgets.dart';
import 'privacy_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _resendCooldown = 60;

  final _codeController = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  bool _resending = false;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focus.dispose();
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
        const SnackBar(content: Text('A new code has been sent by SMS')),
      );
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not resend the code. Check your connection.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_codeController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the code from the SMS')),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyOtp(widget.phone, _codeController.text.trim());
      if (result.isNewUser) {
        await ref.read(dbProvider).resetSyncFlags();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(kLastPulledAtKey);
      }
      if (!mounted) return;
      if (result.isNewUser) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PrivacyScreen()),
        );
      } else {
        ref.read(authControllerProvider.notifier).signedIn();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect or expired code. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canResend = _secondsLeft <= 0 && !_resending;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PressScale(
                      borderRadius: 99,
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const ProgressDotBar(count: 3, index: 1, activeWidth: 22),
                  ],
                ),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.sms_rounded,
                    color: AppColors.teal,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Check your\nmessages',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.forestDeep,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to '),
                      TextSpan(
                        text: widget.phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const TextSpan(text: '. It expires in 10 minutes.'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _codeController,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 14,
                    color: AppColors.forestDeep,
                  ),
                  onChanged: (v) {
                    if (v.length == 6) _verify();
                  },
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: TextStyle(letterSpacing: 12),
                  ),
                ),
                const SizedBox(height: 20),
                LimeButton(
                  label: _busy ? 'Checking…' : 'Verify my number',
                  icon: _busy ? null : Icons.check_rounded,
                  onPressed: _busy ? null : _verify,
                ),
                const SizedBox(height: 14),
                Center(
                  child: canResend
                      ? TextButton.icon(
                          onPressed: _resend,
                          icon: const Icon(Icons.refresh_rounded, size: 17),
                          label: const Text('Resend code'),
                        )
                      : Text(
                          _resending
                              ? 'Sending a new code…'
                              : 'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                SurfaceCard(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_rounded,
                        size: 18,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No SMS? Check your network, or tap resend after '
                          'the timer. Your code may arrive as a small pop-up.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkSoft,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
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
