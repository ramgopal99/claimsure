import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../application/claim_form_notifier.dart';
import '../../application/claims_providers.dart';
import '../../domain/models/claim.dart';

class ClaimEditScreen extends ConsumerWidget {
  const ClaimEditScreen({
    super.key,
    this.initialClaim,
  });

  final Claim? initialClaim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(claimFormNotifierProvider(initialClaim));
    final formNotifier =
        ref.read(claimFormNotifierProvider(initialClaim).notifier);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(formState.isNew ? 'New Claim' : 'Edit Claim'),
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
              TextFormField(
                initialValue: formState.patientName,
                decoration: const InputDecoration(
                  labelText: 'Patient Name *',
                  border: OutlineInputBorder(),
                ),
                onChanged: formNotifier.updatePatientName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: formState.patientId,
                decoration: const InputDecoration(
                  labelText: 'Patient ID *',
                  border: OutlineInputBorder(),
                ),
                onChanged: formNotifier.updatePatientId,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: formState.gender.isEmpty ? null : formState.gender,
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
                          formNotifier.updateGender(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          formState.age == 0 ? '' : formState.age.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Age *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value.trim()) ?? 0;
                        formNotifier.updateAge(parsed);
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
              TextFormField(
                initialValue: formState.insurerName,
                decoration: const InputDecoration(
                  labelText: 'Insurer Name *',
                  border: OutlineInputBorder(),
                ),
                onChanged: formNotifier.updateInsurerName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: formState.policyNumber,
                decoration: const InputDecoration(
                  labelText: 'Policy Number *',
                  border: OutlineInputBorder(),
                ),
                onChanged: formNotifier.updatePolicyNumber,
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
                      date: formState.admissionDate,
                      onChanged: formNotifier.updateAdmissionDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Discharge Date *',
                      date: formState.dischargeDate,
                      onChanged: formNotifier.updateDischargeDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: formState.remarks,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: formNotifier.updateRemarks,
              ),
              const SizedBox(height: 16),
              if (formState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    formState.errorMessage!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: formState.isSaving
                          ? null
                          : () async {
                              final saved = await formNotifier.saveDraft();
                              if (saved != null && context.mounted) {
                                ref.invalidate(claimsListProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Draft saved'),
                                  ),
                                );
                                context.pop();
                              }
                            },
                      child: const Text('Save as Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: formState.isSaving
                          ? null
                          : () async {
                              final saved = await formNotifier.saveDraft();
                              if (saved != null && context.mounted) {
                                ref.invalidate(claimsListProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Draft saved. Add bills, advances, and settlements below.',
                                    ),
                                  ),
                                );
                                context.pushReplacementNamed(
                                  routeClaimDetail,
                                  pathParameters: {'id': saved.id},
                                );
                              }
                            },
                      child: const Text('Save & Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

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

