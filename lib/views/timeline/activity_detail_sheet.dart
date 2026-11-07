import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity_model.dart';
import '../../models/media_model.dart';
import '../../providers/activity_provider.dart';
import '../media/fullscreen_media_viewer.dart';

class ActivityDetailSheet extends StatefulWidget {
  final ActivityModel activity;
  final int babyId;
  final VoidCallback onUpdated;

  const ActivityDetailSheet({
    super.key,
    required this.activity,
    required this.babyId,
    required this.onUpdated,
  });

  @override
  State<ActivityDetailSheet> createState() => _ActivityDetailSheetState();
}

class _ActivityDetailSheetState extends State<ActivityDetailSheet> {
  bool _isEditing = false;
  bool _isSaving = false;

  // Edit fields
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  late TextEditingController _notesCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _nursingMinutesCtrl;
  String? _breastSide;
  String? _sleepQuality;
  String? _diaperType;

  // Attached media
  final ApiClient _api = ApiClient();
  final ImagePicker _picker = ImagePicker();
  List<MediaModel> _activityMedia = [];
  bool _loadingMedia = false;
  bool _uploadingMedia = false;

  @override
  void initState() {
    super.initState();
    _initValues();
    _loadActivityMedia();
  }

  Future<void> _loadActivityMedia() async {
    setState(() => _loadingMedia = true);
    try {
      final res = await _api.getMediaList(babyId: widget.babyId, activityId: widget.activity.id);
      if (res.statusCode == 200) {
        final list = (res.data is Map ? res.data['items'] : res.data) as List? ?? [];
        if (mounted) {
          setState(() {
            _activityMedia = list.map((item) => MediaModel.fromJson(item)).toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingMedia = false);
  }

  Future<void> _pickAndUploadMediaToActivity({bool isVideo = false, ImageSource source = ImageSource.gallery}) async {
    final XFile? picked;
    if (isVideo) {
      picked = await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 5));
    } else {
      picked = await _picker.pickImage(source: source, imageQuality: 85);
    }
    if (picked == null || !mounted) return;

    setState(() => _uploadingMedia = true);
    try {
      final file = File(picked.path);
      final ok = await _api.uploadMedia(
        file,
        widget.babyId,
        activityId: widget.activity.id,
        caption: 'Kèm theo ${_getTypeLabel(widget.activity.activityType)}',
      );
      if (ok.statusCode == 200 || ok.statusCode == 201) {
        await _loadActivityMedia();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isVideo ? 'Đã đính kèm video thành công! 🎥' : 'Đã đính kèm ảnh thành công! 📸'),
              backgroundColor: AppTheme.emerald500,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải file: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
    if (mounted) setState(() => _uploadingMedia = false);
  }

  void _showMediaUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.brand500),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadMediaToActivity(isVideo: false, source: ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined, color: Colors.indigoAccent),
                title: const Text('Chọn video từ thư viện'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadMediaToActivity(isVideo: true, source: ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.emerald500),
                title: const Text('Chụp ảnh ngay'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadMediaToActivity(isVideo: false, source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: Colors.purpleAccent),
                title: const Text('Quay video ngay'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadMediaToActivity(isVideo: true, source: ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initValues() {
    DateTime start = DateTime.now();
    try {
      start = DateTime.parse(widget.activity.startTime).toLocal();
    } catch (_) {}

    TimeOfDay? end;
    if (widget.activity.endTime != null) {
      try {
        final endDt = DateTime.parse(widget.activity.endTime!).toLocal();
        end = TimeOfDay.fromDateTime(endDt);
      } catch (_) {}
    }

    _selectedDate = start;
    _startTime = TimeOfDay.fromDateTime(start);
    _endTime = end;
    _notesCtrl = TextEditingController(text: widget.activity.notes ?? '');
    _amountCtrl = TextEditingController(text: widget.activity.amountMl?.toString() ?? '');
    _nursingMinutesCtrl = TextEditingController(text: widget.activity.nursingMinutes?.toString() ?? '');
    _breastSide = widget.activity.breastSide ?? 'both';
    _sleepQuality = widget.activity.sleepQuality ?? 'good';
    _diaperType = widget.activity.diaperType ?? 'both';
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _amountCtrl.dispose();
    _nursingMinutesCtrl.dispose();
    super.dispose();
  }

  // --- Helpers matching ActivityDetailModal.vue ---
  String _getTypeLabel(String type) {
    switch (type) {
      case 'feeding':
        return 'Cữ bú';
      case 'sleeping':
        return 'Giấc ngủ';
      case 'diaper':
        return 'Thay tã';
      case 'bath':
        return 'Tắm bé';
      case 'play':
        return 'Vận động';
      case 'solid':
        return 'Ăn dặm';
      default:
        return 'Hoạt động';
    }
  }

  String _getMainHighlight(ActivityModel act) {
    if (act.activityType == 'feeding') {
      if (act.feedingType == 'breast') {
        final side = act.breastSide == 'left' ? 'ngực trái' : act.breastSide == 'right' ? 'ngực phải' : 'cả 2 bên';
        return 'Bú mẹ direct ($side)';
      }
      return '${act.amountMl ?? 0} ml sữa bú';
    }
    if (act.activityType == 'sleeping') {
      if (act.durationMinutes != null && act.durationMinutes! > 0) {
        final hours = act.durationMinutes! ~/ 60;
        final mins = act.durationMinutes! % 60;
        return hours > 0 ? '$hours giờ $mins phút' : '$mins phút ngủ ngon';
      }
      return 'Đang trong giấc ngủ...';
    }
    if (act.activityType == 'diaper') {
      if (act.diaperType == 'pee') return 'Bé tè nhiều';
      if (act.diaperType == 'poop') return 'Bé đi ị';
      if (act.diaperType == 'both') return 'Bé vừa tè vừa ị';
      return 'Thay tã sạch';
    }
    if (act.activityType == 'bath') return 'Tắm mát cho bé';
    if (act.activityType == 'play') return 'Tập lẫy / Tummy time';
    if (act.activityType == 'solid') return 'Bữa ăn dặm (${act.amountMl ?? 0}g)';
    return act.title;
  }

  String? _getSubHighlight(ActivityModel act) {
    if (act.activityType == 'solid') {
      return act.notes?.isNotEmpty == true ? act.notes : 'Bữa ăn dặm (Cháo / Bột / Hoa quả)';
    }
    if (act.activityType == 'feeding') {
      if (act.feedingType == 'breast') {
        return act.nursingMinutes != null ? 'Thời gian bú: ${act.nursingMinutes} phút' : null;
      }
      return act.feedingType == 'bottle_breast' ? 'Bú bình • Sữa mẹ vắt ra' : 'Bú bình • Sữa công thức';
    }
    if (act.activityType == 'sleeping') {
      final q = act.sleepQuality == 'good' ? 'Bé ngủ rất ngoan, sâu giấc' : act.sleepQuality == 'restless' ? 'Bé trằn trọc, dễ giật mình' : 'Giấc ngủ bình thường';
      return q;
    }
    return null;
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} • ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  void _finishOngoingFeeding() async {
    final actProv = Provider.of<ActivityProvider>(context, listen: false);
    final ok = await actProv.endBreastFeeding(
      widget.babyId,
      widget.activity.id,
      15,
      side: widget.activity.breastSide,
    );
    if (mounted) {
      if (ok) {
        widget.onUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã kết thúc cữ bú! ✅')));
      }
    }
  }

  void _finishOngoingSleep() async {
    final actProv = Provider.of<ActivityProvider>(context, listen: false);
    final ok = await actProv.endSleep(widget.babyId, widget.activity.id);
    if (mounted) {
      if (ok) {
        widget.onUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bé đã thức dậy! ☀️')));
      }
    }
  }

  void _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Mẹ có chắc chắn muốn xóa bản ghi hoạt động này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final actProv = Provider.of<ActivityProvider>(context, listen: false);
      await actProv.deleteActivity(widget.activity.id, widget.babyId);
      widget.onUpdated();
      if (mounted) Navigator.pop(context);
    }
  }

  void _saveEdit() async {
    setState(() => _isSaving = true);

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    DateTime? endDateTime;
    if (_endTime != null) {
      endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime!.hour,
        _endTime!.minute,
      );
    }

    final data = <String, dynamic>{
      'start_time': startDateTime.toUtc().toIso8601String(),
      if (endDateTime != null) 'end_time': endDateTime.toUtc().toIso8601String(),
      'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    };

    if (widget.activity.activityType == 'feeding') {
      if (widget.activity.feedingType != 'breast') {
        data['amount_ml'] = int.tryParse(_amountCtrl.text);
      } else {
        data['breast_side'] = _breastSide;
        data['nursing_minutes'] = int.tryParse(_nursingMinutesCtrl.text);
      }
    } else if (widget.activity.activityType == 'sleeping') {
      data['sleep_quality'] = _sleepQuality;
    } else if (widget.activity.activityType == 'diaper') {
      data['diaper_type'] = _diaperType;
    } else if (widget.activity.activityType == 'solid') {
      data['amount_ml'] = int.tryParse(_amountCtrl.text);
    }

    try {
      final res = await ApiClient().updateActivity(widget.activity.id, data);
      if (res.statusCode == 200 && mounted) {
        widget.onUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật chi tiết hoạt động! 🎉')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi lưu cập nhật hoạt động')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final act = widget.activity;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // iOS Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray700 : AppTheme.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Modal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray800 : AppTheme.brand50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(act.icon, style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Chỉnh sửa ${_getTypeLabel(act.activityType)}' : 'Chi tiết ${_getTypeLabel(act.activityType)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDateTime(act.startTime),
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              child: _isEditing ? _buildEditForm(isDark) : _buildViewMode(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // --- View Mode Widget ---
  Widget _buildViewMode(bool isDark) {
    final act = widget.activity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Highlights Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray800 : AppTheme.brand50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.brand200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tóm tắt hoạt động',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
              ),
              const SizedBox(height: 4),
              Text(
                _getMainHighlight(act),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              if (_getSubHighlight(act) != null) ...[
                const SizedBox(height: 4),
                Text(
                  _getSubHighlight(act)!,
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray300 : AppTheme.gray700),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Detail Information Rows (Grey Box)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray800.withValues(alpha: 0.5) : AppTheme.gray100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildDetailRow('Loại sinh hoạt:', act.activityType.toUpperCase(), isDark),
              const SizedBox(height: 10),
              _buildDetailRow('Thời gian bắt đầu:', _formatDateTime(act.startTime), isDark),
              if (act.endTime != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow('Thời gian kết thúc:', _formatDateTime(act.endTime), isDark),
              ],
              if (act.durationMinutes != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow('Tổng thời lượng:', '${act.durationMinutes} phút', isDark, isHighlight: true),
              ],

              // Feeding details
              if (act.activityType == 'feeding') ...[
                const SizedBox(height: 10),
                _buildDetailRow('Hình thức bú:', act.feedingType == 'breast' ? 'Bú mẹ direct' : 'Bú bình', isDark),
                if (act.amountMl != null) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow('Lượng sữa:', '${act.amountMl} ml', isDark, isHighlight: true),
                ],
                if (act.breastSide != null) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow('Bên bú:', act.breastSide == 'left' ? 'Ngực trái' : act.breastSide == 'right' ? 'Ngực phải' : 'Cả 2 bên', isDark),
                ],
                if (act.nursingMinutes != null) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow('Thời gian bú mẹ:', '${act.nursingMinutes} phút', isDark),
                ],
              ],

              // Sleeping details
              if (act.activityType == 'sleeping') ...[
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Chất lượng giấc ngủ:',
                  act.sleepQuality == 'good' ? 'Ngoan / Sâu giấc' : act.sleepQuality == 'restless' ? 'Trằn trọc' : 'Bình thường',
                  isDark,
                ),
              ],

              // Diaper details
              if (act.activityType == 'diaper') ...[
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Phân loại tã:',
                  act.diaperType == 'pee' ? 'Tè' : act.diaperType == 'poop' ? 'Ị' : 'Tè + Ị',
                  isDark,
                ),
              ],

              // Solid details
              if (act.activityType == 'solid') ...[
                if (act.amountMl != null) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow('Lượng ăn dặm:', '${act.amountMl} ml / gam', isDark, isHighlight: true),
                ],
                const SizedBox(height: 10),
                _buildDetailRow('Hình thức:', 'Cháo / Bột / Hoa quả', isDark),
              ],

              if (act.activityType == 'feeding' || act.activityType == 'sleeping') ...[
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Trạng thái:',
                  act.endTime != null
                      ? 'Đã hoàn thành'
                      : (act.activityType == 'feeding' ? 'Đang trong cữ bú' : 'Đang trong giấc ngủ'),
                  isDark,
                  statusColor: act.endTime != null
                      ? AppTheme.emerald500
                      : (act.activityType == 'feeding' ? AppTheme.brand500 : Colors.amber.shade700),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Notes section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray800 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ghi chú của mẹ:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
              ),
              const SizedBox(height: 4),
              Text(
                act.notes?.isNotEmpty == true ? act.notes! : 'Không có ghi chú thêm.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? AppTheme.gray300 : AppTheme.gray800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Ongoing Action Cards (End Feeding / Wake up)
        if (act.activityType == 'feeding' && act.endTime == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.brand500.withValues(alpha: 0.15) : AppTheme.brand50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.brand500.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 10, color: AppTheme.brand500),
                    SizedBox(width: 6),
                    Text('Bé đang trong cữ bú...', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brand500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald500),
                    icon: const Text('✅', style: TextStyle(fontSize: 16)),
                    label: const Text('Kết thúc cữ bú ngay'),
                    onPressed: _finishOngoingFeeding,
                  ),
                ),
              ],
            ),
          ),

        if (act.activityType == 'sleeping' && act.endTime == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.indigo900.withValues(alpha: 0.2) : AppTheme.indigo50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.indigo500.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 10, color: AppTheme.indigo500),
                    SizedBox(width: 6),
                    Text('Bé đang ngủ ngon...', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.indigo500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                    icon: const Text('☀️', style: TextStyle(fontSize: 16)),
                    label: const Text('Bé đã dậy'),
                    onPressed: _finishOngoingSleep,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 14),

        // 4b. Attached Media Section (Images & Videos)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('📷', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'Hình ảnh & Video đính kèm (${_activityMedia.length})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _uploadingMedia ? null : () => _showMediaUploadOptions(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.brand500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.brand500.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, size: 13, color: AppTheme.brand500),
                          const SizedBox(width: 3),
                          Text(
                            _uploadingMedia ? 'Đang tải...' : '+ Thêm file',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.brand500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_loadingMedia)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_activityMedia.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Chưa có ảnh hoặc video nào đính kèm cữ này.',
                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.gray400 : AppTheme.gray500),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activityMedia.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (ctx, idx) {
                    final item = _activityMedia[idx];
                    String fullUrl = item.fileUrl;
                    if (!fullUrl.startsWith('http')) {
                      final baseHost = AppConfig.baseUrl.replaceAll('/api', '');
                      fullUrl = '$baseHost$fullUrl';
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        FullscreenMediaViewer.show(
                          context,
                          items: _activityMedia,
                          initialIndex: idx,
                          babyId: widget.babyId,
                          onDelete: (delItem) async {
                            await _api.deleteMedia(delItem.id);
                            await _loadActivityMedia();
                          },
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item.isVideo
                            ? Container(
                                color: Colors.grey.shade900,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    const Center(
                                      child: Icon(Icons.play_circle_fill_rounded, size: 36, color: Colors.white),
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.videocam, size: 9, color: Colors.white),
                                            SizedBox(width: 2),
                                            Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: fullUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                                errorWidget: (_, __, ___) => Container(
                                  color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                                  child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                ),
                              ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 5. Footer Buttons: Chỉnh sửa & Xóa bản ghi
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.gray800 : AppTheme.gray200,
                  foregroundColor: isDark ? Colors.white : AppTheme.gray900,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Text('✏️'),
                label: const Text('Chỉnh sửa'),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Text('🗑️'),
                label: const Text('Xóa bản ghi'),
                onPressed: _delete,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool isHighlight = false, Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: statusColor ?? (isHighlight ? AppTheme.brand500 : (isDark ? Colors.white : AppTheme.gray900)),
          ),
        ),
      ],
    );
  }

  // --- Edit Mode Widget ---
  Widget _buildEditForm(bool isDark) {
    final act = widget.activity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date & Start Time Pickers
        Row(
          children: [
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200)),
                leading: const Icon(Icons.calendar_today, size: 16, color: AppTheme.brand500),
                title: const Text('Ngày', style: TextStyle(fontSize: 11)),
                subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200)),
                leading: const Icon(Icons.access_time, size: 16, color: AppTheme.brand500),
                title: const Text('Giờ bắt đầu', style: TextStyle(fontSize: 11)),
                subtitle: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _startTime);
                  if (picked != null) setState(() => _startTime = picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // End Time Picker
        if (act.activityType == 'sleeping' || act.activityType == 'feeding' || act.endTime != null) ...[
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? AppTheme.gray700 : AppTheme.gray200)),
            leading: const Icon(Icons.flag_outlined, size: 18, color: AppTheme.brand500),
            title: Text(act.activityType == 'sleeping' ? '☀️ Giờ thức dậy' : '🏁 Giờ kết thúc', style: const TextStyle(fontSize: 11)),
            subtitle: Text(
              _endTime != null ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}' : 'Chưa kết thúc (Bấm để chọn)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            trailing: _endTime != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => setState(() => _endTime = null),
                  )
                : null,
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay.now());
              if (picked != null) setState(() => _endTime = picked);
            },
          ),
          const SizedBox(height: 12),
        ],

        // Feeding amount / nursing minutes
        if (act.activityType == 'feeding' && act.feedingType != 'breast') ...[
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Số ml sữa bú', suffixText: 'ml', prefixIcon: Icon(Icons.water_drop_outlined)),
          ),
          const SizedBox(height: 12),
        ],

        if (act.activityType == 'solid') ...[
          const Text('Lượng ăn dặm (ml hoặc gam):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [30, 50, 80, 100, 120, 150, 200, 250].map((g) {
              final isSel = _amountCtrl.text == g.toString();
              return ChoiceChip(
                label: Text('${g}g', style: const TextStyle(fontSize: 12)),
                selected: isSel,
                selectedColor: Colors.amber.shade600,
                onSelected: (_) => setState(() => _amountCtrl.text = g.toString()),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số lượng (ml / gam)',
              suffixText: 'g',
              prefixIcon: Icon(Icons.restaurant, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (act.activityType == 'feeding' && act.feedingType == 'breast') ...[
          const Text('Bên ngực bú:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Trái', style: TextStyle(fontSize: 12)),
                selected: _breastSide == 'left',
                onSelected: (_) => setState(() => _breastSide = 'left'),
              ),
              ChoiceChip(
                label: const Text('Phải', style: TextStyle(fontSize: 12)),
                selected: _breastSide == 'right',
                onSelected: (_) => setState(() => _breastSide = 'right'),
              ),
              ChoiceChip(
                label: const Text('Cả hai', style: TextStyle(fontSize: 12)),
                selected: _breastSide == 'both',
                onSelected: (_) => setState(() => _breastSide = 'both'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nursingMinutesCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Thời gian bú mẹ (phút)', suffixText: 'phút', prefixIcon: Icon(Icons.timer_outlined)),
          ),
          const SizedBox(height: 12),
        ],

        if (act.activityType == 'sleeping') ...[
          const Text('Chất lượng giấc ngủ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('😴 Ngoan / Sâu giấc', style: TextStyle(fontSize: 12)),
                selected: _sleepQuality == 'good',
                onSelected: (_) => setState(() => _sleepQuality = 'good'),
              ),
              ChoiceChip(
                label: const Text('🙂 Bình thường', style: TextStyle(fontSize: 12)),
                selected: _sleepQuality == 'normal',
                onSelected: (_) => setState(() => _sleepQuality = 'normal'),
              ),
              ChoiceChip(
                label: const Text('🥱 Trằn trọc / Khó ngủ', style: TextStyle(fontSize: 12)),
                selected: _sleepQuality == 'restless',
                onSelected: (_) => setState(() => _sleepQuality = 'restless'),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        if (act.activityType == 'diaper') ...[
          const Text('Loại tã:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('💧 Tè', style: TextStyle(fontSize: 12)),
                selected: _diaperType == 'pee',
                onSelected: (_) => setState(() => _diaperType = 'pee'),
              ),
              ChoiceChip(
                label: const Text('💩 Ị', style: TextStyle(fontSize: 12)),
                selected: _diaperType == 'poop',
                onSelected: (_) => setState(() => _diaperType = 'poop'),
              ),
              ChoiceChip(
                label: const Text('💧💩 Cả hai', style: TextStyle(fontSize: 12)),
                selected: _diaperType == 'both',
                onSelected: (_) => setState(() => _diaperType = 'both'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Notes
        TextField(
          controller: _notesCtrl,
          decoration: const InputDecoration(labelText: 'Ghi chú của mẹ', prefixIcon: Icon(Icons.edit_note)),
        ),
        const SizedBox(height: 20),

        // Save / Cancel Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Hủy'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _isSaving ? null : _saveEdit,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lưu thay đổi'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
