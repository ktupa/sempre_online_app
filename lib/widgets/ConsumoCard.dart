import 'package:flutter/material.dart';

class ConsumoCard extends StatelessWidget {
  final double downloadGB;
  final double uploadGB;

  const ConsumoCard({
    Key? key,
    required this.downloadGB,
    required this.uploadGB,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Download: ${downloadGB.toStringAsFixed(2)} GB',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload: ${uploadGB.toStringAsFixed(2)} GB',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
