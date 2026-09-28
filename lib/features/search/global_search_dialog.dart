import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/portfolio_providers.dart';

class GlobalSearchDialog extends ConsumerStatefulWidget {
  const GlobalSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const GlobalSearchDialog(),
    );
  }

  @override
  ConsumerState<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(publishedProjectsProvider).valueOrNull ?? [];
    final services = ref.watch(publishedServicesProvider).valueOrNull ?? [];
    final certs = ref.watch(publishedCertificatesProvider).valueOrNull ?? [];
    final q = _query.trim().toLowerCase();

    final filteredProjects = q.isEmpty
        ? []
        : projects
            .where((p) =>
                p.title.toLowerCase().contains(q) ||
                p.shortDescription.toLowerCase().contains(q) ||
                p.technologies.any((t) => t.toLowerCase().contains(q)))
            .toList();

    final filteredServices = q.isEmpty
        ? []
        : services
            .where((s) =>
                s.title.toLowerCase().contains(q) ||
                s.shortDescription.toLowerCase().contains(q) ||
                s.technologies.any((t) => t.toLowerCase().contains(q)))
            .toList();

    final filteredCerts = q.isEmpty
        ? []
        : certs
            .where((c) =>
                c.title.toLowerCase().contains(q) ||
                c.issuer.toLowerCase().contains(q) ||
                c.skills.any((s) => s.toLowerCase().contains(q)))
            .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 600),
        // Material (not a decorated Container) so ListTile ink splashes render
        // and the framework's "invisible background" assertion is satisfied.
        child: Material(
          color: AppColors.darkSurface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            side: const BorderSide(color: AppColors.darkCardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSearchInput(),
              const Divider(height: 1, color: AppColors.darkCardBorder),
              Flexible(
                child: _buildResults(
                  filteredProjects,
                  filteredServices,
                  filteredCerts,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.accentCyan),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Search projects, services, certs...',
                hintStyle:
                    TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResults(List projects, List services, List certs) {
    if (_query.isEmpty) {
      return const Center(
        child: Text('Type to search across portfolio...',
            style: TextStyle(color: AppColors.textSecondaryDark)),
      );
    }
    if (projects.isEmpty && services.isEmpty && certs.isEmpty) {
      return const Center(
        child: Text('No matching entries found.',
            style: TextStyle(color: AppColors.textSecondaryDark)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (projects.isNotEmpty) ...[
          _header('PROJECTS'),
          ...projects.map((p) => ListTile(
                leading: const Icon(Icons.rocket_launch,
                    color: AppColors.accentCyan, size: 20),
                title: Text(p.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(p.shortDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondaryDark, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/projects/${p.id}');
                },
              )),
          const SizedBox(height: 12),
        ],
        if (services.isNotEmpty) ...[
          _header('SERVICES'),
          ...services.map((s) => ListTile(
                leading: const Icon(Icons.design_services,
                    color: AppColors.primary, size: 20),
                title: Text(s.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(s.shortDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondaryDark, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/services/${s.id}');
                },
              )),
          const SizedBox(height: 12),
        ],
        if (certs.isNotEmpty) ...[
          _header('CERTIFICATES'),
          ...certs.map((c) => ListTile(
                leading: const Icon(Icons.verified,
                    color: AppColors.accentCyan, size: 20),
                title: Text(c.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(c.issuer,
                    style: const TextStyle(
                        color: AppColors.textSecondaryDark, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/certificates');
                },
              )),
        ],
      ],
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.accentCyan,
            letterSpacing: 1),
      ),
    );
  }
}

