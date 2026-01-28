import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../application/claims_providers.dart';
import '../widgets/claim_card.dart';
import '../widgets/empty_state.dart';

class ClaimsDashboardScreen extends ConsumerWidget {
  const ClaimsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncClaims = ref.watch(claimsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Claims Dashboard'),
      ),
      body: SafeArea(
        child: asyncClaims.when(
          data: (claims) {
            if (claims.isEmpty) {
              return EmptyState(
                icon: Icons.folder_open,
                message:
                    'No claims have been created yet.\nStart by registering a new hospital claim.',
                actionLabel: 'Create first claim',
                onAction: () => context.pushNamed(routeNewClaim),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.refresh(claimsListProvider.future),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 96,
                ),
                itemCount: claims.length,
                itemBuilder: (context, index) {
                  final claim = claims[index];
                  return ClaimCard(claim: claim);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            message:
                'Unable to load claims at the moment.\nPlease check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.refresh(claimsListProvider),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushNamed(routeNewClaim);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Claim'),
      ),
    );
  }
}

