class CurrentUser {
  static final CurrentUser _instance = CurrentUser._internal();

  factory CurrentUser() => _instance;

  CurrentUser._internal();

  String? role;
  String? teamId;

  void clear() {
    role = null;
    teamId = null;
  }
}
