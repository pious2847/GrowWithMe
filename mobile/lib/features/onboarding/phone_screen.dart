import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/regions.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_widgets.dart';
import 'otp_screen.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phoneController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).requestOtp(phone);
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not send code. Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final region = ref.watch(regionProvider).value ?? RegionSettings.defaults;

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
                    const ProgressDotBar(count: 3, index: 0, activeWidth: 22),
                  ],
                ),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.limeSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: AppColors.forest,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Let\'s keep your\nfamily safe',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.forestDeep,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter your phone number. We will text you a 6-digit code — '
                  'no password to remember.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Text('Phone number', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(12),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  ],
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(
                    hintText: '24 123 4567',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            region.country.flag,
                            style: const TextStyle(fontSize: 17),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            region.country.dialCode,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 22,
                            color: AppColors.line,
                          ),
                        ],
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _continue(),
                ),
                const SizedBox(height: 22),
                LimeButton(
                  label: _busy ? 'Sending code…' : 'Send my code',
                  icon: _busy ? null : Icons.arrow_forward_rounded,
                  onPressed: _busy ? null : _continue,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock_rounded, size: 13, color: AppColors.muted),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Private by design · your number is never sold',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                SurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const NanaPortrait(size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New here?',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              'A free account gives your family reminders, '
                              'health checks and Nana.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                                height: 1.35,
                              ),
                            ),
                          ],
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
