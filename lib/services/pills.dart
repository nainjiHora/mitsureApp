import 'package:flutter/material.dart';

class PillTab extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool active;

   PillTab({Key? key, required this.label, this.onTap,required this.active}) ;

  @override
  _PillTabState createState() => _PillTabState();
}

class _PillTabState extends State<PillTab> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.active ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.active  ? primary : Colors.grey.shade400,
            width: 1.2,
          ),
          boxShadow: widget.active
              ? [
            BoxShadow(
              color: primary.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : null,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.active  ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
