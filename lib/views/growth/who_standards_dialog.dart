import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class WHOStandardsDialog extends StatefulWidget {
  final String gender;
  final int? currentBabyMonths;

  const WHOStandardsDialog({
    super.key,
    required this.gender,
    this.currentBabyMonths,
  });

  @override
  State<WHOStandardsDialog> createState() => _WHOStandardsDialogState();
}

class _WHOStandardsDialogState extends State<WHOStandardsDialog> {
  List<dynamic> _standards = [];
  bool _isLoading = true;
  late String _gender;

  @override
  void initState() {
    super.initState();
    _gender = widget.gender;
    _fetchStandards();
  }

  void _fetchStandards() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().getWhoStandards(gender: _gender, maxMonths: 36);
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _standards = (res.data is List ? res.data : res.data['standards']) ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('📏', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bảng chuẩn WHO (${_gender == "girl" ? "Bé Gái 👧" : "Bé Trai 👦"})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Bé Gái 👧'),
                  selected: _gender == 'girl',
                  onSelected: (_) {
                    setState(() => _gender = 'girl');
                    _fetchStandards();
                  },
                ),
                ChoiceChip(
                  label: const Text('Bé Trai 👦'),
                  selected: _gender == 'boy',
                  onSelected: (_) {
                    setState(() => _gender = 'boy');
                    _fetchStandards();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            // Header Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              color: isDark ? AppTheme.gray800 : AppTheme.gray100,
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Tháng tuổi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Cân nặng (kg)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Chiều cao (cm)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _standards.length,
                      itemBuilder: (context, index) {
                        final item = _standards[index];
                        final m = item['month'] ?? index;
                        final isCurrent = widget.currentBabyMonths != null && widget.currentBabyMonths == m;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? (isDark ? AppTheme.brand500.withValues(alpha: 0.25) : AppTheme.brand50)
                                : (index % 2 == 0 ? (isDark ? AppTheme.gray900 : Colors.white) : (isDark ? AppTheme.gray800 : AppTheme.gray50)),
                            border: isCurrent ? Border.all(color: AppTheme.brand500, width: 1.5) : null,
                            borderRadius: isCurrent ? BorderRadius.circular(8) : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  m == 0 ? 'Mới sinh' : '$m tháng ${isCurrent ? "🎂" : ""}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrent ? AppTheme.brand500 : null,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '${item['weight_median'] ?? "--"} kg (${item['weight_sd_neg2'] ?? "--"} - ${item['weight_sd_pos2'] ?? "--"})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '${item['height_median'] ?? "--"} cm',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
