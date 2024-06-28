import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/enums/direction_enum.dart';
import 'package:story_view/enums/indicator_height_enum.dart';
import 'package:story_view/enums/playback_state_enum.dart';
import 'package:story_view/enums/progress_position_enum.dart';
import 'package:story_view/models/story_item_model.dart';
import 'package:story_view/widgets/story_progress_indicator.dart';

class StoryView extends StatefulWidget {
  final List<StoryItem> items;
  final StoryController controller;
  final VoidCallback? onComplete;
  final Function(Direction)? onVerticalSwipeComplete;
  final Function(StoryItem, int)? onStoryShow;
  final ProgressPosition progressPosition;
  final Color? indicatorColor;
  final Color? indicatorForegroundColor;
  final IndicatorHeight indicatorHeight;

  StoryView({
    required this.items,
    required this.controller,
    this.onComplete,
    this.onVerticalSwipeComplete,
    this.onStoryShow,
    this.progressPosition = ProgressPosition.top,
    this.indicatorColor,
    this.indicatorForegroundColor,
    this.indicatorHeight = IndicatorHeight.medium,
  });

  @override
  StoryViewState createState() => StoryViewState();
}

class StoryViewState extends State<StoryView> with TickerProviderStateMixin {
  List<StoryItem> storyItems = [];

  AnimationController? animationController;
  Animation<double>? currentAnimation;

  StreamSubscription<PlaybackState>? playbackSubscription;

  StoryItem? get currentStory => storyItems.firstWhereOrNull(
        (it) => !it.shown,
      );

  Widget get currentView =>
      storyItems.firstWhereOrNull((it) => !it.shown)?.view ??
      storyItems.last.view;

  @override
  void initState() {
    storyItems = widget.items;

    final initialPage = storyItems.firstWhereOrNull(
      (it) => !it.shown,
    );

    if (initialPage == null) {
      storyItems = widget.items.map((it) => it.copyWith(shown: false)).toList();
    }

    super.initState();

    widget.controller.play();

    playbackSubscription = widget.controller.playbackNotifier.listen(
      (playbackState) {
        if (playbackState == PlaybackState.play) {
          animationController?.forward();
        } else if (playbackState == PlaybackState.pause) {
          animationController?.stop(canceled: false);
        } else if (playbackState == PlaybackState.next) {
          goForward();
        } else if (playbackState == PlaybackState.previous) {
          goBack();
        }
      },
    );

    animationController = AnimationController(
      vsync: this,
      duration: currentStory?.duration ?? Duration(seconds: 5),
    );

    currentAnimation = Tween(begin: 0.0, end: 1.0).animate(animationController!)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (storyItems.lastIndexWhere((it) => !it.shown) ==
              storyItems.length - 1) {
            if (widget.onComplete != null) {
              widget.onComplete!();
            }

            animationController!.stop();
          } else {
            setState(() {
              storyItems[storyItems.indexOf(currentStory!)] =
                  currentStory!.copyWith(shown: true);
            });

            if (widget.onStoryShow != null) {
              widget.onStoryShow!(
                  currentStory!, storyItems.indexOf(currentStory!));
            }

            animationController!.duration =
                currentStory?.duration ?? Duration(seconds: 5);

            animationController!.forward(from: 0);
          }
        }
      });

    animationController!.forward();
  }

  @override
  void dispose() {
    animationController!.dispose();
    playbackSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTapDown: (details) {
            widget.controller.pause();
          },
          onTapCancel: () {
            widget.controller.play();
          },
          onTapUp: (details) {
            widget.controller.play();
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              goBack();
            } else if (details.primaryVelocity! < 0) {
              goForward();
            }
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              widget.onVerticalSwipeComplete?.call(Direction.down);
            } else if (details.primaryVelocity! < 0) {
              widget.onVerticalSwipeComplete?.call(Direction.up);
            }
          },
          child: currentView,
        ),
        widget.progressPosition == ProgressPosition.none
            ? const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(),
              )
            : SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: StoryProgressIndicator(
                    animationController: animationController!,
                    storyLength: storyItems.length,
                    shownStoryCount: storyItems.where((it) => it.shown).length,
                    indicatorColor: widget.indicatorColor,
                    indicatorForegroundColor: widget.indicatorForegroundColor,
                    indicatorHeight: widget.indicatorHeight,
                  ),
                ),
              ),
      ],
    );
  }

  void goForward() {
    if (storyItems.lastIndexWhere((it) => !it.shown) == storyItems.length - 1) {
      return;
    }

    setState(() {
      storyItems[storyItems.indexOf(currentStory!)] =
          currentStory!.copyWith(shown: true);
    });

    if (widget.onStoryShow != null) {
      widget.onStoryShow!(currentStory!, storyItems.indexOf(currentStory!));
    }

    animationController!.duration =
        currentStory?.duration ?? Duration(seconds: 5);

    animationController!.forward(from: 0);
  }

  void goBack() {
    if (storyItems.firstWhereOrNull((it) => it.shown) == null) {
      return;
    }

    final prevStoryIndex = storyItems.lastIndexWhere((it) => it.shown);

    setState(() {
      storyItems[prevStoryIndex] =
          storyItems[prevStoryIndex].copyWith(shown: false);
    });

    if (widget.onStoryShow != null) {
      widget.onStoryShow!(currentStory!, storyItems.indexOf(currentStory!));
    }

    animationController!.duration =
        currentStory?.duration ?? Duration(seconds: 5);

    animationController!.forward(from: 0);
  }
}
