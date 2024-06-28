import 'package:flutter/material.dart';

import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/enums/direction_enum.dart';
import 'package:story_view/enums/indicator_height_enum.dart';
import 'package:story_view/models/group_data_model.dart';
import 'package:story_view/models/story_item_model.dart';
import 'package:story_view/widgets/story_view.dart';

class GroupedView extends StatefulWidget {
  final Duration? duration;
  final Curve? curve;
  final VoidCallback? onComplete;
  final VoidCallback? onGroupComplete;
  final Widget? groupInfo;
  final List<GroupData> groupedStoryItems;

  final void Function(StoryItem item, int index)? onStoryShow;

  final Function(Direction)? onVerticalSwipeComplete;

  final bool? repeat;

  final bool? inline;

  final StoryController storyController;

  final PageController pageController;

  final Color? indicatorColor;

  final Color? indicatorForegroundColor;

  final IndicatorHeight? indicatorHeight;

  final EdgeInsetsGeometry? indicatorOuterPadding;

  const GroupedView({
    Key? key,
    this.duration,
    this.curve,
    this.onComplete,
    this.onGroupComplete,
    this.groupInfo,
    required this.groupedStoryItems,
    this.onStoryShow,
    this.onVerticalSwipeComplete,
    this.repeat,
    this.inline,
    required this.storyController,
    required this.pageController,
    this.indicatorColor,
    this.indicatorForegroundColor,
    this.indicatorHeight,
    this.indicatorOuterPadding,
  }) : super(key: key);

  @override
  State<GroupedView> createState() => _GroupedViewState();
}

class _GroupedViewState extends State<GroupedView> {
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: widget.groupedStoryItems.length,
      controller: widget.pageController,
      itemBuilder: (context, index) {
        return StoryView(
          groupInfo: widget.groupInfo,
          storyItems: widget.groupedStoryItems[index].stories,
          controller: widget.storyController,
          onVerticalSwipeComplete: widget.onVerticalSwipeComplete,
          onComplete: () {
            if (index < widget.groupedStoryItems.length) {
              setState(() {
                widget.pageController.nextPage(
                  duration: widget.duration ?? Duration(milliseconds: 300),
                  curve: widget.curve ?? Curves.linear,
                );
              });

              if (widget.onGroupComplete != null) {
                widget.onGroupComplete!();
              }
            } else {
              if (widget.onComplete != null) {
                widget.onComplete!();
              }
            }
          },
          onStoryShow: widget.onStoryShow,
        );
      },
    );
  }
}
