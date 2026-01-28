import '../domain/models/claim.dart';

abstract class ClaimsRepository {
  Future<List<Claim>> getAll();
  Future<Claim?> getById(String id);
  Future<void> add(Claim claim);
  Future<void> update(Claim claim);
  Future<void> remove(String id);
}
