import 'package:flutter/material.dart';

class CoordinatorScreen extends StatelessWidget {
  const CoordinatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coordination')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(title: const Text('Contrat #C001'), subtitle: const Text('Famille T. ↔ Aïcha D.'), trailing: Wrap(children: [TextButton(onPressed: (){}, child: const Text('Valider')), TextButton(onPressed: (){}, child: const Text('Refuser'))],))),
          Card(child: ListTile(title: const Text('Contrat #C002'), subtitle: const Text('Famille K. ↔ Boris M.'), trailing: Wrap(children: [TextButton(onPressed: (){}, child: const Text('Valider')), TextButton(onPressed: (){}, child: const Text('Refuser'))],))),
        ],
      ),
    );
  }
}
