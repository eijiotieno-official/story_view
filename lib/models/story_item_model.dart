import 'package:flutter/material.dart';

import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/utils.dart';
import 'package:story_view/widgets/story_image.dart';
import 'package:story_view/widgets/story_video.dart';

// Represents an item in a story feed, could be text, image, or video
class StoryItem {
  final String id; // Unique identifier for the story item
  final Duration duration; // Duration for which the item should be displayed
  bool shown; // Indicates if the item has been shown

  // Widget representing the visual content of the story item
  final Widget view;

  // Constructor for text-based story item
  StoryItem({
    required this.id,
    required this.duration,
    required this.shown,
    required this.view,
  });

  // Factory constructor for creating a text-based story item
  static StoryItem text({
    required String id,
    required String text,
    required Color backgroundColor,
    required bool shown,
    Key? key,
  }) {
    // Determine text color based on background contrast
    double contrast = ContrastHelper.contrast([
      backgroundColor.red,
      backgroundColor.green,
      backgroundColor.blue,
    ], [
      255,
      255,
      255
    ] /** white text */);

    // Return a StoryItem configured with a text view
    return StoryItem(
      id: id,
      view: Container(
        key: key,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor.withOpacity(0.5),
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

  // Factory constructor for creating an image-based story item
  factory StoryItem.image({
    required String id,
    required String url,
    required StoryController controller,
    Key? key,
    String? caption,
    required bool shown,
  }) {
    // Return a StoryItem configured with an image view
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
            // Display the image using StoryImage widget
            StoryImage.url(url, controller: controller),
            // Optionally display a caption at the bottom
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

  // Factory constructor for creating a video-based story item
  factory StoryItem.video({
    required String id,
    required String url,
    required StoryController controller,
    Key? key,
    required Duration duration,
    String? caption,
    required bool shown,
  }) {
    // Return a StoryItem configured with a video view
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
            // Display the video using StoryVideo widget
            StoryVideo.url(url, controller: controller),
            // Optionally display a caption at the bottom
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

  // Allows creating a copy of this instance with optionally modified properties
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

  // String representation of the StoryItem for debugging purposes
  @override
  String toString() {
    return 'StoryItem(id: $id, duration: $duration, shown: $shown, view: $view)';
  }
}
