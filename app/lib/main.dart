import 'package:flutter/material.dart';
import 'package:warrantyvault/app.dart';
import 'package:warrantyvault/core/config/amplify_config.dart';
import 'package:warrantyvault/core/di/injection.dart';
import 'package:warrantyvault/core/sync/background_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureAmplify();
  await configureDependencies();
  await initializeBackgroundSync();
  runApp(const WarrantyVaultApp());
}
