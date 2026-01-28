import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../application/claims_providers.dart';
import '../../domain/models/advance.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/claim.dart';
import '../../domain/models/claim_status.dart';
import '../../domain/models/settlement.dart';

class ClaimFullCreateScreen extends ConsumerStatefulWidget {
  const ClaimFullCreateScreen({super.key});

  @override
  ConsumerState<ClaimFullCreateScreen> createState() =>
      _ClaimFullCreateScreenState();
}

class _ClaimFullCreateScreenState
    extends ConsumerState<ClaimFullCreateScreen> {
  final _patientNameController = TextEditingController();
  final _patientIdController = TextEditingController();
  String _gender = '';
  int _age = 0;
  final _insurerNameController = TextEditingController();
  final _policyNumberController = TextEditingController();
  final _remarksController = TextEditingController();

  DateTime _admissionDate = DateTime.now();
  DateTime _dischargeDate = DateTime.now();

  final _random = Random();

  final List<Bill> _bills = [];
  final List<Advance> _advances = [];
  final List<Settlement> _settlements = [];

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientIdController.dispose();
    _insurerNameController.dispose();
    _policyNumberController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _patientNameController.text.trim().isNotEmpty &&
        _patientIdController.text.trim().isNotEmpty &&
        _gender.trim().isNotEmpty &&
        _age > 0 &&
        _insurerNameController.text.trim().isNotEmpty &&
        _policyNumberController.text.trim().isNotEmpty &&
        !_dischargeDate.isBefore(_admissionDate);
  }

  String _generateClaimId() {
    final number = 1000 + _random.nextInt(9000);
    return 'CLM-$number';
  }

  double get _totalBills =>
      _bills.fold(0.0, (sum, bill) => sum + bill.amount);

  double get _totalAdvances =>
      _advances.fold(0.0, (sum, a) => sum + a.amount);

  double get _totalSettlements =>
      _settlements.fold(0.0, (sum, s) => sum + s.amount);

  double get _pendingAmount =>
      _totalBills - _totalAdvances - _totalSettlements;

  Future<void> _submit() async {
    if (!_isFormValid) {
      setState(() {
        _errorMessage =
            'Please fill all required fields and ensure dates are valid.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final claim = Claim(
        id: _generateClaimId(),
        patientName: _patientNameController.text.trim(),
        patientId: _patientIdController.text.trim(),
        gender: _gender.trim(),
        age: _age,
        admissionDate: _admissionDate,
        dischargeDate: _dischargeDate,
        insurerName: _insurerNameController.text.trim(),
        policyNumber: _policyNumberController.text.trim(),
        status: ClaimStatus.draft,
        bills: List<Bill>.unmodifiable(_bills),
        advances: List<Advance>.unmodifiable(_advances),
        settlements: List<Settlement>.unmodifiable(_settlements),
        createdAt: now,
        updatedAt: now,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      final repo = ref.read(claimsRepositoryProvider);
      await repo.add(claim);

      ref.invalidate(claimsListProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim created successfully.'),
        ),
      );

      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to create claim. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Claim'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient Details',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _patientIdController,
                decoration: const InputDecoration(
                  labelText: 'Patient ID *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender.isEmpty ? null : _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _gender = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Age *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value.trim()) ?? 0;
                        setState(() => _age = parsed);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Insurance Details',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _insurerNameController,
                decoration: const InputDecoration(
                  labelText: 'Insurer Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _policyNumberController,
                decoration: const InputDecoration(
                  labelText: 'Policy Number *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Admission & Discharge',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Admission Date *',
                      date: _admissionDate,
                      onChanged: (d) =>
                          setState(() => _admissionDate = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Discharge Date *',
                      date: _dischargeDate,
                      onChanged: (d) =>
                          setState(() => _dischargeDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Bills',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              _FinancialListSection<Bill>(
                items: _bills,
                emptyLabel:
                    'No bills added yet.\nTap "Add bill" to begin.',
                onAdd: () async {
                  final bill = await _showBillDialog(context);
                  if (bill != null) {
                    setState(() => _bills.add(bill));
                  }
                },
                onEdit: (bill) async {
                  final updated = await _showBillDialog(
                    context,
                    existing: bill,
                  );
                  if (updated != null) {
                    setState(() {
                      final index =
                          _bills.indexWhere((b) => b.id == bill.id);
                      if (index != -1) _bills[index] = updated;
                    });
                  }
                },
                onDelete: (bill) {
                  setState(() {
                    _bills.removeWhere((b) => b.id == bill.id);
                  });
                },
                labelBuilder: (b) =>
                    '${b.description} • ${b.category.label}',
                dateBuilder: (b) => formatDate(b.date),
                amountBuilder: (b) => formatCurrency(b.amount),
              ),
              const SizedBox(height: 24),
              Text(
                'Advances',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              _FinancialListSection<Advance>(
                items: _advances,
                emptyLabel:
                    'No advances recorded yet.\nTap "Add advance" to record one.',
                onAdd: () async {
                  final adv = await _showAdvanceDialog(context);
                  if (adv != null) {
                    setState(() => _advances.add(adv));
                  }
                },
                onEdit: (adv) async {
                  final updated = await _showAdvanceDialog(
                    context,
                    existing: adv,
                  );
                  if (updated != null) {
                    setState(() {
                      final index = _advances
                          .indexWhere((a) => a.id == adv.id);
                      if (index != -1) _advances[index] = updated;
                    });
                  }
                },
                onDelete: (adv) {
                  setState(() {
                    _advances.removeWhere((a) => a.id == adv.id);
                  });
                },
                labelBuilder: (a) => a.description,
                dateBuilder: (a) => formatDate(a.date),
                amountBuilder: (a) => formatCurrency(a.amount),
              ),
              const SizedBox(height: 24),
              Text(
                'Settlements',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              _FinancialListSection<Settlement>(
                items: _settlements,
                emptyLabel:
                    'No settlements recorded yet.\nTap "Add settlement" to record one.',
                onAdd: () async {
                  final set = await _showSettlementDialog(context);
                  if (set != null) {
                    setState(() => _settlements.add(set));
                  }
                },
                onEdit: (set) async {
                  final updated = await _showSettlementDialog(
                    context,
                    existing: set,
                  );
                  if (updated != null) {
                    setState(() {
                      final index = _settlements
                          .indexWhere((s) => s.id == set.id);
                      if (index != -1) _settlements[index] = updated;
                    });
                  }
                },
                onDelete: (set) {
                  setState(() {
                    _settlements.removeWhere((s) => s.id == set.id);
                  });
                },
                labelBuilder: (s) => s.description,
                dateBuilder: (s) => formatDate(s.date),
                amountBuilder: (s) => formatCurrency(s.amount),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Total bills',
                        value: formatCurrency(_totalBills),
                      ),
                      _SummaryRow(
                        label: 'Advances',
                        value: formatCurrency(_totalAdvances),
                      ),
                      _SummaryRow(
                        label: 'Settlements',
                        value: formatCurrency(_totalSettlements),
                      ),
                      _SummaryRow(
                        label: 'Pending',
                        value: formatCurrency(_pendingAmount),
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Claim'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Bill?> _showBillDialog(
    BuildContext context, {
    Bill? existing,
  }) async {
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    BillCategory category = existing?.category ?? BillCategory.other;
    DateTime date = existing?.date ?? DateTime.now();

    return showDialog<Bill?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing == null ? 'Add bill' : 'Edit bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<BillCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: BillCategory.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ),
                      )
                      .toList(),
                  onChanged: (c) {
                    if (c != null) {
                      category = c;
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('Date: ${formatDate(date)}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          date = picked;
                          // force rebuild
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final description = descriptionController.text.trim();
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (description.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a description and a positive amount.',
                      ),
                    ),
                  );
                  return;
                }

                final id = existing?.id ??
                    'bill-${DateTime.now().millisecondsSinceEpoch}';
                Navigator.of(ctx).pop(
                  Bill(
                    id: id,
                    description: description,
                    category: category,
                    date: date,
                    amount: amount,
                  ),
                );
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Future<Advance?> _showAdvanceDialog(
    BuildContext context, {
    Advance? existing,
  }) async {
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    DateTime date = existing?.date ?? DateTime.now();

    return showDialog<Advance?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing == null ? 'Add advance' : 'Edit advance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('Date: ${formatDate(date)}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          date = picked;
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final description = descriptionController.text.trim();
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (description.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a description and a positive amount.',
                      ),
                    ),
                  );
                  return;
                }

                final id = existing?.id ??
                    'adv-${DateTime.now().millisecondsSinceEpoch}';
                Navigator.of(ctx).pop(
                  Advance(
                    id: id,
                    description: description,
                    date: date,
                    amount: amount,
                  ),
                );
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Future<Settlement?> _showSettlementDialog(
    BuildContext context, {
    Settlement? existing,
  }) async {
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    DateTime date = existing?.date ?? DateTime.now();

    return showDialog<Settlement?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title:
              Text(existing == null ? 'Add settlement' : 'Edit settlement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('Date: ${formatDate(date)}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          date = picked;
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final description = descriptionController.text.trim();
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (description.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a description and a positive amount.',
                      ),
                    ),
                  );
                  return;
                }

                final id = existing?.id ??
                    'set-${DateTime.now().millisecondsSinceEpoch}';
                Navigator.of(ctx).pop(
                  Settlement(
                    id: id,
                    description: description,
                    date: date,
                    amount: amount,
                  ),
                );
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = formatDate(date);

    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        alignment: Alignment.centerLeft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            formatted,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FinancialListSection<T> extends StatelessWidget {
  const _FinancialListSection({
    required this.items,
    required this.emptyLabel,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.labelBuilder,
    required this.dateBuilder,
    required this.amountBuilder,
  });

  final List<T> items;
  final String emptyLabel;
  final VoidCallback onAdd;
  final void Function(T) onEdit;
  final void Function(T) onDelete;
  final String Function(T) labelBuilder;
  final String Function(T) dateBuilder;
  final String Function(T) amountBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              emptyLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Column(
            children: items
                .map(
                  (item) => Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      title: Text(labelBuilder(item)),
                      subtitle: Text(dateBuilder(item)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(amountBuilder(item)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit',
                            onPressed: () => onEdit(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete',
                            onPressed: () => onDelete(item),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: highlight ? FontWeight.w600 : null,
              color: highlight ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

