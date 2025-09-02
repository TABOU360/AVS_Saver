import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../widgets/avs_card.dart';
import '../core/app_routes.dart';
import '../models/avs.dart';

class BrowseAvsScreen extends StatelessWidget {
  BrowseAvsScreen({super.key});
  final data = DataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un·e AVS')),
      body: FutureBuilder<List<Avs>>(
        future: data.searchAvs(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => AvsCard(
              avs: list[i],
              onTap: () => Navigator.pushNamed(context, AppRoutes.avsProfile, arguments: list[i]),
            ),
          );
        },
      ),
    );
  }
}
