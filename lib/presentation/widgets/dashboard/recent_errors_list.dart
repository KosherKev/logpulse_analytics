import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/error_group.dart';
import '../../providers/navigation_provider.dart';
import '../errors/error_group_card.dart';

/// Compact "Recent Critical Errors" section — reuses [ErrorGroupCard].
class RecentErrorsList extends ConsumerWidget {
  final List<ErrorGroup> errorGroups;
  final int maxVisible;

  /// Optional override; default navigates to the Errors tab.
  final void Function(ErrorGroup group)? onGroupTap;

  const RecentErrorsList({
    super.key,
    required this.errorGroups,
    this.maxVisible = 5,
    this.onGroupTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (errorGroups.isEmpty) return const SizedBox.shrink();

    final c = AppColors.of(context);
    final visible = errorGroups.take(maxVisible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Critical Errors',
              style: AppTextStyles.h2.copyWith(color: c.textPrimary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => ref.read(navigationProvider.notifier).goToErrors(),
              child: Text(
                'view all →',
                style: AppTextStyles.monoSm.copyWith(color: c.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...visible.map(
          (group) => ErrorGroupCard(
            group: group,
            onTap: () {
              if (onGroupTap != null) {
                onGroupTap!(group);
              } else {
                ref.read(navigationProvider.notifier).goToErrors();
              }
            },
          ),
        ),
      ],
    );
  }
}
