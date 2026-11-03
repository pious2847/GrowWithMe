import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import 'documents_screen.dart';
import 'onboarding_frame.dart';

/// "I am a responder" — name, professional tier, area and license number.
/// Saving switches the account's role to volunteer on the backend. The tier
/// decides routing priority once documents are verified.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
      text: widget.user['name'] as String? ?? '');
  late final _district = TextEditingController(
      text: widget.user['district'] as String? ?? '');
  late final _community = TextEditingController(
      text: widget.user['community'] as String? ?? '');
  late final _license = TextEditingController(
      text: widget.user['credentials']?['licenseNumber'] as String? ?? '');
  String? _region;
  String _tier = 'volunteer';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final savedTier = widget.user['credentials']?['tier'] as String?;
    if (savedTier != null && kTiers.containsKey(savedTier)) _tier = savedTier;
    final savedRegion = widget.user['region'] as String?;
    if (savedRegion != null && kGhanaRegions.contains(savedRegion)) {
      _region = savedRegion;
    }
  }

  // Medical professionals must provide their license number (and later the
  // license document); volunteers and CHWs may leave it blank.
  bool get _needsLicense =>
      const ['nurse', 'midwife', 'doctor'].contains(_tier);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await Api.I.dio.post('/responder/profile', data: {
        'name': _name.text.trim(),
        'tier': _tier,
        'region': _region ?? '',
        'district': _district.text.trim(),
        'community': _community.text.trim(),
        if (_license.text.trim().isNotEmpty)
          'licenseNumber': _license.text.trim(),
      });
      final user = res.data['user'] as Map<String, dynamic>;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DocumentsScreen(user: user)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error =
          'Could not save your profile. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return OnboardingFrame(
      step: 2,
      title: 'Who is answering?',
      subtitle: 'Your professional tier decides which urgent cases reach you '
          'first. Be honest — false credentials are removed.',
      onBack: () => Navigator.of(context).maybePop(),
      footer: Column(
        children: [
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 10),
          ],
          LimeButton(
            label: 'Continue to documents',
            icon: Icons.arrow_forward_rounded,
            busy: _busy,
            onPressed: _busy ? null : _save,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('YOUR ROLE', style: _eyebrow),
            const SizedBox(height: 10),
            for (final entry in kTiers.entries) ...[
              _TierOption(
                tier: entry.key,
                label: entry.value,
                selected: _tier == entry.key,
                onTap: () => setState(() => _tier = entry.key),
              ),
              const SizedBox(height: 8),
            ],
            if (_needsLicense) ...[
              const SizedBox(height: 2),
              NoticeBanner(
                icon: Icons.badge_rounded,
                message: '${kTiers[_tier]}s must add a license number and '
                    'upload the license for verification.',
                color: const Color(0xFF8A4A00),
              ),
            ],
            const SizedBox(height: 22),
            Text('ABOUT YOU', style: _eyebrow),
            const SizedBox(height: 10),
            SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 21),
                    ),
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'Your name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _region,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Region',
                      prefixIcon: Icon(Icons.public_rounded, size: 21),
                    ),
                    items: [
                      for (final region in kGhanaRegions)
                        DropdownMenuItem(value: region, child: Text(region)),
                    ],
                    onChanged: (v) => setState(() => _region = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Choose your region' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _district,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'District',
                      prefixIcon: Icon(Icons.location_city_rounded, size: 21),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _community,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Community / town (optional)',
                      prefixIcon: Icon(Icons.holiday_village_rounded, size: 21),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _license,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: _needsLicense
                          ? 'Professional license number'
                          : 'License number (optional)',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 21),
                    ),
                    validator: (v) =>
                        _needsLicense && (v == null || v.trim().isEmpty)
                            ? 'Required for ${kTiers[_tier]!.toLowerCase()}s'
                            : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 15, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your name and phone are shared with a caregiver only when '
                    'you accept their case.',
                    style: t.bodySmall?.copyWith(
                      color: AppColors.faint,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _TierOption extends StatelessWidget {
  const _TierOption({
    required this.tier,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String tier;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _meta = {
    'volunteer': (Icons.groups_rounded, 'First responder on foot, bike or car', 1),
    'chw': (Icons.health_and_safety_rounded, 'Trained community health worker', 2),
    'nurse': (Icons.vaccines_rounded, 'Registered nurse', 3),
    'midwife': (Icons.pregnant_woman_rounded, 'Registered midwife', 4),
    'doctor': (Icons.medical_services_rounded, 'Medical doctor', 5),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, description, priority) = _meta[tier]!;
    return PressScale(
      borderRadius: AppRadii.lg,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.enter,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? AppColors.limeSoft : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: selected ? AppColors.forest : AppColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            IconBubble(
              icon: icon,
              color: selected ? AppColors.forest : AppColors.muted,
              size: 38,
              iconSize: 19,
              background: selected
                  ? AppColors.white.withValues(alpha: 0.7)
                  : AppColors.creamDeep,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  'PRIORITY',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: selected ? AppColors.forest : AppColors.faint,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Container(
                        width: 4,
                        height: 10,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: i < priority
                              ? (selected ? AppColors.forest : AppColors.lineStrong)
                              : AppColors.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: AppMotion.fast,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.forest : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.forest : AppColors.lineStrong,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: AppColors.lime)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
