import 'package:flutter/material.dart';
import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/utils.dart';
import 'package:story_view/widgets/story_image.dart';
import 'package:story_view/widgets/story_video.dart';

class StoryItem {
  final String id;
  final Duration duration;
  final bool shown;
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
    double contrast = ColorUtils.contrast([
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

  /// Factory constructor for page images. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.image({
    required String id,
    required String url,
    required StoryController controller,
    Key? key,
    Text? caption,
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
                  color: caption != null ? Colors.black54 : Colors.transparent,
                  child: caption ?? const SizedBox.shrink(),
                ),
              ),
            )
          ],
        ),
      ),
      shown: shown,
      duration: Duration(seconds: 8),
    );
  }

  /// Shorthand for creating page video. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.video({
    required String id,
    required String user,
    required DateTime time,
    required List<String> likes,
    required int views,
    required String url,
    required StoryController controller,
    Key? key,
    Duration? duration,
    BoxFit imageFit = BoxFit.fitWidth,
    Widget? caption,
    required bool shown,
    Map<String, dynamic>? requestHeaders,
    Widget? loadingWidget,
    Widget? errorWidget,
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
            StoryVideo.url(
              url,
              controller: controller,
              requestHeaders: requestHeaders,
              loadingWidget: loadingWidget,
              errorWidget: errorWidget,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 24),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  color: caption != null ? Colors.black54 : Colors.transparent,
                  child: caption ?? const SizedBox.shrink(),
                ),
              ),
            )
          ],
        ),
      ),
      shown: shown,
      duration: duration ?? Duration(seconds: 10),
    );
  }
}
