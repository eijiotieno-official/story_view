import 'story_item_model.dart';

class GroupData {
  final String key;
  final List<StoryItem> stories;
  GroupData({
    required this.key,
    required this.stories,
  });
}
