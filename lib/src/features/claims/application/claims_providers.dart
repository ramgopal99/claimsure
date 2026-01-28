import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/claims_repository.dart';
import '../data/claims_repository_in_memory.dart';
import '../domain/models/claim.dart';

final claimsRepositoryProvider = Provider<ClaimsRepository>((ref) {
  return ClaimsRepositoryInMemory();
});

final claimsListProvider = FutureProvider<List<Claim>>((ref) async {
  final repo = ref.watch(claimsRepositoryProvider);
  return repo.getAll();
});

final selectedClaimProvider =
    FutureProvider.family<Claim?, String>((ref, id) async {
  final repo = ref.watch(claimsRepositoryProvider);
  return repo.getById(id);
});
