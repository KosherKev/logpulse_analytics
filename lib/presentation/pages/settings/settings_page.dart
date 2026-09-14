import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Settings Page
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final apiConfig = ref.read(apiConfigProvider);
    _apiUrlController.text = apiConfig.baseUrl ?? '';
    _apiKeyController.text = apiConfig.apiKey ?? '';
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final apiConfig = ref.watch(apiConfigProvider);
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // API Configuration Section
          _buildSectionHeader('API Configuration'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (apiConfig.profiles.isNotEmpty)
                    Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: apiConfig.profiles.length,
                          itemBuilder: (context, index) {
                            final profile = apiConfig.profiles[index];
                            final isActive =
                                profile.id == apiConfig.activeProfileId;
                            return GestureDetector(
                              onTap: () async {
                                await ref
                                    .read(apiConfigProvider.notifier)
                                    .setActiveProfile(profile.id);
                                setState(() {
                                  _apiUrlController.text = profile.baseUrl;
                                  _apiKeyController.text = profile.apiKey;
                                  _isEditing = false;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: c.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: c.border, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isActive ? c.accent : c.border,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.name,
                                            style: AppTextStyles.body.copyWith(
                                              color: c.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _truncateUrl(profile.baseUrl),
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                    color: c.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: c.textSecondary,
                                      onPressed: () async {
                                        await ref
                                            .read(apiConfigProvider.notifier)
                                            .removeProfile(profile.id);
                                        final updated =
                                            ref.read(apiConfigProvider);
                                        setState(() {
                                          _apiUrlController.text =
                                              updated.baseUrl ?? '';
                                          _apiKeyController.text =
                                              updated.apiKey ?? '';
                                          _isEditing = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  TextField(
                    controller: _apiUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Service URL',
                      hintText: 'https://your-service.run.app',
                      prefixIcon: Icon(Icons.link),
                    ),
                    enabled: _isEditing,
                    onChanged: (_) => setState(() => _isEditing = true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Enter your API key',
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: !_isEditing,
                    enabled: _isEditing,
                    onChanged: (_) => setState(() => _isEditing = true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Wrap (not Row+Spacer): on narrow screens "Configure API"/
                  // "API Configured" plus "Add Connection" don't fit on one
                  // line — Wrap drops the overflow to a second line instead
                  // of overflowing the Row (was a confirmed layout overflow
                  // at 375px-wide phone viewports).
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (!_isEditing && !apiConfig.isConfigured)
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit),
                          label: const Text('Configure API'),
                        )
                      else if (!_isEditing)
                        Wrap(
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const Text('API Configured'),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isEditing = true),
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
                      TextButton.icon(
                        onPressed: _showAddConnectionDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Connection'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Custom control, not SegmentedButton: SegmentedButton
                  // divides its parent's full width evenly across all 3
                  // segments regardless of content, and at phone width that
                  // wrapped the label to two lines. Renaming "System" to
                  // "Auto" alone didn't actually fix it — confirmed live on
                  // a real device after deploy, all three labels wrapped
                  // ("Lig/ht", "Dar/k", "Aut/o"), worse than before. A
                  // FittedBox per segment scales its icon+label down to fit
                  // instead of ever wrapping, regardless of width.
                  Row(
                    children: [
                      _ThemeOption(
                        icon: Icons.wb_sunny_outlined,
                        label: 'Light',
                        selected: settings.themeMode == 'light',
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setThemeMode('light'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ThemeOption(
                        icon: Icons.nightlight_round,
                        label: 'Dark',
                        selected: settings.themeMode == 'dark',
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setThemeMode('dark'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ThemeOption(
                        icon: Icons.settings_suggest_outlined,
                        label: 'Auto',
                        selected: settings.themeMode == 'system',
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setThemeMode('system'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Auto Refresh Section
          _buildSectionHeader('Auto Refresh'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.refresh),
                  title: Text(
                    'Enable Auto Refresh',
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Automatically refresh data',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: settings.autoRefresh,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setAutoRefresh(value);
                  },
                ),
                if (settings.autoRefresh)
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: Text(
                      'Refresh Interval',
                      style: AppTextStyles.body.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text('${settings.refreshInterval} seconds'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showIntervalPicker(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(
                    'Version',
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '1.0.0',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(
                    'Documentation',
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // Open documentation
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Danger Zone
          _buildSectionHeader('Danger Zone'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    title: Text(
                      'Clear Cache',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Clear all cached data',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () => _showClearCacheDialog(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: Text(
                      'Clear Configuration',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Remove API configuration',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () => _showClearConfigDialog(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showIntervalPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refresh Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [10, 30, 60, 120, 300].map((seconds) {
            return RadioListTile<int>(
              title: Text('$seconds seconds'),
              value: seconds,
              groupValue: ref.read(settingsProvider).refreshInterval,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setRefreshInterval(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will remove all cached log data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: Text('Clear',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showClearConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Configuration?'),
        content: const Text(
          'This will remove your API URL and API key. '
          'You will need to reconfigure the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(apiConfigProvider.notifier).clearConfig();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuration cleared')),
              );
            },
            child: Text('Clear',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final url = _apiUrlController.text.trim();
    final key = _apiKeyController.text.trim();

    if (url.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    await ref.read(apiConfigProvider.notifier).configure(
          baseUrl: url,
          apiKey: key,
        );

    setState(() => _isEditing = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  void _showAddConnectionDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController(text: _apiUrlController.text);
    final keyController = TextEditingController(text: _apiKeyController.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Add Connection', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Production, Staging, Dev',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Service URL',
                  hintText: 'https://your-service.run.app',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your API key',
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final name = nameController.text.trim().isEmpty
                          ? 'Connection'
                          : nameController.text.trim();
                      final url = urlController.text.trim();
                      final key = keyController.text.trim();
                      if (url.isEmpty || key.isEmpty) return;
                      await ref.read(apiConfigProvider.notifier).addProfile(
                            name: name,
                            baseUrl: url,
                            apiKey: key,
                          );
                      final updated = ref.read(apiConfigProvider);
                      setState(() {
                        _apiUrlController.text = updated.baseUrl ?? '';
                        _apiKeyController.text = updated.apiKey ?? '';
                        _isEditing = false;
                      });
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _truncateUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 37)}…';
  }
}

/// One theme choice in the Appearance section's Light/Dark/Auto row.
/// A FittedBox scales icon+label down together if the segment is ever too
/// narrow, rather than wrapping the label onto a second line the way
/// [SegmentedButton] did.
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? c.accent.withValues(alpha: 0.15) : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? c.accent : c.border,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 18, color: selected ? c.accent : c.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: selected ? c.accent : c.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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
