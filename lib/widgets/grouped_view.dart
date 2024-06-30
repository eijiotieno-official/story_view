import 'package:flutter/material.dart'; // Import for Flutter widgets and material design

import 'package:story_view/controller/story_controller.dart'; // Import for StoryController
import 'package:story_view/enums/direction_enum.dart'; // Import for swipe direction enum
import 'package:story_view/enums/indicator_height_enum.dart'; // Import for indicator height enum
import 'package:story_view/models/group_data_model.dart'; // Import for group data model
import 'package:story_view/models/story_item_model.dart'; // Import for story item model
import 'package:story_view/widgets/story_view.dart'; // Import for StoryView widget

// GroupedView widget that displays groups of stories
class GroupedView extends StatefulWidget {
  final VoidCallback? onComplete; // Callback for when all groups are completed
  final VoidCallback? onGroupComplete; // Callback for when a group is completed
  final Widget? groupInfo; // Widget to show group info
  final List<GroupData> groupedStoryItems; // List of grouped story items

  final void Function(GroupData group, int index)? onGroupShow;
  final void Function(StoryItem item, int index)?
      onStoryShow; // Callback for when a story is shown
  final Function(Direction)?
      onVerticalSwipeComplete; // Callback for vertical swipe
  final bool? repeat; // Flag to repeat stories
  final bool? inline; // Flag to determine if stories are inline
  final StoryController
      storyController; // Controller for managing story playback
  final PageController pageController; // Controller for managing page view
  final Color? indicatorColor; // Color for the indicator
  final Color? indicatorForegroundColor; // Foreground color for the indicator
  final IndicatorHeight? indicatorHeight; // Height of the indicator
  final EdgeInsetsGeometry?
      indicatorOuterPadding; // Outer padding for the indicator

  // Constructor with required and optional parameters
  const GroupedView({
    Key? key,
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
    this.onGroupShow,
  }) : super(key: key);

  @override
  State<GroupedView> createState() => _GroupedViewState();
}

class _GroupedViewState extends State<GroupedView> {
  @override
  void initState() {
    super.initState();

    if (widget.groupedStoryItems.isNotEmpty && widget.onGroupShow != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onGroupShow!(widget.groupedStoryItems[0], 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(16.0),
      child: PageView.builder(
        onPageChanged: (value) {
          if (widget.onGroupShow != null) {
            widget.onGroupShow!(widget.groupedStoryItems[value],
                value); // Call the group complete callback when the page changes
          }
        },
        physics:
            const BouncingScrollPhysics(), // Set the physics for page scrolling
        itemCount: widget.groupedStoryItems.length, // Number of pages (groups)
        controller:
            widget.pageController, // PageController to control page view
        itemBuilder: (context, pageIndex) {
          return StoryView(
            groupInfo:
                widget.groupInfo, // Display additional group info if provided
            storyItems: widget.groupedStoryItems[pageIndex]
                .stories, // Pass the stories for the current group
            controller: widget.storyController, // Controller for story playback
            onVerticalSwipeComplete: widget
                .onVerticalSwipeComplete, // Callback for vertical swipe gesture
            onComplete: () {
              if (pageIndex < widget.groupedStoryItems.length - 1) {
                // If not the last group, move to the next group
                widget.pageController.nextPage(
                  duration: Duration(
                      milliseconds: 300), // Animation duration for page change
                  curve: Curves.linear, // Animation curve for page change
                );
              } else {
                // If the last group, call the complete callback
                if (widget.onComplete != null) {
                  widget.onComplete!();
                }
              }
            },
            onStoryShow: (storyItem, storyIndex) {
              if (widget.onStoryShow != null) {
                widget.onStoryShow!(storyItem, storyIndex);
              }
              if (widget.onGroupComplete != null) {
                bool islastItem = storyIndex ==
                    (widget.groupedStoryItems[pageIndex].stories.length - 1);
                if (islastItem) {
                  widget.onGroupComplete!();
                }
              }
            }, // Callback for when a story is shown
          );
        },
      ),
    );
  }
}
