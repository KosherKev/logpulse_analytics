import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/service_providers.dart';

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
        padding: const EdgeInsets.all(16),
        children: [
          // API Configuration Section
          _buildSectionHeader('API Configuration'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  if (!_isEditing && !apiConfig.isConfigured)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: const Text('Configure API'),
                    )
                  else if (!_isEditing)
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('API Configured'),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _isEditing = true),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  subtitle: Text(_getThemeLabel(settings.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemePicker(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Auto Refresh Section
          _buildSectionHeader('Auto Refresh'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.refresh),
                  title: const Text('Enable Auto Refresh'),
                  subtitle: const Text('Automatically refresh data'),
                  value: settings.autoRefresh,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setAutoRefresh(value);
                  },
                ),
                if (settings.autoRefresh)
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Refresh Interval'),
                    subtitle: Text('${settings.refreshInterval} seconds'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showIntervalPicker(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Documentation'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // Open documentation
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionHeader('Danger Zone'),
          Card(
            color: Colors.red[50],
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Clear Cache',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Clear all cached data'),
                  onTap: () => _showClearCacheDialog(),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Clear Configuration',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Remove API configuration'),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
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
}
