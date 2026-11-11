import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/milk_warming_model.dart';
import '../../providers/baby_provider.dart';
import '../../providers/milk_warming_provider.dart';
import '../dashboard/widgets/milk_warming_dashboard_card.dart';
import 'widgets/milk_warming_form_sheet.dart';
import 'widgets/milk_warming_quick_sheet.dart';

class MilkWarmingView extends StatefulWidget {
  final int? babyId;

  const MilkWarmingView({super.key, this.babyId});

  @override
  State<MilkWarmingView> createState() => _MilkWarmingViewState();
}

class _MilkWarmingViewState extends State<MilkWarmingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  int? get _effectiveBabyId =>
      widget.babyId ?? Provider.of<BabyProvider>(context, listen: false).activeBaby?.id;

  void _loadData() {
    final prov = Provider.of<MilkWarmingProvider>(context, listen: false);
    prov.fetchStatus(_effectiveBabyId);
    prov.fetchOverview(_effectiveBabyId);
  }

  void _openQuickSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MilkWarmingQuickSheet(babyId: _effectiveBabyId),
    ).then((val) {
      if (val == true) _loadData();
    });
  }

  void _openFormSheet({MilkWarmingRecordModel? record}) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MilkWarmingFormSheet(record: record, babyId: _effectiveBabyId),
    ).then((val) {
      if (val == true) _loadData();
    });
  }

  void _deleteRecord(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa bản ghi cữ hâm sữa này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final prov = Provider.of<MilkWarmingProvider>(context, listen: false);
      await prov.deleteRecord(id, _effectiveBabyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MilkWarmingProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overview = provider.overview;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch hâm sữa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nhập thủ công',
            onPressed: () => _openFormSheet(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQuickSheet,
        backgroundColor: Colors.amber.shade700,
        icon: const Text('⚡', style: TextStyle(fontSize: 16)),
        label: const Text('Ghi nhanh lịch hâm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 96),
          children: [
            // Top Live Card
            MilkWarmingDashboardCard(babyId: _effectiveBabyId),
            const SizedBox(height: 16),

            // Today Summary Metrics
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray900 : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sữa hâm hôm nay', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${overview?.todayTotalMl ?? 0} ml',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray900 : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Số cữ hôm nay', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${overview?.todaySessionsCount ?? 0} cữ',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Correlation Card
            if (overview?.todayCorrelation != null)
              _buildTodayCorrelationCard(overview!.todayCorrelation!, isDark),

            const SizedBox(height: 16),

            // History List
            const Text(
              'Nhật ký các lần hâm sữa',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (provider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (overview == null || overview.groups.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray900 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                ),
                child: Column(
                  children: [
                    const Text('🍼', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 10),
                    const Text('Chưa có bản ghi hâm sữa nào', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Bấm "Ghi nhanh lịch hâm" để lưu lần hâm đầu tiên.',
                      style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                    ),
                  ],
                ),
              )
            else
              ...overview.groups.map((group) => _buildDayGroup(group, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCorrelationCard(MilkWarmingCorrelationModel corr, bool isDark) {
    Color statusColor = AppTheme.emerald500;
    String statusText = 'Tối ưu';
    if (corr.status == 'waste') {
      statusColor = Colors.amber.shade700;
      statusText = 'Dư thừa';
    } else if (corr.status == 'deficit') {
      statusColor = Colors.red.shade600;
      statusText = 'Lệch số liệu';
    } else if (corr.status == 'balanced') {
      statusColor = Colors.lightBlue.shade700;
      statusText = 'Khá tốt';
    } else if (corr.status == 'no_data') {
      statusColor = AppTheme.gray500;
      statusText = 'Chưa có cữ hâm';
    }

    final double ratio = corr.consumptionRatioPercent ?? 0;
    final double barRatio = (ratio / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⚖️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  const Text(
                    'Tương quan Hâm & Bú hôm nay',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF451A03).withValues(alpha: 0.2) : AppTheme.amber50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('♨️ Đã hâm', style: TextStyle(fontSize: 10.5, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${corr.warmedTotalMl} ml', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                      Text('${corr.warmedSessionsCount} cữ', style: TextStyle(fontSize: 10, color: Colors.amber.shade800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.brand700.withValues(alpha: 0.15) : AppTheme.brand50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🍼 Bé đã bú (hâm)', style: TextStyle(fontSize: 10.5, color: AppTheme.brand600, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${corr.consumedWarmedMl} ml', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.brand500)),
                      Text('${corr.consumedWarmedCount} cữ', style: TextStyle(fontSize: 10, color: AppTheme.brand600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (corr.warmedTotalMl > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tỉ lệ bú / hâm: ${ratio.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
                Text(
                  corr.differenceMl >= 0 ? 'Dư/hao hụt: ${corr.differenceMl} ml' : 'Bú vượt: ${corr.differenceMl.abs()} ml',
                  style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: barRatio,
                minHeight: 6,
                backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (corr.consumedDirectCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray800 : AppTheme.gray50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🧴 Sữa mẹ tươi ti trực tiếp:', style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
                  Text(
                    '${corr.consumedDirectMl} ml (${corr.consumedDirectCount} cữ)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          Text(
            '💡 ${corr.message}',
            style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildDayGroup(MilkWarmingDayGroupModel group, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(group.displayDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (group.correlation != null && (group.correlation!.consumedWarmedMl > 0 || group.correlation!.warmedTotalMl > 0)) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.brand500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🍼 Bú ${group.correlation!.consumedWarmedMl}/${group.correlation!.warmedTotalMl}ml',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.brand500),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '${group.totalAmountMl} ml • ${group.sessionsCount} cữ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray900 : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.records.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? AppTheme.gray800 : AppTheme.gray100),
              itemBuilder: (ctx, idx) {
                final rec = group.records[idx];
                final start = rec.startDateTime;
                final end = rec.endDateTime;
                final startStr = start != null ? '${start.toLocal().hour.toString().padLeft(2, '0')}:${start.toLocal().minute.toString().padLeft(2, '0')}' : '';
                final endStr = end != null ? '${end.toLocal().hour.toString().padLeft(2, '0')}:${end.toLocal().minute.toString().padLeft(2, '0')}' : '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: rec.status == 'warming'
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(rec.status == 'warming' ? '🔥' : '♨️', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text('${rec.amountMl} ml', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      if (rec.status == 'warming') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Đang hâm', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    endStr.isNotEmpty ? '$startStr → $endStr (${rec.formatDuration()})' : 'Bắt đầu lúc $startStr',
                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _openFormSheet(record: rec),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        onPressed: () => _deleteRecord(rec.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
