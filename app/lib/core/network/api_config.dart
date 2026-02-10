/// API configuration with endpoint paths and timeouts.
class ApiConfig {
  const ApiConfig._();

  /// Base URL — set from CDK CfnOutput after deploy.
  /// Will be overridden in amplify_config.dart with actual deployed URL.
  static String baseUrl = 'https://q1e4rkyf7e.execute-api.eu-west-1.amazonaws.com/prod';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Endpoints
  static const String receipts = '/receipts';
  static const String receipt = '/receipts/{id}';
  static const String receiptRestore = '/receipts/{id}/restore';
  static const String refinement = '/receipts/{id}/refine';
  static const String sync = '/sync';
  static const String syncPull = '/sync/pull';
  static const String syncPush = '/sync/push';
  static const String syncFull = '/sync/full';
  static const String categories = '/categories';
  static const String presignedUrl = '/presigned-url';
  static const String userProfile = '/user/profile';
  static const String userSettings = '/user/settings';
  static const String userDelete = '/user/delete';
  static const String userExport = '/user/export';
  static const String warranties = '/warranties/expiring';
}
