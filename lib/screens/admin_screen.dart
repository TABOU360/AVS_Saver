import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(leading: Icon(Icons.verified), title: Text('Vérifier identité AVS'), subtitle: Text('Pièces, diplômes, casier')),
          ListTile(leading: Icon(Icons.security), title: Text('Sécurité & rôles'), subtitle: Text('Permissions, mots de passe')),
          ListTile(leading: Icon(Icons.analytics), title: Text('Rapports & stats'), subtitle: Text('Missions, paiements')),
        ],
      ),
    );
  }
}
