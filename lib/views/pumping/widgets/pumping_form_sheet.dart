import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/pumping_model.dart';

class PumpingFormSheet extends StatefulWidget {
  final PumpingRecordModel? record;
  final Function({
    required DateTime startTime,
    required DateTime endTime,
    required int amountMl,
    required String breastSide,
    int? leftAmountMl,
    int? rightAmountMl,
    String? notes,
  }) onSave;
  final VoidCallback? onDelete;

  const PumpingFormSheet({
    super.key,
    this.record,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<PumpingFormSheet> createState() => _PumpingFormSheetState();
}

class _PumpingFormSheetState extends State<PumpingFormSheet> {
  late DateTime _startTime;
  late DateTime _endTime;
  late TextEditingController _amountCtrl;
  late TextEditingController _leftCtrl;
  late TextEditingController _rightCtrl;
  late TextEditingController _notesCtrl;
  String _breastSide = 'both';
  bool _showSplit = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.record != null) {
      _startTime = DateTime.tryParse(widget.record!.startTime)?.toLocal() ?? now.subtract(const Duration(minutes: 20));
      _endTime = DateTime.tryParse(widget.record!.endTime)?.toLocal() ?? now;
      _amountCtrl = TextEditingController(text: widget.record!.amountMl.toString());
      _leftCtrl = TextEditingController(text: widget.record!.leftAmountMl?.toString() ?? '');
      _rightCtrl = TextEditingController(text: widget.record!.rightAmountMl?.toString() ?? '');
      _notesCtrl = TextEditingController(text: widget.record!.notes ?? '');
      _breastSide = widget.record!.breastSide;
      if (widget.record!.leftAmountMl != null || widget.record!.rightAmountMl != null) {
        _showSplit = true;
      }
    } else {
      _startTime = now.subtract(const Duration(minutes: 20));
      _endTime = now;
      _amountCtrl = TextEditingController(text: '120');
      _leftCtrl = TextEditingController();
      _rightCtrl = TextEditingController();
      _notesCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _leftCtrl.dispose();
    _rightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _durationMinutes {
    final diff = _endTime.difference(_startTime).inMinutes;
    return diff > 0 ? diff : 0;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialDate = isStart ? _startTime : _endTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startTime = combined;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(minutes: 20));
        }
      } else {
        _endTime = combined;
      }
    });
  }

  void _addAmount(int val) {
    final curr = int.tryParse(_amountCtrl.text) ?? 0;
    _amountCtrl.text = (curr + val).toString();
  }

  void _onSplitChanged() {
    final left = int.tryParse(_leftCtrl.text) ?? 0;
    final right = int.tryParse(_rightCtrl.text) ?? 0;
    if (left > 0 || right > 0) {
      _amountCtrl.text = (left + right).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('HH:mm dd/MM');

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🍼', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      widget.record != null ? 'Chỉnh Sửa Cữ Hút' : 'Ghi Cữ Hút Sữa',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start & End Time Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(isStart: true),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🕒 Bắt đầu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            dateFormat.format(_startTime),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(isStart: false),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⏱️ Kết thúc', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            dateFormat.format(_endTime),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Duration badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.brand500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thời lượng cữ hút:', style: TextStyle(fontSize: 11, color: AppTheme.brand500, fontWeight: FontWeight.w600)),
                  Text('$_durationMinutes phút', style: const TextStyle(fontSize: 12, color: AppTheme.brand500, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Total Amount ml
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Tổng lượng sữa (ml) *',
                hintText: 'VD: 140',
                suffixText: 'ml',
                prefixIcon: const Icon(Icons.water_drop_outlined, color: AppTheme.brand500),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 8),

            // Quick add chips
            Row(
              children: [
                const Text('Nhanh: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                for (final v in [20, 30, 50, 100])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text('+$v', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      padding: EdgeInsets.zero,
                      onPressed: () => _addAmount(v),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Breast side selector
            const Text('Bên ngực hút:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildSideBtn('both', 'Cả 2 bên ✌️'),
                const SizedBox(width: 8),
                _buildSideBtn('left', 'Trái 👈'),
                const SizedBox(width: 8),
                _buildSideBtn('right', 'Phải 👉'),
              ],
            ),

            const SizedBox(height: 14),

            // Split Toggle
            InkWell(
              onTap: () => setState(() => _showSplit = !_showSplit),
              child: Row(
                children: [
                  Icon(_showSplit ? Icons.arrow_drop_down : Icons.arrow_right, size: 20),
                  Text(
                    _showSplit ? 'Thu gọn chia Trái / Phải' : 'Chia chi tiết lượng sữa Trái / Phải (tùy chọn)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brand500),
                  ),
                ],
              ),
            ),

            if (_showSplit) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _leftCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _onSplitChanged(),
                      decoration: InputDecoration(
                        labelText: 'Ngực trái (ml)',
                        suffixText: 'ml',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _rightCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _onSplitChanged(),
                      decoration: InputDecoration(
                        labelText: 'Ngực phải (ml)',
                        suffixText: 'ml',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Ghi chú cữ hút',
                hintText: 'VD: Sữa vàng, trữ đông tủ đá...',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                if (widget.record != null && widget.onDelete != null)
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Xóa cữ này',
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final amount = int.tryParse(_amountCtrl.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập lượng sữa (ml)')),
                      );
                      return;
                    }
                    widget.onSave(
                      startTime: _startTime,
                      endTime: _endTime,
                      amountMl: amount,
                      breastSide: _breastSide,
                      leftAmountMl: int.tryParse(_leftCtrl.text),
                      rightAmountMl: int.tryParse(_rightCtrl.text),
                      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(widget.record != null ? 'Cập nhật' : 'Lưu cữ hút'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBtn(String side, String label) {
    final isSelected = _breastSide == side;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _breastSide = side),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.brand500 : Colors.grey.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
