import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';

import 'package:story_view/enums/direction_enum.dart';
import 'package:story_view/enums/indicator_height_enum.dart';
import 'package:story_view/enums/playback_state_enum.dart';
import 'package:story_view/enums/progress_position_enum.dart';
import 'package:story_view/models/page_data_model.dart';
import 'package:story_view/models/story_item_model.dart';

import '../controller/story_controller.dart';
import '../utils.dart';
import 'page_bar.dart';

class StoryView extends StatefulWidget {
  /// The pages to displayed.
  final List<StoryItem> storyItems;

  /// Callback for when a full cycle of story is shown. This will be called
  /// each time the full story completes when [repeat] is set to `true`.
  final VoidCallback? onComplete;

  /// Callback for when a vertical swipe gesture is detected. If you do not
  /// want to listen to such event, do not provide it. For instance,
  /// for inline stories inside ListViews, it is preferrable to not to
  /// provide this callback so as to enable scroll events on the list view.
  final Function(Direction)? onVerticalSwipeComplete;

  /// Callback for when a story and it index is currently being shown.
  final void Function(StoryItem storyItem, int index)? onStoryShow;

  /// Where the progress indicator should be placed.
  final ProgressPosition progressPosition;

  /// Should the story be repeated forever?
  final bool repeat;

  /// If you would like to display the story as full-page, then set this to
  /// `false`. But in case you would display this as part of a page (eg. in
  /// a [ListView] or [Column]) then set this to `true`.
  final bool inline;

  /// Controls the playback of the stories
  final StoryController controller;

  /// Indicator Color
  final Color? indicatorColor;

  /// Indicator Foreground Color
  final Color? indicatorForegroundColor;

  /// Determine the height of the indicator
  final IndicatorHeight indicatorHeight;

  /// Use this if you want to give outer padding to the indicator
  final EdgeInsetsGeometry indicatorOuterPadding;

  final Widget? groupInfo;

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
    return StoryViewState();
  }
}

class StoryViewState extends State<StoryView> with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _currentAnimation;
  Timer? _nextDebouncer;

  StreamSubscription<PlaybackState>? _playbackSubscription;

  VerticalDragInfo? verticalDragInfo;

  StoryItem? get _currentStory {
    return widget.storyItems.firstWhereOrNull((it) => !it.shown);
  }

  Widget get _currentView {
    var item = widget.storyItems.firstWhereOrNull((it) => !it.shown);
    item ??= widget.storyItems.last;
    return item.view;
  }

  @override
  void initState() {
    super.initState();

    // All pages after the first unshown page should have their shown value as
    // false
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

    this._playbackSubscription =
        widget.controller.playbackNotifier.listen((playbackStatus) {
      switch (playbackStatus) {
        case PlaybackState.play:
          _removeNextHold();
          this._animationController?.forward();
          break;

        case PlaybackState.pause:
          _holdNext(); // then pause animation
          this._animationController?.stop(canceled: false);
          break;

        case PlaybackState.next:
          _removeNextHold();
          _goForward();
          break;

        case PlaybackState.previous:
          _removeNextHold();
          _goBack();
          break;
      }
    });

    _play();
  }

  @override
  void dispose() {
    _clearDebouncer();

    _animationController?.dispose();
    _playbackSubscription?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _play() {
    _animationController?.dispose();
    // get the next playing page
    final storyItem = widget.storyItems.firstWhere((it) {
      return !it.shown;
    });

    final storyItemIndex = widget.storyItems.indexOf(storyItem);

    if (widget.onStoryShow != null) {
      widget.onStoryShow!(storyItem, storyItemIndex);
    }

    _animationController =
        AnimationController(duration: storyItem.duration, vsync: this);

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        storyItem.shown = true;
        if (widget.storyItems.last != storyItem) {
          _beginPlay();
        } else {
          // done playing
          _onComplete();
        }
      }
    });

    _currentAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_animationController!);

    widget.controller.play();
  }

  void _beginPlay() {
    setState(() {});
    _play();
  }

  void _onComplete() {
    if (widget.onComplete != null) {
      widget.controller.pause();
      widget.onComplete!();
    }

    if (widget.repeat) {
      widget.storyItems.forEach((it) {
        it.shown = false;
      });

      _beginPlay();
    }
  }

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

  void _goForward() {
    if (this._currentStory != widget.storyItems.last) {
      _animationController!.stop();

      // get last showing
      final _last = this._currentStory;

      if (_last != null) {
        _last.shown = true;
        if (_last != widget.storyItems.last) {
          _beginPlay();
        }
      }
    } else {
      // this is the last page, progress animation should skip to end
      _animationController!
          .animateTo(1.0, duration: Duration(milliseconds: 10));
    }
  }

  void _clearDebouncer() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _removeNextHold() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _holdNext() {
    _nextDebouncer?.cancel();
    _nextDebouncer = Timer(Duration(milliseconds: 500), () {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _currentView,
        Visibility(
          visible: widget.progressPosition != ProgressPosition.none,
          child: Align(
            alignment: widget.progressPosition == ProgressPosition.top
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            child: SafeArea(
              bottom: widget.inline ? false : true,
              // we use SafeArea here for notched and bezeles phones
              child: Container(
                padding: widget.indicatorOuterPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                widget.controller.pause();
              },
              onTapCancel: () {
                widget.controller.play();
              },
              onTapUp: (details) {
                // if debounce timed out (not active) then continue anim
                if (_nextDebouncer?.isActive == false) {
                  widget.controller.play();
                } else {
                  widget.controller.next();
                }
              },
              onVerticalDragStart: (details) {
                widget.controller.pause();
              },
              onVerticalDragCancel: () {
                widget.controller.play();
              },
              onVerticalDragUpdate: (details) {
                if (verticalDragInfo == null) {
                  verticalDragInfo = VerticalDragInfo();
                }

                verticalDragInfo!.update(details.primaryDelta!);
              },
              onVerticalDragEnd: (details) {
                widget.controller.play();
                // finish up drag cycle
                if (!verticalDragInfo!.cancel &&
                    widget.onVerticalSwipeComplete != null) {
                  widget.onVerticalSwipeComplete!(verticalDragInfo!.direction!);
                }

                verticalDragInfo = null;
              },
            )),
        Align(
          alignment: Alignment.centerLeft,
          heightFactor: 1,
          child: SizedBox(
              child: GestureDetector(onTap: () {
                widget.controller.previous();
              }),
              width: 70),
        ),
      ],
    );
  }
}
