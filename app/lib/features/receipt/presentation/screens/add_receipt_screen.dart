import 'package:flutter/material.dart';

/// Placeholder screen for adding a new receipt.
///
/// Provides three capture methods: camera, gallery import, and file import.
/// Currently shows placeholder cards for each method that will be wired up
/// to the image capture and import logic.
class AddReceiptScreen extends StatelessWidget {
  const AddReceiptScreen({super.key});

  static const _forestGreen = Color(0xFF2D5A3D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Receipt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo,
              size: 64,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 16),
            const Text(
              'Capture or import a receipt',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),
            _CaptureOptionCard(
              icon: Icons.camera_alt,
              label: 'Take Photo',
              onTap: () {
                // TODO: Implement camera capture
              },
            ),
            const SizedBox(height: 12),
            _CaptureOptionCard(
              icon: Icons.photo_library,
              label: 'From Gallery',
              onTap: () {
                // TODO: Implement gallery import
              },
            ),
            const SizedBox(height: 12),
            _CaptureOptionCard(
              icon: Icons.file_present,
              label: 'From Files',
              onTap: () {
                // TODO: Implement file import
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureOptionCard extends StatelessWidget {
  const _CaptureOptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AddReceiptScreen._forestGreen,
        ),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
