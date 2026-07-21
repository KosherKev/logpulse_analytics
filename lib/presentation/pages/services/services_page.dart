import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/services_provider.dart';
import '../../widgets/services/service_catalog_row.dart';
import '../service_details/service_details_page.dart';

/// Dedicated Services catalog tab — list from `GET /api/v1/services`.
class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(servicesListProvider.notifier).load(),
    );
  }

  Future<void> _refresh() => ref.read(servicesListProvider.notifier).load();

  void _openDetail(String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailsPage(serviceName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = ref.watch(servicesListProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          'Services',
          style: AppTextStyles.h1.copyWith(color: c.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: c.textSecondary),
            onPressed: _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(state, c),
    );
  }

  Widget _buildBody(ServicesListState state, AppColorTokens c) {
    if (state.isLoading && state.services.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error!,
                style: AppTextStyles.body.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.services.isEmpty) {
      return Center(
        child: Text(
          'No services reporting yet',
          style: AppTextStyles.body.copyWith(color: c.textTertiary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: state.services.length,
        itemBuilder: (context, index) {
          final s = state.services[index];
          return ServiceCatalogRow(
            service: s,
            onTap: () => _openDetail(s.name),
          );
        },
      ),
    );
  }
}
