import 'package:flutter/material.dart';

class MonthYearFilter extends StatefulWidget {
  final Function(int month, int year) onSelected;
  final int? initialMonth;
  final int? initialYear;

  const MonthYearFilter({
    super.key,
    required this.onSelected,
    this.initialMonth,
    this.initialYear,
  });

  @override
  State<MonthYearFilter> createState() => _MonthYearFilterState();
}

class _MonthYearFilterState extends State<MonthYearFilter> {
  late int selectedMonth;
  late int selectedYear;

  final List<String> monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  late List<int> years;

  @override
  void initState() {
    super.initState();

    final currentYear = DateTime.now().year;
    years = List.generate(10, (index) => currentYear - index); // last 10 years

    selectedMonth = widget.initialMonth ?? DateTime.now().month;
    selectedYear = widget.initialYear ?? currentYear;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.indigo[50],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [

          /// Month Dropdown
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: const InputDecoration(
                labelText: "Month",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(monthNames[index]),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedMonth = value);
                  widget.onSelected(selectedMonth, selectedYear);
                }
              },
            ),
          ),

          const SizedBox(width: 12),

          /// Year Dropdown
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: const InputDecoration(
                labelText: "Year",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedYear = value);
                  widget.onSelected(selectedMonth, selectedYear);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
