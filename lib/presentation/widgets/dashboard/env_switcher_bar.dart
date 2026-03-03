import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/service_providers.dart';

/// ENV Switcher Bar — shown at top of dashboard.
///
/// Shows: pulsing status dot · profile name · truncated URL · SWITCH button
/// Tap SWITCH opens a bottom sheet with all profiles listed.
class EnvSwitcherBar extends ConsumerStatefulWidget {
  const EnvSwitcherBar({super.key});

  @override
  ConsumerState<EnvSwitcherBar> createState() => _EnvSwitcherBarState();
}

class _EnvSwitcherBarState extends ConsumerState<EnvSwitcherBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final apiConfig = ref.watch(apiConfigProvider);
    final isConnected = apiConfig.isConfigured;
    final dotColor = isConnected ? c.pulse : c.error;

    final activeProfile = apiConfig.profiles.cast<dynamic>().firstWhere(
          (p) => p.id == apiConfig.activeProfileId,
          orElse: () => null,
        );
    final profileName = (activeProfile?.name as String?) ?? 'Not configured';
    final baseUrl = apiConfig.baseUrl ?? '';
    final shortUrl = baseUrl.replaceAll(RegExp(r'^https?://'), '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Row(
        children: [
          // Pulsing status dot
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.5),
                        blurRadius: 4 * _scaleAnim.value,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Profile name + URL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName,
                  style: AppTextStyles.monoMd.copyWith(color: c.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (shortUrl.isNotEmpty)
                  Text(
                    shortUrl,
                    style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // SWITCH button
          GestureDetector(
            onTap: () => _showSwitchSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: c.accentDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'SWITCH',
                style: AppTextStyles.label.copyWith(color: c.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSwitchSheet(BuildContext context) {
    final c = AppColors.of(context);
    final apiConfig = ref.read(apiConfigProvider);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'CONNECTIONS',
                  style: AppTextStyles.label.copyWith(color: c.textTertiary),
                ),
              ),
              if (apiConfig.profiles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No connections configured',
                    style: AppTextStyles.body.copyWith(color: c.textSecondary),
                  ),
                )
              else
                ...apiConfig.profiles.map((profile) {
                  final isActive = profile.id == apiConfig.activeProfileId;
                  return InkWell(
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await ref
                          .read(apiConfigProvider.notifier)
                          .setActiveProfile(profile.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: isActive
                            ? Border(
                                left: BorderSide(color: c.accent, width: 3),
                              )
                            : null,
                        color: isActive
                            ? c.accentGlow
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? c.pulse : c.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: AppTextStyles.monoMd.copyWith(
                                    color: isActive ? c.accent : c.textPrimary,
                                  ),
                                ),
                                Text(
                                  profile.baseUrl.replaceAll(
                                    RegExp(r'^https?://'),
                                    '',
                                  ),
                                  style: AppTextStyles.monoSm.copyWith(
                                    color: c.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Icon(Icons.check, size: 16, color: c.accent),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
