// lib/widgets/consumo_card.dart
import 'dart:math' as math;
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
    final total = downloadGB + uploadGB;
    final downloadPct = total == 0 ? .5 : downloadGB / total;
    // final uploadPct = 1 - downloadPct;

    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /*---------------- Donut mais compacto ----------------*/
        SizedBox(
          width: 38, // era 48
          height: 38,
          child: CustomPaint(
            painter: _DonutPainter(
              downloadPercent: downloadPct,
              downloadColor: primary,
              uploadColor: secondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        /*---------------- Texto ocupa o resto ----------------*/
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Download: ${downloadGB.toStringAsFixed(2)} GB',
                softWrap: true,
                overflow: TextOverflow.fade,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Upload: ${uploadGB.toStringAsFixed(2)} GB',
                softWrap: true,
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/*=================================================================*/
/*                         Custom painter                          */
/*=================================================================*/
class _DonutPainter extends CustomPainter {
  final double downloadPercent;
  final Color downloadColor;
  final Color uploadColor;

  _DonutPainter({
    required this.downloadPercent,
    required this.downloadColor,
    required this.uploadColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .20;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round;

    // upload (fundo)
    paint.color = uploadColor.withOpacity(.25);
    canvas.drawCircle(center, radius, paint);

    // download (arco)
    paint.color = downloadColor;
    final sweep = 2 * math.pi * downloadPercent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.downloadPercent != downloadPercent ||
      old.downloadColor != downloadColor ||
      old.uploadColor != uploadColor;
}
