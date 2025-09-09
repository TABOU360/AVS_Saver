import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomTextField extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final Color? textColor;
  final Color? fillColor; // Nouveau paramètre pour la couleur de fond

  const CustomTextField(
      {this.hint,
      this.controller,
      this.obscure = false,
      this.textColor,
      this.fillColor, // Paramètre optionnel pour le fond
      super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(
        color: textColor ?? AppColors.darkText, // Couleur du texte
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.secondaryText.withOpacity(0.7), // Hint plus visible
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: fillColor ??
            const Color.fromARGB(
                255, 245, 245, 245), // Fond plus clair par défaut
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
