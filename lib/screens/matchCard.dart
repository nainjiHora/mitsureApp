import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:flutter/material.dart';

class GaugeScreen extends StatefulWidget {
final value;
GaugeScreen({required this.value});

  @override
  State<GaugeScreen> createState() => _GaugeScreenState();
}

class _GaugeScreenState extends State<GaugeScreen> {


  @override
  Widget build(BuildContext context) {
print(widget.value);
    return AnimatedRadialGauge(

        duration: const Duration(seconds: 4),
    curve: Curves.linear,
    radius: 100,
    value: widget.value/100,


    axis: GaugeAxis(
    min: 0,
    max: 100,
    degrees: 270,

    style: const GaugeAxisStyle(
    thickness: 20,
    background: Colors.transparent,
    segmentSpacing: 4,
    ),

    //0/ Define the pointer that will indicate the progress (optional).
    pointer: GaugePointer.needle(
      color: Colors.red,
    height: 70,
    width: 10,

    ),


    progressBar: const GaugeProgressBar.rounded(
    color: Colors.transparent,
    ),

    segments: [
    const GaugeSegment(
    from: 0,
    to: 33.3,
    color: Colors.red,
    cornerRadius: Radius.zero,
    ),
    const GaugeSegment(
    from: 33.3,
    to: 66.6,
    color: Colors.orange,
    cornerRadius: Radius.zero,
    ),
    const GaugeSegment(
    from: 66.6,
    to: 100,
    color: Colors.green,
    cornerRadius: Radius.zero,
    ),
    ]


    ),

    );
  }
}
