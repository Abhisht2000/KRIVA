import 'dart:async';
import '../../models/user_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  // Initial Seed Users
  static final Map<String, UserModel> _mockUsers = {
    'MEM001': UserModel(
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
    'LED001': UserModel(
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
    'ADM001': UserModel(
      uid: 'user_adm001',
      clubId: 'ADM001',
      name: 'Club President',
      email: 'adm001@kriva.app',
      photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=President',
      role: UserRole.admin,
      batch: 'Batch of 2024',
      bio: 'Core Organizer. Managing sessions, roadmaps, and broadcasts.',
      domainsFollowing: [],
      streak: UserStreak(count: 0, lastActiveDate: null),
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
  };

  MockAuthRepository() {
    // Start as signed-out
    _controller.add(null);
  }

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> signIn(String loginId, String password) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network

    // Format loginId if it's club ID
    final String cleanId = loginId.toUpperCase().trim();
    String lookupId = cleanId;
    if (cleanId.contains('@')) {
      // Extract club ID from emails like mem001@kriva.app
      lookupId = cleanId.split('@')[0].toUpperCase();
    }

    if (_mockUsers.containsKey(lookupId)) {
      final user = _mockUsers[lookupId]!;
      _currentUser = user;
      _controller.add(_currentUser);
      return _currentUser!;
    } else {
      // Let's create a generic user if they type something else, for easy demoing
      final genericUser = UserModel(
        uid: 'user_${cleanId.toLowerCase()}',
        clubId: cleanId,
        name: cleanId,
        email: '${cleanId.toLowerCase()}@kriva.app',
        photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=$cleanId',
        role: UserRole.member,
        batch: 'Batch of 2027',
        bio: 'New Club Member! Setting up my journey.',
        domainsFollowing: [],
        streak: UserStreak(count: 1, lastActiveDate: DateTime.now()),
        createdAt: DateTime.now(),
      );
      _currentUser = genericUser;
      _controller.add(_currentUser);
      return _currentUser!;
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _currentUser = UserModel(
      uid: 'google_user_123',
      clubId: 'GGL999',
      name: 'Google User',
      email: 'user@gmail.com',
      photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Google',
      role: UserRole.member,
      batch: 'Batch of 2026',
      bio: 'Logged in with Google.',
      domainsFollowing: [],
      streak: UserStreak(count: 1, lastActiveDate: DateTime.now()),
      createdAt: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<UserModel> completeProfile({
    required String name,
    required String bio,
    required String batch,
    required List<String> domains,
    required String photoUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (_currentUser == null) throw Exception('No user logged in');
    
    _currentUser = _currentUser!.copyWith(
      name: name,
      bio: bio,
      batch: batch,
      domainsFollowing: domains,
      photoUrl: photoUrl.isNotEmpty ? photoUrl : _currentUser!.photoUrl,
    );
    
    // Update the seed map as well so logging back in retains changes in this run
    if (_mockUsers.containsKey(_currentUser!.clubId)) {
      _mockUsers[_currentUser!.clubId] = _currentUser!;
    }
    
    _controller.add(_currentUser);
    return _currentUser!;
  }

  void updateStreak(int increment) {
    if (_currentUser != null) {
      final currentStreak = _currentUser!.streak;
      _currentUser = _currentUser!.copyWith(
        streak: currentStreak.copyWith(
          count: currentStreak.count + increment,
          lastActiveDate: DateTime.now(),
        ),
      );
      _controller.add(_currentUser);
    }
  }
}
