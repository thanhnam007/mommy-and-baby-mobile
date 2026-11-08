import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pumping_model.dart';
import '../../providers/baby_provider.dart';
import '../../providers/pumping_provider.dart';
import 'widgets/pumping_chart_card.dart';
import 'widgets/pumping_form_sheet.dart';

class PumpingView extends StatefulWidget {
  const PumpingView({super.key});

  @override
  State<PumpingView> createState() => _PumpingViewState();
}

class _PumpingViewState extends State<PumpingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final baby = Provider.of<BabyProvider>(context, listen: false).activeBaby;
      final pumping = Provider.of<PumpingProvider>(context, listen: false);
      pumping.fetchOverview(baby?.id);
      pumping.fetchTodaySummary();
    });
  }

  void _openAddSheet(BuildContext context, int? babyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PumpingFormSheet(
        onSave: ({
          required startTime,
          required endTime,
          required amountMl,
          required breastSide,
          leftAmountMl,
          rightAmountMl,
          notes,
        }) async {
          await Provider.of<PumpingProvider>(context, listen: false).createRecord(
            babyId: babyId,
            startTime: startTime,
            endTime: endTime,
            amountMl: amountMl,
            breastSide: breastSide,
            leftAmountMl: leftAmountMl,
            rightAmountMl: rightAmountMl,
            notes: notes,
          );
        },
      ),
    );
  }

  void _openEditSheet(BuildContext context, PumpingRecordModel rec, int? babyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PumpingFormSheet(
        record: rec,
        onSave: ({
          required startTime,
          required endTime,
          required amountMl,
          required breastSide,
          leftAmountMl,
          rightAmountMl,
          notes,
        }) async {
          await Provider.of<PumpingProvider>(context, listen: false).updateRecord(
            rec.id,
            babyId: babyId,
            startTime: startTime,
            endTime: endTime,
            amountMl: amountMl,
            breastSide: breastSide,
            leftAmountMl: leftAmountMl,
            rightAmountMl: rightAmountMl,
            notes: notes,
          );
        },
        onDelete: () {
          Provider.of<PumpingProvider>(context, listen: false).deleteRecord(rec.id, babyId);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baby = Provider.of<BabyProvider>(context).activeBaby;
    final pumping = Provider.of<PumpingProvider>(context);
    final overview = pumping.overview;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🍼', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('Cữ Hút Sữa Của Mẹ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.brand500),
            tooltip: 'Ghi cữ hút mới',
            onPressed: () => _openAddSheet(context, baby?.id),
          ),
        ],
      ),
      body: pumping.isLoading && overview == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  pumping.fetchOverview(baby?.id),
                  pumping.fetchTodaySummary(),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 48),
                children: [
                  // Top Summary Metrics (4 cards)
                  if (overview != null) _buildOverviewMetrics(overview.stats, isDark),

                  const SizedBox(height: 14),

                  // Range Pill Chips (text 12px friendly on mobile 390x844)
                  _buildRangeChips(pumping, baby?.id, isDark),

                  const SizedBox(height: 14),

                  // Chart Card
                  if (overview != null)
                    PumpingChartCard(
                      chartPoints: overview.chartPoints,
                      averageMl: overview.averageMl,
                      rangeType: pumping.rangeType,
                    ),

                  const SizedBox(height: 18),

                  // Timeline / History Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📋 Dòng Thời Gian Cữ Hút (${overview?.groups.fold<int>(0, (acc, g) => acc + g.records.length) ?? 0})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Chạm để sửa',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Groups by Day
                  if (overview == null || overview.groups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Text('🍼', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có cữ hút nào trong khoảng thời gian này.\nBấm "+" để thêm ngay nhé!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final grp in overview.groups) _buildDayGroup(grp, baby?.id, isDark),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, baby?.id),
        backgroundColor: AppTheme.brand500,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ghi Cữ Hút', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOverviewMetrics(PumpingSummaryStatsModel stats, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        // 1. Total Milk
        _buildMetricTile(
          title: '🍼 Tổng sữa',
          value: '${stats.totalAmountMl}',
          unit: 'ml',
          subtitle: stats.comparePrevPeriodDiffMl != null
              ? '${stats.comparePrevPeriodDiffMl! >= 0 ? "+" : ""}${stats.comparePrevPeriodDiffMl} ml kỳ trước'
              : 'Tổng sản lượng',
          color: AppTheme.brand500,
          isDark: isDark,
        ),
        // 2. Total Sessions
        _buildMetricTile(
          title: '⏱️ Số cữ hút',
          value: '${stats.totalSessions}',
          unit: 'cữ',
          subtitle: 'Đã hoàn thành',
          color: Colors.pink[400]!,
          isDark: isDark,
        ),
        // 3. Average per Session
        _buildMetricTile(
          title: '📊 TB mỗi cữ',
          value: '${stats.avgPerSessionMl.round()}',
          unit: 'ml/cữ',
          subtitle: 'Sản lượng/lần',
          color: Colors.indigo[400]!,
          isDark: isDark,
        ),
        // 4. Last Pumping Time
        _buildMetricTile(
          title: '⏰ Cữ gần nhất',
          value: stats.minutesSinceLastPumping != null
              ? (stats.minutesSinceLastPumping! < 60
                  ? '${stats.minutesSinceLastPumping}p'
                  : '${stats.minutesSinceLastPumping! ~/ 60}h')
              : '--',
          unit: 'trước',
          subtitle: stats.lastPumpingTime != null && stats.lastPumpingTime!.length >= 16
              ? stats.lastPumpingTime!.substring(11, 16)
              : 'Chưa có',
          color: Colors.amber[700]!,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(width: 3),
              Text(unit, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ],
          ),
          Text(subtitle, style: TextStyle(fontSize: 9.5, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRangeChips(PumpingProvider pumping, int? babyId, bool isDark) {
    final filters = [
      {'label': 'Hôm nay', 'val': 'day'},
      {'label': '7 ngày', 'val': '7days'},
      {'label': 'Tuần này', 'val': 'week'},
      {'label': 'Tháng này', 'val': 'month'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = pumping.rangeType == f['val'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 12, // text-[12px] convention
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.brand500,
              backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.grey[100],
              onSelected: (_) => pumping.setRangeType(f['val']!, babyId),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayGroup(PumpingDayGroupModel grp, int? babyId, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  grp.displayDate,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      'Tổng: ${grp.totalAmountMl} ml',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brand500),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${grp.sessionsCount} cữ',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Day items
          for (final item in grp.records)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => _openEditSheet(context, item, babyId),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111827) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      // Time & Duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brand500.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.durationMinutes}p',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.brand500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getSideText(item.breastSide),
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '💬 ${item.notes}',
                                  style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.grey[500]),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Milk amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${item.amountMl}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.brand500),
                              ),
                              const SizedBox(width: 2),
                              const Text('ml', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brand500)),
                            ],
                          ),
                          if (item.leftAmountMl != null || item.rightAmountMl != null)
                            Text(
                              'T:${item.leftAmountMl ?? 0} • P:${item.rightAmountMl ?? 0}',
                              style: TextStyle(fontSize: 9.5, color: Colors.grey[500]),
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }

  String _getSideText(String side) {
    switch (side) {
      case 'left':
        return 'Ngực trái 👈';
      case 'right':
        return 'Ngực phải 👉';
      default:
        return 'Cả 2 bên ✌️';
    }
  }
}
