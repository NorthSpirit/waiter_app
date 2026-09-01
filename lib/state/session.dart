class Session {
  static final Session instance = Session._();
  Session._();

  String? baseUrl;
  String? token;

  int? restaurantId;
  String? restaurantName;
  String? restaurantLogoUrl;

  int? employeeId;
  String? employeeName;
  String? role;

  bool pinMode = false;

  bool get isLoggedIn => token != null;

  void updateToken(String newToken) {
    token = newToken;
  }

  /// The restaurant logo as a full, directly-loadable URL — the server
  /// returns a relative path, so this stitches it onto baseUrl. Empty
  /// if the restaurant has no logo set.
  String get restaurantLogoFullUrl {
    if (restaurantLogoUrl == null || restaurantLogoUrl!.isEmpty || baseUrl == null) {
      return '';
    }
    return '$baseUrl$restaurantLogoUrl';
  }

  void clear() {
    token = null;
    restaurantId = null;
    restaurantName = null;
    restaurantLogoUrl = null;
    employeeId = null;
    employeeName = null;
    role = null;
    pinMode = false;
  }
}