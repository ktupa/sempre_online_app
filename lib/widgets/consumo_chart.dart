import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ConsumoChart extends StatelessWidget {
  final double consumo;

  const ConsumoChart({super.key, required this.consumo});

  @override
  Widget build(BuildContext context) {
    final List<BarChartGroupData> barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: consumo, width: 12)],
      ),
    ];

    return SizedBox(
      height: 80,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          barGroups: barGroups,
          alignment: BarChartAlignment.center,
          maxY: consumo > 5 ? consumo * 1.2 : 5,
        ),
      ),
    );
  }
}
