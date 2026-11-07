import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/pumping_model.dart';

class PumpingChartCard extends StatefulWidget {
  final List<PumpingChartPointModel> chartPoints;
  final double averageMl;
  final String rangeType;

  const PumpingChartCard({
    super.key,
    required this.chartPoints,
    required this.averageMl,
    required this.rangeType,
  });

  @override
  State<PumpingChartCard> createState() => _PumpingChartCardState();
}

class _PumpingChartCardState extends State<PumpingChartCard> {
  bool _showChart = true;
  bool _showMilkLine = true;
  bool _showAverageLine = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📈', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        const Text(
                          'Biểu đồ Lượng Sữa (ml)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.rangeType == 'day'
                          ? 'Từng cữ hút trong ngày'
                          : 'Tổng sản lượng sữa theo ngày',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _showChart = !_showChart),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _showChart
                        ? AppTheme.brand500
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showChart ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 14,
                        color: _showChart ? Colors.white : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showChart ? 'Hiển thị' : 'Đã ẩn',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _showChart ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_showChart) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Checkbox filters for series
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildFilterChip(
                  label: '🍼 Lượng sữa (ml)',
                  isActive: _showMilkLine,
                  activeColor: AppTheme.brand500,
                  onTap: () => setState(() => _showMilkLine = !_showMilkLine),
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: '🎯 Mức TB (${widget.averageMl.round()} ml)',
                  isActive: _showAverageLine,
                  activeColor: Colors.amber[700]!,
                  onTap: () => setState(() => _showAverageLine = !_showAverageLine),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // FlChart Line Chart
            if (widget.chartPoints.isEmpty)
              Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900]!.withValues(alpha: 0.4) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Chưa có dữ liệu cữ hút trong kỳ này',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: _buildLineChart(isDark),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: isDark ? 0.25 : 0.1)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.grey[400],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? activeColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(bool isDark) {
    final pts = widget.chartPoints;

    double maxVal = 0;
    for (final p in pts) {
      if (p.amountMl > maxVal) maxVal = p.amountMl.toDouble();
    }
    if (widget.averageMl > maxVal) maxVal = widget.averageMl;
    if (maxVal <= 0) maxVal = 100;
    maxVal = (maxVal / 50).ceil() * 50.0;

    final spots = <FlSpot>[];
    for (int i = 0; i < pts.length; i++) {
      spots.add(FlSpot(i.toDouble(), pts[i].amountMl.toDouble()));
    }

    final avgSpots = <FlSpot>[];
    if (_showAverageLine && widget.averageMl > 0) {
      for (int i = 0; i < pts.length; i++) {
        avgSpots.add(FlSpot(i.toDouble(), widget.averageMl));
      }
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (pts.length - 1).toDouble() > 0 ? (pts.length - 1).toDouble() : 1,
        minY: 0,
        maxY: maxVal,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4 > 0 ? maxVal / 4 : 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: maxVal / 4 > 0 ? maxVal / 4 : 25,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= pts.length) return const SizedBox.shrink();
                // Reduce crowding if more than 6 points
                if (pts.length > 7 && idx % 2 != 0 && idx != pts.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    pts[idx].label,
                    style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => isDark ? Colors.grey[900]! : Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final pt = pts[idx];
                return LineTooltipItem(
                  '${pt.label}\n🍼 ${spot.y.toInt()} ml',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          // Milk Amount Line
          if (_showMilkLine && spots.isNotEmpty)
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.brand500,
              barWidth: 2.5,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.brand500.withValues(alpha: 0.15),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppTheme.brand500,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
            ),

          // Average Line
          if (_showAverageLine && avgSpots.isNotEmpty)
            LineChartBarData(
              spots: avgSpots,
              isCurved: false,
              color: Colors.amber[700]!,
              barWidth: 1.5,
              dashArray: [5, 4],
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }
}
