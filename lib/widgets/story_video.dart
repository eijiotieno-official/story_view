import 'dart:async'; // For StreamSubscription
import 'dart:io'; // For File

import 'package:flutter/material.dart'; // For Flutter widgets
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // For caching video files
import 'package:story_view/story_view.dart';
import 'package:video_player/video_player.dart'; // For video playback

/// Class responsible for loading video from a given URL and managing its state.
class VideoLoader {
  final String url;
  File? videoFile;
  final Map<String, dynamic>? requestHeaders;
  LoadState state = LoadState.loading;

  VideoLoader(this.url, {this.requestHeaders});

  /// Loads the video and notifies the caller when complete.
  void loadVideo(VoidCallback onComplete) {
    if (videoFile != null) {
      state = LoadState.success;
      onComplete();
      return;
    }

    final fileStream = DefaultCacheManager().getFileStream(
      url,
      headers: requestHeaders as Map<String, String>?,
    );

    fileStream.listen((fileResponse) {
      if (fileResponse is FileInfo) {
        if (videoFile == null) {
          state = LoadState.success;
          videoFile = fileResponse.file;
          onComplete();
        }
      }
    });
  }
}

/// Widget for displaying a video as part of a story.
class StoryVideo extends StatefulWidget {
  final StoryController? storyController;
  final VideoLoader videoLoader;

  StoryVideo(this.videoLoader, {Key? key, this.storyController})
      : super(key: key ?? UniqueKey());

  /// Named constructor to create a StoryVideo from a URL.
  static StoryVideo url(
    String url, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    Key? key,
  }) {
    return StoryVideo(
      VideoLoader(url, requestHeaders: requestHeaders),
      storyController: controller,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() => StoryVideoState();
}

/// State class for StoryVideo widget.
class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;
  StreamSubscription? _streamSubscription;
  VideoPlayerController? playerController;

  @override
  void initState() {
    super.initState();
    widget.storyController?.pause(); // Pause the story initially
    widget.videoLoader.loadVideo(() {
      if (widget.videoLoader.state == LoadState.success) {
        playerController =
            VideoPlayerController.file(widget.videoLoader.videoFile!);
        playerController!.initialize().then((_) {
          widget.storyController
              ?.setDuration(playerController?.value.duration ?? Duration.zero);
          setState(() {}); // Refresh UI when video is ready
          widget.storyController?.play(); // Play the story once video is loaded
        });

        _streamSubscription =
            widget.storyController?.playbackState.listen((playbackState) {
          if (playbackState == PlaybackState.pause) {
            playerController?.pause();
          } else {
            playerController?.play();
          }
        });
      } else {
        setState(() {}); // Refresh UI on load failure
      }
    });
  }

  /// Builds the UI for the video player.
  Widget getContentView() {
    if (widget.videoLoader.state == LoadState.success &&
        playerController?.value.isInitialized == true) {
      return Center(
        child: AspectRatio(
          aspectRatio: playerController!.value.aspectRatio,
          child: VideoPlayer(playerController!),
        ),
      );
    }

    return widget.videoLoader.state == LoadState.loading
        ? Center(
            child: SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          )
        : Center(
            child: Text(
              "Media failed to load.",
              style: TextStyle(color: Colors.white),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: getContentView(),
    );
  }

  @override
  void dispose() {
    playerController?.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
