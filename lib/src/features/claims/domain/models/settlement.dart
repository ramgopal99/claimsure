class Settlement {
  Settlement({
    required this.id,
    required this.description,
    required this.date,
    required this.amount,
  });

  final String id;
  final String description;
  final DateTime date;
  final double amount;
}

