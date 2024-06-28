import 'package:flutter/material.dart';

/// A custom progress indicator for story pages.
class StoryProgressIndicator extends StatelessWidget {
  final double value; // Current progress value
  final double indicatorHeight; // Height of the indicator
  final Color? indicatorColor; // Background color of the indicator
  final Color? indicatorForegroundColor; // Foreground color of the indicator

  StoryProgressIndicator(
    this.value, {
    this.indicatorHeight = 5,
    this.indicatorColor,
    this.indicatorForegroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromHeight(
          indicatorHeight), // Set the size of the custom paint area
      foregroundPainter: IndicatorOval(
        indicatorForegroundColor ?? Colors.white.withOpacity(0.8),
        value,
      ), // Draws the foreground (progress) of the indicator
      painter: IndicatorOval(
        indicatorColor ?? Colors.white.withOpacity(0.4),
        1.0,
      ), // Draws the background of the indicator
    );
  }
}

/// Custom painter class for drawing the progress indicator oval.
class IndicatorOval extends CustomPainter {
  final Color color; // Color to paint the oval
  final double widthFactor; // Factor to determine the width of the oval

  IndicatorOval(this.color, this.widthFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color; // Create a paint object with the specified color
    // Draw a rounded rectangle (oval) with the specified width factor
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * widthFactor, size.height),
        Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true; // Always repaint when the paint method is called
  }
}
