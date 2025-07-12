import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final bool enabled;

  const CustomTextField({
    super.key,
    this.label,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onSaved,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget textFormField = TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );

    if (label != null && label!.isNotEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label!,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: textFormField),
        ],
      );
    } else {
      return textFormField;
    }
  }
}
