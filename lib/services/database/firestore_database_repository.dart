import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/domain_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/broadcast_model.dart';
import '../../models/user_model.dart';
import 'database_repository.dart';

class FirestoreDatabaseRepository implements DatabaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Roadmaps & Domains
  @override
  Stream<List<DomainModel>> getDomains() {
    return _firestore.collection('domains').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DomainModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<DomainModel> getDomainById(String domainId) async {
    final doc = await _firestore.collection('domains').doc(domainId).get();
    if (!doc.exists) throw Exception('Domain $domainId not found');
    return DomainModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Stream<List<ModuleModel>> getModules(String domainId) {
    return _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ModuleModel.fromMap(doc.data(), doc.id, domainId);
      }).toList();
    });
  }

  @override
  Stream<List<TopicModel>> getTopics(String domainId, String moduleId) {
    return _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .doc(moduleId)
        .collection('topics')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TopicModel.fromMap(doc.data(), doc.id, moduleId);
      }).toList();
    });
  }

  // Progress Tracking
  @override
  Stream<UserProgressModel?> getUserProgress(String uid, String domainId) {
    final docId = '${uid}_$domainId';
    return _firestore
        .collection('userProgress')
        .doc(docId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return UserProgressModel(
          uid: uid,
          domainId: domainId,
          topicsCompleted: {},
          percentComplete: 0.0,
        );
      }
      return UserProgressModel.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<void> toggleTopicCompletion(
    String uid, 
    String domainId, 
    String topicId, 
    bool isCompleted,
    int totalTopicsInDomain,
  ) async {
    final docId = '${uid}_$domainId';
    final docRef = _firestore.collection('userProgress').doc(docId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      Map<String, dynamic> topicsCompleted = {};
      
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data['topicsCompleted'] is Map) {
          topicsCompleted = Map<String, dynamic>.from(data['topicsCompleted']);
        }
      }

      if (isCompleted) {
        topicsCompleted[topicId] = {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        };
      } else {
        topicsCompleted.remove(topicId);
      }

      final double computedPercent = totalTopicsInDomain > 0
          ? (topicsCompleted.length / totalTopicsInDomain)
          : 0.0;

      final double percentComplete = double.parse(computedPercent.toStringAsFixed(2));

      transaction.set(docRef, {
        'uid': uid,
        'domainId': domainId,
        'topicsCompleted': topicsCompleted,
        'percentComplete': percentComplete,
      }, SetOptions(merge: true));
    });
  }

  // Broadcasts
  @override
  Stream<List<BroadcastModel>> getBroadcasts(UserModel user) {
    // Note: To avoid complex client-side filter overheads or Firestore composite index demands,
    // we fetch the recent broadcasts (e.g. limit to 50) and filter them in memory.
    return _firestore
        .collection('broadcasts')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return BroadcastModel.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Perform memory audience filtering
      return list.where((bc) {
        if (bc.audienceType == 'all') return true;
        if (bc.audienceType == 'batch' && bc.audienceValue == user.batch) return true;
        if (bc.audienceType == 'domain' && user.domainsFollowing.contains(bc.audienceValue)) return true;
        return false;
      }).toList();
    });
  }

  @override
  Future<void> markBroadcastAsRead(String uid, String broadcastId) async {
    await _firestore.collection('broadcasts').doc(broadcastId).update({
      'readBy': FieldValue.arrayUnion([uid])
    });
  }

  @override
  Future<void> createBroadcast(BroadcastModel broadcast) async {
    await _firestore.collection('broadcasts').add(broadcast.toMap());
  }

  // Admin roadmaps management
  @override
  Future<void> createDomain(DomainModel domain) async {
    await _firestore.collection('domains').doc(domain.id).set(domain.toMap());
  }

  @override
  Future<void> createModule(String domainId, ModuleModel module) async {
    await _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .doc(module.id)
        .set(module.toMap());
  }

  @override
  Future<void> createTopic(String domainId, String moduleId, TopicModel topic) async {
    await _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .doc(moduleId)
        .collection('topics')
        .doc(topic.id)
        .set(topic.toMap());
  }

  // Member Directory
  @override
  Stream<List<UserModel>> getMembers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role.value
    });
  }
}
