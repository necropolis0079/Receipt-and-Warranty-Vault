import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:warrantyvault/app.dart';
import 'package:warrantyvault/core/di/injection.dart';
import 'package:warrantyvault/core/errors/error_logger.dart';
import 'package:warrantyvault/core/notifications/notification_service.dart';
import 'package:warrantyvault/core/services/home_widget_service.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize error logger before anything else.
      await ErrorLogger.instance.initialize();

      // Capture Flutter framework errors.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        ErrorLogger.instance.logFlutterError(details);
      };

      // Capture platform-level errors not caught by Flutter framework.
      PlatformDispatcher.instance.onError = (error, stack) {
        ErrorLogger.instance.logError(error, stack);
        return true;
      };

      await configureDependencies();
      await getIt<NotificationService>().initialize();
      await getIt<HomeWidgetService>().initialize();
      await getIt<HomeWidgetService>().checkAndStoreInitialLaunch();
      runApp(const WarrantyVaultApp());
    },
    (error, stack) {
      // Catch any errors that escape the Flutter framework.
      ErrorLogger.instance.logError(error, stack);
    },
  );
}
