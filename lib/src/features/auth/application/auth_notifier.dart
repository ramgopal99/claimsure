import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user.dart';

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null);

  void login(String email, String displayName) {
    state = User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName.isNotEmpty ? displayName : email.split('@').first,
    );
  }

  void updateProfile(String displayName, String email) {
    if (state == null) return;
    state = User(
      id: state!.id,
      email: email.trim(),
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : email.split('@').first,
      avatarUrl: state!.avatarUrl,
    );
  }

  void logout() {
    state = null;
  }
}
