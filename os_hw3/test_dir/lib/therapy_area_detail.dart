import 'package:flutter/material.dart';
import 'therapy_area.dart'; // For getIconDataFromString

class TherapyAreaDetailPage extends StatelessWidget {
  final String title;
  final String description;
  final String iconName;

  const TherapyAreaDetailPage({
    super.key,
    required this.title,
    required this.description,
    required this.iconName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              getIconDataFromString(iconName),
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}