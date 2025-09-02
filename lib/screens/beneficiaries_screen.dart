import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/beneficiary.dart';
import '../core/app_routes.dart';

class BeneficiariesScreen extends StatelessWidget {
  BeneficiariesScreen({super.key});
  final data = DataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bénéficiaires')),
      body: FutureBuilder<List<Beneficiary>>(
        future: data.listBeneficiaries(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => Card(
              child: ListTile(
                title: Text('${list[i].fullName} • ${list[i].age} ans'),
                subtitle: Text(list[i].condition),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.pushNamed(context, AppRoutes.beneficiaryDetail, arguments: list[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}
