import 'dart:async'; // Import for Timer and StreamSubscription

import 'package:collection/collection.dart'
    show IterableExtension; // Import for convenient iterable operations
import 'package:flutter/material.dart'; // Import for Flutter widgets and material design

import 'package:story_view/enums/direction_enum.dart'; // Import for swipe direction enum
import 'package:story_view/enums/indicator_height_enum.dart'; // Import for indicator height enum
import 'package:story_view/enums/playback_state_enum.dart'; // Import for playback state enum
import 'package:story_view/enums/progress_position_enum.dart'; // Import for progress position enum
import 'package:story_view/models/page_data_model.dart'; // Import for page data model
import 'package:story_view/models/story_item_model.dart'; // Import for story item model

import '../controller/story_controller.dart'; // Import for story controller
import '../utils.dart'; // Import for utility functions
import 'page_bar.dart'; // Import for page bar widget

// Main StoryView widget that displays the story items
class StoryView extends StatefulWidget {
  final List<StoryItem> storyItems; // List of story items to display
  final VoidCallback? onComplete; // Callback for when the story completes
  final Function(Direction)?
      onVerticalSwipeComplete; // Callback for vertical swipe gesture
  final void Function(StoryItem storyItem, int index)?
      onStoryShow; // Callback for when a story item is shown
  final ProgressPosition progressPosition; // Position of the progress indicator
  final bool repeat; // Flag to repeat the story
  final bool inline; // Flag to determine if the story is inline
  final StoryController controller; // Controller for managing story playback
  final Color? indicatorColor; // Color for the indicator
  final Color? indicatorForegroundColor; // Foreground color for the indicator
  final IndicatorHeight indicatorHeight; // Height of the indicator
  final EdgeInsetsGeometry
      indicatorOuterPadding; // Outer padding for the indicator
  final Widget? groupInfo; // Additional info widget for the group

  // Constructor with required and optional parameters
  StoryView({
    Key? key,
    required this.storyItems,
    this.onComplete,
    required this.onVerticalSwipeComplete,
    required this.onStoryShow,
    this.progressPosition = ProgressPosition.top,
    this.repeat = false,
    this.inline = false,
    required this.controller,
    this.indicatorColor,
    this.indicatorForegroundColor,
    this.indicatorHeight = IndicatorHeight.large,
    this.indicatorOuterPadding = const EdgeInsets.all(16.0),
    this.groupInfo,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StoryViewState(); // Create and return the state object
  }
}

// State class for StoryView widget
class StoryViewState extends State<StoryView> with TickerProviderStateMixin {
  AnimationController? _animationController; // Controller for animation
  Animation<double>? _currentAnimation; // Current animation
  Timer? _nextDebouncer; // Debouncer timer for next action

  StreamSubscription<PlaybackState>?
      _playbackSubscription; // Subscription for playback state

  VerticalDragInfo? verticalDragInfo; // Information about vertical drag gesture

  // Getter for the current story item
  StoryItem? get _currentStory {
    return widget.storyItems.firstWhereOrNull((it) => !it.shown);
  }

  // Getter for the current view of the story item
  Widget get _currentView {
    var item = widget.storyItems.firstWhereOrNull((it) => !it.shown);
    item ??= widget.storyItems.last; // If no unshown item, use the last item
    return item.view;
  }

  @override
  void initState() {
    super.initState();

    // Reset the shown status for all story items after the first unshown item
    final firstPage = widget.storyItems.firstWhereOrNull((it) => !it.shown);
    if (firstPage == null) {
      widget.storyItems.forEach((it2) {
        it2.shown = false;
      });
    } else {
      final lastShownPos = widget.storyItems.indexOf(firstPage);
      widget.storyItems.sublist(lastShownPos).forEach((it) {
        it.shown = false;
      });
    }

    // Listen to playback state changes
    this._playbackSubscription =
        widget.controller.playbackState.listen((playbackStatus) {
      switch (playbackStatus) {
        case PlaybackState.play:
          _removeNextHold();
          this._animationController?.forward(); // Play the animation
          break;

        case PlaybackState.pause:
          _holdNext(); // Pause the animation
          this._animationController?.stop(canceled: false);
          break;

        case PlaybackState.next:
          _removeNextHold();
          _goForward(); // Move to the next story
          break;

        case PlaybackState.previous:
          _removeNextHold();
          _goBack(); // Move to the previous story
          break;
      }
    });

    _play(); // Start playing the story
  }

  @override
  void dispose() {
    _clearDebouncer(); // Clear the debouncer timer

    _animationController?.dispose(); // Dispose the animation controller
    _playbackSubscription?.cancel(); // Cancel the playback subscription

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn); // Update the state only if the widget is mounted
    }
  }

  // Function to play the story
  void _play() {
    _animationController
        ?.dispose(); // Dispose the existing animation controller
    // Get the next story item to play
    final storyItem = widget.storyItems.firstWhere((it) {
      return !it.shown;
    });

    final storyItemIndex = widget.storyItems.indexOf(storyItem);

    if (widget.onStoryShow != null) {
      widget.onStoryShow!(
          storyItem, storyItemIndex); // Call the callback for showing the story
    }

    _animationController =
        AnimationController(duration: storyItem.duration, vsync: this);

    // Add listener for animation status changes
    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        storyItem.shown = true;
        if (widget.storyItems.last != storyItem) {
          _beginPlay(); // Play the next story item
        } else {
          _onComplete(); // Call the complete callback if all stories are shown
        }
      }
    });

    // Create the animation for the story item
    _currentAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_animationController!);

    widget.controller.play(); // Start playing the story item
  }

  // Function to begin playing the next story item
  void _beginPlay() {
    setState(() {});
    _play();
  }

  // Function to handle story completion
  void _onComplete() {
    if (widget.onComplete != null) {
      widget.controller.pause();
      widget.onComplete!(); // Call the complete callback
    }

    if (widget.repeat) {
      widget.storyItems.forEach((it) {
        it.shown = false; // Reset the shown status for repeating the story
      });

      _beginPlay();
    }
  }

  // Function to go back to the previous story item
  void _goBack() {
    _animationController!.stop();

    if (this._currentStory == null) {
      widget.storyItems.last.shown = false;
    }

    if (this._currentStory == widget.storyItems.first) {
      _beginPlay();
    } else {
      this._currentStory!.shown = false;
      int lastPos = widget.storyItems.indexOf(this._currentStory!);
      final previous = widget.storyItems[lastPos - 1];

      previous.shown = false;

      _beginPlay();
    }
  }

  // Function to go forward to the next story item
  void _goForward() {
    if (this._currentStory != widget.storyItems.last) {
      _animationController!.stop();

      // Get the last shown story item
      final _last = this._currentStory;

      if (_last != null) {
        _last.shown = true;
        if (_last != widget.storyItems.last) {
          _beginPlay();
        }
      }
    } else {
      // This is the last story item, complete the animation
      _animationController!
          .animateTo(1.0, duration: Duration(milliseconds: 10));
    }
  }

  // Function to clear the debouncer timer
  void _clearDebouncer() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  // Function to remove the next hold
  void _removeNextHold() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  // Function to hold the next action
  void _holdNext() {
    _nextDebouncer?.cancel();
    _nextDebouncer = Timer(Duration(milliseconds: 500), () {});
  }

  // Build method to render the widget tree
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Stack(
        children: <Widget>[
          _currentView, // Display the current story item view
          Visibility(
            visible: widget.progressPosition != ProgressPosition.none,
            child: Align(
              alignment: widget.progressPosition == ProgressPosition.top
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              child: SafeArea(
                bottom: widget.inline ? false : true,
                // We use SafeArea here for notched and bezel-less phones
                child: Container(
                  padding: widget.indicatorOuterPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page bar to show the progress of the story items
                      PageBar(
                        widget.storyItems
                            .map((it) => PageData(it.duration, it.shown))
                            .toList(),
                        this._currentAnimation,
                        key: UniqueKey(),
                        indicatorHeight: widget.indicatorHeight,
                        indicatorColor: widget.indicatorColor,
                        indicatorForegroundColor: widget.indicatorForegroundColor,
                      ),
                      if (widget.groupInfo != null) widget.groupInfo!,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
              alignment: Alignment.centerRight,
              heightFactor: 1,
              child: GestureDetector(
                onTapDown: (details) {
                  widget.controller.pause(); // Pause the story on tap down
                },
                onTapCancel: () {
                  widget.controller.play(); // Play the story on tap cancel
                },
                onTapUp: (details) {
                  // If debounce timed out, continue animation, else go to next story
                  if (_nextDebouncer?.isActive == false) {
                    widget.controller.play();
                  } else {
                    widget.controller.next();
                  }
                },
                onVerticalDragStart: (details) {
                  widget.controller
                      .pause(); // Pause the story on vertical drag start
                },
                onVerticalDragCancel: () {
                  widget.controller
                      .play(); // Play the story on vertical drag cancel
                },
                onVerticalDragUpdate: (details) {
                  if (verticalDragInfo == null) {
                    verticalDragInfo =
                        VerticalDragInfo(); // Initialize vertical drag info
                  }
      
                  verticalDragInfo!
                      .update(details.primaryDelta!); // Update drag info
                },
                onVerticalDragEnd: (details) {
                  widget.controller.play(); // Play the story on vertical drag end
                  // Finish up drag cycle
                  if (!verticalDragInfo!.cancel &&
                      widget.onVerticalSwipeComplete != null) {
                    widget.onVerticalSwipeComplete!(verticalDragInfo!
                        .direction!); // Call the vertical swipe callback
                  }
      
                  verticalDragInfo = null; // Reset drag info
                },
              )),
          Align(
            alignment: Alignment.centerLeft,
            heightFactor: 1,
            child: SizedBox(
                child: GestureDetector(onTap: () {
                  widget.controller.previous(); // Go to the previous story on tap
                }),
                width: 70),
          ),
        ],
      ),
    );
  }
}
