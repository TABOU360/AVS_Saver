import 'package:flutter/material.dart';
import '../models/beneficiary.dart';

class BeneficiaryDetailScreen extends StatelessWidget {
  const BeneficiaryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Beneficiary b = ModalRoute.of(context)!.settings.arguments as Beneficiary;
    return Scaffold(
      appBar: AppBar(title: Text(b.fullName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${b.fullName} • ${b.age} ans', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Condition: ${b.condition}'),
            const SizedBox(height: 12),
            const Text('Historique médical (mock):'),
            const SizedBox(height: 8),
            const Text('• 10/08/2025: Observation stable'),
            const Text('• 07/08/2025: Séance motricité fine'),
            const Spacer(),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, child: const Text('Ajouter observation')))
          ],
        ),
      ),
    );
  }
}
