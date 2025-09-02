import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  const CustomButton(
  {
    required this.text,
    required this.onPressed,
    this.isLoading= false,
    super.key,
  }
      );
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20 , horizontal: 24),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
      ? const SizedBox(
        height: 20,
        width: double.infinity,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      )
          : Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
