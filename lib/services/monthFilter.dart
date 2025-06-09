import 'package:flutter/material.dart';

class MonthFilter extends StatefulWidget {
  final Function(int) onMonthSelected;
  final int? initialMonth;

  const MonthFilter({
    super.key,
    required this.onMonthSelected,
    required this.initialMonth,
  });

  @override
  State<MonthFilter> createState() => _MonthFilterState();
}

class _MonthFilterState extends State<MonthFilter> {
  late int selectedMonth;

  final List<String> monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
   
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.indigo[50],
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      
      child: DropdownButton<int>(
        value: widget.initialMonth,
        icon: const Icon(Icons.arrow_drop_down),
        items: List.generate(12, (index) {
          return DropdownMenuItem<int>(
            value: index + 1,
            child: Text(monthNames[index]),
          );
        }),
        onChanged: (int? newMonth) {
          if (newMonth != null) {
            setState(() {
              selectedMonth = newMonth;
            });
            widget.onMonthSelected(newMonth);
          }
        },
      ),
    );
  }
}
