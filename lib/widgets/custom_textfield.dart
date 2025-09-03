import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final bool autoFocus;
  final int? maxLines;
  final Duration animationDuration;
  final Color focusedBorderColor;
  final Color enabledBorderColor;
  final double borderWidth;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.autoFocus = false,
    this.maxLines = 1,
    this.animationDuration = const Duration(milliseconds: 300),
    this.focusedBorderColor = Colors.blueAccent,
    this.enabledBorderColor = Colors.grey,
    this.borderWidth = 1.5,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _labelAnimation;
  late Animation<Color?> _borderColorAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _labelAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _borderColorAnimation = ColorTween(
      begin: widget.enabledBorderColor,
      end: widget.focusedBorderColor,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    setState(() => _isFocused = hasFocus);
    hasFocus ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Correction de la déclaration

    return Focus(
      onFocusChange: _onFocusChange,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label animé
              if (widget.labelText != null)
                Transform.translate(
                  offset: Offset(0, 10 - (_labelAnimation.value * 10)),
                  child: Opacity(
                    opacity: _labelAnimation.value,
                    child: Text(
                      widget.labelText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _borderColorAnimation.value,
                      ),
                    ),
                  ),
                ),

              // Champ de texte
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isFocused
                      ? [
                    BoxShadow(
                      color: widget.focusedBorderColor.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                      : null,
                ),
                child: TextFormField(
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator,
                  autofocus: widget.autoFocus,
                  maxLines: widget.maxLines,
                  onChanged: widget.onChanged,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: widget.prefixIcon != null
                        ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: IconTheme(
                        data: IconThemeData(
                          color: _isFocused
                              ? widget.focusedBorderColor
                              : Colors.grey.shade600,
                        ),
                        child: widget.prefixIcon!,
                      ),
                    )
                        : null,
                    suffixIcon: widget.suffixIcon,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: _isFocused
                        ? widget.focusedBorderColor.withOpacity(0.03)
                        : Colors.grey.shade100,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}