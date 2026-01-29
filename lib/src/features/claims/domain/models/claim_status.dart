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

  /// Short label for chart axes (avoids overlap on mobile).
  String get shortLabel {
    switch (this) {
      case ClaimStatus.draft:
        return 'Draft';
      case ClaimStatus.submitted:
        return 'Sub';
      case ClaimStatus.approved:
        return 'App';
      case ClaimStatus.rejected:
        return 'Rej';
      case ClaimStatus.partiallySettled:
        return 'Part';
    }
  }
}

