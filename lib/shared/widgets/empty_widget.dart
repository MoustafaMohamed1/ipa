import 'package:flutter/material.dart';

class EmptyWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyWidget({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ],
        ),
      ),
    );
  }
}
