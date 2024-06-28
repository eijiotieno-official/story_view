import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:story_view/enums/load_state_enum.dart';
import 'package:story_view/enums/playback_state_enum.dart';

import '../controller/story_controller.dart';

/// Utility to load image (gif, png, jpg, etc) media just once. Resource is
/// cached to disk with default configurations of [DefaultCacheManager].
class ImageLoader {
  ui.Codec? frames; // Holds the image frames (for animated images)

  final String url; // URL of the image to be loaded

  final Map<String, dynamic>? requestHeaders; // Optional HTTP request headers

  LoadState state = LoadState.loading; // Initial state is loading

  ImageLoader(this.url, {this.requestHeaders});

  /// Load image from disk cache first, if not found then load from network.
  /// `onComplete` is called when [imageBytes] become available.
  void loadImage(VoidCallback onComplete) {
    if (frames != null) {
      // If frames are already loaded, set state to success and call onComplete
      state = LoadState.success;
      onComplete();
      return;
    }

    // Fetch the file from the cache manager
    final fileStream = DefaultCacheManager()
        .getFileStream(url, headers: requestHeaders as Map<String, String>?);

    fileStream.listen(
      (fileResponse) {
        if (fileResponse is! FileInfo) return;

        // If frames are already loaded, do nothing
        if (frames != null) return;

        // Read image bytes
        final imageBytes = fileResponse.file.readAsBytesSync();
        state = LoadState.success;

        // Decode the image bytes
        ui.instantiateImageCodec(imageBytes).then((codec) {
          frames = codec;
          onComplete();
        }, onError: (error) {
          state = LoadState.failure;
          onComplete();
        });
      },
      onError: (error) {
        state = LoadState.failure;
        onComplete();
      },
    );
  }
}

/// Widget to display animated gifs or still images. Shows a loader while image
/// is being loaded. Listens to playback states from [controller] to pause and
/// forward animated media.
class StoryImage extends StatefulWidget {
  final ImageLoader imageLoader;
  final StoryController? controller;

  StoryImage(
    this.imageLoader, {
    Key? key,
    this.controller,
  }) : super(key: key ?? UniqueKey());

  /// Use this shorthand to fetch images/gifs from the provided [url]
  factory StoryImage.url(
    String url, {
    StoryController? controller,
    Key? key,
  }) {
    return StoryImage(
      ImageLoader(url),
      controller: controller,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() => StoryImageState();
}

class StoryImageState extends State<StoryImage> {
  ui.Image?
      currentFrame; // Holds the current frame of the image (for animated images)

  Timer? _timer; // Timer for handling frame updates

  StreamSubscription<PlaybackState>?
      _streamSubscription; // Subscription to playback state changes

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      // Listen to playback state changes
      _streamSubscription =
          widget.controller!.playbackState.listen((playbackState) {
        if (widget.imageLoader.frames == null) return;

        if (playbackState == PlaybackState.pause) {
          _timer?.cancel();
        } else {
          forward();
        }
      });
    }

    widget.controller?.pause();

    // Load the image
    widget.imageLoader.loadImage(() {
      if (mounted) {
        if (widget.imageLoader.state == LoadState.success) {
          widget.controller?.play();
          forward();
        } else {
          setState(() {}); // Refresh to show error
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  /// Advances to the next frame of the animated image
  void forward() async {
    _timer?.cancel();

    if (widget.controller != null &&
        widget.controller!.playbackState.first == PlaybackState.pause) {
      return;
    }

    final nextFrame = await widget.imageLoader.frames!.getNextFrame();

    currentFrame = nextFrame.image;

    if (nextFrame.duration > Duration(milliseconds: 0)) {
      _timer = Timer(nextFrame.duration, forward);
    }

    setState(() {});
  }

  /// Returns the appropriate widget based on the current load state
  Widget getContentView() {
    switch (widget.imageLoader.state) {
      case LoadState.success:
        return RawImage(
          image: currentFrame,
          fit: BoxFit.fitWidth,
        );
      case LoadState.failure:
        return Center(
          child: Text(
            "Image failed to load.",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        );
      default:
        return Center(
          child: Container(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: getContentView(),
    );
  }
}
