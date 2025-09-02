import 'package:flutter/material.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(title: Text('10:30-11:30 • Mme N.'), subtitle: Text('Séance kiné - Domicile')),
          ListTile(title: Text('14:00-15:00 • M. B.'), subtitle: Text('Motricité globale - Centre')),
        ],
      ),
    );
  }
}
