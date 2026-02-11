import 'dart:async';

import 'package:home_widget/home_widget.dart';

/// Wraps the `home_widget` package behind an injectable service.
///
/// Provides a clean interface for:
/// - Initializing the widget bridge (iOS app group)
/// - Pushing stats updates to the native widget
/// - Detecting widget-click launches (cold + warm start)
class HomeWidgetService {
  static const _androidWidgetName = 'WarrantyVaultWidgetProvider';
  static const _iOSWidgetName = 'WarrantyVaultWidget';
  static const _appGroupId = 'group.io.cronos.warrantyvault';
  static const _statsKey = 'stats_text';

  Uri? _pendingUri;

  /// Call once at app startup.
  Future<void> initialize() async {
    HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Saves [statsText] to shared storage and triggers a native widget refresh.
  Future<void> updateStats(String statsText) async {
    await HomeWidget.saveWidgetData<String>(_statsKey, statsText);
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  }

  /// Checks whether the app was cold-launched from a home-screen widget tap.
  ///
  /// If so, stores the URI for later consumption via [consumePendingUri].
  Future<void> checkAndStoreInitialLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) {
      _pendingUri = uri;
    }
  }

  /// Returns the stored initial-launch URI once, then clears it.
  Uri? consumePendingUri() {
    final uri = _pendingUri;
    _pendingUri = null;
    return uri;
  }

  /// Stream of URIs emitted when the user taps the widget while the app is
  /// already running (warm start).
  Stream<Uri?> get widgetClickStream => HomeWidget.widgetClicked;
}
