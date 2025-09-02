import 'package:flutter/material.dart';
import '../models/avs.dart';

class AvsCard extends StatelessWidget {
  final Avs avs;
  final VoidCallback onTap;
  const AvsCard({super.key, required this.avs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text('${avs.name} • ${avs.rating.toStringAsFixed(1)}★'),
        subtitle: Text('${avs.skills.join(', ')}  •  ${avs.hourlyRate.toStringAsFixed(0)}€/h  ${avs.verified ? "• Vérifiée ✅" : ""}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
