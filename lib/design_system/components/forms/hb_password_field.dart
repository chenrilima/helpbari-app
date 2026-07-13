import 'package:flutter/material.dart';

class HBPasswordField extends StatefulWidget {
  const HBPasswordField({
    required this.controller,
    super.key,
    this.label = 'Senha',
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? semanticLabel;

  @override
  State<HBPasswordField> createState() => _HBPasswordFieldState();
}

class _HBPasswordFieldState extends State<HBPasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    final visibilityLabel = _obscureText ? 'Mostrar senha' : 'Ocultar senha';

    return Semantics(
      textField: true,
      label: widget.semanticLabel ?? widget.label,
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        enableSuggestions: false,
        autocorrect: false,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted,
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: IconButton(
            tooltip: visibilityLabel,
            onPressed: _toggleVisibility,
            icon: Icon(
              _obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
      ),
    );
  }
}
