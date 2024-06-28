import 'package:flutter/material.dart';
import 'package:story_view/enums/indicator_height_enum.dart';

class StoryProgressIndicator extends StatelessWidget {
  final AnimationController animationController;
  final int storyLength;
  final int shownStoryCount;
  final Color? indicatorColor;
  final Color? indicatorForegroundColor;
  final IndicatorHeight indicatorHeight;

  StoryProgressIndicator({
    required this.animationController,
    required this.storyLength,
    required this.shownStoryCount,
    this.indicatorColor,
    this.indicatorForegroundColor,
    required this.indicatorHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(storyLength, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3.0),
              child: LinearProgressIndicator(
                value: index < shownStoryCount
                    ? 1.0
                    : index == shownStoryCount
                        ? animationController.value
                        : 0.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                    indicatorForegroundColor ?? Colors.white),
                backgroundColor: indicatorColor ?? Colors.white38,
                minHeight: indicatorHeight == IndicatorHeight.small
                    ? 2.0
                    : indicatorHeight == IndicatorHeight.medium
                        ? 4.0
                        : 6.0,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
