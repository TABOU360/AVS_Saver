import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView(
        children: const [
          ListTile(title: Text('Aïcha D.'), subtitle: Text('Bonjour, je suis disponible...')),
          ListTile(title: Text('Coordinateur'), subtitle: Text('Demande validée, merci.')),
        ],
      ),
    );
  }
}
