import '../../models/domain_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/broadcast_model.dart';
import '../../models/user_model.dart';

abstract class DatabaseRepository {
  // Roadmaps & Domains
  Stream<List<DomainModel>> getDomains();
  Future<DomainModel> getDomainById(String domainId);
  Stream<List<ModuleModel>> getModules(String domainId);
  Stream<List<TopicModel>> getTopics(String domainId, String moduleId);
  
  // Progress Tracking
  Stream<UserProgressModel?> getUserProgress(String uid, String domainId);
  Future<void> toggleTopicCompletion(
    String uid, 
    String domainId, 
    String topicId, 
    bool isCompleted,
    int totalTopicsInDomain,
  );
  
  // Broadcasts
  Stream<List<BroadcastModel>> getBroadcasts(UserModel user);
  Future<void> markBroadcastAsRead(String uid, String broadcastId);
  Future<void> createBroadcast(BroadcastModel broadcast);

  // Admin / Leads management
  Future<void> createDomain(DomainModel domain);
  Future<void> createModule(String domainId, ModuleModel module);
  Future<void> createTopic(String domainId, String moduleId, TopicModel topic);
  Stream<List<UserModel>> getMembers();
  Future<void> updateUserRole(String uid, UserRole role);
  Future<void> updateFollowedDomains(String uid, List<String> domains);
}
