import 'package:flutter/material.dart';

class FuturCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final double iconSize;
  final double fontSize;
  final color;

  const FuturCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.iconSize = 40.0,
    this.fontSize = 16.0,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData() = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      splashColor: Colors.white.withOpacity(0.3),  // Subtle ripple effect
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: color,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color,  // Match shadow to gradient
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(5, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  )
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,  // Prevent overflow for longer titles
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}