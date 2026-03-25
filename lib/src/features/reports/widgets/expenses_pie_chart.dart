import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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

    final total = entries.fold<double>(0, (s, e) => s + e.value.totalAmount);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      height: 240,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 400;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
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
                    sectionsSpace: 2,
                    centerSpaceRadius: isSmall ? 35 : 45,
                    sections: _buildSections(entries, total, isSmall),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      entries.length,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Indicator(
                          color: IconUtils.getColor(entries[i].value.colorHex),
                          text: entries[i].value.displayName.tr(),
                          isSquare: false,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, CategoryReportData>> entries,
    double total,
    bool isSmall,
  ) {
    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final valuePercent = total > 0 ? (entries[i].value.totalAmount / total * 100) : 0.0;
      final radius = isTouched ? (isSmall ? 55.0 : 65.0) : (isSmall ? 45.0 : 55.0);
      
      return PieChartSectionData(
        color: IconUtils.getColor(entries[i].value.colorHex),
        value: entries[i].value.totalAmount,
        title: valuePercent >= 5 ? '${valuePercent.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 16 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
        ),
        titlePositionPercentageOffset: 0.55,
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
