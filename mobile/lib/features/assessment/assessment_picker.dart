import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import 'assessment_screen.dart';

/// "Who is this check for?" — shared by the home quick actions and Nana's
/// companion sheet so the safest feature in the app is always one tap away.
void startAssessmentPicker(BuildContext context, WidgetRef ref) {
  final children = ref.read(childrenProvider).value ?? const [];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who is this check for?',
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Answer a few simple questions. It works without internet.',
              style: Theme.of(
                sheetContext,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            for (final child in children)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PressScale(
                  borderRadius: AppRadii.md,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AssessmentScreen(
                          subjectType: 'child',
                          childId: child.id,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        IconBubble(
                          icon: Icons.child_care_rounded,
                          color: AppColors.sky,
                          size: 40,
                          iconSize: 20,
                          background: AppColors.skySoft,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            child.name,
                            style: Theme.of(sheetContext).textTheme.titleSmall,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.faint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            PressScale(
              borderRadius: AppRadii.md,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AssessmentScreen(subjectType: 'pregnancy'),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.limeSoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.lime),
                ),
                child: Row(
                  children: [
                    IconBubble(
                      icon: Icons.pregnant_woman_rounded,
                      color: AppColors.forest,
                      size: 40,
                      iconSize: 20,
                      background: AppColors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'My pregnancy / myself',
                        style: Theme.of(sheetContext).textTheme.titleSmall,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.forest,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
