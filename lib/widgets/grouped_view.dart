import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';

// GroupedView widget that displays groups of stories
class GroupedView extends StatefulWidget {
 final StoryController storyController;
  final List<GroupItem> groupedStoryItems; // List of grouped story items
  final VoidCallback? onComplete; // Callback for when all groups are completed
  final VoidCallback? onGroupComplete; // Callback for when a group is completed
  final Widget? groupInfo; // Widget to show group info
  final void Function(GroupItem group, int index)? onGroupShow;
  final void Function(StoryItem story, int index)?
      onStoryShow; // Callback for when a story is shown
  final Function(Direction)?
      onVerticalSwipeComplete; // Callback for vertical swipe
  final Color? indicatorColor; // Color for the indicator
  final Color? indicatorForegroundColor; // Foreground color for the indicator
  final IndicatorHeight indicatorHeight; // Height of the indicator

  // Constructor with required and optional parameters
  const GroupedView({
    Key? key,
    this.onComplete,
    this.onGroupComplete,
    this.groupInfo,
    required this.groupedStoryItems,
    this.onStoryShow,
    this.onVerticalSwipeComplete,
    this.indicatorColor,
    this.indicatorForegroundColor,
    this.indicatorHeight = IndicatorHeight.large,
    this.onGroupShow, required this.storyController,
  }) : super(key: key);

  @override
  State<GroupedView> createState() => _GroupedViewState();
}

class _GroupedViewState extends State<GroupedView> {
  final PageController _pageController = PageController();

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
        controller: _pageController, // PageController to control page view
        itemBuilder: (context, pageIndex) {
          return StoryView(
            indicatorColor: widget.indicatorColor,
            indicatorForegroundColor: widget.indicatorForegroundColor,
            indicatorHeight: widget.indicatorHeight,
            groupInfo:
                widget.groupInfo, // Display additional group info if provided
            storyItems: widget.groupedStoryItems[pageIndex]
                .stories, // Pass the stories for the current group
            controller: widget.storyController, // Controller for story playback
            onVerticalSwipeComplete: widget
                .onVerticalSwipeComplete, // Callback for vertical swipe gesture
            onComplete: () {
              if (widget.onGroupComplete != null) {
                widget.onGroupComplete!();
              }
              if (pageIndex < widget.groupedStoryItems.length - 1) {
                // If not the last group, move to the next group
                _pageController.nextPage(
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
            onStoryShow:
                widget.onStoryShow, // Callback for when a story is shown
            onPreviousGroup: () {
              _pageController.previousPage(
                duration: Duration(
                    milliseconds: 300), // Animation duration for page change
                curve: Curves.linear, // Animation curve for page change
              );
            },
          );
        },
      ),
    );
  }
}
