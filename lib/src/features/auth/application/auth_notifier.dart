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

  void logout() {
    state = null;
  }
}
