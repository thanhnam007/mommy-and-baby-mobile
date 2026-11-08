import 'package:flutter/material.dart';

/// Reusable Button supporting an automatic or external loading/processing state.
/// Automatically disables on click to prevent duplicate submits and debounces double-taps.
class LoadingButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget? child;
  final String? label;
  final String? loadingLabel;
  final Widget? icon;
  final ButtonStyle? style;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? spinnerColor;

  const LoadingButton({
    super.key,
    required this.onPressed,
    this.child,
    this.label,
    this.loadingLabel,
    this.icon,
    this.style,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.spinnerColor,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _internalLoading = false;
  DateTime? _lastPressedAt;

  bool get _effectiveLoading => widget.isLoading || _internalLoading;

  Future<void> _handlePressed() async {
    if (widget.onPressed == null || _effectiveLoading) return;

    // Cooldown debounce (500ms) to prevent hardware/rapid double-clicks
    final now = DateTime.now();
    if (_lastPressedAt != null && now.difference(_lastPressedAt!).inMilliseconds < 500) {
      return;
    }
    _lastPressedAt = now;

    setState(() => _internalLoading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _internalLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = _effectiveLoading ? null : _handlePressed;

    final childWidget = _effectiveLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.spinnerColor ?? Colors.white,
                  ),
                ),
              ),
              if (widget.loadingLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.loadingLabel!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          )
        : (widget.child ??
            (widget.icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.icon!,
                      const SizedBox(width: 8),
                      Text(
                        widget.label ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : Text(
                    widget.label ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )));

    final button = ElevatedButton(
      style: widget.style,
      onPressed: effectiveOnPressed,
      child: childWidget,
    );

    if (widget.width != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: button,
      );
    }

    return SizedBox(
      height: widget.height,
      child: button,
    );
  }
}
