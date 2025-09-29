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

  /// Créer un profil utilisateur dans Firestore
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
    required String role,
    String? phone,
    String? address,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userData = {
        'id': uid,
        'email': email,
        'name': name,
        'role': role,
        'phone': phone,
        'address': address,
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

  /// Récupérer le profil d'un utilisateur
  Future<app_user.AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return app_user.AppUser(
          id: data['id'] ?? '',
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          role: data['role'] ?? 'AVS',
          phone: data['phone'],
          address: data['address'],
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// Mettre à jour le profil utilisateur
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

  /// Récupérer tous les AVS
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

  /// Rechercher des AVS par compétences
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

  /// Créer un profil AVS
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

  /// Récupérer les bénéficiaires d'un utilisateur
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

  /// Ajouter un bénéficiaire
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
        'additionalInfo': additionalInfo ?? '',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(AppConstants.beneficiariesCollection)
          .add(beneficiaryData);

      return docRef.id;
    } catch (e) {
      throw Exception("Erreur lors de l'ajout du bénéficiaire: $e");
    }
  }

  Future<app_user.AppUser?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    return await getUserProfile(currentUser.uid);
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final notifData = {
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(AppConstants.notificationsCollection)
          .add(notifData);
    } catch (e) {
      throw Exception('Erreur sauvegarde notification: $e');
    }
  }

  // ==================== MISSIONS / RÉSERVATIONS ====================

  /// Créer une demande de réservation
  Future<String> createBookingRequest({
    required String familyId,
    required String avsId,
    required String beneficiaryId,
    required DateTime startTime,
    required DateTime endTime,
    required String address,
    String? notes,
  }) async {
    try {
      final bookingData = {
        'familyId': familyId,
        'avsId': avsId,
        'beneficiaryId': beneficiaryId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'address': address,
        'notes': notes ?? '',
        'status': AppConstants.missionPending,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(AppConstants.bookingsCollection)
          .add(bookingData);

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la réservation: $e');
    }
  }

  /// Récupérer les missions d'un utilisateur
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

      final result = await query.orderBy('start', descending: true).get();

      return result.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Mission(
          id: doc.id,
          avsId: data['avsId'] ?? '',
          beneficiaryId: data['beneficiaryId'] ?? '',
          start: (data['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
          end: (data['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: _stringToMissionStatus(data['status']),
          familyId: data['familyId'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des missions: $e');
    }
  }

  /// Mettre à jour le statut d'une mission
  Future<void> updateMissionStatus(
      String missionId, MissionStatus status) async {
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

  Future<Avs?> getAvsById(String avsId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.avsCollection)
          .doc(avsId)
          .get();
      if (!doc.exists) return null;
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
    } catch (e) {
      throw Exception("Erreur lors de la récupération de l'AVS: $e");
    }
  }

  // ==================== MESSAGES ====================

  /// Envoyer un message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? type,
  }) async {
    try {
      final messageData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'type': type ?? 'text',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(AppConstants.messagesCollection)
          .add(messageData);
    } catch (e) {
      throw Exception("Erreur lors de l'envoi du message: $e");
    }
  }

  /// Stream des messages entre deux utilisateurs
  Stream<QuerySnapshot> getMessagesStream(String userId1, String userId2) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('senderId', whereIn: [userId1, userId2])
        .where('receiverId', whereIn: [userId1, userId2])
        .orderBy('timestamp', descending: true)
        .snapshots();
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

  /// Vérifier si l'utilisateur actuel a les permissions pour une action
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
