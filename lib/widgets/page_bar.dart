import 'package:collection/collection.dart'; // Importing collection package for using firstWhereOrNull
import 'package:flutter/material.dart'; // Importing Flutter material package
import 'package:story_view/story_view.dart';

/// Widget to display the progress indicators for the story pages.
class PageBar extends StatefulWidget {
  final List<PageData> pages; // List of story pages
  final Animation<double>? animation; // Animation to control progress
  final IndicatorHeight indicatorHeight; // Height of the progress indicators
  final Color? indicatorColor; // Color of the indicator background
  final Color? indicatorForegroundColor; // Color of the indicator foreground

  PageBar(
    this.pages,
    this.animation, {
    this.indicatorHeight = IndicatorHeight.medium,
    this.indicatorColor,
    this.indicatorForegroundColor,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => PageBarState();
}

class PageBarState extends State<PageBar> {
  double spacing = 4; // Spacing between the indicators

  @override
  void initState() {
    super.initState();

    // Adjust spacing based on the number of pages
    int count = widget.pages.length;
    spacing = (count > 15) ? 2 : ((count > 10) ? 3 : 4);

    // Listen to animation changes to refresh the UI
    widget.animation?.addListener(() {
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  /// Determines if a page is currently playing based on its shown status.
  bool isPlaying(PageData page) {
    return widget.pages.firstWhereOrNull((it) => !it.shown) == page;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.pages.map((it) {
        return Expanded(
          child: Container(
            padding:
                EdgeInsets.only(right: widget.pages.last == it ? 0 : spacing),
            child: StoryProgressIndicator(
              isPlaying(it) ? widget.animation!.value : (it.shown ? 1 : 0),
              indicatorHeight: widget.indicatorHeight == IndicatorHeight.large
                  ? 5
                  : widget.indicatorHeight == IndicatorHeight.medium
                      ? 3
                      : 2,
              indicatorColor: widget.indicatorColor,
              indicatorForegroundColor: widget.indicatorForegroundColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}
