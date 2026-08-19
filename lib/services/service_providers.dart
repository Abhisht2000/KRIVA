import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/auth_repository.dart';
import 'auth/mock_auth_repository.dart';
import 'auth/firebase_auth_repository.dart';
import 'database/database_repository.dart';
import 'database/mock_database_repository.dart';
import 'database/firestore_database_repository.dart';
import '../models/user_model.dart';
import '../models/domain_model.dart';
import '../models/user_progress_model.dart';
import '../models/broadcast_model.dart';

// Provider for SharedPreferences (initialized in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
});

// Notifier to manage and toggle Mock Mode
class MockModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'use_mock_mode_v1';

  MockModeNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> toggle(bool val) async {
    state = val;
    await _prefs.setBool(_key, val);
  }
}

final useMockModeProvider = StateNotifierProvider<MockModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MockModeNotifier(prefs);
});

// Singletons for Mock repositories to maintain state in-memory during execution
final mockAuthRepositoryProvider = Provider<MockAuthRepository>((ref) {
  return MockAuthRepository();
});

final mockDatabaseRepositoryProvider = Provider<MockDatabaseRepository>((ref) {
  return MockDatabaseRepository();
});

// Dynamic Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final useMock = ref.watch(useMockModeProvider);
  if (useMock) {
    return ref.watch(mockAuthRepositoryProvider);
  } else {
    return FirebaseAuthRepository();
  }
});

// Dynamic Database Repository Provider
final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  final useMock = ref.watch(useMockModeProvider);
  if (useMock) {
    return ref.watch(mockDatabaseRepositoryProvider);
  } else {
    return FirestoreDatabaseRepository();
  }
});

// Auth State Changes Provider
final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

// Current UserModel Provider (derived from authStateChangesProvider)
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull;
});

// Streams of Domains
final domainsProvider = StreamProvider<List<DomainModel>>((ref) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getDomains();
});

// Stream of progress for a specific domain
final userProgressProvider = StreamProvider.family<UserProgressModel?, String>((ref, domainId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getUserProgress(user.uid, domainId);
});

// Streams of Broadcasts filtered for current user
final broadcastsProvider = StreamProvider<List<BroadcastModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getBroadcasts(user);
});
