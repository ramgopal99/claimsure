import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/claims_repository.dart';
import '../domain/models/advance.dart';
import '../domain/models/bill.dart';
import '../domain/models/claim.dart';
import '../domain/models/claim_status.dart';
import '../domain/models/settlement.dart';
import 'claims_providers.dart';

class ClaimFormState {
  ClaimFormState({
    this.id,
    this.patientName = '',
    this.patientId = '',
    this.gender = '',
    this.age = 0,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    this.insurerName = '',
    this.policyNumber = '',
    this.status = ClaimStatus.draft,
    this.remarks = '',
    this.isSaving = false,
    this.errorMessage,
  })  : admissionDate = admissionDate ?? DateTime.now(),
        dischargeDate = dischargeDate ?? DateTime.now();

  final String? id;
  final String patientName;
  final String patientId;
  final String gender;
  final int age;
  final DateTime admissionDate;
  final DateTime dischargeDate;
  final String insurerName;
  final String policyNumber;
  final ClaimStatus status;
  final String remarks;
  final bool isSaving;
  final String? errorMessage;

  bool get isNew => id == null;

  bool get isValid {
    return patientName.trim().isNotEmpty &&
        patientId.trim().isNotEmpty &&
        gender.trim().isNotEmpty &&
        age > 0 &&
        insurerName.trim().isNotEmpty &&
        policyNumber.trim().isNotEmpty &&
        !dischargeDate.isBefore(admissionDate);
  }

  ClaimFormState copyWith({
    String? id,
    String? patientName,
    String? patientId,
    String? gender,
    int? age,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    String? insurerName,
    String? policyNumber,
    ClaimStatus? status,
    String? remarks,
    bool? isSaving,
    String? errorMessage,
  }) {
    return ClaimFormState(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientId: patientId ?? this.patientId,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      admissionDate: admissionDate ?? this.admissionDate,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      insurerName: insurerName ?? this.insurerName,
      policyNumber: policyNumber ?? this.policyNumber,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class ClaimFormNotifier extends StateNotifier<ClaimFormState> {
  ClaimFormNotifier({
    required ClaimsRepository repository,
    Claim? initialClaim,
  })  : _repository = repository,
        _random = Random(),
        _initialClaim = initialClaim,
        super(
          initialClaim != null
              ? ClaimFormState(
                  id: initialClaim.id,
                  patientName: initialClaim.patientName,
                  patientId: initialClaim.patientId,
                  gender: initialClaim.gender,
                  age: initialClaim.age,
                  admissionDate: initialClaim.admissionDate,
                  dischargeDate: initialClaim.dischargeDate,
                  insurerName: initialClaim.insurerName,
                  policyNumber: initialClaim.policyNumber,
                  status: initialClaim.status,
                  remarks: initialClaim.remarks ?? '',
                )
              : ClaimFormState(),
        );

  final ClaimsRepository _repository;
  final Random _random;
  final Claim? _initialClaim;

  void updatePatientName(String value) {
    state = state.copyWith(patientName: value);
  }

  void updatePatientId(String value) {
    state = state.copyWith(patientId: value);
  }

  void updateGender(String value) {
    state = state.copyWith(gender: value);
  }

  void updateAge(int value) {
    state = state.copyWith(age: value);
  }

  void updateInsurerName(String value) {
    state = state.copyWith(insurerName: value);
  }

  void updatePolicyNumber(String value) {
    state = state.copyWith(policyNumber: value);
  }

  void updateAdmissionDate(DateTime value) {
    state = state.copyWith(admissionDate: value);
  }

  void updateDischargeDate(DateTime value) {
    state = state.copyWith(dischargeDate: value);
  }

  void updateRemarks(String value) {
    state = state.copyWith(remarks: value);
  }

  Future<Claim?> saveDraft() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage:
            'Please fill all required fields and ensure dates are valid.',
      );
      return null;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final now = DateTime.now();

      final bills = state.isNew ? <Bill>[] : _initialClaim!.bills;
      final advances = state.isNew ? <Advance>[] : _initialClaim!.advances;
      final settlements =
          state.isNew ? <Settlement>[] : _initialClaim!.settlements;
      final createdAt = state.isNew ? now : _initialClaim!.createdAt;

      final claim = Claim(
        id: state.id ?? _generateClaimId(),
        patientName: state.patientName.trim(),
        patientId: state.patientId.trim(),
        gender: state.gender.trim(),
        age: state.age,
        admissionDate: state.admissionDate,
        dischargeDate: state.dischargeDate,
        insurerName: state.insurerName.trim(),
        policyNumber: state.policyNumber.trim(),
        status: ClaimStatus.draft,
        bills: bills,
        advances: advances,
        settlements: settlements,
        createdAt: createdAt,
        updatedAt: now,
        remarks: state.remarks.trim().isEmpty ? null : state.remarks.trim(),
      );

      if (state.isNew) {
        await _repository.add(claim);
      } else {
        await _repository.update(claim);
      }

      final saved = claim;
      state = state.copyWith(
        id: saved.id,
        isSaving: false,
        errorMessage: null,
      );
      return saved;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save claim. Please try again.',
      );
      return null;
    }
  }

  String _generateClaimId() {
    final number = 1000 + _random.nextInt(9000);
    return 'CLM-$number';
  }
}

final claimFormNotifierProvider =
    StateNotifierProvider.autoDispose.family<ClaimFormNotifier, ClaimFormState,
        Claim?>(
  (ref, initialClaim) {
    final repository = ref.watch(claimsRepositoryProvider);
    return ClaimFormNotifier(
      repository: repository,
      initialClaim: initialClaim,
    );
  },
);

