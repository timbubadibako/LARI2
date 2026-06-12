import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HoldActionButton extends StatefulWidget {
  final VoidCallback onComplete;
  final String label;
  final IconData? icon;
  final Color baseColor;
  final Color progressColor;
  final Color textColor;
  final Duration holdDuration;
  final double height;
  final double? width;
  final bool isOutlined;
  final BorderRadiusGeometry? borderRadius;
  final TextStyle? textStyle;

  const HoldActionButton({
    super.key,
    required this.onComplete,
    required this.label,
    this.icon,
    required this.baseColor,
    required this.progressColor,
    required this.textColor,
    this.holdDuration = const Duration(milliseconds: 1500),
    this.height = 56.0,
    this.width,
    this.isOutlined = false,
    this.borderRadius,
    this.textStyle,
  });

  @override
  State<HoldActionButton> createState() => _HoldActionButtonState();
}

class _HoldActionButtonState extends State<HoldActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.holdDuration);
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await HapticFeedback.heavyImpact();
        widget.onComplete();
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(12);

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: widget.isOutlined ? Colors.transparent : widget.baseColor,
              borderRadius: effectiveBorderRadius,
              border: widget.isOutlined
                  ? Border.all(color: widget.baseColor)
                  : null,
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // Progress fill
                if (progress > 0)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(color: widget.progressColor),
                      ),
                    ),
                  ),
                // Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: widget.textColor),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            style: widget.textStyle ?? TextStyle(
                              color: widget.textColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: widget.isOutlined ? 2.0 : 0.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
