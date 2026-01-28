import 'package:flutter/material.dart';

import '../../domain/models/claim_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, bgColor) = _colorsForStatus(theme, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _colorsForStatus(ThemeData theme, ClaimStatus s) {
    final colorScheme = theme.colorScheme;
    switch (s) {
      case ClaimStatus.draft:
        return (colorScheme.onSurfaceVariant, colorScheme.surfaceContainerHighest);
      case ClaimStatus.submitted:
        return (colorScheme.tertiary, colorScheme.tertiaryContainer);
      case ClaimStatus.approved:
        return (colorScheme.primary, colorScheme.primaryContainer);
      case ClaimStatus.rejected:
        return (colorScheme.error, colorScheme.errorContainer);
      case ClaimStatus.partiallySettled:
        return (colorScheme.secondary, colorScheme.secondaryContainer);
    }
  }
}
