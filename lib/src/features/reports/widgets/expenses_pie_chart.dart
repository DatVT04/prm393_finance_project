import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:prm393_finance_project/src/core/utils/icon_utils.dart';
import '../models/category_report_data.dart';

class ExpensesPieChart extends StatefulWidget {
  const ExpensesPieChart({super.key, this.data = const {}});

  final Map<String, CategoryReportData> data;

  @override
  State<ExpensesPieChart> createState() => _ExpensesPieChartState();
}

class _ExpensesPieChartState extends State<ExpensesPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    if (entries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Chưa có dữ liệu chi tiêu')),
      );
    }

    final total = entries.fold<double>(0, (s, e) => s + e.value);
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: _buildSections(entries, total),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                entries.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Indicator(
                    color: IconUtils.getColor(entries[i].value.colorHex),
                    text: entries[i].value.displayName,
                    isSquare: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(List<MapEntry<String, CategoryReportData>> entries, double total) {
    const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final value = total > 0 ? (entries[i].value.totalAmount / total * 100) : 0.0;
      final radius = isTouched ? 60.0 : 50.0;
      return PieChartSectionData(
        color: IconUtils.getColor(entries[i].value.colorHex),
        value: entries[i].value.totalAmount,
        title: '${value.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 18 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
      );
    });
  }
}

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    this.isSquare = true,
    this.size = 16,
    this.textColor,
  });
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
