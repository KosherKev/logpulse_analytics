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
  String? _selectedProfileId;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final apiConfig = ref.read(apiConfigProvider);
    _selectedProfileId = apiConfig.activeProfileId;
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
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isActive
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                              ),
                              title: Text(profile.name),
                              subtitle: Text(
                                profile.baseUrl,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              onTap: () async {
                                await ref
                                    .read(apiConfigProvider.notifier)
                                    .setActiveProfile(profile.id);
                                setState(() {
                                  _selectedProfileId = profile.id;
                                  _apiUrlController.text = profile.baseUrl;
                                  _apiKeyController.text = profile.apiKey;
                                  _isEditing = false;
                                });
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await ref
                                      .read(apiConfigProvider.notifier)
                                      .removeProfile(profile.id);
                                  final updated =
                                      ref.read(apiConfigProvider);
                                  setState(() {
                                    _selectedProfileId =
                                        updated.activeProfileId;
                                    _apiUrlController.text =
                                        updated.baseUrl ?? '';
                                    _apiKeyController.text =
                                        updated.apiKey ?? '';
                                    _isEditing = false;
                                  });
                                },
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
                  Row(
                    children: [
                      if (!_isEditing && !apiConfig.isConfigured)
                        ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit),
                          label: const Text('Configure API'),
                        )
                      else if (!_isEditing)
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green),
                            const SizedBox(width: AppSpacing.sm),
                            const Text('API Configured'),
                            const SizedBox(width: AppSpacing.sm),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isEditing = true),
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
                      const Spacer(),
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: Text(
                    'Theme',
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(_getThemeLabel(settings.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemePicker(),
                ),
              ],
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
            color: AppColors.errorLight,
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: AppColors.error),
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
                  leading:
                      const Icon(Icons.logout, color: AppColors.error),
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.overline.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  String _getThemeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
      default:
        return 'System Default';
    }
  }

  void _showThemePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: ref.read(settingsProvider).themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: ref.read(settingsProvider).themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'system',
              groupValue: ref.read(settingsProvider).themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
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
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
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
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Connection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim().isEmpty
                    ? 'Connection'
                    : nameController.text.trim();
                final url = urlController.text.trim();
                final key = keyController.text.trim();

                if (url.isEmpty || key.isEmpty) {
                  return;
                }

                await ref.read(apiConfigProvider.notifier).addProfile(
                      name: name,
                      baseUrl: url,
                      apiKey: key,
                    );

                final updated = ref.read(apiConfigProvider);
                setState(() {
                  _selectedProfileId = updated.activeProfileId;
                  _apiUrlController.text = updated.baseUrl ?? '';
                  _apiKeyController.text = updated.apiKey ?? '';
                  _isEditing = false;
                });

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
