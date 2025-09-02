import 'package:flutter/material.dart';
import '../models/avs.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final dateCtl = TextEditingController();
  final startCtl = TextEditingController();
  final endCtl = TextEditingController();
  final addrCtl = TextEditingController();
  final notesCtl = TextEditingController();

  @override
  void dispose() {
    dateCtl.dispose(); startCtl.dispose(); endCtl.dispose(); addrCtl.dispose(); notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Avs avs = ModalRoute.of(context)!.settings.arguments as Avs;
    return Scaffold(
      appBar: AppBar(title: const Text('Demande de réservation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('AVS: ${avs.name}'),
            const SizedBox(height: 12),
            TextField(controller: dateCtl, decoration: const InputDecoration(labelText: 'Date (JJ/MM/AAAA)')),
            TextField(controller: startCtl, decoration: const InputDecoration(labelText: 'Heure début (HH:MM)')),
            TextField(controller: endCtl, decoration: const InputDecoration(labelText: 'Heure fin (HH:MM)')),
            TextField(controller: addrCtl, decoration: const InputDecoration(labelText: 'Adresse')),            
            TextField(controller: notesCtl, decoration: const InputDecoration(labelText: 'Notes')),            
            const Spacer(),
            SizedBox(width: double.infinity, child: ElevatedButton(child: const Text('Envoyer la demande'), onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande envoyée au coordinateur'))); Navigator.pop(context);}))
          ],
        ),
      ),
    );
  }
}
