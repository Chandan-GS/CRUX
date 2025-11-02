import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A pill-shaped countdown timer with 60 circular ticks representing seconds.
class TickingTimer extends StatefulWidget {
  final int minutes;
  final double width;
  final double height;

  const TickingTimer({
    super.key,

    required this.minutes,
    this.width = 150,
    this.height = 100, // Retains the larger default height
  });

  @override
  State<TickingTimer> createState() => _TickingTimerState();
}

class _TickingTimerState extends State<TickingTimer> {
  Timer? _timer;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    _totalSeconds = (widget.minutes * 60);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_totalSeconds > 0) {
        setState(() => _totalSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Formats the remaining time for display.
  String get _timeDisplay {
    final hours = _totalSeconds ~/ 3600;
    final minutes = (_totalSeconds % 3600) ~/ 60;
    final seconds = _totalSeconds % 60;
    final minutesPadded = minutes.toString().padLeft(2, '0');
    final secondsPadded = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return "$hours:$minutesPadded:$secondsPadded";
    } else {
      return "$minutesPadded:$secondsPadded";
    }
  }

  /// Calculates which tick should be the last active one.
  int get _activeTickIndex {
    if (_totalSeconds == 0) return -1;
    return (_totalSeconds - 1) % 60;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 25, 0),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TimerTickPainter(
                activeTickIndex: _activeTickIndex,
                activeColor: Theme.of(context).colorScheme.tertiary,
                inactiveColor: Theme.of(context).colorScheme.secondary,
                dotRadius: 2.5, // The radius of each circular dot
              ),
            ),
          ),
          Text(
            _timeDisplay,
            style: GoogleFonts.robotoCondensed(
              // --- CHANGE 1: Font size is now hardcoded to 18 ---
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerTickPainter extends CustomPainter {
  final int activeTickIndex;
  final Color activeColor;
  final Color inactiveColor;
  final double dotRadius;

  _TimerTickPainter({
    required this.activeTickIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const totalTicks = 60;
    final paint = Paint()..style = PaintingStyle.fill;

    // The path for the ticks remains dynamic to handle any widget size.
    final pathRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          // Inset the path from the edge so the dots are centered nicely.
          pathRect.deflate(dotRadius * 4),
          Radius.circular(size.height / 2),
        ),
      );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    for (int i = 0; i < totalTicks; i++) {
      paint.color = i <= activeTickIndex ? activeColor : inactiveColor;

      final distance = metric.length * i / totalTicks;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent == null) continue;

      final pos = tangent.position;

      // --- CHANGE 2: Draw a circle at the position on the path ---
      canvas.drawCircle(pos, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerTickPainter oldDelegate) =>
      oldDelegate.activeTickIndex != activeTickIndex;
}
