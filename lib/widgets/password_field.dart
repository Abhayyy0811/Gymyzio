import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? errorText;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final IconData prefixIcon;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onEditingComplete;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText = 'Password',
    this.hintText,
    this.errorText,
    this.hasError = false,
    this.onChanged,
    this.prefixIcon = Icons.lock_outline,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onEditingComplete,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isError = widget.hasError || (widget.errorText != null && widget.errorText!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onFieldSubmitted,
          onEditingComplete: widget.onEditingComplete,
          obscureText: _obscureText,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            filled: true,
            fillColor: AppColors.surfaceLight,
            prefixIcon: Icon(
              widget.prefixIcon,
              color: isError ? Colors.redAccent : AppColors.secondary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: isError ? Colors.redAccent : AppColors.textMuted,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isError ? Colors.redAccent : AppColors.border,
                width: isError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isError ? Colors.redAccent : AppColors.secondary,
                width: 2.0,
              ),
            ),
          ),
        ),
        if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
