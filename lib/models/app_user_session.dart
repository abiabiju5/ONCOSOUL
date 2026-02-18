import '../services/auth_service.dart';

/// Simple in-memory session holder.
/// Stores the currently logged-in user so any screen can access it.
class AppUserSession {
  AppUserSession._();

  static AppUser? currentUser;

  static bool get isLoggedIn => currentUser != null;

  static void clear() => currentUser = null;
}