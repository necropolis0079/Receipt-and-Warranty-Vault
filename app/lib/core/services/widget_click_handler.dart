import 'package:flutter/material.dart';

import '../../features/receipt/presentation/screens/add_receipt_screen.dart';
import '../../features/receipt/presentation/widgets/capture_option_sheet.dart';

/// Handles deep-link URIs originating from home-screen widget taps.
///
/// Expected URI format: `warrantyvault://capture?source=camera|gallery|files`
class WidgetClickHandler {
  WidgetClickHandler._();

  /// Parses [uri] and navigates to [AddReceiptScreen] with the appropriate
  /// [CaptureOption].
  static void handle(Uri uri, BuildContext context) {
    if (uri.host != 'capture') return;

    final source = uri.queryParameters['source'];
    final CaptureOption option;

    switch (source) {
      case 'camera':
        option = CaptureOption.camera;
      case 'gallery':
        option = CaptureOption.gallery;
      case 'files':
        option = CaptureOption.files;
      default:
        // Unknown source — default to camera.
        option = CaptureOption.camera;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddReceiptScreen(initialOption: option),
      ),
    );
  }
}
