import 'advance.dart';
import 'bill.dart';
import 'claim_status.dart';
import 'settlement.dart';

class Claim {
  Claim({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.gender,
    required this.age,
    required this.admissionDate,
    required this.dischargeDate,
    required this.insurerName,
    required this.policyNumber,
    required this.status,
    required this.bills,
    required this.advances,
    required this.settlements,
    required this.createdAt,
    required this.updatedAt,
    this.remarks,
  });

  final String id;
  final String patientName;
  final String patientId;
  final String gender;
  final int age;
  final DateTime admissionDate;
  final DateTime dischargeDate;
  final String insurerName;
  final String policyNumber;
  final ClaimStatus status;
  final List<Bill> bills;
  final List<Advance> advances;
  final List<Settlement> settlements;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remarks;

  double get totalBills =>
      bills.fold(0.0, (sum, bill) => sum + bill.amount);

  double get totalAdvances =>
      advances.fold(0.0, (sum, advance) => sum + advance.amount);

  double get totalSettlements =>
      settlements.fold(0.0, (sum, settlement) => sum + settlement.amount);

  double get pendingAmount =>
      totalBills - totalAdvances - totalSettlements;

  bool get isEditable =>
      status == ClaimStatus.draft || status == ClaimStatus.rejected;

  Claim copyWith({
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
    List<Bill>? bills,
    List<Advance>? advances,
    List<Settlement>? settlements,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remarks,
  }) {
    return Claim(
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
      bills: bills ?? this.bills,
      advances: advances ?? this.advances,
      settlements: settlements ?? this.settlements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remarks: remarks ?? this.remarks,
    );
  }
}

