import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/milk_warming_model.dart';
import '../../../../providers/milk_warming_provider.dart';

class MilkWarmingFormSheet extends StatefulWidget {
  final MilkWarmingRecordModel? record;
  final int? babyId;

  const MilkWarmingFormSheet({super.key, this.record, this.babyId});

  @override
  State<MilkWarmingFormSheet> createState() => _MilkWarmingFormSheetState();
}

class _MilkWarmingFormSheetState extends State<MilkWarmingFormSheet> {
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  DateTime _startTime = DateTime.now().subtract(const Duration(minutes: 5));
  DateTime _endTime = DateTime.now();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _amountController = TextEditingController(text: widget.record!.amountMl.toString());
      _notesController = TextEditingController(text: widget.record!.notes ?? '');
      if (widget.record!.startDateTime != null) _startTime = widget.record!.startDateTime!.toLocal();
      if (widget.record!.endDateTime != null) _endTime = widget.record!.endDateTime!.toLocal();
    } else {
      _amountController = TextEditingController(text: '120');
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null || !mounted) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = combined;
      } else {
        _endTime = combined;
      }
    });
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Vui lòng nhập số mililit sữa');
      return;
    }
    if (_endTime.isBefore(_startTime)) {
      setState(() => _errorMessage = 'Thời gian kết thúc không thể trước thời gian bắt đầu');
      return;
    }

    setState(() => _errorMessage = null);
    final provider = Provider.of<MilkWarmingProvider>(context, listen: false);

    bool success;
    if (widget.record != null) {
      success = await provider.updateRecord(
        widget.record!.id,
        babyId: widget.babyId,
        startTime: _startTime,
        endTime: _endTime,
        amountMl: amount,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
    } else {
      success = await provider.createManual(
        babyId: widget.babyId,
        startTime: _startTime,
        endTime: _endTime,
        amountMl: amount,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
    }

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage = 'Lỗi khi lưu cữ hâm sữa');
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.record != null ? 'Sửa cữ hâm sữa' : 'Nhập thủ công cữ hâm',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Amount
          const Text('Số lượng sữa (ml)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '120',
              suffixText: 'ml',
              filled: true,
              fillColor: isDark ? AppTheme.gray800 : AppTheme.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Start & End Times
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bắt đầu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _pickDateTime(true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.gray800 : AppTheme.gray50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                        ),
                        child: Text(
                          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')} - ${_startTime.day}/${_startTime.month}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kết thúc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _pickDateTime(false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.gray800 : AppTheme.gray50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                        ),
                        child: Text(
                          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')} - ${_endTime.day}/${_endTime.month}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Notes
          const Text('Ghi chú (tùy chọn)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ghi chú...',
              filled: true,
              fillColor: isDark ? AppTheme.gray800 : AppTheme.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: provider.isActionLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand500,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                provider.isActionLoading ? 'Đang lưu...' : (widget.record != null ? 'Lưu thay đổi' : 'Lưu cữ hâm'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
