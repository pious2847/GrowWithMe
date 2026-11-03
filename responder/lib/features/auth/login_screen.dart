import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import 'otp_screen.dart';

/// Welcome + phone entry. The responder app shares GrowWithMe's identity but
/// leads with the clinical promise: someone answers when a mother or child is
/// in danger.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final phone = _phone.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length < 9) {
      setState(() => _error = 'Enter the number you registered with.');
      _focus.requestFocus();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.I.dio.post('/auth/request-otp', data: {'phone': phone});
      if (!mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not send the code. Check the number and your '
            'connection, then try again.';
      });
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 46),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const ResponderMark(size: 40),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GrowWithMe',
                                  style: t.titleMedium
                                      ?.copyWith(color: AppColors.forestDeep)),
                              const Text(
                                'RESPONDER',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.4,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Pill(
                            label: 'GHANA',
                            icon: Icons.public_rounded,
                            foreground: AppColors.forest,
                            background: AppColors.limeSoft,
                            dense: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      _HeroPortrait(),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        child: Text(
                          'Answer the call\nwhen it matters most.',
                          style: t.displaySmall?.copyWith(
                            color: AppColors.forestDeep,
                            height: 1.06,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'One tap connects you to a mother or child nearby who '
                        'needs help right now. Every minute you give can change '
                        'a life.',
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.muted,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 26),
                      SurfaceCard(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SIGN IN OR JOIN', style: _eyebrow),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phone,
                              focusNode: _focus,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+ ]')),
                              ],
                              onSubmitted: (_) => _requestOtp(),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                                hintText: '050 078 2010',
                                prefixIcon:
                                    Icon(Icons.phone_iphone_rounded, size: 21),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 16, color: AppColors.coral),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: AppColors.coral,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            LimeButton(
                              label: _busy ? 'Sending code' : 'Send me a code',
                              icon: Icons.sms_rounded,
                              busy: _busy,
                              onPressed: _busy ? null : _requestOtp,
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'New responders are guided through consent, '
                                'credentials and verification.',
                                textAlign: TextAlign.center,
                                style: t.bodySmall?.copyWith(
                                  color: AppColors.faint,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _TrustRow(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

final _eyebrow = const TextStyle(
  fontFamily: 'Manrope',
  fontSize: 10.5,
  fontWeight: FontWeight.w800,
  letterSpacing: 1.6,
  color: AppColors.muted,
);

class _HeroPortrait extends StatelessWidget {
  const _HeroPortrait();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Stack(
        children: [
          Image.asset(
            'assets/illustrations/responder_hero.webp',
            height: 236,
            width: double.infinity,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.25),
            errorBuilder: (_, _, _) => Container(
              height: 236,
              color: AppColors.limeSoft,
              child: const Icon(Icons.medical_services_rounded,
                  size: 56, color: AppColors.forest),
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.forestDeep.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Sparkle(size: 11),
                  SizedBox(width: 6),
                  Text(
                    'ON CALL, TOGETHER',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.cream,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Patient data is confidential. Access is logged and protected '
            'under Ghana\'s Data Protection Act.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.faint,
                  fontSize: 11,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}
