import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/milk_warming_provider.dart';

class MilkWarmingQuickSheet extends StatefulWidget {
  final int? babyId;

  const MilkWarmingQuickSheet({super.key, this.babyId});

  @override
  State<MilkWarmingQuickSheet> createState() => _MilkWarmingQuickSheetState();
}

class _MilkWarmingQuickSheetState extends State<MilkWarmingQuickSheet> {
  final TextEditingController _amountController = TextEditingController(text: '120');
  final TextEditingController _notesController = TextEditingController();
  int _selectedAmount = 120;
  String? _errorMessage;

  final List<int> _quickAmounts = [60, 90, 120, 150, 180, 210, 240];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountSelected(int val) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAmount = val;
      _amountController.text = val.toString();
    });
  }

  Future<void> _submit() async {
    final text = _amountController.text.trim();
    final amount = int.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Vui lòng nhập số mililit sữa');
      return;
    }

    setState(() => _errorMessage = null);
    final provider = Provider.of<MilkWarmingProvider>(context, listen: false);

    final success = await provider.quickStart(
      babyId: widget.babyId,
      amountMl: amount,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (!mounted) return;
    if (success) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage = 'Đang có cữ hâm chưa kết thúc hoặc lỗi kết nối');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<MilkWarmingProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('♨️', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ghi nhanh lịch hâm',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Bắt đầu: Ngay bây giờ (tự động)',
                      style: TextStyle(fontSize: 11.5, color: Colors.amber.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question: How many ml?
          const Text(
            'Bao nhiêu mililit sữa? (ml)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '120',
              suffixText: 'ml',
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              filled: true,
              fillColor: isDark ? AppTheme.gray800 : AppTheme.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.amber, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (val) {
              final parsed = int.tryParse(val);
              setState(() {
                _selectedAmount = parsed ?? 0;
              });
            },
          ),
          const SizedBox(height: 12),

          // Quick chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((val) {
              final isSel = _selectedAmount == val;
              return ChoiceChip(
                label: Text('$val ml', style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                selected: isSel,
                onSelected: (_) => _onAmountSelected(val),
                selectedColor: Colors.amber.shade600,
                backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray100,
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Optional notes
          TextField(
            controller: _notesController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ghi chú thêm (tùy chọn, vd: sữa ngăn mát)...',
              filled: true,
              fillColor: isDark ? AppTheme.gray800 : AppTheme.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: provider.isActionLoading ? null : _submit,
              icon: provider.isActionLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('🔥', style: TextStyle(fontSize: 16)),
              label: Text(
                provider.isActionLoading ? 'Đang tạo...' : 'Bắt đầu hâm ngay',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
