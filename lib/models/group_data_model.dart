import 'package:story_view/story_view.dart';

class GroupItem {
  final String key;
  final List<StoryItem> stories;
  GroupItem({
    required this.key,
    required this.stories,
  });
}
