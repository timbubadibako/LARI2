import 'package:flutter/material.dart';
import '../theme/stride_colors.dart';
import '../theme/stride_typography.dart';

class V3InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isPassword;
  final TextInputType? keyboardType;
  final Color? activeBorderColor;
  final Color? inactiveBorderColor;
  final Iterable<String>? autofillHints;

  const V3InputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.keyboardType,
    this.activeBorderColor,
    this.inactiveBorderColor,
    this.autofillHints,
  });

  @override
  State<V3InputField> createState() => _V3InputFieldState();
}

class _V3InputFieldState extends State<V3InputField> {
  bool _obscureText = true;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.isPassword;
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeBorderColor ?? StrideColors.neonGreen;
    final inactiveColor = widget.inactiveBorderColor ?? StrideColors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: StrideTypography.labelTactical.copyWith(
            fontSize: 9, 
            color: _isFocused ? activeColor : StrideColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: StrideColors.surface,
            border: Border(
              left: BorderSide(
                color: _isFocused ? activeColor : inactiveColor,
                width: 4,
              ),
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            autofillHints: widget.autofillHints,
            style: StrideTypography.labelBold.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: StrideTypography.labelBold.copyWith(fontSize: 14, color: StrideColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _isFocused ? activeColor : Colors.white38,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
