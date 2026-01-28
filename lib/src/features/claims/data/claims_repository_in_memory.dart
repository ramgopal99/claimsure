import '../domain/models/advance.dart';
import '../domain/models/bill.dart';
import '../domain/models/claim.dart';
import '../domain/models/claim_status.dart';
import '../domain/models/settlement.dart';
import 'claims_repository.dart';

class ClaimsRepositoryInMemory implements ClaimsRepository {
  ClaimsRepositoryInMemory() {
    _claims.addAll(_seedClaims);
  }

  final Map<String, Claim> _claims = {};

  static final Map<String, Claim> _seedClaims = {
    'clm-001': Claim(
      id: 'clm-001',
      patientName: 'John Doe',
      patientId: 'PID-1001',
      gender: 'Male',
      age: 45,
      admissionDate: DateTime(2025, 1, 10),
      dischargeDate: DateTime(2025, 1, 18),
      insurerName: 'HealthFirst Insurance',
      policyNumber: 'HF-789456',
      status: ClaimStatus.submitted,
      bills: [
        Bill(
          id: 'bill-001-a',
          description: 'General ward - 5 days',
          category: BillCategory.room,
          date: DateTime(2025, 1, 12),
          amount: 15000,
        ),
        Bill(
          id: 'bill-001-b',
          description: 'Blood panel & ECG',
          category: BillCategory.diagnostics,
          date: DateTime(2025, 1, 11),
          amount: 3200,
        ),
      ],
      advances: [
        Advance(
          id: 'adv-001',
          description: 'Initial advance',
          date: DateTime(2025, 1, 14),
          amount: 8000,
        ),
      ],
      settlements: [],
      createdAt: DateTime(2025, 1, 15),
      updatedAt: DateTime(2025, 1, 22),
      remarks: null,
    ),
    'clm-002': Claim(
      id: 'clm-002',
      patientName: 'Jane Smith',
      patientId: 'PID-1002',
      gender: 'Female',
      age: 38,
      admissionDate: DateTime(2025, 1, 5),
      dischargeDate: DateTime(2025, 1, 12),
      insurerName: 'MediCare Plus',
      policyNumber: 'MC-112233',
      status: ClaimStatus.draft,
      bills: [
        Bill(
          id: 'bill-002-a',
          description: 'ICU - 2 days',
          category: BillCategory.room,
          date: DateTime(2025, 1, 6),
          amount: 24000,
        ),
      ],
      advances: [],
      settlements: [],
      createdAt: DateTime(2025, 1, 8),
      updatedAt: DateTime(2025, 1, 20),
      remarks: null,
    ),
    'clm-003': Claim(
      id: 'clm-003',
      patientName: 'Robert Wilson',
      patientId: 'PID-1003',
      gender: 'Male',
      age: 52,
      admissionDate: DateTime(2025, 1, 2),
      dischargeDate: DateTime(2025, 1, 8),
      insurerName: 'HealthFirst Insurance',
      policyNumber: 'HF-654321',
      status: ClaimStatus.approved,
      bills: [
        Bill(
          id: 'bill-003-a',
          description: 'Surgery - Appendectomy',
          category: BillCategory.surgery,
          date: DateTime(2025, 1, 3),
          amount: 45000,
        ),
        Bill(
          id: 'bill-003-b',
          description: 'Post-op pharmacy',
          category: BillCategory.pharmacy,
          date: DateTime(2025, 1, 5),
          amount: 2100,
        ),
      ],
      advances: [
        Advance(
          id: 'adv-003',
          description: 'Advance against claim',
          date: DateTime(2025, 1, 6),
          amount: 20000,
        ),
      ],
      settlements: [
        Settlement(
          id: 'set-003',
          description: 'Full settlement',
          date: DateTime(2025, 1, 25),
          amount: 27100,
        ),
      ],
      createdAt: DateTime(2025, 1, 4),
      updatedAt: DateTime(2025, 1, 26),
      remarks: null,
    ),
  };

  @override
  Future<List<Claim>> getAll() async {
    final list = _claims.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<Claim?> getById(String id) async => _claims[id];

  @override
  Future<void> add(Claim claim) async {
    _claims[claim.id] = claim;
  }

  @override
  Future<void> update(Claim claim) async {
    _claims[claim.id] = claim;
  }

  @override
  Future<void> remove(String id) async {
    _claims.remove(id);
  }
}
