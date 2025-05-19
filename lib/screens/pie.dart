import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class IncentivePieChart extends StatelessWidget {
  final List<dynamic> incentu;

  IncentivePieChart({required this.incentu});

  Color getRandomColor() {
    final Random random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );
  }
  capitalize(value) {
    if (value.isNotEmpty) {
      List<dynamic> a = value.split('');
      a[0] = a[0].toUpperCase();
      return a.join('');
    } else {
      return '';
    }
  }
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // Add 100% opacity if not specified
    }
    return Color(int.parse(hexColor, radix: 16));
  }
  @override
  Widget build(BuildContext context) {
    List<Color> colors = List.generate(incentu.length, (index) => getRandomColor());

    return Padding(
      padding: EdgeInsets.only(right: 15.0),
      child: Container(
        color: Colors.white,
        height: 250,
        // Adjusted height for the chart
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Incentive Earned",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            Wrap(
              spacing: 6.0,
              runSpacing: 1.0,
              children: List.generate(
                incentu.length,
                    (index) => Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: _getColorFromHex(incentu[index]['color']??'#000'),
                    ),
                    SizedBox(width: 5),
                    Text(capitalize(incentu[index]['series']), style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: incentu.every((item) => (item['amount'] ?? 0) == 0)
                      ? [
                    PieChartSectionData(
                      color: Colors.grey,
                      value: 1, // Give a default value to render the chart
                      title: '',
                      radius: 30,
                      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  ]
                      : List.generate(
                    incentu.length,
                        (index) {
                      final item = incentu[index];
                      return PieChartSectionData(
                        color: _getColorFromHex(item['color']??'#000'),
                        value: double.parse(item['amount'].toString()),
                        title: '',
                        radius: 30,
                        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
