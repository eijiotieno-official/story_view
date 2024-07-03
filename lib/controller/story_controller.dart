import 'package:rxdart/rxdart.dart';
import 'package:story_view/enums/playback_state_enum.dart';

/// A controller class to manage the playback state of stories.
class StoryController {
  Duration _duration = Duration.zero;

  Duration get duration => _duration;

  void setDuration(Duration newDuration) {
    _duration = newDuration;
  }

  /// A stream that broadcasts the playback state of the stories.
  /// Using BehaviorSubject to provide the last emitted value to new subscribers.
  final _playbackNotifier = BehaviorSubject<PlaybackState>();

  /// Expose the playback state stream.
  Stream<PlaybackState> get playbackState => _playbackNotifier.stream;

  /// Pauses the story playback by adding a [PlaybackState.pause] state to the stream.
  void pause() {
    _playbackNotifier.add(PlaybackState.pause);
  }

  /// Resumes the story playback by adding a [PlaybackState.play] state to the stream.
  void play() {
    _playbackNotifier.add(PlaybackState.play);
  }

  /// Moves to the next story by adding a [PlaybackState.next] state to the stream.
  void next() {
    _playbackNotifier.add(PlaybackState.next);
  }

  /// Moves to the previous story by adding a [PlaybackState.previous] state to the stream.
  void previous() {
    _playbackNotifier.add(PlaybackState.previous);
  }

  /// Disposes of the controller by closing the [BehaviorSubject] stream.
  /// This is important to prevent memory leaks.
  void dispose() {
    _playbackNotifier.close();
  }
}
