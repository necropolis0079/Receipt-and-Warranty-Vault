import 'package:flutter/material.dart';
import 'package:warrantyvault/app.dart';
import 'package:warrantyvault/core/di/injection.dart';
import 'package:warrantyvault/core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await getIt<NotificationService>().initialize();
  runApp(const WarrantyVaultApp());
}
