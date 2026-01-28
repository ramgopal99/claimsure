import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/claims_repository.dart';
import '../domain/models/claim.dart';
import '../domain/models/claim_status.dart';
import 'claims_providers.dart';

/// Result of a workflow action. [error] is null on success.
typedef WorkflowResult = ({String? error});

/// Enforces claim status transition rules and updates the repository.
/// Surfaces friendly error messages when a transition is invalid.
class ClaimWorkflowNotifier {
  ClaimWorkflowNotifier({
    required Ref ref,
    required ClaimsRepository repository,
  })  : _ref = ref,
        _repository = repository;

  final Ref _ref;
  final ClaimsRepository _repository;

  /// Draft → Submitted. Requires at least one bill and patient basic info.
  Future<WorkflowResult> submit(String claimId) async {
    final claim = await _repository.getById(claimId);
    if (claim == null) {
      return (error: 'Claim not found.');
    }
    if (claim.status != ClaimStatus.draft) {
      return (error: 'Only draft claims can be submitted.');
    }

    if (claim.bills.isEmpty) {
      return (error: 'Add at least one bill before submitting.');
    }
    final patientOk = _hasPatientBasicInfo(claim);
    if (!patientOk) {
      return (error: 'Fill patient details, insurer, policy, and dates before submitting.');
    }

    final updated = claim.copyWith(
      status: ClaimStatus.submitted,
      updatedAt: DateTime.now(),
    );
    await _repository.update(updated);
    _invalidate(claimId);
    return (error: null);
  }

  /// Submitted → Approved.
  Future<WorkflowResult> approve(String claimId) async {
    final claim = await _repository.getById(claimId);
    if (claim == null) {
      return (error: 'Claim not found.');
    }
    if (claim.status != ClaimStatus.submitted) {
      return (error: 'Only submitted claims can be approved.');
    }

    final updated = claim.copyWith(
      status: ClaimStatus.approved,
      updatedAt: DateTime.now(),
    );
    await _repository.update(updated);
    _invalidate(claimId);
    return (error: null);
  }

  /// Submitted → Rejected.
  Future<WorkflowResult> reject(String claimId) async {
    final claim = await _repository.getById(claimId);
    if (claim == null) {
      return (error: 'Claim not found.');
    }
    if (claim.status != ClaimStatus.submitted) {
      return (error: 'Only submitted claims can be rejected.');
    }

    final updated = claim.copyWith(
      status: ClaimStatus.rejected,
      updatedAt: DateTime.now(),
    );
    await _repository.update(updated);
    _invalidate(claimId);
    return (error: null);
  }

  /// Submitted → PartiallySettled.
  Future<WorkflowResult> markPartiallySettled(String claimId) async {
    final claim = await _repository.getById(claimId);
    if (claim == null) {
      return (error: 'Claim not found.');
    }
    if (claim.status != ClaimStatus.submitted) {
      return (error: 'Only submitted claims can be marked partially settled.');
    }

    final updated = claim.copyWith(
      status: ClaimStatus.partiallySettled,
      updatedAt: DateTime.now(),
    );
    await _repository.update(updated);
    _invalidate(claimId);
    return (error: null);
  }

  bool _hasPatientBasicInfo(Claim c) {
    return c.patientName.trim().isNotEmpty &&
        c.patientId.trim().isNotEmpty &&
        c.gender.trim().isNotEmpty &&
        c.age > 0 &&
        c.insurerName.trim().isNotEmpty &&
        c.policyNumber.trim().isNotEmpty &&
        !c.dischargeDate.isBefore(c.admissionDate);
  }

  void _invalidate(String claimId) {
    _ref.invalidate(selectedClaimProvider(claimId));
    _ref.invalidate(claimsListProvider);
  }
}

final claimWorkflowProvider = Provider<ClaimWorkflowNotifier>((ref) {
  return ClaimWorkflowNotifier(
    ref: ref,
    repository: ref.watch(claimsRepositoryProvider),
  );
});
