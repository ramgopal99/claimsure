import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user.dart';
import 'auth_notifier.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, User?>((ref) => AuthNotifier());

/// Notifications on/off (in-memory; add shared_preferences later for persistence).
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
