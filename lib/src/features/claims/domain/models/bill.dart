enum BillCategory {
  room,
  surgery,
  diagnostics,
  pharmacy,
  other,
}

extension BillCategoryX on BillCategory {
  String get label {
    switch (this) {
      case BillCategory.room:
        return 'Room';
      case BillCategory.surgery:
        return 'Surgery';
      case BillCategory.diagnostics:
        return 'Diagnostics';
      case BillCategory.pharmacy:
        return 'Pharmacy';
      case BillCategory.other:
        return 'Other';
    }
  }
}

class Bill {
  Bill({
    required this.id,
    required this.description,
    required this.category,
    required this.date,
    required this.amount,
  });

  final String id;
  final String description;
  final BillCategory category;
  final DateTime date;
  final double amount;
}

