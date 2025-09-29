import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../models/user.dart';
import '../models/mission.dart';
import '../core/app_routes.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class AvsDashboardScreen extends StatefulWidget {
  const AvsDashboardScreen({super.key});

  @override
  State<AvsDashboardScreen> createState() => _AvsDashboardScreenState();
}

class _AvsDashboardScreenState extends State<AvsDashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final NavigationService _nav = NavigationService();

  AppUser? _user;
  bool _loading = true;
  List<Mission> _missions = [];
  List<Mission> _upcomingMissions = [];
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
      if (currentUser.role != AppConstants.roleAvs &&
          currentUser.role != AppConstants.roleAdmin) {
        _nav.showPermissionError();
        _nav.navigateBasedOnRole();
        return;
      }

      // Charger les missions de l'AVS
      final missions =
          await _db.getUserMissions(currentUser.id, currentUser.role);

      // Filtrer les missions à venir
      final now = DateTime.now();
      final upcoming = missions
          .where((m) =>
              m.start.isAfter(now) &&
              (m.status == MissionStatus.confirmed ||
                  m.status == MissionStatus.pending))
          .toList();

      // Calculer les statistiques
      final stats = _calculateStats(missions);

      setState(() {
        _user = currentUser;
        _missions = missions;
        _upcomingMissions = upcoming;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement données AVS: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Map<String, int> _calculateStats(List<Mission> missions) {
    final now = DateTime.now();
    return {
      'total': missions.length,
      'pending':
          missions.where((m) => m.status == MissionStatus.pending).length,
      'confirmed':
          missions.where((m) => m.status == MissionStatus.confirmed).length,
      'completed': missions.where((m) => m.status == MissionStatus.done).length,
      'today': missions
          .where((m) =>
              m.start.year == now.year &&
              m.start.month == now.month &&
              m.start.day == now.day)
          .length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord - ${_user?.name ?? 'AVS'}'),
        backgroundColor: const Color.fromARGB(255, 0, 251, 33),
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

            // Missions d'aujourd'hui
            _buildTodayMissions(),
            const SizedBox(height: 24),

            // Prochaines missions
            _buildUpcomingMissions(),
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
              backgroundColor: Colors.orange.shade100,
              child: Text(
                _user?.name.isNotEmpty == true
                    ? _user!.name[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 251, 33),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour ${_user?.name ?? 'AVS'} 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prêt(e) à accompagner vos bénéficiaires aujourd\'hui ?',
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
          title: 'Missions confirmées',
          value: '${_stats['confirmed'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'En attente',
          value: '${_stats['pending'] ?? 0}',
          icon: Icons.access_time,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Terminées',
          value: '${_stats['completed'] ?? 0}',
          icon: Icons.done_all,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Aujourd\'hui',
          value: '${_stats['today'] ?? 0}',
          icon: Icons.today,
          color: Colors.purple,
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

  Widget _buildTodayMissions() {
    final todayMissions = _missions.where((m) {
      final now = DateTime.now();
      return m.start.year == now.year &&
          m.start.month == now.month &&
          m.start.day == now.day;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Missions d\'aujourd\'hui',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (todayMissions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune mission prévue aujourd\'hui'),
            ),
          )
        else
          ...todayMissions.map((mission) => _buildMissionCard(mission)),
      ],
    );
  }

  Widget _buildUpcomingMissions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prochaines missions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => _nav.navigateTo(AppRoutes.agenda),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_upcomingMissions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune mission à venir'),
            ),
          )
        else
          ..._upcomingMissions
              .take(3)
              .map((mission) => _buildMissionCard(mission)),
      ],
    );
  }

  Widget _buildMissionCard(Mission mission) {
    Color statusColor;
    String statusText;

    switch (mission.status) {
      case MissionStatus.pending:
        statusColor = Colors.orange;
        statusText = 'En attente';
        break;
      case MissionStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Confirmée';
        break;
      case MissionStatus.done:
        statusColor = Colors.blue;
        statusText = 'Terminée';
        break;
      case MissionStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Annulée';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.assignment, color: statusColor),
        title: Text('Mission #${mission.id.substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${_formatDateTime(mission.start)} - ${_formatDateTime(mission.end)}'),
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
        trailing: mission.status == MissionStatus.pending
            ? PopupMenuButton<String>(
                onSelected: (value) => _handleMissionAction(mission, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'accept',
                    child: Text('Accepter'),
                  ),
                  const PopupMenuItem(
                    value: 'decline',
                    child: Text('Refuser'),
                  ),
                ],
              )
            : const Icon(Icons.chevron_right),
        onTap: () {
          // Navigation vers les détails de la mission
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
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Mon agenda',
                icon: Icons.calendar_month,
                onPressed: () => _nav.navigateTo(AppRoutes.agenda),
                backgroundColor: Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Messages',
                icon: Icons.message,
                onPressed: () => _nav.navigateTo(AppRoutes.messages),
                backgroundColor: Colors.teal.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: const Color.fromARGB(255, 0, 251, 33),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Agenda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 1:
            _nav.navigateTo(AppRoutes.agenda);
            break;
          case 2:
            _nav.navigateTo(AppRoutes.messages);
            break;
          case 3:
            _nav.navigateTo(AppRoutes.avsProfile);
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

  void _handleMissionAction(Mission mission, String action) async {
    try {
      MissionStatus newStatus;
      String message;

      switch (action) {
        case 'accept':
          newStatus = MissionStatus.confirmed;
          message = 'Mission acceptée';
          break;
        case 'decline':
          newStatus = MissionStatus.cancelled;
          message = 'Mission refusée';
          break;
        default:
          return;
      }

      await _db.updateMissionStatus(mission.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
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
