import 'package:flutter/material.dart';
import '../theme/stride_colors.dart';
import '../theme/stride_typography.dart';

class TacticalButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final Color? color;

  const TacticalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.color,
  });

  @override
  State<TacticalButton> createState() => _TacticalButtonState();
}

class _TacticalButtonState extends State<TacticalButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? StrideColors.sapphire;
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: StrideColors.background, size: 20),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  widget.label.toUpperCase(),
                  style: StrideTypography.labelTactical.copyWith(
                    color: StrideColors.background,
                    letterSpacing: 2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
