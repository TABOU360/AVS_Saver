import 'package:flutter/material.dart';
import '../models/avs.dart';
import '../core/app_routes.dart';
import '../utils/constants.dart';

class AvsProfileScreen extends StatelessWidget {
  const AvsProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Avs avs = ModalRoute.of(context)!.settings.arguments as Avs;

    return Scaffold(
      appBar: AppBar(
        title: Text(avs.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () =>
                _shareAvsProfile(context, avs), // Passer le context
            tooltip: 'Partager le profil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du profil
            _buildProfileHeader(avs),

            const SizedBox(height: 24),

            // Section compétences
            _buildSkillsSection(avs),

            const SizedBox(height: 24),

            // Section à propos
            _buildAboutSection(avs),

            const SizedBox(height: 24),

            // Section tarifs et disponibilités
            _buildDetailsSection(avs),

            const SizedBox(height: 32),

            // Bouton d'action
            _buildActionButton(context, avs),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Avs avs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.blue.shade100,
          child: Icon(
            Icons.person,
            size: 40,
            color: Colors.blue.shade600,
          ),
        ),

        const SizedBox(width: 16),

        // Informations principales
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                avs.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    avs.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ' (${_getRatingCount(avs.rating)})',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    avs.verified ? Icons.verified : Icons.verified_outlined,
                    color: avs.verified ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    avs.verified ? 'Vérifié(e)' : 'En attente de vérification',
                    style: TextStyle(
                      color: avs.verified ? Colors.green : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(Avs avs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compétences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: avs.skills.map((skill) {
            return Chip(
              label: Text(skill),
              backgroundColor: Colors.blue.shade50,
              labelStyle: TextStyle(color: Colors.blue.shade800),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAboutSection(Avs avs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'À propos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          avs.bio.isEmpty
              ? 'Aucune description disponible pour le moment.'
              : avs.bio,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(Avs avs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.euro_symbol,
            'Tarif horaire',
            '${avs.hourlyRate.toStringAsFixed(0)}€/heure',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.work_history,
            'Expérience',
            _getExperienceLevel(avs.rating),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.access_time,
            'Disponibilité',
            'Flexible',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, Avs avs) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.booking,
          arguments: avs,
        ),
        icon: const Icon(Icons.event_available),
        label: const Text(
          'Proposer un créneau',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.medicalBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // CORRECTION : Ajouter le paramètre context
  void _shareAvsProfile(BuildContext context, Avs avs) {
    // TODO: Implémenter le partage du profil
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à venir'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _getRatingCount(double rating) {
    // Simulation du nombre d'avis basé sur la note
    final baseCount = (rating * 10).toInt();
    return '$baseCount avis';
  }

  String _getExperienceLevel(double rating) {
    if (rating >= 4.5) return 'Expert';
    if (rating >= 4.0) return 'Expérimenté(e)';
    if (rating >= 3.0) return 'Intermédiaire';
    return 'Débutant';
  }
}
