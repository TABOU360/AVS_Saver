import 'package:flutter/material.dart';
import '../models/avs.dart';
import '../core/app_routes.dart';

class AvsProfileScreen extends StatelessWidget {
  const AvsProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Avs avs = ModalRoute.of(context)!.settings.arguments as Avs;
    return Scaffold(
      appBar: AppBar(title: Text(avs.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${avs.name} • ${avs.rating.toStringAsFixed(1)}★', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Compétences: ${avs.skills.join(', ')}'),
            const SizedBox(height: 8),
            Text('Tarif: ${avs.hourlyRate.toStringAsFixed(0)}€/h'),
            const SizedBox(height: 8),
            Text(avs.verified ? 'Vérifiée ✅' : 'Non vérifiée'),
            const SizedBox(height: 12),
            Text(avs.bio),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.booking, arguments: avs),
                icon: const Icon(Icons.event_available),
                label: const Text('Proposer un créneau'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
