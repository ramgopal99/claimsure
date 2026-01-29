import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../application/auth_providers.dart';
import '../../../claims/application/claims_providers.dart';
import '../../../claims/domain/models/claim.dart';
import '../../../claims/domain/models/claim_status.dart';
import '../../../claims/presentation/widgets/claim_card.dart';
import '../../../claims/presentation/widgets/empty_state.dart';
import '../../../claims/presentation/screens/claims_analysis_screen.dart';
import 'profile_screen.dart';

class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  ConsumerState<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.login_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please sign in to continue',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.goNamed(routeLogin),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claimsure by MEDOC HEALTH'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Claims', icon: Icon(Icons.folder_open_rounded)),
            Tab(text: 'Analysis', icon: Icon(Icons.analytics_outlined)),
            Tab(text: 'Settings', icon: Icon(Icons.settings_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ClaimsTab(),
          ClaimsAnalysisScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed(routeNewClaim),
              icon: const Icon(Icons.add),
              label: const Text('New Claim'),
            )
          : null,
    );
  }
}

/// Claims tab content: search/filter bar + list of claims or empty state.
class _ClaimsTab extends ConsumerStatefulWidget {
  const _ClaimsTab();

  @override
  ConsumerState<_ClaimsTab> createState() => _ClaimsTabState();
}

class _ClaimsTabState extends ConsumerState<_ClaimsTab> {
  final _searchController = TextEditingController();
  ClaimStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Claim> _filterAndSort(List<Claim> claims) {
    var list = List<Claim>.from(claims);
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        return c.patientName.toLowerCase().contains(q) ||
            c.insurerName.toLowerCase().contains(q) ||
            c.id.toLowerCase().contains(q);
      }).toList();
    }
    if (_statusFilter != null) {
      list = list.where((c) => c.status == _statusFilter).toList();
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final asyncClaims = ref.watch(claimsListProvider);

    return asyncClaims.when(
      data: (claims) {
        final filtered = _filterAndSort(claims);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search patient, insurer, or claim ID…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _statusFilter == null,
                          onTap: () {
                            setState(() => _statusFilter = null);
                          },
                        ),
                        ...ClaimStatus.values.map(
                          (s) => _FilterChip(
                            label: s.label,
                            selected: _statusFilter == s,
                            onTap: () {
                              setState(() => _statusFilter = _statusFilter == s
                                  ? null
                                  : s);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: claims.isEmpty
                          ? Icons.folder_open_rounded
                          : Icons.filter_list_off_rounded,
                      message: claims.isEmpty
                          ? 'No claims yet.\nCreate your first hospital claim to get started.'
                          : 'No claims match your search or filter.',
                      actionLabel: claims.isEmpty ? 'New Claim' : 'Clear filters',
                      onAction: () {
                        if (claims.isEmpty) {
                          context.pushNamed(routeNewClaim);
                        } else {
                          _searchController.clear();
                          setState(() => _statusFilter = null);
                        }
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final claim = filtered[index];
                        return ClaimCard(claim: claim);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        message:
            'Unable to load claims.\nCheck your connection and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.refresh(claimsListProvider),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
