import 'dart:async';
import '../../models/domain_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/broadcast_model.dart';
import '../../models/user_model.dart';
import 'database_repository.dart';

class MockDatabaseRepository implements DatabaseRepository {
  // Streams controllers
  final _domainController = StreamController<List<DomainModel>>.broadcast();
  final _broadcastController = StreamController<List<BroadcastModel>>.broadcast();
  final _membersController = StreamController<List<UserModel>>.broadcast();
  
  // Specific topic and progress streams
  final _progressControllers = <String, StreamController<UserProgressModel?>>{};
  final _modulesControllers = <String, StreamController<List<ModuleModel>>>{};
  final _topicsControllers = <String, StreamController<List<TopicModel>>>{};

  // Memory Storage
  late List<DomainModel> _domains;
  late List<ModuleModel> _modules;
  late List<TopicModel> _topics;
  final List<BroadcastModel> _broadcasts = [];
  final List<UserModel> _members = [];
  final Map<String, UserProgressModel> _progressStore = {};

  MockDatabaseRepository() {
    _initMockData();
  }

  void _initMockData() {
    // 1. Initial Domains
    _domains = [
      DomainModel(
        id: 'dsa',
        name: 'Data Structures & Algorithms',
        description: 'Master core computational problem solving. Graphs, Dynamic Programming, Trees, and analysis.',
        leadUserId: 'user_led001',
        modules: [],
      ),
      DomainModel(
        id: 'web_dev',
        name: 'Web Development (Full Stack)',
        description: 'Build modern responsive websites and APIs using React, Node.js, Express, and Database design.',
        leadUserId: 'user_adm001',
        modules: [],
      ),
      DomainModel(
        id: 'ml',
        name: 'Machine Learning & AI',
        description: 'Deep dive into statistics, linear regression, neural networks, computer vision, and NLP.',
        leadUserId: 'user_adm001',
        modules: [],
      ),
    ];

    // 2. Initial Modules
    _modules = [
      // DSA Modules
      ModuleModel(id: 'dsa_mod1', domainId: 'dsa', title: 'Arrays & Hashing', order: 1, topics: []),
      ModuleModel(id: 'dsa_mod2', domainId: 'dsa', title: 'Two Pointers & Slid Window', order: 2, topics: []),
      ModuleModel(id: 'dsa_mod3', domainId: 'dsa', title: 'Trees & Recursion', order: 3, topics: []),
      
      // Web Dev Modules
      ModuleModel(id: 'web_mod1', domainId: 'web_dev', title: 'HTML, CSS & Modern layouts', order: 1, topics: []),
      ModuleModel(id: 'web_mod2', domainId: 'web_dev', title: 'JS Core & Asynchronous flows', order: 2, topics: []),
      ModuleModel(id: 'web_mod3', domainId: 'web_dev', title: 'State Management & Flutter Web', order: 3, topics: []),
    ];

    // 3. Initial Topics
    _topics = [
      // DSA mod1
      TopicModel(id: 'dsa_top1', moduleId: 'dsa_mod1', title: 'Contains Duplicate (Easy)', order: 1, resources: [
        ResourceModel(title: 'LeetCode Problem #217', url: 'https://leetcode.com/problems/contains-duplicate/', type: 'link'),
        ResourceModel(title: 'NeetCode Video Solution', url: 'https://www.youtube.com/watch?v=3OamzN90kDg', type: 'video'),
      ]),
      TopicModel(id: 'dsa_top2', moduleId: 'dsa_mod1', title: 'Two Sum (Easy)', order: 2, resources: [
        ResourceModel(title: 'LeetCode Problem #1', url: 'https://leetcode.com/problems/two-sum/', type: 'link'),
        ResourceModel(title: 'Video walkthrough', url: 'https://www.youtube.com/watch?v=KLlXCFG5Tk0', type: 'video'),
      ]),
      TopicModel(id: 'dsa_top3', moduleId: 'dsa_mod1', title: 'Group Anagrams (Medium)', order: 3, resources: [
        ResourceModel(title: 'LeetCode Problem #49', url: 'https://leetcode.com/problems/group-anagrams/', type: 'link'),
        ResourceModel(title: 'Optimal Approach Article', url: 'https://neetcode.io/solutions/group-anagrams', type: 'doc'),
      ]),

      // DSA mod2
      TopicModel(id: 'dsa_top4', moduleId: 'dsa_mod2', title: 'Valid Palindrome', order: 1, resources: [
        ResourceModel(title: 'LeetCode #125', url: 'https://leetcode.com/problems/valid-palindrome/', type: 'link'),
      ]),
      TopicModel(id: 'dsa_top5', moduleId: 'dsa_mod2', title: 'Two Sum II - Sorted Input', order: 2, resources: [
        ResourceModel(title: 'LeetCode #167', url: 'https://leetcode.com/problems/two-sum-ii-input-array-is-sorted/', type: 'link'),
      ]),

      // DSA mod3
      TopicModel(id: 'dsa_top6', moduleId: 'dsa_mod3', title: 'Invert Binary Tree', order: 1, resources: [
        ResourceModel(title: 'LeetCode #226', url: 'https://leetcode.com/problems/invert-binary-tree/', type: 'link'),
      ]),

      // Web Dev mod1
      TopicModel(id: 'web_top1', moduleId: 'web_mod1', title: 'Semantic Tags & Structures', order: 1, resources: [
        ResourceModel(title: 'MDN Semantic Elements Guide', url: 'https://developer.mozilla.org/en-US/docs/Glossary/Semantics', type: 'doc'),
      ]),
      TopicModel(id: 'web_top2', moduleId: 'web_mod1', title: 'CSS Grid & Flexbox Mastery', order: 2, resources: [
        ResourceModel(title: 'CSS Tricks Flexbox Complete Guide', url: 'https://css-tricks.com/snippets/css/a-guide-to-flexbox/', type: 'doc'),
        ResourceModel(title: 'Grid Garden Practice game', url: 'https://cssgridgarden.com/', type: 'practice'),
      ]),

      // Web Dev mod2
      TopicModel(id: 'web_top3', moduleId: 'web_mod2', title: 'Promises & Async Await', order: 1, resources: [
        ResourceModel(title: 'JavaScript.info Async chapter', url: 'https://javascript.info/async', type: 'doc'),
      ]),
    ];

    // 4. Initial Broadcasts
    _broadcasts.addAll([
      BroadcastModel(
        id: 'bc1',
        title: '🚀 Welcome to KRIVA App!',
        body: 'Kriva is officially launched for our community. Start tracking your roadmap, follow domains, and prepare for upcoming hackathons!',
        audienceType: 'all',
        audienceValue: '',
        sentBy: 'Club President',
        sentAt: DateTime.now().subtract(const Duration(days: 3)),
        readBy: ['user_mem001'],
      ),
      BroadcastModel(
        id: 'bc2',
        title: '📅 DSA Mentorship Session Today',
        body: 'Join us today at 6:00 PM in Seminar Hall 1 for an interactive Q&A session on trees and graphs. Don\'t forget to mark your roadmaps!',
        audienceType: 'domain',
        audienceValue: 'dsa',
        sentBy: 'Elena Rostova (DSA Lead)',
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
        readBy: [],
      ),
      BroadcastModel(
        id: 'bc3',
        title: '📢 Batch of 2026 Feedback Needed',
        body: 'We are planning our web dev workshop slots. Please complete the interest form pinned in the group.',
        audienceType: 'batch',
        audienceValue: 'Batch of 2026',
        sentBy: 'Club President',
        sentAt: DateTime.now().subtract(const Duration(days: 1)),
        readBy: [],
      ),
    ]);

    // 5. Initial Members
    _members.addAll([
      UserModel(
        uid: 'user_mem001',
        clubId: 'MEM001',
        name: 'Abhisht Singh',
        email: 'mem001@kriva.app',
        photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Abhisht',
        role: UserRole.member,
        batch: 'Batch of 2026',
        bio: 'Flutter enthusiast & competitive programmer. Building cool stuff!',
        domainsFollowing: ['dsa', 'web_dev'],
        streak: UserStreak(count: 7, lastActiveDate: DateTime.now().subtract(const Duration(hours: 4))),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      UserModel(
        uid: 'user_led001',
        clubId: 'LED001',
        name: 'Elena Rostova',
        email: 'led001@kriva.app',
        photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Elena',
        role: UserRole.lead,
        batch: 'Batch of 2025',
        bio: 'Domain Lead for Data Structures & Algorithms. Ask me anything about graphs!',
        domainsFollowing: ['dsa'],
        streak: UserStreak(count: 24, lastActiveDate: DateTime.now()),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      UserModel(
        uid: 'user_mem002',
        clubId: 'MEM002',
        name: 'Jane Doe',
        email: 'mem002@kriva.app',
        photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Jane',
        role: UserRole.member,
        batch: 'Batch of 2026',
        bio: 'Aspiring Web Developer & UI Designer.',
        domainsFollowing: ['web_dev'],
        streak: UserStreak(count: 3, lastActiveDate: DateTime.now()),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ]);

    // 6. Prepopulate Progress
    _progressStore['user_mem001_dsa'] = UserProgressModel(
      uid: 'user_mem001',
      domainId: 'dsa',
      topicsCompleted: {
        'dsa_top1': DateTime.now().subtract(const Duration(days: 5)),
        'dsa_top2': DateTime.now().subtract(const Duration(days: 2)),
      },
      percentComplete: 0.33,
    );
  }

  // Domain Stream
  @override
  Stream<List<DomainModel>> getDomains() {
    // Yield current values and update future subscribers
    Timer.run(() => _domainController.add(_domains));
    return _domainController.stream;
  }

  @override
  Future<DomainModel> getDomainById(String domainId) async {
    return _domains.firstWhere((element) => element.id == domainId);
  }

  // Modules Stream
  @override
  Stream<List<ModuleModel>> getModules(String domainId) {
    final key = domainId;
    if (!_modulesControllers.containsKey(key)) {
      _modulesControllers[key] = StreamController<List<ModuleModel>>.broadcast();
    }
    
    // Push updates
    final domainMods = _modules.where((m) => m.domainId == domainId).toList();
    domainMods.sort((a, b) => a.order.compareTo(b.order));
    Timer.run(() => _modulesControllers[key]!.add(domainMods));
    
    return _modulesControllers[key]!.stream;
  }

  // Topics Stream
  @override
  Stream<List<TopicModel>> getTopics(String domainId, String moduleId) {
    final key = moduleId;
    if (!_topicsControllers.containsKey(key)) {
      _topicsControllers[key] = StreamController<List<TopicModel>>.broadcast();
    }

    final modTopics = _topics.where((t) => t.moduleId == moduleId).toList();
    modTopics.sort((a, b) => a.order.compareTo(b.order));
    Timer.run(() => _topicsControllers[key]!.add(modTopics));

    return _topicsControllers[key]!.stream;
  }

  // User Progress Stream
  @override
  Stream<UserProgressModel?> getUserProgress(String uid, String domainId) {
    final key = '${uid}_$domainId';
    if (!_progressControllers.containsKey(key)) {
      _progressControllers[key] = StreamController<UserProgressModel?>.broadcast();
    }

    final progress = _progressStore[key] ?? UserProgressModel(
      uid: uid,
      domainId: domainId,
      topicsCompleted: {},
      percentComplete: 0.0,
    );

    Timer.run(() => _progressControllers[key]!.add(progress));
    return _progressControllers[key]!.stream;
  }

  // Toggle Completion
  @override
  Future<void> toggleTopicCompletion(
    String uid, 
    String domainId, 
    String topicId, 
    bool isCompleted,
    int totalTopicsInDomain,
  ) async {
    final progressKey = '${uid}_$domainId';
    final existing = _progressStore[progressKey] ?? UserProgressModel(
      uid: uid,
      domainId: domainId,
      topicsCompleted: {},
      percentComplete: 0.0,
    );

    final updatedMap = Map<String, DateTime>.from(existing.topicsCompleted);
    if (isCompleted) {
      updatedMap[topicId] = DateTime.now();
    } else {
      updatedMap.remove(topicId);
    }

    final double computedPercent = totalTopicsInDomain > 0
        ? (updatedMap.length / totalTopicsInDomain)
        : 0.0;

    final updatedProgress = existing.copyWith(
      topicsCompleted: updatedMap,
      percentComplete: double.parse(computedPercent.toStringAsFixed(2)),
    );

    _progressStore[progressKey] = updatedProgress;

    // Trigger update on stream
    if (_progressControllers.containsKey(progressKey)) {
      _progressControllers[progressKey]!.add(updatedProgress);
    }
  }

  // Broadcasts Stream
  @override
  Stream<List<BroadcastModel>> getBroadcasts(UserModel user) {
    // Sort broadcasts, newest first
    _sortBroadcasts();

    // Trigger immediate emission
    Timer.run(() => _broadcastController.add(_filterBroadcastsForUser(user)));
    return _broadcastController.stream;
  }

  void _sortBroadcasts() {
    _broadcasts.sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  List<BroadcastModel> _filterBroadcastsForUser(UserModel user) {
    return _broadcasts.where((bc) {
      if (bc.audienceType == 'all') return true;
      if (bc.audienceType == 'batch' && bc.audienceValue == user.batch) return true;
      if (bc.audienceType == 'domain' && user.domainsFollowing.contains(bc.audienceValue)) return true;
      return false;
    }).toList();
  }

  @override
  Future<void> markBroadcastAsRead(String uid, String broadcastId) async {
    final idx = _broadcasts.indexWhere((element) => element.id == broadcastId);
    if (idx != -1) {
      final bc = _broadcasts[idx];
      if (!bc.readBy.contains(uid)) {
        final updatedRead = List<String>.from(bc.readBy)..add(uid);
        _broadcasts[idx] = bc.copyWith(readBy: updatedRead);
        _broadcastController.add(_broadcasts); // updates listeners
      }
    }
  }

  @override
  Future<void> createBroadcast(BroadcastModel broadcast) async {
    _broadcasts.add(broadcast);
    _sortBroadcasts();
    _broadcastController.add(_broadcasts);
  }

  // Admin Roadmaps setup
  @override
  Future<void> createDomain(DomainModel domain) async {
    _domains.add(domain);
    _domainController.add(_domains);
  }

  @override
  Future<void> createModule(String domainId, ModuleModel module) async {
    _modules.add(module);
    if (_modulesControllers.containsKey(domainId)) {
      final domainMods = _modules.where((m) => m.domainId == domainId).toList();
      domainMods.sort((a, b) => a.order.compareTo(b.order));
      _modulesControllers[domainId]!.add(domainMods);
    }
  }

  @override
  Future<void> createTopic(String domainId, String moduleId, TopicModel topic) async {
    _topics.add(topic);
    if (_topicsControllers.containsKey(moduleId)) {
      final modTopics = _topics.where((t) => t.moduleId == moduleId).toList();
      modTopics.sort((a, b) => a.order.compareTo(b.order));
      _topicsControllers[moduleId]!.add(modTopics);
    }
  }

  // Members Stream
  @override
  Stream<List<UserModel>> getMembers() {
    Timer.run(() => _membersController.add(_members));
    return _membersController.stream;
  }

  @override
  Future<void> updateUserRole(String uid, UserRole role) async {
    final index = _members.indexWhere((element) => element.uid == uid);
    if (index != -1) {
      _members[index] = _members[index].copyWith(role: role);
      _membersController.add(_members);
    }
  }

  @override
  Future<void> updateFollowedDomains(String uid, List<String> domains) async {
    final index = _members.indexWhere((element) => element.uid == uid);
    if (index != -1) {
      _members[index] = _members[index].copyWith(domainsFollowing: domains);
      _membersController.add(_members);
    }
  }
}
