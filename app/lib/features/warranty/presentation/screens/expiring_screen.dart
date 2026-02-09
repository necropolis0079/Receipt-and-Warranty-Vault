import 'package:flutter/material.dart';

/// Placeholder screen for the Expiring Warranties tab.
///
/// Will display warranties sorted by expiry date with countdown timers.
/// Currently shows placeholder content.
class ExpiringScreen extends StatelessWidget {
  const ExpiringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiring Warranties'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer,
              size: 64,
              color: Color(0xFFBDBDBD),
            ),
            SizedBox(height: 16),
            Text(
              'Expiring warranties will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
