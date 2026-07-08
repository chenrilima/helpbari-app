import 'package:flutter/material.dart';

import '../../design_system.dart';

class HBTextField extends StatelessWidget {
  const HBTextField({
    required this.controller,
    required this.label,
    super.key,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.maxLines,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLines;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel ?? label,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
