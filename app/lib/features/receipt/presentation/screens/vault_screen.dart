import 'package:flutter/material.dart';

/// Placeholder screen for the Vault (home) tab.
///
/// Displays the user's receipt list. Currently shows placeholder content
/// that will be replaced with a receipt list view backed by the Drift
/// database and BLoC state management.
class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Receipts'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Color(0xFFBDBDBD),
            ),
            SizedBox(height: 16),
            Text(
              'Your receipts will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement camera capture
        },
        tooltip: 'Capture receipt',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
