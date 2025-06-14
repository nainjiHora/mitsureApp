import 'package:flutter/material.dart';

class AnimatedCircleTimer extends StatefulWidget {
  final String time;
  final Color hours;
  final bool flag;

  const AnimatedCircleTimer({
    super.key,
    required this.time,
    required this.hours,
    required this.flag,
  });

  @override
  State<AnimatedCircleTimer> createState() => _AnimatedCircleTimerState();
}

class _AnimatedCircleTimerState extends State<AnimatedCircleTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.flag) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCircleTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flag && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.flag && _controller.isAnimating) {
      _controller.stop();
    }
  }
  

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = widget.hours;
    final glowColor = hours;
    final glowIntensity = (7.clamp(1, 12)) * 0.2;

    if (!widget.flag) {
      // Static circle with shadow and blur, no animation
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: glowColor, width: 4),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(1.0),
              blurRadius: (10 + glowIntensity * 2),
              spreadRadius: (1 + glowIntensity),
            ),
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.time,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[900],
            ),
          ),
        ),
      );
    }

    // Animated version with ripple + pulse
    return SizedBox(
      width: 160,
      height: 160,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final safeScale = _animation.value.clamp(0.9, 1.1);
          final rippleSize = (140 * safeScale).clamp(1.0, double.infinity);
          final rippleOpacity = (0.2 * (2 - safeScale)).clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Ripple effect circle
              Container(
                width: rippleSize,
                height: rippleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowColor.withOpacity(rippleOpacity),
                ),
              ),

              // Main glowing circle with scaling pulse
              Transform.scale(
                scale: safeScale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: glowColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withOpacity(safeScale.clamp(0.0, 1.0)),
                        blurRadius: (10 + glowIntensity * 2),
                        spreadRadius: (1 + glowIntensity),
                      ),
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.time,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
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
}
