import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/growth_model.dart';
import '../../providers/baby_provider.dart';
import '../../providers/growth_provider.dart';
import 'who_standards_dialog.dart';

class GrowthView extends StatefulWidget {
  const GrowthView({super.key});

  @override
  State<GrowthView> createState() => _GrowthViewState();
}

class _GrowthViewState extends State<GrowthView> {
  String _activeMetric = 'weight'; // 'weight' or 'height'

  void _showRecordDialog(BuildContext context, int babyId, {GrowthRecordModel? record}) {
    final weightCtrl = TextEditingController(
      text: record?.weightKg != null ? record!.weightKg.toString() : '',
    );
    final heightCtrl = TextEditingController(
      text: record?.heightCm != null ? record!.heightCm.toString() : '',
    );
    final notesCtrl = TextEditingController(text: record?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record != null
                    ? 'Chỉnh sửa Số đo Chiều cao & Cân nặng'
                    : 'Ghi nhận Số đo Chiều cao & Cân nặng',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (record != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Mốc đo: ${record.recordedAt.length >= 16 ? record.recordedAt.substring(0, 16).replaceAll("T", " ") : record.recordedAt}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.brand500, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cân nặng (kg)',
                  hintText: 'VD: 6.8',
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Chiều cao (cm)',
                  hintText: 'VD: 64.5',
                  suffixText: 'cm',
                  prefixIcon: Icon(Icons.height_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final w = double.tryParse(weightCtrl.text);
                    final h = double.tryParse(heightCtrl.text);
                    if (w == null && h == null) return;

                    final growth = Provider.of<GrowthProvider>(context, listen: false);
                    final bool ok;
                    if (record != null) {
                      ok = await growth.updateRecord(
                        record.id,
                        babyId,
                        w,
                        h,
                        notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                      );
                    } else {
                      ok = await growth.addRecord(
                        babyId,
                        w,
                        h,
                        notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                      );
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? (record != null ? 'Đã cập nhật số đo thành công! 🎉' : 'Đã lưu số đo thành công! 🎉')
                              : 'Lỗi khi lưu số đo'),
                        ),
                      );
                    }
                  },
                  child: Text(record != null ? 'Lưu cập nhật' : 'Lưu số đo'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openWhoTable(BuildContext context, String gender, int? months) {
    showDialog(
      context: context,
      builder: (_) => WHOStandardsDialog(gender: gender, currentBabyMonths: months),
    );
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = Provider.of<BabyProvider>(context);
    final growthProvider = Provider.of<GrowthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baby = babyProvider.activeBaby;
    if (baby == null) {
      return const Center(child: Text('Vui lòng chọn bé'));
    }

    final summary = growthProvider.summary;
    final records = summary?.records ?? [];

    final actualVals = records
        .map((r) => _activeMetric == 'weight' ? r.weightKg : r.heightCm)
        .whereType<double>()
        .toList();
    final whoVal = summary?.currentWhoStandard != null
        ? (_activeMetric == 'weight' ? summary!.currentWhoStandard.weightMedian : summary!.currentWhoStandard.heightMedian)
        : null;
    final allVals = [...actualVals, ?whoVal];
    final double? calcMin = allVals.isNotEmpty ? allVals.reduce((a, b) => a < b ? a : b) : null;
    final double? calcMax = allVals.isNotEmpty ? allVals.reduce((a, b) => a > b ? a : b) : null;
    final double? chartMinY = calcMin != null ? (calcMin - (_activeMetric == 'weight' ? 0.8 : 3.0)).clamp(0.0, double.infinity) : null;
    final double? chartMaxY = calcMax != null ? calcMax + (_activeMetric == 'weight' ? 0.8 : 3.0) : null;

    final rangeFilters = [
      {'key': 'week', 'label': '7 ngày'},
      {'key': 'month', 'label': '30 ngày'},
      {'key': 'year', 'label': '1 năm'},
      {'key': 'all', 'label': 'Tất cả'},
    ];

    return RefreshIndicator(
      onRefresh: () => growthProvider.fetchGrowth(baby.id),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Cards: Current Weight & Height (Tap to edit latest record)
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (summary?.latestRecord != null) {
                          _showRecordDialog(context, baby.id, record: summary!.latestRecord);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.gray900 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Text('⚖️', style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 6),
                                    Text('Cân nặng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (summary?.latestRecord != null)
                                  const Text(
                                    '✏️ Sửa',
                                    style: TextStyle(fontSize: 10, color: AppTheme.brand500, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              summary?.latestRecord?.weightKg != null
                                  ? '${summary!.latestRecord!.weightKg} kg'
                                  : '-- kg',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary?.currentWhoStandard != null
                                  ? 'Chuẩn WHO: ${summary!.currentWhoStandard.weightMedian.toStringAsFixed(1)} kg'
                                  : 'Chưa có chuẩn',
                              style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (summary?.latestRecord != null) {
                          _showRecordDialog(context, baby.id, record: summary!.latestRecord);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.gray900 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Text('📏', style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 6),
                                    Text('Chiều cao', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (summary?.latestRecord != null)
                                  const Text(
                                    '✏️ Sửa',
                                    style: TextStyle(fontSize: 10, color: Colors.indigoAccent, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              summary?.latestRecord?.heightCm != null
                                  ? '${summary!.latestRecord!.heightCm} cm'
                                  : '-- cm',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary?.currentWhoStandard != null
                                  ? 'Chuẩn WHO: ${summary!.currentWhoStandard.heightMedian.toStringAsFixed(1)} cm'
                                  : 'Chưa có chuẩn',
                              style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. Time Range Selector (100% full width segmented bar)
            Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: rangeFilters.map((f) {
                  final isSel = growthProvider.rangeType == f['key'];
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => growthProvider.setRangeType(f['key']!, baby.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel
                              ? (isDark ? AppTheme.gray900 : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          f['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel
                                ? AppTheme.brand500
                                : (isDark ? AppTheme.gray300 : AppTheme.gray600),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Controls Bar: Metric Switcher & Chuẩn WHO Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Metric Toggle (Cân nặng / Chiều cao) - Capsule Segmented Control
                Container(
                  height: 36,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMetricTab(
                        title: '⚖️ Cân nặng',
                        isSelected: _activeMetric == 'weight',
                        isDark: isDark,
                        onTap: () => setState(() => _activeMetric = 'weight'),
                      ),
                      _buildMetricTab(
                        title: '📏 Chiều cao',
                        isSelected: _activeMetric == 'height',
                        isDark: isDark,
                        onTap: () => setState(() => _activeMetric = 'height'),
                      ),
                    ],
                  ),
                ),

                // WHO Standards Menu Item Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openWhoTable(context, baby.gender, baby.ageInMonths),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.table_chart_rounded,
                            size: 15,
                            color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Chuẩn WHO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Line Chart
            Container(
              height: 240,
              padding: const EdgeInsets.only(top: 20, bottom: 8, right: 16, left: 14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray900 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
              ),
              child: records.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có dữ liệu đo nào.\nHãy bấm "Ghi số đo" ở trên để xem biểu đồ!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minX: records.length == 1 ? -0.5 : 0,
                        maxX: records.length == 1 ? 0.5 : (records.length - 1).toDouble(),
                        minY: chartMinY,
                        maxY: chartMaxY,
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            if (summary?.currentWhoStandard != null)
                              HorizontalLine(
                                y: _activeMetric == 'weight'
                                    ? summary!.currentWhoStandard.weightMedian
                                    : summary!.currentWhoStandard.heightMedian,
                                color: Colors.indigoAccent,
                                strokeWidth: 1.5,
                                dashArray: [6, 4],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.only(right: 6, bottom: 2),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigoAccent,
                                  ),
                                  labelResolver: (line) =>
                                      'WHO: ${line.y.toStringAsFixed(1)} ${_activeMetric == "weight" ? "kg" : "cm"}',
                                ),
                              ),
                          ],
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark ? AppTheme.gray800 : AppTheme.gray200,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if ((value - value.round()).abs() > 0.01) {
                                  return const SizedBox.shrink();
                                }
                                final idx = value.round();
                                if (idx >= 0 && idx < records.length) {
                                  final r = records[idx];
                                  final dt = r.recordedAt.length >= 10 ? r.recordedAt.substring(5, 10) : '';
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      dt,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.max || value == meta.min) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  value.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // Actual Baby Line
                          LineChartBarData(
                            spots: _buildActualSpots(records, _activeMetric),
                            isCurved: true,
                            color: AppTheme.brand500,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.brand500.withValues(alpha: 0.12),
                            ),
                          ),
                          // WHO Median Line
                          if (summary?.currentWhoStandard != null)
                            LineChartBarData(
                              spots: _buildWhoMedianSpots(records, summary!.currentWhoStandard, _activeMetric),
                              isCurved: false,
                              color: Colors.indigoAccent,
                              barWidth: 2,
                              dashArray: [5, 5],
                              dotData: const FlDotData(show: false),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(width: 14, height: 4, decoration: BoxDecoration(color: AppTheme.brand500, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    const Text('Bé thực tế', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Container(width: 14, height: 2, decoration: BoxDecoration(color: Colors.indigoAccent, borderRadius: BorderRadius.circular(1))),
                    const SizedBox(width: 6),
                    const Text('Chuẩn WHO (Median)', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Measurement History List Header & Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch sử các lần đo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showRecordDialog(context, baby.id),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE11D48).withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 15, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Ghi số đo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (records.isEmpty)
              const SizedBox.shrink()
            else
              ...records.reversed.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray900 : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showRecordDialog(context, baby.id, record: r),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r.weightKg != null ? "${r.weightKg} kg" : ""} ${r.heightCm != null ? "• ${r.heightCm} cm" : ""}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.recordedAt.length >= 10 ? r.recordedAt.substring(0, 10) : '',
                                  style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                                ),
                                if (r.notes != null && r.notes!.isNotEmpty)
                                  Text(
                                    r.notes!,
                                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                                  ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.brand500),
                                  onPressed: () => _showRecordDialog(context, baby.id, record: r),
                                  tooltip: 'Chỉnh sửa',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    growthProvider.deleteRecord(r.id, baby.id);
                                  },
                                  tooltip: 'Xóa',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTab({
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.gray900 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppTheme.brand500
                : (isDark ? AppTheme.gray400 : AppTheme.gray600),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildActualSpots(List<GrowthRecordModel> records, String metric) {
    final spots = <FlSpot>[];
    for (int i = 0; i < records.length; i++) {
      final val = metric == 'weight' ? records[i].weightKg : records[i].heightCm;
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }
    return spots;
  }

  List<FlSpot> _buildWhoMedianSpots(List<GrowthRecordModel> records, WHOReferencePoint standard, String metric) {
    final spots = <FlSpot>[];
    final median = metric == 'weight' ? standard.weightMedian : standard.heightMedian;
    for (int i = 0; i < records.length; i++) {
      spots.add(FlSpot(i.toDouble(), median));
    }
    return spots;
  }
}
