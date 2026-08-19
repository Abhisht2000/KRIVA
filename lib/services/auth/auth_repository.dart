import '../../models/user_model.dart';

abstract class AuthRepository {
  /// Stream that emits the current user whenever auth state changes.
  Stream<UserModel?> get authStateChanges;

  /// Current logged in user (null if guest).
  UserModel? get currentUser;

  /// Signs in using either a Club ID (which internally maps to clubid@kriva.app) or an email address.
  Future<UserModel> signIn(String loginId, String password);

  /// Signs in using Google Sign-In.
  Future<UserModel> signInWithGoogle();

  /// Logs out the current user.
  Future<void> signOut();

  /// Updates the password (useful for first-time login temp password updates).
  Future<void> updatePassword(String newPassword);

  /// Completes profile setup on first-time login.
  Future<UserModel> completeProfile({
    required String name,
    required String bio,
    required String batch,
    required List<String> domains,
    required String photoUrl,
  });
}
