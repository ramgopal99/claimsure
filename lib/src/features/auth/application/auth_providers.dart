import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user.dart';
import 'auth_notifier.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, User?>((ref) => AuthNotifier());
