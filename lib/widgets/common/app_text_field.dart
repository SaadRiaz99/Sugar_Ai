import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final int? maxLength;
  final double? fontSize;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.validator,
    this.onChanged,
    this.onTap,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(
        fontSize: fontSize ?? 16,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        labelStyle: TextStyle(
          fontSize: fontSize ?? 16,
        ),
        hintStyle: TextStyle(
          fontSize: fontSize ?? 16,
        ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
