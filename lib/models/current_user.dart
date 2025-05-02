
// Singleton model to store the current user's role and team ID
// This class is used to manage the current user's role and team ID throughout the app
class CurrentUser {
  static final CurrentUser _instance = CurrentUser._internal(); // Private instance

  factory CurrentUser() => _instance; // returns the singleton instance

  CurrentUser._internal(); // Private constructor

  String? role; // User's role (e.g., 'coach', 'player')
  String? teamId; // User's team ID

  // Clears all values when the user logs out
  void clear() {
    role = null;
    teamId = null;
  }
}
