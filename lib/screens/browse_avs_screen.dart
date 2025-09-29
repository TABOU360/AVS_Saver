import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/database_service.dart';
import '../widgets/avs_card.dart';
import '../core/app_routes.dart';
import '../models/avs.dart';
import '../utils/constants.dart';

class BrowseAvsScreen extends StatefulWidget {
  const BrowseAvsScreen({super.key});

  @override
  State<BrowseAvsScreen> createState() => _BrowseAvsScreenState();
}

class _BrowseAvsScreenState extends State<BrowseAvsScreen> {
  final DataService _dataService = DataService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Avs> _allAvs = [];
  List<Avs> _filteredAvs = [];
  bool _isLoading = true;
  String _selectedSkill = 'Toutes';
  List<String> _availableSkills = [];

  @override
  void initState() {
    super.initState();
    _loadAvs();
  }

  Future<void> _loadAvs() async {
    try {
      final avsList = await _dataService.searchAvs();
      final skills = await _getAvailableSkills(avsList);

      setState(() {
        _allAvs = avsList;
        _filteredAvs = avsList;
        _availableSkills = [
          'Toutes',
          'Pros à domicile',
          'Pros en milieu scolaire',
          'Pros en milieu hospitalier',
          'Pros en accompagnement plein air',
          ...skills
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Erreur lors du chargement des AVS');
    }
  }

  Future<List<String>> _getAvailableSkills(List<Avs> avsList) async {
    final allSkills = avsList.expand((avs) => avs.skills).toSet().toList();
    return allSkills..sort();
  }

  void _filterAvs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAvs = _allAvs.where((avs) {
        final matchesSearch = avs.name.toLowerCase().contains(query) ||
            avs.bio.toLowerCase().contains(query) ||
            avs.skills.any((skill) => skill.toLowerCase().contains(query));

        final matchesSkill =
            _selectedSkill == 'Toutes' || avs.skills.contains(_selectedSkill);

        return matchesSearch && matchesSkill;
      }).toList();
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un(e) AVS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAvs,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchFilters(),

          // Indicateur de résultats
          _buildResultsIndicator(),

          // Liste des AVS
          Expanded(child: _buildAvsList()),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color.fromARGB(255, 94, 95, 148),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un AVS, une compétence...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterAvs();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => _filterAvs(),
          ),

          const SizedBox(height: 12),

          // Filtre par compétence
          Row(
            children: [
              const Text('Compétence:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSkill,
                  items: _availableSkills.map((skill) {
                    return DropdownMenuItem(
                      value: skill,
                      child: Text(skill),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSkill = value!);
                    _filterAvs();
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color.fromARGB(255, 124, 124, 128),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredAvs.length} AVS trouvé(s)',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (_filteredAvs.isNotEmpty)
            Text(
              'Trié par note ⭐',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredAvs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _allAvs.isEmpty ? 'Aucun AVS disponible' : 'Aucun résultat',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _allAvs.isEmpty
                  ? 'Revenez plus tard pour découvrir nos AVS'
                  : 'Essayez de modifier vos critères de recherche',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredAvs.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final avs = _filteredAvs[index];
        return AvsCard(
          avs: avs,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.avsProfile,
            arguments: avs,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
