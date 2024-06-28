import 'dart:math';

import 'package:story_view/enums/direction_enum.dart';

class VerticalDragInfo {
  bool cancel = false;

  Direction? direction;

  void update(double primaryDelta) {
    Direction tmpDirection;

    if (primaryDelta > 0) {
      tmpDirection = Direction.down;
    } else {
      tmpDirection = Direction.up;
    }

    if (direction != null && tmpDirection != direction) {
      cancel = true;
    }

    direction = tmpDirection;
  }
}

class ColorUtils {
  /// Calculate luminance of an RGB color
  static double luminance(List<int> rgb) {
    double r = rgb[0] / 255.0;
    double g = rgb[1] / 255.0;
    double b = rgb[2] / 255.0;

    List<double> rs = [r, g, b];

    for (int i = 0; i < 3; i++) {
      if (rs[i] <= 0.03928) {
        rs[i] = rs[i] / 12.92;
      } else {
        rs[i] = pow((rs[i] + 0.055) / 1.055, 2.4).toDouble();
      }
    }

    return 0.2126 * rs[0] + 0.7152 * rs[1] + 0.0722 * rs[2];
  }

  /// Calculate contrast of a color against another color
  static double contrast(List<int> rgb1, List<int> rgb2) {
    double lum1 = luminance(rgb1) + 0.05;
    double lum2 = luminance(rgb2) + 0.05;

    return max(lum1, lum2) / min(lum1, lum2);
  }
}
