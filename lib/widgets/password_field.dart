import 'package:flutter/material.dart';

/// Uygulama genelinde tutarlı şifre input alanı: göster/gizle ikonu ile.
/// Login, kayıt ve diğer şifre alanlarında aynı UX standardı için kullanılır.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.autofillHints,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        suffixIcon: IconButton(
          icon: Icon(_obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined),
          tooltip: _obscure ? 'Şifreyi göster' : 'Şifreyi gizle',
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
