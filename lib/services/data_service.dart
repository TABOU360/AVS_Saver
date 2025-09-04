import 'package:firebase_auth/firebase_auth.dart';
import '../models/avs.dart';
import '../models/beneficiary.dart';
import '../models/mission.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache local pour améliorer les performances
  List<Avs>? _cachedAvsList;
  List<Beneficiary>? _cachedBeneficiaries;
  DateTime? _lastCacheUpdate;

  // ==================== AVS ====================

  /// Rechercher des AVS avec cache intelligent
  Future<List<Avs>> searchAvs({List<String>? skills, bool forceRefresh = false}) async {
    try {
      // Vérifier le cache (valide pendant 5 minutes)
      if (!forceRefresh &&
          _cachedAvsList != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5) {

        // Filtrer par compétences si nécessaire
        if (skills != null && skills.isNotEmpty) {
          return _cachedAvsList!.where((avs) =>
              skills.any((skill) => avs.skills.contains(skill))
          ).toList();
        }

        return _cachedAvsList!;
      }

      // Récupérer depuis Firebase
      List<Avs> avsList;
      if (skills != null && skills.isNotEmpty) {
        avsList = await _databaseService.searchAvsBySkills(skills);
      } else {
        avsList = await _databaseService.getAllAvs();
      }

      // Mettre à jour le cache
      _cachedAvsList = avsList;
      _lastCacheUpdate = DateTime.now();

      return avsList;
    } catch (e) {
      print('Erreur recherche AVS: $e');
      // Retourner les données mockées en cas d'erreur
      return _getMockAvsList();
    }
  }

  /// Obtenir un AVS par ID
  Future<Avs?> getAvsById(String avsId) async {
    try {
      // Chercher d'abord dans le cache
      if (_cachedAvsList != null) {
        final cachedAvs = _cachedAvsList!.firstWhere(
              (avs) => avs.id == avsId,
          orElse: () => throw StateError('AVS non trouvé'),
        );
        if (cachedAvs != null) return cachedAvs;
      }

      // Récupérer depuis Firebase si pas dans le cache
      // TODO: Implémenter getAvsById dans DatabaseService
      final allAvs = await searchAvs(forceRefresh: true);
      return allAvs.firstWhere(
            (avs) => avs.id == avsId,
        orElse: () => throw StateError('AVS non trouvé'),
      );
    } catch (e) {
      print('Erreur récupération AVS: $e');
      return null;
    }
  }

  // ==================== BÉNÉFICIAIRES ====================

  /// Récupérer les bénéficiaires de l'utilisateur actuel
  Future<List<Beneficiary>> listBeneficiaries({bool forceRefresh = false}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier le cache
      if (!forceRefresh &&
          _cachedBeneficiaries != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5) {
        return _cachedBeneficiaries!;
      }

      // Récupérer depuis Firebase
      final beneficiaries = await _databaseService.getUserBeneficiaries(currentUser.uid);

      // Mettre à jour le cache
      _cachedBeneficiaries = beneficiaries;

      return beneficiaries;
    } catch (e) {
      print('Erreur récupération bénéficiaires: $e');
      // Retourner les données mockées en cas d'erreur
      return _getMockBeneficiariesList();
    }
  }

  /// Ajouter un nouveau bénéficiaire
  Future<String> addBeneficiary({
    required String fullName,
    required int age,
    required String condition,
    String? additionalInfo,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final beneficiaryId = await _databaseService.addBeneficiary(
        familyId: currentUser.uid,
        fullName: fullName,
        age: age,
        condition: condition,
        additionalInfo: additionalInfo,
      );

      // Invalider le cache pour forcer le rafraîchissement
      _cachedBeneficiaries = null;

      return beneficiaryId;
    } catch (e) {
      print('Erreur ajout bénéficiaire: $e');
      rethrow;
    }
  }

  // ==================== MISSIONS ====================

  /// Récupérer les missions de l'utilisateur actuel
  Future<List<Mission>> getUserMissions() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer le rôle utilisateur
      final userProfile = await _databaseService.getUserProfile(currentUser.uid);
      if (userProfile == null) {
        throw Exception('Profil utilisateur non trouvé');
      }

      return await _databaseService.getUserMissions(currentUser.uid, userProfile.role);
    } catch (e) {
      print('Erreur récupération missions: $e');
      return _getMockMissionsList();
    }
  }

  /// Créer une demande de réservation
  Future<String> createBookingRequest({
    required String avsId,
    required String beneficiaryId,
    required DateTime startTime,
    required DateTime endTime,
    required String address,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      return await _databaseService.createBookingRequest(
        familyId: currentUser.uid,
        avsId: avsId,
        beneficiaryId: beneficiaryId,
        startTime: startTime,
        endTime: endTime,
        address: address,
        notes: notes,
      );
    } catch (e) {
      print('Erreur création réservation: $e');
      rethrow;
    }
  }

  // ==================== STATISTIQUES ====================

  /// Obtenir des statistiques pour l'utilisateur
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final missions = await getUserMissions();
      final beneficiaries = await listBeneficiaries();

      return {
        'totalMissions': missions.length,
        'completedMissions': missions.where((m) => m.status == MissionStatus.done).length,
        'pendingMissions': missions.where((m) => m.status == MissionStatus.pending).length,
        'totalBeneficiaries': beneficiaries.length,
        'thisMonthMissions': missions.where((m) {
          final now = DateTime.now();
          return m.start.month == now.month && m.start.year == now.year;
        }).length,
      };
    } catch (e) {
      print('Erreur calcul statistiques: $e');
      return {
        'totalMissions': 0,
        'completedMissions': 0,
        'pendingMissions': 0,
        'totalBeneficiaries': 0,
        'thisMonthMissions': 0,
      };
    }
  }

  // ==================== RECHERCHE AVANCÉE ====================

  /// Recherche d'AVS avec filtres avancés
  Future<List<Avs>> searchAvsAdvanced({
    List<String>? skills,
    double? minRating,
    double? maxHourlyRate,
    bool? verifiedOnly,
    String? searchQuery,
  }) async {
    try {
      List<Avs> results = await searchAvs();

      // Filtrer par compétences
      if (skills != null && skills.isNotEmpty) {
        results = results.where((avs) =>
            skills.any((skill) => avs.skills.contains(skill))
        ).toList();
      }

      // Filtrer par note minimale
      if (minRating != null) {
        results = results.where((avs) => avs.rating >= minRating).toList();
      }

      // Filtrer par tarif maximum
      if (maxHourlyRate != null) {
        results = results.where((avs) => avs.hourlyRate <= maxHourlyRate).toList();
      }

      // Filtrer par statut vérifié
      if (verifiedOnly == true) {
        results = results.where((avs) => avs.verified).toList();
      }

      // Filtrer par recherche textuelle
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        results = results.where((avs) =>
        avs.name.toLowerCase().contains(query) ||
            avs.bio.toLowerCase().contains(query) ||
            avs.skills.any((skill) => skill.toLowerCase().contains(query))
        ).toList();
      }

      // Trier par note décroissante
      results.sort((a, b) => b.rating.compareTo(a.rating));

      return results;
    } catch (e) {
      print('Erreur recherche avancée: $e');
      return [];
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Vider le cache
  void clearCache() {
    _cachedAvsList = null;
    _cachedBeneficiaries = null;
    _lastCacheUpdate = null;
  }

  /// Rafraîchir toutes les données
  Future<void> refreshAllData() async {
    clearCache();
    await Future.wait([
      searchAvs(forceRefresh: true),
      listBeneficiaries(forceRefresh: true),
    ]);
  }

  // ==================== DONNÉES MOCKÉES (FALLBACK) ====================

  List<Avs> _getMockAvsList() {
    return [
      Avs(
        id: 'mock_a1',
        name: 'Aïcha Diallo',
        rating: 4.8,
        skills: ['Autisme', 'Troubles DYS'],
        hourlyRate: 15,
        verified: true,
        bio: '5 ans d\'expérience en accompagnement d\'enfants autistes. Formation premiers secours.',
      ),
      Avs(
        id: 'mock_a2',
        name: 'Boris Martin',
        rating: 4.6,
        skills: ['Déficience motrice', 'Paralysie cérébrale'],
        hourlyRate: 12,
        verified: false,
        bio: 'Spécialisé dans l\'accompagnement moteur. Patient et bienveillant.',
      ),
      Avs(
        id: 'mock_a3',
        name: 'Sarah Dubois',
        rating: 4.9,
        skills: ['Déficience visuelle', 'Communication alternative'],
        hourlyRate: 18,
        verified: true,
        bio: 'Experte en techniques d\'aide à la communication. 8 ans d\'expérience.',
      ),
    ];
  }

  List<Beneficiary> _getMockBeneficiariesList() {
    return [
      Beneficiary(
        id: 'mock_b1',
        fullName: 'Emma Martin',
        age: 8,
        condition: 'Autisme léger',
      ),
      Beneficiary(
        id: 'mock_b2',
        fullName: 'Lucas Petit',
        age: 12,
        condition: 'TDAH',
      ),
    ];
  }

  List<Mission> _getMockMissionsList() {
    final now = DateTime.now();
    return [
      Mission(
        id: 'mock_m1',
        avsId: 'mock_a1',
        beneficiaryId: 'mock_b1',
        start: now.add(const Duration(days: 1)),
        end: now.add(const Duration(days: 1, hours: 2)),
        status: MissionStatus.confirmed, familyId: '',
      ),
      Mission(
        id: 'mock_m2',
        avsId: 'mock_a2',
        beneficiaryId: 'mock_b2',
        start: now.subtract(const Duration(days: 3)),
        end: now.subtract(const Duration(days: 3, hours: -1)),
        status: MissionStatus.done, familyId: '',
      ),
    ];
  }

  /// Vérifier la connectivité et l'état des services
  Future<bool> isServiceHealthy() async {
    try {
      await _databaseService.getUserProfile('test');
      return true;
    } catch (e) {
      print('Service indisponible: $e');
      return false;
    }
  }
}