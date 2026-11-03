import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/attention.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_widgets.dart';
import '../home/home_shell.dart';
import 'documents_screen.dart';
import 'onboarding_frame.dart';

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
  bool _checking = false;

  String get _status => _user['credentials']?['status'] as String? ?? 'pending';
  String? get _tier => _user['credentials']?['tier'] as String?;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_status == 'verified') Attention.success();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_checking) return;
    _checking = true;
    try {
      final res = await Api.I.dio.get('/users/me');
      if (!mounted) return;
      final was = _status;
      final user = res.data['user'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _user = user);
      if (was != _status && _status == 'verified') Attention.success();
    } catch (_) {
      // Stay on the last known state; the timer will try again.
    } finally {
      _checking = false;
    }
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
    final t = Theme.of(context).textTheme;
    final note = _user['credentials']?['note'] as String?;
    final docs =
        ((_user['credentials']?['documents'] as List?) ?? []).cast<Map>();

    final (icon, accent, title, message, eyebrow) = switch (_status) {
      'verified' => (
          Icons.verified_rounded,
          AppColors.teal,
          'You’re verified.',
          'Your documents were confirmed. Verified responders are trusted '
              'first when urgent cases are routed.',
          'WELCOME TO THE NETWORK',
        ),
      'rejected' => (
          Icons.report_gmailerrorred_rounded,
          AppColors.coral,
          'Not approved yet.',
          note == null || note.isEmpty
              ? 'Your documents could not be confirmed. Re-submit clear photos '
                  'of your Ghana Card and professional license.'
              : 'Reviewer’s note: $note',
          'NEEDS ANOTHER LOOK',
        ),
      _ => (
          Icons.hourglass_top_rounded,
          AppColors.amber,
          'You’re in the queue.',
          'An administrator is checking your Ghana Card and credentials. This '
              'screen updates automatically — you can start working now; '
              'unverified responders simply rank lower when cases are routed.',
          'DOCUMENTS UNDER REVIEW',
        ),
    };

    return OnboardingFrame(
      step: 4,
      title: title,
      subtitle: message,
      footer: _status == 'rejected'
          ? LimeButton(
              label: 'Re-submit documents',
              icon: Icons.upload_rounded,
              onPressed: _reupload,
            )
          : LimeButton(
              label: _status == 'verified'
                  ? 'Open my dashboard'
                  : 'Start working while I wait',
              icon: Icons.arrow_forward_rounded,
              onPressed: _continueToApp,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(20),
            gradient: _status == 'verified'
                ? AppColors.heroGradient
                : null,
            borderColor:
                _status == 'verified' ? AppColors.forestDeep : AppColors.line,
            child: Column(
              children: [
                _StatusOrb(
                  status: _status,
                  icon: icon,
                  accent: accent,
                ),
                const SizedBox(height: 18),
                Text(
                  eyebrow,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: _status == 'verified'
                        ? AppColors.lime
                        : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  switch (_status) {
                    'verified' => 'Your badge is live',
                    'rejected' => 'One more step',
                    _ => 'Usually within 24 hours',
                  },
                  textAlign: TextAlign.center,
                  style: t.titleMedium?.copyWith(
                    color: _status == 'verified'
                        ? AppColors.cream
                        : AppColors.ink,
                  ),
                ),
                if (_status != 'verified') ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: const LinearProgressIndicator(
                      minHeight: 5,
                      value: null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('YOUR FILE', style: _eyebrow),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _FileRow(
                  icon: Icons.credit_card_rounded,
                  label: 'Ghana Card',
                  done: docs.any((d) => d['kind'] == 'ghana_card'),
                ),
                const Divider(height: 22),
                _FileRow(
                  icon: Icons.badge_rounded,
                  label: _tier == null
                      ? 'Professional license'
                      : '${kTiers[_tier] ?? 'Professional'} license',
                  done: docs.any((d) => d['kind'] == 'license'),
                  optional: !const ['nurse', 'midwife', 'doctor'].contains(_tier),
                ),
                const Divider(height: 22),
                _FileRow(
                  icon: Icons.health_and_safety_rounded,
                  label: 'Role: ${kTiers[_tier] ?? 'Responder'}',
                  done: true,
                  neutral: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_status == 'pending')
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Checking for updates every 15 seconds.',
                    style: t.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            'You can close this screen and keep working. Verification only '
            'changes how you rank in routing — never your ability to help.',
            style: t.bodySmall?.copyWith(
              color: AppColors.faint,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

final _eyebrow = const TextStyle(
  fontFamily: 'Manrope',
  fontSize: 10,
  fontWeight: FontWeight.w800,
  letterSpacing: 1.6,
  color: AppColors.muted,
);

class _StatusOrb extends StatefulWidget {
  const _StatusOrb({
    required this.status,
    required this.icon,
    required this.accent,
  });

  final String status;
  final IconData icon;
  final Color accent;

  @override
  State<_StatusOrb> createState() => _StatusOrbState();
}

class _StatusOrbState extends State<_StatusOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.status == 'pending') _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verified = widget.status == 'verified';
    final inner = Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: verified
            ? AppColors.lime.withValues(alpha: 0.16)
            : widget.accent.withValues(alpha: 0.12),
      ),
      child: Icon(
        widget.icon,
        size: 40,
        color: verified ? AppColors.lime : widget.accent,
      ),
    );
    if (widget.status != 'pending') return inner;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 82 + 26 * _controller.value,
              height: 82 + 26 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.accent
                      .withValues(alpha: 0.35 * (1 - _controller.value)),
                  width: 2,
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: inner,
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.icon,
    required this.label,
    required this.done,
    this.optional = false,
    this.neutral = false,
  });

  final IconData icon;
  final String label;
  final bool done;
  final bool optional;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 19,
            color: neutral
                ? AppColors.muted
                : done
                    ? AppColors.teal
                    : AppColors.coral),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        if (neutral)
          const SizedBox.shrink()
        else if (done)
          const Pill(
            label: 'ON FILE',
            foreground: AppColors.teal,
            background: AppColors.tealSoft,
            dense: true,
          )
        else if (optional)
          const Pill(
            label: 'OPTIONAL',
            foreground: AppColors.muted,
            background: AppColors.creamDeep,
            dense: true,
          )
        else
          const Pill(
            label: 'MISSING',
            foreground: AppColors.coral,
            background: AppColors.coralSoft,
            dense: true,
          ),
      ],
    );
  }
}
