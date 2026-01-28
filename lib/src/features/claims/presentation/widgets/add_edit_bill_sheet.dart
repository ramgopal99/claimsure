import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/claims_providers.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/claim.dart';
import '../../../../core/utils/formatters.dart';

void showAddEditBillSheet(
  BuildContext context,
  WidgetRef ref, {
  required Claim claim,
  required String claimId,
  Bill? existingBill,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AddEditBillSheetContent(
      claim: claim,
      claimId: claimId,
      existingBill: existingBill,
      ref: ref,
    ),
  );
}

class _AddEditBillSheetContent extends ConsumerStatefulWidget {
  const _AddEditBillSheetContent({
    required this.claim,
    required this.claimId,
    required this.ref,
    this.existingBill,
  });

  final Claim claim;
  final String claimId;
  final WidgetRef ref;
  final Bill? existingBill;

  @override
  ConsumerState<_AddEditBillSheetContent> createState() =>
      _AddEditBillSheetContentState();
}

class _AddEditBillSheetContentState
    extends ConsumerState<_AddEditBillSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late BillCategory _category;
  late DateTime _date;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEdit => widget.existingBill != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBill;
    _descriptionController = TextEditingController(text: b?.description ?? '');
    _amountController = TextEditingController(
      text: b != null ? b.amount.toString() : '',
    );
    _category = b?.category ?? BillCategory.other;
    _date = b?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final amountStr = _amountController.text.trim();
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid amount.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(claimsRepositoryProvider);
      List<Bill> newBills;
      if (_isEdit) {
        final id = widget.existingBill!.id;
        newBills = widget.claim.bills
            .map((b) => b.id == id
                ? Bill(
                    id: id,
                    description: description,
                    category: _category,
                    date: _date,
                    amount: amount,
                  )
                : b)
            .toList();
      } else {
        final id =
            'bill-${widget.claimId}-${DateTime.now().millisecondsSinceEpoch}';
        newBills = [
          ...widget.claim.bills,
          Bill(
            id: id,
            description: description,
            category: _category,
            date: _date,
            amount: amount,
          ),
        ];
      }

      final updated = widget.claim.copyWith(
        bills: newBills,
        updatedAt: DateTime.now(),
      );
      await repo.update(updated);

      ref.invalidate(selectedClaimProvider(widget.claimId));
      ref.invalidate(claimsListProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Bill updated' : 'Bill added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'Edit bill' : 'Add bill',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. General ward - 5 days',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BillCategory>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: BillCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  child: Text(formatDate(_date)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: '0',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter amount';
                  }
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Update bill' : 'Add bill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
