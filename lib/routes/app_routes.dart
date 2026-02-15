/// App route names
class AppRoutes {
  // Main routes
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String logs = '/logs';
  static const String errors = '/errors';
  static const String settings = '/settings';
  
  // Detail routes
  static const String logDetails = '/logs/:id';
  static const String serviceDetails = '/services/:name';
  
  // Onboarding
  static const String setup = '/setup';
  
  /// Generate log details route with ID
  static String logDetailsRoute(String id) => '/logs/$id';
  
  /// Generate service details route with name
  static String serviceDetailsRoute(String name) => '/services/$name';
}
