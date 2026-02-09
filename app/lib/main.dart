import 'package:flutter/material.dart';
import 'package:warrantyvault/app.dart';
import 'package:warrantyvault/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const WarrantyVaultApp());
}
