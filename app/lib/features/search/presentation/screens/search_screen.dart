import 'package:flutter/material.dart';

/// Placeholder screen for the Search tab.
///
/// Provides a search bar and will eventually support keyword search,
/// FTS5 full-text search, and filters. Currently non-functional.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search your receipts',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) {
                // TODO: Implement search
              },
            ),
            const SizedBox(height: 48),
            const Icon(
              Icons.search,
              size: 64,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 16),
            const Text(
              'Search your receipts',
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
