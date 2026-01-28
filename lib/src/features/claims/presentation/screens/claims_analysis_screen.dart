import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/claims_providers.dart';
import '../../domain/models/claim.dart';
import '../../domain/models/claim_status.dart';
import '../widgets/empty_state.dart';

class ClaimsAnalysisScreen extends ConsumerWidget {
  const ClaimsAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncClaims = ref.watch(claimsListProvider);

    return asyncClaims.when(
      data: (claims) {
        if (claims.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                icon: Icons.insights_outlined,
                message:
                    'No data to analyse yet.\nCreate a few claims to see trends and charts here.',
              ),
            ),
          );
        }

        final stats = _ClaimsAnalytics.compute(claims);

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Claims Analytics',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'High-level overview of all hospital claims, amounts and trends.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _SummaryRow(stats: stats),
                      const SizedBox(height: 24),
                      _SectionCard(
                        title: 'Claims by status',
                        subtitle:
                            'How many claims are Draft, Submitted, Approved, etc.',
                        child: SizedBox(
                          height: 220,
                          child: _StatusBarChart(stats: stats),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Monthly trend',
                        subtitle:
                            'New claims and settled amounts over the last 6 months.',
                        child: _MonthlyTrendCharts(stats: stats),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Top insurers by volume',
                        subtitle:
                            'Insurers with the highest number of claims.',
                        child: _TopInsurersList(stats: stats),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        message:
            'Unable to load analytics right now.\nPlease check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.refresh(claimsListProvider),
      ),
    );
  }
}

class _ClaimsAnalytics {
  _ClaimsAnalytics({
    required this.totalClaims,
    required this.totalBilled,
    required this.totalSettled,
    required this.totalPending,
    required this.byStatusCount,
    required this.byStatusAmount,
    required this.monthlyCreatedCount,
    required this.monthlySettledAmount,
    required this.topInsurers,
  });

  final int totalClaims;
  final double totalBilled;
  final double totalSettled;
  final double totalPending;
  final Map<ClaimStatus, int> byStatusCount;
  final Map<ClaimStatus, double> byStatusAmount;
  final Map<DateTime, int> monthlyCreatedCount;
  final Map<DateTime, double> monthlySettledAmount;
  final List<_InsurerStat> topInsurers;

  static _ClaimsAnalytics compute(List<Claim> claims) {
    final totalClaims = claims.length;
    var totalBilled = 0.0;
    var totalSettled = 0.0;
    var totalPending = 0.0;

    final byStatusCount = <ClaimStatus, int>{
      for (final s in ClaimStatus.values) s: 0,
    };
    final byStatusAmount = <ClaimStatus, double>{
      for (final s in ClaimStatus.values) s: 0,
    };

    final now = DateTime.now();
    final sixMonthsAgo =
        DateTime(now.year, now.month - 5, 1); // include current month

    final monthlyCreatedCount = <DateTime, int>{};
    final monthlySettledAmount = <DateTime, double>{};

    final insurerMap = <String, _InsurerStat>{};

    for (final claim in claims) {
      final billed = claim.totalBills;
      final settled = claim.totalSettlements;
      final pending = claim.pendingAmount;

      totalBilled += billed;
      totalSettled += settled;
      totalPending += pending;

      byStatusCount[claim.status] = (byStatusCount[claim.status] ?? 0) + 1;
      byStatusAmount[claim.status] =
          (byStatusAmount[claim.status] ?? 0) + billed;

      // Monthly created count
      final createdMonth =
          DateTime(claim.createdAt.year, claim.createdAt.month);
      if (!createdMonth.isBefore(sixMonthsAgo)) {
        monthlyCreatedCount[createdMonth] =
            (monthlyCreatedCount[createdMonth] ?? 0) + 1;
      }

      // Monthly settled amount (use settlements' dates)
      for (final s in claim.settlements) {
        final m = DateTime(s.date.year, s.date.month);
        if (!m.isBefore(sixMonthsAgo)) {
          monthlySettledAmount[m] = (monthlySettledAmount[m] ?? 0) + s.amount;
        }
      }

      // Insurer stats
      final key = claim.insurerName;
      final existing = insurerMap[key];
      if (existing == null) {
        insurerMap[key] = _InsurerStat(
          insurerName: key,
          claimCount: 1,
          totalBilled: billed,
        );
      } else {
        insurerMap[key] = existing.copyWith(
          claimCount: existing.claimCount + 1,
          totalBilled: existing.totalBilled + billed,
        );
      }
    }

    final sortedInsurers = insurerMap.values.toList()
      ..sort((a, b) => b.claimCount.compareTo(a.claimCount));

    return _ClaimsAnalytics(
      totalClaims: totalClaims,
      totalBilled: totalBilled,
      totalSettled: totalSettled,
      totalPending: totalPending,
      byStatusCount: byStatusCount,
      byStatusAmount: byStatusAmount,
      monthlyCreatedCount: monthlyCreatedCount,
      monthlySettledAmount: monthlySettledAmount,
      topInsurers: sortedInsurers.take(5).toList(),
    );
  }
}

class _InsurerStat {
  const _InsurerStat({
    required this.insurerName,
    required this.claimCount,
    required this.totalBilled,
  });

  final String insurerName;
  final int claimCount;
  final double totalBilled;

  _InsurerStat copyWith({
    String? insurerName,
    int? claimCount,
    double? totalBilled,
  }) {
    return _InsurerStat(
      insurerName: insurerName ?? this.insurerName,
      claimCount: claimCount ?? this.claimCount,
      totalBilled: totalBilled ?? this.totalBilled,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});

  final _ClaimsAnalytics stats;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.compactCurrency(symbol: '₹');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final children = [
          _SummaryTile(
            label: 'Total claims',
            value: stats.totalClaims.toString(),
            icon: Icons.folder_open_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          _SummaryTile(
            label: 'Total billed',
            value: currency.format(stats.totalBilled),
            icon: Icons.receipt_long_rounded,
            color: Colors.orange,
          ),
          _SummaryTile(
            label: 'Pending amount',
            value: currency.format(stats.totalPending),
            icon: Icons.pending_actions_rounded,
            color: Colors.redAccent,
          ),
        ];

        if (isWide) {
          return Row(
            children: children
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: c,
                    ),
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: children
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: c,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Returns a "nice" ceiling for Y-axis max (1, 2, 5, 10, 15, 20, ...).
int _niceMaxY(int maxCount) {
  if (maxCount <= 0) return 1;
  const nice = [1, 2, 5, 10, 15, 20, 25, 50, 100, 200, 500];
  for (final n in nice) {
    if (n >= maxCount) return n;
  }
  return ((maxCount / 100).ceil() * 100).clamp(100, 10000);
}

/// Y-axis interval for ~4–6 ticks.
double _yInterval(int niceMax) {
  if (niceMax <= 2) return 1;
  if (niceMax <= 5) return 1;
  if (niceMax <= 10) return 2;
  if (niceMax <= 20) return 5;
  if (niceMax <= 50) return 10;
  return (niceMax / 5).ceilToDouble().clamp(10, 100);
}

/// Format Y-axis label: integer or compact (e.g. 1K) for large values.
String _formatYLabel(double value) {
  final n = value.round();
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
  return n.toString();
}

Color _barColorForStatus(ThemeData theme, ClaimStatus s) {
  final c = theme.colorScheme;
  switch (s) {
    case ClaimStatus.draft:
      return c.onSurfaceVariant;
    case ClaimStatus.submitted:
      return c.tertiary;
    case ClaimStatus.approved:
      return c.primary;
    case ClaimStatus.rejected:
      return c.error;
    case ClaimStatus.partiallySettled:
      return c.secondary;
  }
}

class _StatusBarChart extends StatelessWidget {
  const _StatusBarChart({required this.stats});

  final _ClaimsAnalytics stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusList = ClaimStatus.values.toList();
    final maxCount =
        stats.byStatusCount.values.fold<int>(0, (max, v) => v > max ? v : max);

    if (maxCount == 0) {
      return Center(
        child: Text(
          'No status data yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final niceMax = _niceMaxY(maxCount);
    final interval = _yInterval(niceMax);

    // Dark tooltip background so light text is clearly visible on hover
    const tooltipBg = Color(0xFF1E293B);
    const tooltipText = Color(0xFFF1F5F9);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: 0,
        maxY: niceMax.toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: scheme.outlineVariant.withOpacity(0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value < 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    _formatYLabel(value),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= statusList.length) {
                  return const SizedBox.shrink();
                }
                final label = statusList[index].label.split(' ').first;
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => tooltipBg,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 8,
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final status = statusList[groupIndex];
              final count = rod.toY.round();
              return BarTooltipItem(
                '${status.label}\n$count',
                TextStyle(
                  color: tooltipText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < statusList.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: stats.byStatusCount[statusList[i]]!.toDouble(),
                  color: _barColorForStatus(theme, statusList[i]),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Last 6 calendar months (including current) for consistent X-axis.
List<DateTime> _last6Months() {
  final now = DateTime.now();
  return List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
}

/// Format Y-axis for currency (compact: ₹10K, etc.).
String _formatAmountY(double value) {
  if (value.abs() < 0.5) return '0';
  final n = value.round();
  if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(n % 100000 == 0 ? 0 : 1)}L';
  if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
  return '₹$n';
}

/// Nice ceiling for amount axis.
double _niceMaxAmount(double maxAmount) {
  if (maxAmount <= 0) return 1000;
  final candidates = [1000.0, 2500.0, 5000.0, 10000.0, 25000.0, 50000.0, 100000.0, 250000.0, 500000.0];
  for (final c in candidates) {
    if (c >= maxAmount) return c;
  }
  return (maxAmount / 100000).ceil() * 100000;
}

double _amountInterval(double niceMax) {
  if (niceMax <= 2500) return 500;
  if (niceMax <= 10000) return 2500;
  if (niceMax <= 50000) return 10000;
  if (niceMax <= 100000) return 25000;
  return 50000;
}

class _MonthlyTrendCharts extends StatelessWidget {
  const _MonthlyTrendCharts({required this.stats});

  final _ClaimsAnalytics stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final months = _last6Months();
    final hasAny = stats.monthlyCreatedCount.isNotEmpty ||
        stats.monthlySettledAmount.isNotEmpty;

    if (!hasAny) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Monthly trend will appear once you have more data.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New claims',
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 180,
          child: _MonthlyClaimsLineChart(stats: stats, months: months),
        ),
        const SizedBox(height: 20),
        Text(
          'Settled amount (₹)',
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.teal.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 180,
          child: _MonthlySettledLineChart(stats: stats, months: months),
        ),
      ],
    );
  }
}

class _MonthlyClaimsLineChart extends StatelessWidget {
  const _MonthlyClaimsLineChart({
    required this.stats,
    required this.months,
  });

  final _ClaimsAnalytics stats;
  final List<DateTime> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final monthFormat = DateFormat.MMM();
    const tooltipBg = Color(0xFF1E293B);
    const tooltipText = Color(0xFFF1F5F9);

    final spots = <FlSpot>[];
    var maxCount = 0;
    for (var i = 0; i < months.length; i++) {
      final c = stats.monthlyCreatedCount[months[i]] ?? 0;
      maxCount = c > maxCount ? c : maxCount;
      spots.add(FlSpot(i.toDouble(), c.toDouble()));
    }

    final niceMax = _niceMaxY(maxCount);
    final interval = _yInterval(niceMax);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (months.length - 1).toDouble(),
        minY: 0,
        maxY: niceMax.toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outlineVariant.withOpacity(0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value < 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    _formatYLabel(value),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= months.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    monthFormat.format(months[i]),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => tooltipBg,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 8,
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final i = s.x.toInt();
              final m = i >= 0 && i < months.length ? months[i] : null;
              final label = m != null ? '${monthFormat.format(m)}\n${s.y.toInt()} claims' : '${s.y.toInt()} claims';
              return LineTooltipItem(
                label,
                TextStyle(color: tooltipText, fontWeight: FontWeight.w600, fontSize: 13),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: scheme.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: scheme.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySettledLineChart extends StatelessWidget {
  const _MonthlySettledLineChart({
    required this.stats,
    required this.months,
  });

  final _ClaimsAnalytics stats;
  final List<DateTime> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final monthFormat = DateFormat.MMM();
    final currency = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    const tooltipBg = Color(0xFF1E293B);
    const tooltipText = Color(0xFFF1F5F9);
    final settledColor = Colors.teal.shade700;

    final spots = <FlSpot>[];
    var maxAmount = 0.0;
    for (var i = 0; i < months.length; i++) {
      final a = stats.monthlySettledAmount[months[i]] ?? 0.0;
      if (a > maxAmount) maxAmount = a;
      spots.add(FlSpot(i.toDouble(), a));
    }

    final niceMax = _niceMaxAmount(maxAmount);
    final interval = _amountInterval(niceMax);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (months.length - 1).toDouble(),
        minY: 0,
        maxY: niceMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outlineVariant.withOpacity(0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value < 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    _formatAmountY(value),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= months.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    monthFormat.format(months[i]),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => tooltipBg,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 8,
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final i = s.x.toInt();
              final m = i >= 0 && i < months.length ? months[i] : null;
              final amt = s.y;
              final label = m != null
                  ? '${monthFormat.format(m)}\n${currency.format(amt)}'
                  : currency.format(amt);
              return LineTooltipItem(
                label,
                TextStyle(color: tooltipText, fontWeight: FontWeight.w600, fontSize: 13),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: settledColor,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: settledColor,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: settledColor.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopInsurersList extends StatelessWidget {
  const _TopInsurersList({required this.stats});

  final _ClaimsAnalytics stats;

  @override
  Widget build(BuildContext context) {
    if (stats.topInsurers.isEmpty) {
      return const Text('Insurer breakdown will appear once you add claims.');
    }
    final currency = NumberFormat.compactCurrency(symbol: '₹');
    final maxCount = stats.topInsurers
        .fold<int>(0, (max, s) => s.claimCount > max ? s.claimCount : max);

    return Column(
      children: [
        for (final insurer in stats.topInsurers)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    insurer.insurerName,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: insurer.claimCount / maxCount,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${insurer.claimCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                Text(
                  currency.format(insurer.totalBilled),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

