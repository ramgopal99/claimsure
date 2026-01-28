import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/claim_workflow_notifier.dart';
import '../../application/claims_providers.dart';
import '../../domain/models/advance.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/claim.dart';
import '../../domain/models/claim_status.dart';
import '../../domain/models/settlement.dart';
import '../widgets/add_edit_bill_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';

class ClaimDetailScreen extends ConsumerWidget {
  const ClaimDetailScreen({super.key, required this.claimId});

  final String claimId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncClaim = ref.watch(selectedClaimProvider(claimId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Claim Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: asyncClaim.when(
            data: (claim) {
              if (claim == null || !claim.isEditable) return const [];
              return [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit claim',
                  onPressed: () {
                    context.pushNamed(
                      routeEditClaim,
                      pathParameters: {'id': claim.id},
                      extra: claim,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete claim',
                  onPressed: () =>
                      _confirmDeleteClaim(context, ref, claim),
                ),
              ];
            },
            loading: () => const [],
            error: (e, st) => const [],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Summary'),
            ],
          ),
        ),
        body: SafeArea(
          child: asyncClaim.when(
            data: (claim) {
              if (claim == null) {
                return const EmptyState(
                  icon: Icons.search_off,
                  message:
                      'We could not find this claim.\nIt may have been removed.',
                );
              }
              return TabBarView(
                children: [
                  _ClaimDetailContent(claim: claim),
                  _ClaimSummaryTab(claim: claim),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const EmptyState(
              icon: Icons.error_outline,
              message:
                  'Something went wrong while loading the claim.\nPlease try again.',
            ),
          ),
        ),
      ),
    );
  }
}

class _ClaimDetailContent extends ConsumerWidget {
  const _ClaimDetailContent({required this.claim});

  final Claim claim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  claim.patientName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusChip(status: claim.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Claim #${claim.id}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _WorkflowActionsBar(claim: claim),
          const SizedBox(height: 24),
          _Section(title: 'Patient', children: [
            _RowLabel('Name', claim.patientName),
            _RowLabel('ID', claim.patientId),
            _RowLabel('Gender', claim.gender),
            _RowLabel('Age', '${claim.age}'),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Insurance', children: [
            _RowLabel('Insurer', claim.insurerName),
            _RowLabel('Policy', claim.policyNumber),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Dates', children: [
            _RowLabel('Admission', formatDate(claim.admissionDate)),
            _RowLabel('Discharge', formatDate(claim.dischargeDate)),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Amounts', children: [
            _RowLabel('Total bills', formatCurrency(claim.totalBills)),
            _RowLabel('Advances', formatCurrency(claim.totalAdvances)),
            _RowLabel('Settlements', formatCurrency(claim.totalSettlements)),
            _RowLabel(
              'Pending',
              formatCurrency(claim.pendingAmount),
              highlight: true,
            ),
          ]),
          const SizedBox(height: 24),
          _FinancialRecordsSection<Bill>(
            title: 'Bills',
            items: claim.bills,
            itemLabelBuilder: (b) => '${b.description} • ${b.category.label}',
            itemDateBuilder: (b) => formatDate(b.date),
            itemAmountBuilder: (b) => formatCurrency(b.amount),
            onAdd: () => showAddEditBillSheet(
              context,
              ref,
              claim: claim,
              claimId: claim.id,
            ),
            onEdit: (bill) => showAddEditBillSheet(
              context,
              ref,
              claim: claim,
              claimId: claim.id,
              existingBill: bill,
            ),
            onDelete: (bill) =>
                _confirmDeleteBill(context, ref, claim, bill),
          ),
          const SizedBox(height: 16),
          _FinancialRecordsSection<Advance>(
            title: 'Advances',
            items: claim.advances,
            itemLabelBuilder: (a) => a.description,
            itemDateBuilder: (a) => formatDate(a.date),
            itemAmountBuilder: (a) => formatCurrency(a.amount),
            onAdd: () => _showAdvanceFormSheet(context, ref, claim),
            onEdit: (advance) =>
                _showAdvanceFormSheet(context, ref, claim, advance: advance),
            onDelete: (advance) =>
                _confirmDeleteAdvance(context, ref, claim, advance),
          ),
          const SizedBox(height: 16),
          _FinancialRecordsSection<Settlement>(
            title: 'Settlements',
            items: claim.settlements,
            itemLabelBuilder: (s) => s.description,
            itemDateBuilder: (s) => formatDate(s.date),
            itemAmountBuilder: (s) => formatCurrency(s.amount),
            onAdd: () => _showSettlementFormSheet(context, ref, claim),
            onEdit: (settlement) => _showSettlementFormSheet(
              context,
              ref,
              claim,
              settlement: settlement,
            ),
            onDelete: (settlement) =>
                _confirmDeleteSettlement(context, ref, claim, settlement),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _WorkflowActionsBar extends ConsumerStatefulWidget {
  const _WorkflowActionsBar({required this.claim});

  final Claim claim;

  @override
  ConsumerState<_WorkflowActionsBar> createState() =>
      _WorkflowActionsBarState();
}

class _WorkflowActionsBarState extends ConsumerState<_WorkflowActionsBar> {
  bool _isTransitioning = false;

  Future<void> _runTransition(
    Future<WorkflowResult> Function() action,
    String successMessage,
  ) async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    try {
      final result = await action();
      if (!mounted) return;
      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _isTransitioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = ref.watch(claimWorkflowProvider);
    final claim = widget.claim;
    final status = claim.status;
    final busy = _isTransitioning;

    if (status == ClaimStatus.draft) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => _runTransition(
                      () => workflow.submit(claim.id),
                      'Claim submitted.',
                    ),
            icon: const Icon(Icons.send, size: 18),
            label: Text(busy ? 'Submitting…' : 'Submit'),
          ),
        ],
      );
    }

    if (status == ClaimStatus.submitted) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => _runTransition(
                      () => workflow.approve(claim.id),
                      'Claim approved.',
                    ),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Approve'),
          ),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () => _runTransition(
                      () => workflow.reject(claim.id),
                      'Claim rejected.',
                    ),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Reject'),
          ),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () => _runTransition(
                      () => workflow.markPartiallySettled(claim.id),
                      'Claim marked partially settled.',
                    ),
            icon: const Icon(Icons.pending_actions, size: 18),
            label: const Text('Mark partially settled'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _ClaimSummaryTab extends StatelessWidget {
  const _ClaimSummaryTab({required this.claim});

  final Claim claim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial summary',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(claim: claim),
          const SizedBox(height: 24),
          Text(
            'Claim history',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _HistoryTimeline(claim: claim),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.claim});

  final Claim claim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.patientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Claim #${claim.id} • ${claim.insurerName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(status: claim.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryMetric(
                label: 'Total bills',
                value: formatCurrency(claim.totalBills),
              ),
              _SummaryMetric(
                label: 'Advances',
                value: formatCurrency(claim.totalAdvances),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryMetric(
                label: 'Settlements',
                value: formatCurrency(claim.totalSettlements),
              ),
              _SummaryMetric(
                label: 'Pending',
                value: formatCurrency(claim.pendingAmount),
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: highlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.claim});

  final Claim claim;

  @override
  Widget build(BuildContext context) {
    final events = <_HistoryEvent>[
      _HistoryEvent(
        title: 'Claim created',
        subtitle: 'Draft created for ${claim.patientName}',
        date: claim.createdAt,
        icon: Icons.note_add,
      ),
      if (claim.advances.isNotEmpty)
        _HistoryEvent(
          title: 'Advance added',
          subtitle:
              'First advance of ${formatCurrency(claim.advances.first.amount)}',
          date: claim.advances.first.date,
          icon: Icons.payments,
        ),
      if (claim.settlements.isNotEmpty)
        _HistoryEvent(
          title: 'Settlement recorded',
          subtitle:
              'Latest settlement of ${formatCurrency(claim.settlements.last.amount)}',
          date: claim.settlements.last.date,
          icon: Icons.verified,
        ),
      _HistoryEvent(
        title: 'Last updated',
        subtitle: 'Status: ${claim.status.label}',
        date: claim.updatedAt,
        icon: Icons.update,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < events.length; i++) ...[
              _HistoryTile(
                event: events[i],
                isFirst: i == 0,
                isLast: i == events.length - 1,
              ),
              if (i != events.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryEvent {
  _HistoryEvent({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final IconData icon;
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final _HistoryEvent event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 12,
                color: theme.colorScheme.outlineVariant,
              ),
            CircleAvatar(
              radius: 12,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                event.icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                event.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatDate(event.date),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _RowLabel extends StatelessWidget {
  const _RowLabel(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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

class _FinancialRecordsSection<T> extends StatelessWidget {
  const _FinancialRecordsSection({
    required this.title,
    required this.items,
    required this.itemLabelBuilder,
    required this.itemDateBuilder,
    required this.itemAmountBuilder,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final String Function(T) itemDateBuilder;
  final String Function(T) itemAmountBuilder;
  final VoidCallback onAdd;
  final void Function(T) onEdit;
  final void Function(T) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No $title recorded yet.\nTap "Add" to record one.',
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
                      title: Text(itemLabelBuilder(item)),
                      subtitle: Text(itemDateBuilder(item)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(itemAmountBuilder(item)),
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

Future<void> _showAdvanceFormSheet(
  BuildContext context,
  WidgetRef ref,
  Claim claim, {
  Advance? advance,
}) async {
  final descriptionController =
      TextEditingController(text: advance?.description ?? '');
  final amountController = TextEditingController(
    text: advance != null ? advance.amount.toStringAsFixed(2) : '',
  );
  DateTime selectedDate = advance?.date ?? DateTime.now();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            final theme = Theme.of(ctx);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advance == null ? 'Add Advance' : 'Edit Advance',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date: ${formatDate(selectedDate)}'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final description =
                          descriptionController.text.trim();
                      final amountText =
                          amountController.text.trim().replaceAll(',', '');
                      final amount = double.tryParse(amountText) ?? 0;

                      if (description.isEmpty || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please enter a description and a positive amount.'),
                          ),
                        );
                        return;
                      }

                      final repo = ref.read(claimsRepositoryProvider);
                      final current = await repo.getById(claim.id);
                      if (current == null) {
                        Navigator.of(sheetContext).pop();
                        return;
                      }

                      final updatedAdvances =
                          List<Advance>.from(current.advances);

                      if (advance == null) {
                        final newAdvance = Advance(
                          id:
                              'adv-${DateTime.now().millisecondsSinceEpoch}',
                          description: description,
                          date: selectedDate,
                          amount: amount,
                        );
                        updatedAdvances.add(newAdvance);
                      } else {
                        final index = updatedAdvances
                            .indexWhere((a) => a.id == advance.id);
                        if (index != -1) {
                          updatedAdvances[index] = Advance(
                            id: advance.id,
                            description: description,
                            date: selectedDate,
                            amount: amount,
                          );
                        }
                      }

                      final updatedClaim = Claim(
                        id: current.id,
                        patientName: current.patientName,
                        patientId: current.patientId,
                        gender: current.gender,
                        age: current.age,
                        admissionDate: current.admissionDate,
                        dischargeDate: current.dischargeDate,
                        insurerName: current.insurerName,
                        policyNumber: current.policyNumber,
                        status: current.status,
                        bills: current.bills,
                        advances: updatedAdvances,
                        settlements: current.settlements,
                        createdAt: current.createdAt,
                        updatedAt: DateTime.now(),
                        remarks: current.remarks,
                      );

                      await repo.update(updatedClaim);
                      ref.invalidate(selectedClaimProvider(claim.id));
                      ref.invalidate(claimsListProvider);

                      if (context.mounted) {
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              advance == null
                                  ? 'Advance added.'
                                  : 'Advance updated.',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(advance == null ? 'Add' : 'Save'),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

Future<void> _showSettlementFormSheet(
  BuildContext context,
  WidgetRef ref,
  Claim claim, {
  Settlement? settlement,
}) async {
  final descriptionController =
      TextEditingController(text: settlement?.description ?? '');
  final amountController = TextEditingController(
    text: settlement != null ? settlement.amount.toStringAsFixed(2) : '',
  );
  DateTime selectedDate = settlement?.date ?? DateTime.now();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            final theme = Theme.of(ctx);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settlement == null ? 'Add Settlement' : 'Edit Settlement',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date: ${formatDate(selectedDate)}'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final description =
                          descriptionController.text.trim();
                      final amountText =
                          amountController.text.trim().replaceAll(',', '');
                      final amount = double.tryParse(amountText) ?? 0;

                      if (description.isEmpty || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please enter a description and a positive amount.'),
                          ),
                        );
                        return;
                      }

                      final repo = ref.read(claimsRepositoryProvider);
                      final current = await repo.getById(claim.id);
                      if (current == null) {
                        Navigator.of(sheetContext).pop();
                        return;
                      }

                      final updatedSettlements =
                          List<Settlement>.from(current.settlements);

                      if (settlement == null) {
                        final newSettlement = Settlement(
                          id:
                              'set-${DateTime.now().millisecondsSinceEpoch}',
                          description: description,
                          date: selectedDate,
                          amount: amount,
                        );
                        updatedSettlements.add(newSettlement);
                      } else {
                        final index = updatedSettlements.indexWhere(
                            (s) => s.id == settlement.id);
                        if (index != -1) {
                          updatedSettlements[index] = Settlement(
                            id: settlement.id,
                            description: description,
                            date: selectedDate,
                            amount: amount,
                          );
                        }
                      }

                      final updatedClaim = Claim(
                        id: current.id,
                        patientName: current.patientName,
                        patientId: current.patientId,
                        gender: current.gender,
                        age: current.age,
                        admissionDate: current.admissionDate,
                        dischargeDate: current.dischargeDate,
                        insurerName: current.insurerName,
                        policyNumber: current.policyNumber,
                        status: current.status,
                        bills: current.bills,
                        advances: current.advances,
                        settlements: updatedSettlements,
                        createdAt: current.createdAt,
                        updatedAt: DateTime.now(),
                        remarks: current.remarks,
                      );

                      await repo.update(updatedClaim);
                      ref.invalidate(selectedClaimProvider(claim.id));
                      ref.invalidate(claimsListProvider);

                      if (context.mounted) {
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              settlement == null
                                  ? 'Settlement added.'
                                  : 'Settlement updated.',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(settlement == null ? 'Add' : 'Save'),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

Future<void> _confirmDeleteAdvance(
  BuildContext context,
  WidgetRef ref,
  Claim claim,
  Advance advance,
) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete advance'),
          content: const Text(
            'Are you sure you want to delete this advance?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) return;

  final repo = ref.read(claimsRepositoryProvider);
  final current = await repo.getById(claim.id);
  if (current == null) return;

  final updatedAdvances = current.advances
      .where((a) => a.id != advance.id)
      .toList(growable: false);

  final updatedClaim = Claim(
    id: current.id,
    patientName: current.patientName,
    patientId: current.patientId,
    gender: current.gender,
    age: current.age,
    admissionDate: current.admissionDate,
    dischargeDate: current.dischargeDate,
    insurerName: current.insurerName,
    policyNumber: current.policyNumber,
    status: current.status,
    bills: current.bills,
    advances: updatedAdvances,
    settlements: current.settlements,
    createdAt: current.createdAt,
    updatedAt: DateTime.now(),
    remarks: current.remarks,
  );

  await repo.update(updatedClaim);
  ref.invalidate(selectedClaimProvider(claim.id));
  ref.invalidate(claimsListProvider);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Advance deleted.')),
  );
}

Future<void> _confirmDeleteSettlement(
  BuildContext context,
  WidgetRef ref,
  Claim claim,
  Settlement settlement,
) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete settlement'),
          content: const Text(
            'Are you sure you want to delete this settlement?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) return;

  final repo = ref.read(claimsRepositoryProvider);
  final current = await repo.getById(claim.id);
  if (current == null) return;

  final updatedSettlements = current.settlements
      .where((s) => s.id != settlement.id)
      .toList(growable: false);

  final updatedClaim = Claim(
    id: current.id,
    patientName: current.patientName,
    patientId: current.patientId,
    gender: current.gender,
    age: current.age,
    admissionDate: current.admissionDate,
    dischargeDate: current.dischargeDate,
    insurerName: current.insurerName,
    policyNumber: current.policyNumber,
    status: current.status,
    bills: current.bills,
    advances: current.advances,
    settlements: updatedSettlements,
    createdAt: current.createdAt,
    updatedAt: DateTime.now(),
    remarks: current.remarks,
  );

  await repo.update(updatedClaim);
  ref.invalidate(selectedClaimProvider(claim.id));
  ref.invalidate(claimsListProvider);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Settlement deleted.')),
  );
}

Future<void> _confirmDeleteBill(
  BuildContext context,
  WidgetRef ref,
  Claim claim,
  Bill bill,
) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete bill'),
          content: const Text(
            'Are you sure you want to delete this bill?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) return;

  final repo = ref.read(claimsRepositoryProvider);
  final current = await repo.getById(claim.id);
  if (current == null) return;

  final updatedBills =
      current.bills.where((b) => b.id != bill.id).toList(growable: false);

  final updatedClaim = current.copyWith(
    bills: updatedBills,
    updatedAt: DateTime.now(),
  );

  await repo.update(updatedClaim);
  ref.invalidate(selectedClaimProvider(claim.id));
  ref.invalidate(claimsListProvider);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill deleted.')),
    );
  }
}

Future<void> _confirmDeleteClaim(
  BuildContext context,
  WidgetRef ref,
  Claim claim,
) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete claim'),
          content: const Text(
            'Are you sure you want to delete this claim? '
            'This will remove all associated bills, advances, and settlements.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) return;

  final repo = ref.read(claimsRepositoryProvider);
  await repo.remove(claim.id);

  ref.invalidate(claimsListProvider);
  ref.invalidate(selectedClaimProvider(claim.id));

  if (context.mounted) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Claim deleted.')),
    );
  }
}
