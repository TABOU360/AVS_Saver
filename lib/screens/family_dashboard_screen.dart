import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../models/user.dart';
import '../models/beneficiary.dart';
import '../models/mission.dart';
import '../core/app_routes.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final NavigationService _nav = NavigationService();

  AppUser? _user;
  bool _loading = true;
  List<Beneficiary> _beneficiaries = [];
  List<Mission> _bookings = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = await _db.getCurrentUser();
      if (currentUser == null) {
        _nav.navigateToLogin();
        return;
      }

      // Vérifier le rôle
      if (currentUser.role != AppConstants.roleFamille &&
          currentUser.role != AppConstants.roleAdmin) {
        _nav.showPermissionError();
        _nav.navigateBasedOnRole();
        return;
      }

      // Charger les bénéficiaires
      final beneficiaries = await _db.getUserBeneficiaries(currentUser.id);

      // Charger les réservations/missions
      final bookings =
          await _db.getUserMissions(currentUser.id, currentUser.role);

      // Calculer les statistiques
      final stats = _calculateStats(bookings, beneficiaries);

      setState(() {
        _user = currentUser;
        _beneficiaries = beneficiaries;
        _bookings = bookings;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement données famille: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Map<String, int> _calculateStats(
      List<Mission> bookings, List<Beneficiary> beneficiaries) {
    final now = DateTime.now();
    return {
      'beneficiaries': beneficiaries.length,
      'totalBookings': bookings.length,
      'pendingBookings':
          bookings.where((b) => b.status == MissionStatus.pending).length,
      'confirmedBookings':
          bookings.where((b) => b.status == MissionStatus.confirmed).length,
      'upcomingBookings': bookings
          .where((b) =>
              b.start.isAfter(now) &&
              (b.status == MissionStatus.confirmed ||
                  b.status == MissionStatus.pending))
          .length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Famille - ${_user?.name ?? ''}'),
        backgroundColor: const Color.fromARGB(255, 26, 196, 181),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Mon profil'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Paramètres'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title:
                      Text('Déconnexion', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardContent(),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nav.navigateTo(AppRoutes.browseAvs),
        backgroundColor: const Color.fromARGB(255, 26, 196, 181),
        icon: const Icon(Icons.search),
        label: const Text('Trouver une AVS'),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue
            _buildWelcomeCard(),
            const SizedBox(height: 16),

            // Statistiques rapides
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Bénéficiaires
            _buildBeneficiariesSection(),
            const SizedBox(height: 24),

            // Réservations récentes
            _buildRecentBookings(),
            const SizedBox(height: 24),

            // Actions rapides
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.purple.shade100,
              child: Text(
                _user?.name.isNotEmpty == true
                    ? _user!.name[0].toUpperCase()
                    : 'F',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 26, 196, 181),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour ${_user?.name ?? 'Famille'} 👨‍👩‍👧‍👦',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gérez vos bénéficiaires et trouvez les meilleures AVS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Bénéficiaires',
          value: '${_stats['beneficiaries'] ?? 0}',
          icon: Icons.people,
          color: Colors.purple,
        ),
        _buildStatCard(
          title: 'Réservations',
          value: '${_stats['totalBookings'] ?? 0}',
          icon: Icons.calendar_month,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'En attente',
          value: '${_stats['pendingBookings'] ?? 0}',
          icon: Icons.access_time,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'À venir',
          value: '${_stats['upcomingBookings'] ?? 0}',
          icon: Icons.schedule,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficiariesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vos bénéficiaires',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: _showAddBeneficiaryDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_beneficiaries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun bénéficiaire enregistré',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez un bénéficiaire pour commencer',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddBeneficiaryDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un bénéficiaire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._beneficiaries
              .map((beneficiary) => _buildBeneficiaryCard(beneficiary)),
      ],
    );
  }

  Widget _buildBeneficiaryCard(Beneficiary beneficiary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Text(
            beneficiary.fullName.isNotEmpty
                ? beneficiary.fullName[0].toUpperCase()
                : 'B',
            style: TextStyle(
              color: Colors.purple.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(beneficiary.fullName),
        subtitle: Text('${beneficiary.age} ans - ${beneficiary.condition}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Rechercher une AVS pour ce bénéficiaire
                _nav.navigateTo(AppRoutes.browseAvs, arguments: beneficiary);
              },
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          _nav.navigateTo(AppRoutes.beneficiaryDetail, arguments: beneficiary);
        },
      ),
    );
  }

  Widget _buildRecentBookings() {
    final recentBookings = _bookings.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vos réservations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_bookings.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigation vers la liste complète des réservations
                },
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_bookings.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune réservation en cours',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trouvez une AVS pour commencer',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _nav.navigateTo(AppRoutes.browseAvs),
                    icon: const Icon(Icons.search),
                    label: const Text('Trouver une AVS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 26, 196, 181),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentBookings.map((booking) => _buildBookingCard(booking)),
      ],
    );
  }

  Widget _buildBookingCard(Mission booking) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (booking.status) {
      case MissionStatus.pending:
        statusColor = Colors.orange;
        statusText = 'En attente de confirmation';
        statusIcon = Icons.access_time;
        break;
      case MissionStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Confirmée';
        statusIcon = Icons.check_circle;
        break;
      case MissionStatus.done:
        statusColor = Colors.blue;
        statusText = 'Terminée';
        statusIcon = Icons.done_all;
        break;
      case MissionStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Annulée';
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text('Réservation #${booking.id.substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${_formatDateTime(booking.start)} - ${_formatDateTime(booking.end)}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: booking.status == MissionStatus.pending
            ? PopupMenuButton<String>(
                onSelected: (value) => _handleBookingAction(booking, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Annuler'),
                  ),
                  const PopupMenuItem(
                    value: 'modify',
                    child: Text('Modifier'),
                  ),
                ],
              )
            : const Icon(Icons.chevron_right),
        onTap: () {
          // Navigation vers les détails de la réservation
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildQuickActionCard(
              title: 'Trouver une AVS',
              icon: Icons.search,
              color: Colors.purple.shade600,
              onTap: () => _nav.navigateTo(AppRoutes.browseAvs),
            ),
            _buildQuickActionCard(
              title: 'Mon agenda',
              icon: Icons.calendar_month,
              color: Colors.blue.shade600,
              onTap: () => _nav.navigateTo(AppRoutes.agenda),
            ),
            _buildQuickActionCard(
              title: 'Messages',
              icon: Icons.message,
              color: Colors.teal.shade600,
              onTap: () => _nav.navigateTo(AppRoutes.messages),
            ),
            _buildQuickActionCard(
              title: 'Bénéficiaires',
              icon: Icons.people,
              color: Colors.orange.shade600,
              onTap: () => _nav.navigateTo(AppRoutes.beneficiaries),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: const Color.fromARGB(255, 26, 196, 181),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Bénéficiaires',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Agenda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 1:
            _nav.navigateTo(AppRoutes.beneficiaries);
            break;
          case 2:
            _nav.navigateTo(AppRoutes.agenda);
            break;
          case 3:
            _nav.navigateTo(AppRoutes.profile);
            break;
        }
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        _nav.navigateTo(AppRoutes.profile);
        break;
      case 'settings':
        // TODO: Implémenter les paramètres
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _handleBookingAction(Mission booking, String action) async {
    try {
      switch (action) {
        case 'cancel':
          await _db.updateMissionStatus(booking.id, MissionStatus.cancelled);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Réservation annulée')),
            );
          }
          break;
        case 'modify':
          // TODO: Navigation vers modification de réservation
          break;
      }

      _loadUserData(); // Recharger les données
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showAddBeneficiaryDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final conditionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un bénéficiaire'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir le nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Âge',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir l\'âge';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 0 || age > 120) {
                    return 'Âge invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: conditionController,
                decoration: const InputDecoration(
                  labelText: 'Condition/Besoins',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez décrire les besoins';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && _user != null) {
                try {
                  await _db.addBeneficiary(
                    familyId: _user!.id,
                    fullName: nameController.text.trim(),
                    age: int.parse(ageController.text),
                    condition: conditionController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Bénéficiaire ajouté avec succès')),
                    );
                    _loadUserData(); // Recharger les données
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 26, 196, 181),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr(e) de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
              _nav.navigateToLogin();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
