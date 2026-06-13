import 'package:flutter/material.dart';

import '../core/theme/motofix_ui.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return MotoFixButton(
      label: text,
      icon: icon,
      onPressed: onPressed,
    );
  }
}
