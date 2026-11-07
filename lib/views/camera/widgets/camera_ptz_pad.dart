import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CameraPtzPad extends StatelessWidget {
  final Function(String direction) onDirection;
  final String cameraName;

  const CameraPtzPad({
    super.key,
    required this.onDirection,
    required this.cameraName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.control_camera, size: 16, color: AppTheme.brand500),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Điều khiển góc xoay Camera (PTZ) • $cameraName',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Circular D-Pad
          Container(
            width: 154,
            height: 154,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Up
                Positioned(
                  top: 4,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 28),
                    color: isDark ? Colors.white : AppTheme.gray800,
                    onPressed: () => onDirection('up'),
                    tooltip: 'Xoay lên',
                  ),
                ),
                // Down
                Positioned(
                  bottom: 4,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                    color: isDark ? Colors.white : AppTheme.gray800,
                    onPressed: () => onDirection('down'),
                    tooltip: 'Xoay xuống',
                  ),
                ),
                // Left
                Positioned(
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 28),
                    color: isDark ? Colors.white : AppTheme.gray800,
                    onPressed: () => onDirection('left'),
                    tooltip: 'Xoay trái',
                  ),
                ),
                // Right
                Positioned(
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 28),
                    color: isDark ? Colors.white : AppTheme.gray800,
                    onPressed: () => onDirection('right'),
                    tooltip: 'Xoay phải',
                  ),
                ),
                // Center (Stop)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.stop_circle_outlined, size: 18, color: AppTheme.brand500),
                    onPressed: () => onDirection('stop'),
                    tooltip: 'Dừng xoay',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
