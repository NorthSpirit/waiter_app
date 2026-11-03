// Class for the most basic state stuff of the user
// Like, employee id, name, role, restaurant logo, name, id - stuff, which is useful for multiple screens.
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

  // Pin mode exists in the state, because you select it from options, but it's relavent in the menu pages.
  bool pinMode = false;

  bool get isLoggedIn => token != null;

  // Truth be told, token in this is meant to last while someone is working, but only a hour if they are not, logic being
  // It would kinda suck, if it ran out after a few hours, while it is peak lunch time and waiter is trying to get an order
  // So token gets refreshed after each time, but runs out after an hour of not using
  void updateToken(String newToken) {
    token = newToken;
  }

  // Glues the restaurant logo properly, by getting the URL of the server (be it local for normal use or hosted for demo)
  // Aand glues it together, since pictures are saved by their location in the DB as a relative path
  // for example "/uploads/restaurants/2.jpg", rather than "http/somethingserver/uploads..."
  String get restaurantLogoFullUrl {
    if (restaurantLogoUrl == null || restaurantLogoUrl!.isEmpty || baseUrl == null) {
      return '';
    }
    return '$baseUrl$restaurantLogoUrl';
  }

  // Clear deliberately doesn't clear the URL, logic being, it doesn't really change
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