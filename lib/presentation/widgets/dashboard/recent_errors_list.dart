import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/error_group.dart';
import '../errors/error_group_card.dart';

/// Compact "Recent Critical Errors" section — reuses [ErrorGroupCard].
class RecentErrorsList extends StatelessWidget {
  final List<ErrorGroup> errorGroups;
  final int maxVisible;

  const RecentErrorsList({
    super.key,
    required this.errorGroups,
    this.maxVisible = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (errorGroups.isEmpty) return const SizedBox.shrink();

    final c = AppColors.of(context);
    final visible = errorGroups.take(maxVisible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Critical Errors',
          style: AppTextStyles.h2.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: 12),
        ...visible.map(
          (group) => ErrorGroupCard(
            group: group,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
