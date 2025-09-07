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

  int _selectedBottomNavIndex = 0;
  String? _userRole;
  String? _userName;
  Map<String, dynamic>? _userStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userProfile = await _databaseService.getUserProfile(user.uid);
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
      setState(() {
        _userStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
      setState(() => _isLoadingStats = false);
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
            _buildAppBar(),

            // Stats
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildStatsSection(),
              ),
            ),

            // Navigation cards
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: _buildNavigationGrid(),
              ),
            ),

            // Actions rapides
            SliverToBoxAdapter(
              child: _buildQuickActions(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildContextualFAB(),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.green.shade600,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName != null
                        ? "Bonjour $_userName 👋"
                        : "Bienvenue sur la plateforme",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  if (_userRole != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getRoleDisplayName(_userRole!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.person),
                title: Text("Profil"),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _navigateToRoute(AppRoutes.profile),
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.refresh),
                title: Text("Actualiser"),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _refreshData(),
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text("Déconnexion",
                    style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _showLogoutDialog(),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userStats == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            "Aucune donnée disponible",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
          const Text("Aperçu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    "Missions",
                    "${_userStats!['totalMissions']}",
                    Icons.assignment,
                    Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    "Ce mois",
                    "${_userStats!['thisMonthMissions']}",
                    Icons.calendar_month,
                    Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildNavigationGrid() {
    final cards = _getNavigationCards();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) => cards[i],
    );
  }

  List<Widget> _getNavigationCards() {
    final cards = <Widget>[];

    switch (_userRole) {
      case AppConstants.roleFamille:
        cards.addAll([
          FuturCard(
              icon: Icons.search,
              title: "Trouver un·e AVS",
              onTap: () => _navigateToRoute(AppRoutes.browseAvs),
              color: Colors.blue.shade600),
          FuturCard(
              icon: Icons.people,
              title: "Bénéficiaires",
              onTap: () => _navigateToRoute(AppRoutes.beneficiaries),
              color: Colors.orange.shade600),
        ]);
        break;
      case AppConstants.roleAvs:
        cards.addAll([
          FuturCard(
              icon: Icons.work,
              title: "Mes missions",
              onTap: () => _navigateToRoute(AppRoutes.agenda),
              color: Colors.purple.shade600),
          FuturCard(
              icon: Icons.star,
              title: "Mon profil",
              onTap: () => _navigateToRoute(AppRoutes.profile),
              color: Colors.amber.shade600),
        ]);
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

  Widget _buildQuickActions() {
    if (_userRole != AppConstants.roleFamille) return const SizedBox();
    return Container(
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

    return BottomNavigationBar(
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                _navigationService.navigateToLogin();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Déconnexion"))
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
