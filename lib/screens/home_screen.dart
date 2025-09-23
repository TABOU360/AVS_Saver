import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/futur_card.dart';
import '../core/app_routes.dart';
import '../services/data_service.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataService _dataService = DataService();
  final DatabaseService _databaseService = DatabaseService();
  final NavigationService _navigationService = NavigationService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  int _selectedBottomNavIndex = 0;
  String? _userRole;
  String? _userName;
  Map<String, dynamic>? _userStats;
  bool _isLoadingStats = true;

  // Catégories adaptées à AVS Saver
  final List<Map<String, dynamic>> _categories = [
    {
      'icon': Icons.medical_services,
      'label': 'Soins',
      'color': Colors.blue,
      'route': AppRoutes.browseAvs
    },
    {
      'icon': Icons.school,
      'label': 'Scolaire',
      'color': Colors.green,
      'route': AppRoutes.browseAvs
    },
    {
      'icon': Icons.home,
      'label': 'Domicile',
      'color': Colors.orange,
      'route': AppRoutes.browseAvs
    },
    {
      'icon': Icons.accessibility,
      'label': 'Mobilité',
      'color': Colors.purple,
      'route': AppRoutes.browseAvs
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      if (_currentUser == null) return;

      final userProfile =
          await _databaseService.getUserProfile(_currentUser!.uid);
      if (userProfile != null) {
        setState(() {
          _userRole = userProfile.role;
          _userName = userProfile.name;
        });

        await _loadUserStats();
      }
    } catch (e) {
      debugPrint('Erreur chargement données utilisateur: $e');
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await _dataService.getUserStats();
      if (mounted) {
        setState(() {
          _userStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoadingStats = true);
    await _dataService.refreshAllData();
    await _loadUserStats();
  }

  Future<void> _navigateToRoute(String routeName) async {
    if (await _navigationService.canNavigateTo(routeName)) {
      _navigationService.navigateTo(routeName);
    } else {
      _navigationService.showPermissionError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            // Header avec message de bienvenue
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName != null
                            ? "Bonjour $_userName 👋"
                            : "Bienvenue",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userRole == AppConstants.roleFamille
                            ? "Trouvez l'AVS idéal pour vos proches"
                            : "Gérez vos interventions efficacement",
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.darkText),
                  onPressed: () => _navigateToRoute(AppRoutes.notifications),
                ),
                _buildUserAvatar(),
              ],
            ),

            // Section Catégories de services AVS
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Types d'intervention",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return GestureDetector(
                            onTap: () => _navigateToRoute(category['route']),
                            child: Container(
                              width: 100,
                              margin: EdgeInsets.only(
                                  right:
                                      index == _categories.length - 1 ? 0 : 12),
                              decoration: BoxDecoration(
                                color: category['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: category['color'].withOpacity(0.3)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(category['icon'],
                                      color: category['color'], size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    category['label'],
                                    style: TextStyle(
                                      color: category['color'],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats section
            _buildStatsSection(),

            // Navigation cards
            _buildNavigationGrid(),

            // Quick Actions
            _buildQuickActions(),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildContextualFAB(),
    );
  }

  Widget _buildUserAvatar() {
    return GestureDetector(
      onTap: _showProfileMenu,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _currentUser?.photoURL != null
              ? NetworkImage(_currentUser!.photoURL!) as ImageProvider
              : const AssetImage(AppConstants.placeholderAvatar),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Erreur chargement image: $exception');
          },
        ),
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Voir le profil'),
              onTap: () {
                Navigator.of(c).pop();
                _navigateToRoute(AppRoutes.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier le profil'),
              onTap: () {
                Navigator.of(c).pop();
                _navigateToRoute(AppRoutes.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Se déconnecter',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(c).pop();
                _showLogoutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_userStats == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mes statistiques",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard("Réservations", _userStats!["reservations"] ?? 0,
                    Icons.calendar_today),
                _buildStatCard("Présences", _userStats!["presences"] ?? 0,
                    Icons.check_circle),
                _buildStatCard(
                    "Messages", _userStats!["messages"] ?? 0, Icons.message),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green.shade600, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          "$count",
          style: TextStyle(
            color: Colors.green.shade600,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildNavigationGrid() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Accès rapide",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _buildNavigationCards(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavigationCards() {
    final cards = <Widget>[];

    switch (_userRole) {
      case AppConstants.roleFamille:
        cards.add(FuturCard(
            icon: Icons.home,
            title: "Mon compte",
            onTap: () => _navigateToRoute(AppRoutes.profile),
            color: Colors.blue.shade600));
        break;
      case AppConstants.roleAvs:
        cards.add(FuturCard(
            icon: Icons.work,
            title: "Mes interventions",
            onTap: () => _navigateToRoute(AppRoutes.booking),
            color: Colors.orange.shade600));
        break;
      case AppConstants.roleCoordinateur:
        cards.add(FuturCard(
            icon: Icons.verified_user,
            title: "Coordination",
            onTap: () => _navigateToRoute(AppRoutes.coordinator),
            color: Colors.indigo.shade600));
        break;
      case AppConstants.roleAdmin:
        cards.add(FuturCard(
            icon: Icons.admin_panel_settings,
            title: "Administration",
            onTap: () => _navigateToRoute(AppRoutes.admin),
            color: Colors.red.shade600));
        break;
    }

    cards.addAll([
      FuturCard(
          icon: Icons.calendar_month,
          title: "Agenda",
          onTap: () => _navigateToRoute(AppRoutes.agenda),
          color: Colors.green.shade600),
      FuturCard(
          icon: Icons.chat,
          title: "Messages",
          onTap: () => _navigateToRoute(AppRoutes.messages),
          color: Colors.teal.shade600),
    ]);

    return cards;
  }

  SliverToBoxAdapter _buildQuickActions() {
    if (_userRole != AppConstants.roleFamille) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Actions rapides",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToRoute(AppRoutes.browseAvs),
                    icon: const Icon(Icons.add),
                    label: const Text("Nouvelle réservation"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToRoute(AppRoutes.beneficiaries),
                    icon: const Icon(Icons.person_add),
                    label: const Text("Ajouter bénéficiaire"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
      BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month), label: "Agenda"),
      BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Messages"),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: items,
          currentIndex: _selectedBottomNavIndex,
          onTap: (i) {
            setState(() => _selectedBottomNavIndex = i);
            switch (i) {
              case 1:
                _navigateToRoute(AppRoutes.agenda);
                break;
              case 2:
                _navigateToRoute(AppRoutes.messages);
                break;
              case 3:
                _navigateToRoute(AppRoutes.profile);
                break;
            }
          },
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 8,
          showUnselectedLabels: true,
        ),
      ),
    );
  }

  Widget? _buildContextualFAB() {
    switch (_userRole) {
      case AppConstants.roleFamille:
        return FloatingActionButton(
          onPressed: () => _navigateToRoute(AppRoutes.browseAvs),
          backgroundColor: Colors.green,
          child: const Icon(Icons.search),
        );
      case AppConstants.roleCoordinateur:
        return FloatingActionButton(
          onPressed: () => _navigateToRoute(AppRoutes.coordinator),
          backgroundColor: Colors.indigo,
          child: const Icon(Icons.verified_user),
        );
      default:
        return null;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(c).pop();
              await FirebaseAuth.instance.signOut();
              _navigationService.navigateToLogin();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Déconnexion"),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.roleFamille:
        return "Famille";
      case AppConstants.roleAvs:
        return "AVS";
      case AppConstants.roleCoordinateur:
        return "Coordinateur";
      case AppConstants.roleAdmin:
        return "Administrateur";
      default:
        return role;
    }
  }
}
