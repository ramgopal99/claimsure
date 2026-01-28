enum ClaimStatus {
  draft,
  submitted,
  approved,
  rejected,
  partiallySettled,
}

extension ClaimStatusX on ClaimStatus {
  String get label {
    switch (this) {
      case ClaimStatus.draft:
        return 'Draft';
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.partiallySettled:
        return 'Partially Settled';
    }
  }
}

