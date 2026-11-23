class AppConfig {
  // Set to false for live production PocketBase Cloud deployment
  // Set to true if testing locally with `pocketbase serve`
  static const bool useLocal = false;

  static const String localUrl = 'http://127.0.0.1:8090';
  static const String productionUrl = 'https://rj2jgq7ubyors21.pwz5.pocketbasecloud.com';

  static String get pocketBaseUrl => useLocal ? localUrl : productionUrl;
}
