import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/avs.dart';
import '../models/beneficiary.dart';
import '../models/mission.dart';
import '../models/user.dart' as app_user;
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== UTILISATEURS ====================

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userData = {
        'id': uid,
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        ...?additionalData,
      };

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userData);
    } catch (e) {
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }

  Future<app_user.AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return app_user.AppUser(
          id: data['id'] ?? uid,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          role: data['role'] ?? '',
        );
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // ==================== AVS ====================

  Future<List<Avs>> getAllAvs() async {
    try {
      final query = await _firestore
          .collection(AppConstants.avsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return Avs(
          id: doc.id,
          name: data['name'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          skills: List<String>.from(data['skills'] ?? []),
          hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
          verified: data['verified'] ?? false,
          bio: data['bio'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des AVS: $e');
    }
  }

  Future<List<Avs>> searchAvsBySkills(List<String> skills) async {
    try {
      Query query = _firestore
          .collection(AppConstants.avsCollection)
          .where('isActive', isEqualTo: true);

      if (skills.isNotEmpty) {
        query = query.where('skills', arrayContainsAny: skills);
      }

      final result = await query.get();
      return result.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Avs(
          id: doc.id,
          name: data['name'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          skills: List<String>.from(data['skills'] ?? []),
          hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
          verified: data['verified'] ?? false,
          bio: data['bio'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  Future<void> createAvsProfile({
    required String uid,
    required String name,
    required List<String> skills,
    required double hourlyRate,
    required String bio,
  }) async {
    try {
      final avsData = {
        'userId': uid,
        'name': name,
        'skills': skills,
        'hourlyRate': hourlyRate,
        'bio': bio,
        'rating': 0.0,
        'verified': false,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(AppConstants.avsCollection)
          .doc(uid)
          .set(avsData);
    } catch (e) {
      throw Exception('Erreur lors de la création du profil AVS: $e');
    }
  }

  // ==================== BÉNÉFICIAIRES ====================

  Future<List<Beneficiary>> getUserBeneficiaries(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.beneficiariesCollection)
          .where('familyId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return Beneficiary(
          id: doc.id,
          fullName: data['fullName'] ?? '',
          age: data['age'] ?? 0,
          condition: data['condition'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des bénéficiaires: $e');
    }
  }

  Future<String> addBeneficiary({
    required String familyId,
    required String fullName,
    required int age,
    required String condition,
    String? additionalInfo,
  }) async {
    try {
      final beneficiaryData = {
        'familyId': familyId,
        'fullName': fullName,
        'age': age,
        'condition': condition,
        'additionalInfo': additionalInfo,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(AppConstants.beneficiariesCollection)
          .add(beneficiaryData);

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du bénéficiaire: $e');
    }
  }

  // ==================== MISSIONS ====================

  Future<String> createMission({
    required String familyId,
    required String avsId,
    required String beneficiaryId,
    required DateTime start,
    required DateTime end,
    MissionStatus status = MissionStatus.pending,
  }) async {
    try {
      final missionData = {
        'familyId': familyId,
        'avsId': avsId,
        'beneficiaryId': beneficiaryId,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'status': _missionStatusToString(status),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(AppConstants.missionsCollection)
          .add(missionData);

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la mission: $e');
    }
  }

  Future<List<Mission>> getUserMissions(String userId, String userRole) async {
    try {
      Query query = _firestore.collection(AppConstants.missionsCollection);

      switch (userRole) {
        case AppConstants.roleAvs:
          query = query.where('avsId', isEqualTo: userId);
          break;
        case AppConstants.roleFamille:
          query = query.where('familyId', isEqualTo: userId);
          break;
        default:
          break;
      }

      final result = await query
          .orderBy('start', descending: true)
          .get();

      return result.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Mission(
          id: doc.id,
          familyId: data['familyId'] ?? '',
          avsId: data['avsId'] ?? '',
          beneficiaryId: data['beneficiaryId'] ?? '',
          start: (data['start'] as Timestamp).toDate(),
          end: (data['end'] as Timestamp).toDate(),
          status: _stringToMissionStatus(data['status']),
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des missions: $e');
    }
  }

  Future<void> updateMissionStatus(String missionId, MissionStatus status) async {
    try {
      await _firestore
          .collection(AppConstants.missionsCollection)
          .doc(missionId)
          .update({
        'status': _missionStatusToString(status),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // ==================== HELPERS ====================

  MissionStatus _stringToMissionStatus(String? status) {
    switch (status) {
      case AppConstants.missionConfirmed:
        return MissionStatus.confirmed;
      case AppConstants.missionCompleted:
        return MissionStatus.done;
      case AppConstants.missionCancelled:
        return MissionStatus.cancelled;
      default:
        return MissionStatus.pending;
    }
  }

  String _missionStatusToString(MissionStatus status) {
    switch (status) {
      case MissionStatus.pending:
        return AppConstants.missionPending;
      case MissionStatus.confirmed:
        return AppConstants.missionConfirmed;
      case MissionStatus.done:
        return AppConstants.missionCompleted;
      case MissionStatus.cancelled:
        return AppConstants.missionCancelled;
    }
  }

  Future<bool> hasPermission(String action, {String? targetUserId}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final userProfile = await getUserProfile(currentUser.uid);
    if (userProfile == null) return false;

    switch (userProfile.role) {
      case AppConstants.roleAdmin:
        return true;
      case AppConstants.roleCoordinateur:
        return ['manage_bookings', 'view_all_users', 'send_notifications']
            .contains(action);
      case AppConstants.roleAvs:
        return ['update_profile', 'view_missions', 'respond_bookings']
            .contains(action);
      case AppConstants.roleFamille:
        return ['create_bookings', 'manage_beneficiaries', 'view_own_data']
            .contains(action);
      default:
        return false;
    }
  }
}