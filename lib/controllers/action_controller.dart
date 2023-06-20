import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';

/// use [ActionController] to control the animation of [SlideActionPanel] when the [SlidablePanel] is open
/// for example, you can use [ActionController] to expand the action item to occupy the entire [SlideActionPanel]
final class ActionController extends TickerProvider with ChangeNotifier {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
  );

  ActionController({
    int? index,
  }) : _index = index {
    _animationController.addListener(() {
      notifyListeners();
    });
  }

  int? _index;

  /// [index] would be the index of action items of [SlideActionPanel.actions]
  /// whatever the [ActionPosition] of [SlideActionPanel] is
  int? get index => _index;

  /// the current progress of the animation during expanding or collapsing
  /// it indicates the [index] item is expanding if the progress is increasing from 0 to 1
  /// it indicates the [index] item is collapsing if the progress is decreasing from 1 to 0
  double? get progress => _animationController.value;

  /// expand the [index] item to occupy the entire [SlideActionPanel]
  Future<void> expand(
    int index, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 150),
  }) async {
    if (_index != index) {
      _index = index;
      _animationController.reset();
      // await _animationController.animateTo(1, curve: curve, duration: duration);
      await _animationController.fling(velocity: 1);
    }
  }

  /// collapse the [index] item to the original position
  Future<void> collapse(
    int index, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 150),
  }) async {
    if (_index == index) {
      await _animationController.fling(velocity: -1);

      _index = null;
    }
  }

  /// toggle the [index] item between expanding and collapsing
  Future<void> toggle(
    int index, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 150),
  }) async {
    if (_index == index) {
      await collapse(index, curve: curve, duration: duration);
    } else {
      await expand(index, curve: curve, duration: duration);
    }
  }

  /// whether the [index] item is expanded
  bool hasExpandedAt(int index) => _index == index;

  /// reset the controller without triggering layout or paint
  void reset() {
    _index = null;
    _animationController.reset();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
