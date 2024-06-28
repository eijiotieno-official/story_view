import 'package:flutter/material.dart';

import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/utils.dart';
import 'package:story_view/widgets/story_image.dart';
import 'package:story_view/widgets/story_video.dart';

class StoryItem {
  final String id;
  final Duration duration;
  bool shown;
  final Widget view;

  StoryItem({
    required this.id,
    required this.duration,
    required this.shown,
    required this.view,
  });

  static StoryItem text({
    required String id,
    required String text,
    required Color backgroundColor,
    required bool shown,
    Key? key,
  }) {
    double contrast = ContrastHelper.contrast([
      backgroundColor.red,
      backgroundColor.green,
      backgroundColor.blue,
    ], [
      255,
      255,
      255
    ] /** white text */);

    return StoryItem(
      id: id,
      view: Container(
        key: key,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor.withOpacity(0.35),
              backgroundColor,
            ],
          ),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: contrast > 1.8 ? Colors.white : Colors.black,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      shown: shown,
      duration: Duration(seconds: 8),
    );
  }

  factory StoryItem.image({
    required String id,
    required String url,
    required StoryController controller,
    Key? key,
    String? caption,
    required bool shown,
  }) {
    return StoryItem(
      id: id,
      view: Container(
        key: key,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Stack(
          children: <Widget>[
            StoryImage.url(url, controller: controller),
            if (caption != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      bottom: 24,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    color: Colors.black54,
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      shown: shown,
      duration: Duration(seconds: 8),
    );
  }

  factory StoryItem.video({
    required String id,
    required String url,
    required StoryController controller,
    Key? key,
    required Duration duration,
    String? caption,
    required bool shown,
  }) {
    return StoryItem(
      id: id,
      view: Container(
        key: key,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Stack(
          children: <Widget>[
            StoryVideo.url(url, controller: controller),
            if (caption != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      bottom: 24,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    color: Colors.black54,
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      shown: shown,
      duration: duration,
    );
  }

  StoryItem copyWith({
    String? id,
    Duration? duration,
    bool? shown,
    Widget? view,
  }) {
    return StoryItem(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      shown: shown ?? this.shown,
      view: view ?? this.view,
    );
  }

  @override
  String toString() {
    return 'StoryItem(id: $id, duration: $duration, shown: $shown, view: $view)';
  }
}
