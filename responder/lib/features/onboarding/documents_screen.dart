import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import 'onboarding_frame.dart';
import 'verification_screen.dart';

/// Registration step 3 — verification documents. Everyone uploads a Ghana
/// Card; anyone claiming a medical profession (nurse, midwife, doctor) MUST
/// also upload their professional license. Photos go to Cloudinary via the
/// backend; once the tier's requirements are on file the account enters the
/// admin review queue.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _picker = ImagePicker();
  late Map<String, dynamic> _user = widget.user;
  String? _uploadingKind;
  String? _error;

  List<Map<String, dynamic>> get _docs =>
      ((_user['credentials']?['documents'] as List?) ?? [])
          .cast<Map<String, dynamic>>();

  bool _has(String kind) => _docs.any((d) => d['kind'] == kind);

  /// Medical professionals cannot skip the license upload.
  bool get _needsLicense => const ['nurse', 'midwife', 'doctor']
      .contains(_user['credentials']?['tier'] as String?);

  Future<void> _pickAndUpload(String kind) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cream,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kind == 'ghana_card'
                    ? 'Add your Ghana Card'
                    : 'Add your professional license',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Use a clear photo with all corners visible and no glare.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              _SourceTile(
                icon: Icons.photo_camera_rounded,
                title: 'Take a photo now',
                subtitle: 'Best in daylight, on a flat surface',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _SourceTile(
                icon: Icons.photo_library_rounded,
                title: 'Choose from gallery',
                subtitle: 'Pick an existing clear photo',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Documents are encrypted and only visible to reviewers.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.faint,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(
        source: source, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _uploadingKind = kind;
      _error = null;
    });
    try {
      final form = FormData.fromMap({
        'kind': kind,
        'file': await MultipartFile.fromFile(picked.path,
            filename: picked.name.isEmpty ? 'document.jpg' : picked.name),
      });
      final res = await Api.I.dio.post('/responder/documents', data: form);
      if (!mounted) return;
      setState(() => _user = res.data['user'] as Map<String, dynamic>);
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _error = 'Upload failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _uploadingKind = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ready = _has('ghana_card') && (!_needsLicense || _has('license'));
    final String blocker;
    if (!_has('ghana_card')) {
      blocker = 'Upload your Ghana Card to continue';
    } else if (_needsLicense && !_has('license')) {
      blocker = 'Upload your professional license to continue';
    } else {
      blocker = 'Send for verification';
    }
    return OnboardingFrame(
      step: 3,
      title: 'Prove who you are.',
      subtitle: _needsLicense
          ? 'You registered as a medical professional, so both your Ghana Card '
              'and professional license are required. An administrator reviews '
              'them before you are verified.'
          : 'Upload a photo of your Ghana Card. Verified responders are '
              'trusted first with urgent cases.',
      onBack: () => Navigator.of(context).maybePop(),
      footer: Column(
        children: [
          if (_error != null) ...[
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
            const SizedBox(height: 10),
          ],
          LimeButton(
            label: blocker,
            icon: ready ? Icons.verified_user_rounded : Icons.upload_rounded,
            onPressed: ready
                ? () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => VerificationScreen(user: _user)))
                : null,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DocCard(
            title: 'Ghana Card',
            subtitle: 'Required — front of the card',
            icon: Icons.credit_card_rounded,
            done: _has('ghana_card'),
            uploading: _uploadingKind == 'ghana_card',
            onTap: () => _pickAndUpload('ghana_card'),
          ),
          const SizedBox(height: 12),
          _DocCard(
            title: 'Professional license',
            subtitle: _needsLicense
                ? 'Required for your professional tier'
                : 'Optional for volunteers and CHWs',
            icon: Icons.badge_rounded,
            done: _has('license'),
            uploading: _uploadingKind == 'license',
            onTap: () => _pickAndUpload('license'),
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WHAT HAPPENS NEXT', style: _eyebrow),
                const SizedBox(height: 12),
                const _StepLine(
                  icon: Icons.upload_rounded,
                  title: 'You upload',
                  body: 'Photos go straight to the secure review queue.',
                  done: true,
                ),
                const _StepLine(
                  icon: Icons.person_search_rounded,
                  title: 'An administrator checks',
                  body: 'A human confirms the card and license match you.',
                ),
                const _StepLine(
                  icon: Icons.verified_rounded,
                  title: 'You get the badge',
                  body: 'Verified responders rank first when cases are routed.',
                  last: true,
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
                  'Uploads are encrypted in transit. Documents are never shown '
                  'to caregivers or other responders.',
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

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.done,
    required this.uploading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      borderRadius: AppRadii.lg,
      onTap: uploading ? () {} : onTap,
      child: AnimatedContainer(
        duration: AppMotion.base,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: done ? AppColors.tealSoft : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: done ? AppColors.teal : AppColors.line,
            width: done ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            IconBubble(
              icon: done ? Icons.check_rounded : icon,
              color: done ? AppColors.teal : AppColors.forest,
              size: 46,
              iconSize: 22,
              background:
                  done ? AppColors.white.withValues(alpha: 0.7) : AppColors.limeSoft,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    done ? 'Uploaded — tap to replace' : subtitle,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: done ? AppColors.teal : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (uploading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            else
              Icon(
                done ? Icons.swap_horiz_rounded : Icons.add_a_photo_rounded,
                size: 21,
                color: done ? AppColors.teal : AppColors.forest,
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          IconBubble(icon: icon, color: AppColors.forest, size: 42, iconSize: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11.5,
                      color: AppColors.muted,
                    )),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded,
              size: 18, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({
    required this.icon,
    required this.title,
    required this.body,
    this.done = false,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool done;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: done ? AppColors.limeSoft : AppColors.creamDeep,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 15,
                    color: done ? AppColors.limeInk : AppColors.muted),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 1.4, color: AppColors.line),
                ),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      )),
                  const SizedBox(height: 1),
                  Text(body,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppColors.muted,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
