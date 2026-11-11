import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/milk_warming_provider.dart';
import '../../milk_warming/milk_warming_view.dart';
import '../../milk_warming/widgets/milk_warming_quick_sheet.dart';

class MilkWarmingDashboardCard extends StatelessWidget {
  final int? babyId;

  const MilkWarmingDashboardCard({super.key, this.babyId});

  void _openQuickSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MilkWarmingQuickSheet(babyId: babyId),
    );
  }

  void _openFullView(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MilkWarmingView(babyId: babyId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    MilkWarmingProvider? maybeProvider;
    try {
      maybeProvider = Provider.of<MilkWarmingProvider>(context);
    } catch (_) {
      maybeProvider = null;
    }
    if (maybeProvider == null) {
      return const SizedBox.shrink();
    }
    final MilkWarmingProvider provider = maybeProvider;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isWarming = provider.isWarming;
    final isOver2h = provider.liveIsOver2Hours;
    final lastCompleted = provider.status?.lastCompletedWarming;

    Color borderColor;
    Color bgColor;

    if (isWarming) {
      borderColor = Colors.amber.shade400;
      bgColor = isDark ? Colors.amber.shade900.withValues(alpha: 0.25) : const Color(0xFFFFFBEB);
    } else if (isOver2h) {
      borderColor = Colors.red.shade300;
      bgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.25) : const Color(0xFFFEF2F2);
    } else if (lastCompleted != null) {
      borderColor = const Color(0xFF6EE7B7);
      bgColor = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5);
    } else {
      borderColor = isDark ? AppTheme.gray800 : AppTheme.gray200;
      bgColor = isDark ? AppTheme.gray900 : Colors.white;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isWarming
                          ? Colors.amber.shade100
                          : isOver2h
                              ? Colors.red.shade100
                              : lastCompleted != null
                                  ? const Color(0xFFD1FAE5)
                                  : (isDark ? AppTheme.gray800 : AppTheme.gray100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        isWarming ? '♨️' : isOver2h ? '⚠️' : '🍼',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lịch hâm sữa',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isWarming
                            ? 'Đang hâm bình ${provider.status?.activeWarming?.amountMl}ml'
                            : isOver2h
                                ? 'Đã quá 2h an toàn'
                                : lastCompleted != null
                                    ? 'Bình gần nhất: ${lastCompleted.amountMl}ml'
                                    : 'Chưa hâm sữa hôm nay',
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
                      ),
                    ],
                  ),
                ],
              ),

              // Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isWarming
                      ? Colors.amber.shade600
                      : isOver2h
                          ? Colors.red.shade600
                          : lastCompleted != null
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isWarming
                      ? 'Đang hâm'
                      : isOver2h
                          ? 'Cần hâm sữa mới'
                          : lastCompleted != null
                              ? 'Sữa còn dùng được'
                              : 'Chưa hâm',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Body State
          if (isWarming) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thời gian đang hâm (Live):',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '⏱️ ${MilkWarmingProvider.formatSecondsToDigital(provider.liveActiveDurationSeconds)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber.shade900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${provider.status?.activeWarming?.amountMl} ml',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: provider.isActionLoading
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              await provider.endWarming(provider.status!.activeWarming!.id, babyId: babyId);
                            },
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Kết thúc hâm',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: provider.isActionLoading
                        ? null
                        : () => provider.cancelWarming(provider.status!.activeWarming!.id, babyId),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else if (isOver2h) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CẦN HÂM SỮA MỚI',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        Text(
                          '⏱️ Đã quá 2 tiếng (${MilkWarmingProvider.formatSecondsToDurationText(provider.liveSecondsSinceLastWarming ?? 0)} trước)',
                          style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () => _openQuickSheet(context),
                      icon: const Text('⚡', style: TextStyle(fontSize: 14)),
                      label: const Text(
                        'Ghi nhanh lịch hâm',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => _openFullView(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lịch sử', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else if (lastCompleted != null) ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Đã hâm cách đây:', style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          MilkWarmingProvider.formatElapsedAgo(lastCompleted.endDateTime),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Còn an toàn:', style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          '⏱️ ${MilkWarmingProvider.formatSecondsToDurationText(provider.liveSafeRemainingSeconds ?? 0)}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.teal, fontFamily: 'monospace'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () => _openQuickSheet(context),
                      icon: const Text('⚡', style: TextStyle(fontSize: 14)),
                      label: const Text(
                        'Ghi nhanh lịch hâm',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => _openFullView(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lịch sử', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Chưa ghi nhận cữ hâm nào hôm nay. Bấm ghi nhanh để bắt đầu theo dõi hạn 2h của bình sữa.',
              style: TextStyle(fontSize: 11.5, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () => _openQuickSheet(context),
                      icon: const Text('⚡', style: TextStyle(fontSize: 14)),
                      label: const Text(
                        'Ghi nhanh lịch hâm',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => _openFullView(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lịch sử', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],

          // Correlation Today Strip
          if (provider.overview?.todayCorrelation != null) ...[
            Builder(
              builder: (context) {
                final corr = provider.overview!.todayCorrelation!;
                if (corr.warmedTotalMl == 0 && corr.consumedWarmedMl == 0) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Divider(height: 1, color: isDark ? AppTheme.gray800 : AppTheme.gray200),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openFullView(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('⚖️', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                'Hôm nay bé bú: ${corr.consumedWarmedMl}/${corr.warmedTotalMl}ml',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            corr.consumptionRatioPercent != null
                                ? '${corr.consumptionRatioPercent!.toStringAsFixed(1)}% tiêu thụ →'
                                : 'Chi tiết →',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
