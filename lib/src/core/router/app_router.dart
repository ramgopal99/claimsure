import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/about_screen.dart';
import '../../features/auth/presentation/screens/help_support_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/main_dashboard_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/claims/presentation/screens/claim_detail_screen.dart';
import '../../features/claims/presentation/screens/claim_edit_screen.dart';
import '../../features/claims/presentation/screens/claim_full_create_screen.dart';
import '../constants/route_names.dart';
import '../../features/claims/domain/models/claim.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: routeSplash,
        pageBuilder: (context, state) => const MaterialPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: routeLogin,
        pageBuilder: (context, state) => const MaterialPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        name: routeDashboard,
        pageBuilder: (context, state) => const MaterialPage(
          child: MainDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/help',
        name: routeHelpSupport,
        pageBuilder: (context, state) => MaterialPage(
          key: const ValueKey('HelpSupport'),
          child: const HelpSupportScreen(),
        ),
      ),
      GoRoute(
        path: '/about',
        name: routeAbout,
        pageBuilder: (context, state) => MaterialPage(
          key: const ValueKey('About'),
          child: const AboutScreen(),
        ),
      ),
      GoRoute(
        path: '/claims/new',
        name: routeNewClaim,
        pageBuilder: (context, state) => const MaterialPage(
          child: ClaimFullCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/claims/:id/edit',
        name: routeEditClaim,
        pageBuilder: (context, state) {
          final claim = state.extra as Claim?;
          return MaterialPage(
            child: ClaimEditScreen(initialClaim: claim),
          );
        },
      ),
      GoRoute(
        path: '/claims/:id',
        name: routeClaimDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage(
            child: ClaimDetailScreen(claimId: id),
          );
        },
      ),
    ],
  );
});
