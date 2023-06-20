import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '../models.dart';

const double _lowerBound = -1;
const double _upperBound = 1;
const double _middleBound = 0;
const double _kSlideRatioTolerance = 0.15;

class SlideController extends _SlideAnimator with DragForSlide {
  /// the ratio of triggering the [SlideActionPanel] to the next position
  /// when users try to drag the [SlidablePanel]
  /// default to [_kSlideRatioTolerance]
  final double slideTolerance;

  SlideController({
    this.slideTolerance = _kSlideRatioTolerance,
  }) : assert(slideTolerance >= 0 && slideTolerance <= 1) {
    _animationController.addListener(() {
      notifyListeners();
    });
  }

  /// should toggle the [SlideActionPanel] when the drag distance is greater than [slideTolerance]
  /// if the [dragDiff] is less than or equal to [slideTolerance], the [SlideActionPanel] would be reset to the previous position
  /// if the [dragDiff] is greater than [slideTolerance], the [SlideActionPanel] would be toggled to the next position
  @override
  bool shouldToggle(double dragDiff) {
    return dragDiff.abs() > slideTolerance;
  }

  /// open the [SlidablePanel] to the [position]
  /// it will make the [SlideActionPanel] at the [position] visible
  /// [onOpened] would be called when the [SlideActionPanel] at [position] is opened if provided
  Future<void> open({
    ActionPosition position = ActionPosition.pre,
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
    VoidCallback? onOpened,
  }) async {
    final target = layoutSize!.getOpenTarget(position);

    if (target != null && ratio != target) {
      await _animationController.animateTo(
        target,
        curve: curve,
        duration: duration,
      );
      _resetDrag();

      final shouldInvoke =
          (position == ActionPosition.pre && ratio == _lowerBound) ||
              (position == ActionPosition.post && ratio == _upperBound);

      if (shouldInvoke) {
        onOpened?.call();
      }
    }
  }

  /// close the [SlidablePanel]
  /// it will make all [SlideActionPanel] invisible
  /// it will have no effect if the [SlidablePanel] is already dismissed
  /// [onDismissed] would be called when the [SlidablePanel] is dismissed if provided
  Future<void> dismiss({
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
    VoidCallback? onDismissed,
  }) async {
    if (ratio != _middleBound) {
      await _animationController.animateTo(
        _middleBound,
        curve: curve,
        duration: duration,
      );
      _resetDrag();
    }
    onDismissed?.call();
  }
}

class _SlideAnimator extends TickerProvider with ChangeNotifier {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    lowerBound: _lowerBound,
    upperBound: _upperBound,
  )..value = _middleBound;

  set _animationValue(double value) {
    _animationController.value = value;
  }

  Animation<double> get slidePercent => _animationController;

  /// represents the current sliding ratio relative to the size of the [SlidePanel]
  /// if [ratio] > 0  indicates we are sliding to see the pre actions
  /// if [ratio] < 0  indicates we are sliding to see the post actions
  /// if [ratio] == 0 indicates we are not sliding, all actions are hidden, only the main child is visible
  double get ratio => _animationController.value;
  double get absoluteRatio => ratio.abs();

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

mixin DragForSlide on _SlideAnimator {
  LayoutSize? _layoutSize;
  LayoutSize? get layoutSize => _layoutSize;

  /// the layout result of [RenderSlidable]
  /// it will be set instantly after [RenderSlidable.performLayout]
  /// users must not set it manually
  set layoutSize(LayoutSize? layoutSize) {
    if (_layoutSize != layoutSize) {
      _layoutSize = layoutSize;
    }
  }

  /// the direction of the sliding
  /// if [ratio] is 0, it will be [SlideDirection.idle], indicating not sliding
  ///
  /// if [ratio] > 0, it will be [SlideDirection.leftToRight] or [SlideDirection.topToBottom]
  /// indicating sliding to see the pre actions
  ///
  /// if [ratio] < 0, it will be [SlideDirection.rightToLeft] or [SlideDirection.bottomToTop]
  /// indicating sliding to see the post actions
  SlideDirection get direction {
    assert(layoutSize != null);

    if (ratio == 0) {
      return SlideDirection.idle;
    }

    if (ratio > 0) {
      return switch (layoutSize!.axis) {
        Axis.horizontal => SlideDirection.leftToRight,
        Axis.vertical => SlideDirection.topToBottom,
      };
    } else {
      return switch (layoutSize!.axis) {
        Axis.horizontal => SlideDirection.rightToLeft,
        Axis.vertical => SlideDirection.bottomToTop,
      };
    }
  }

  double _dragExtent = 0;
  bool _forwarding = false;

  void _resetDrag() {
    _dragExtent = layoutSize?.getDragExtent(ratio) ?? 0;
    _forwarding = false;
  }

  bool shouldToggle(double dragDiff) => true;

  /// when dragging the [SlidablePanel], this method will be called
  /// each update of the [ratio] would trigger the [RenderSlidable] to re-layout
  void onDragUpdate(DragUpdateDetails details) {
    assert(layoutSize != null);
    final shift = switch (layoutSize!.axis) {
      Axis.horizontal => details.delta.dx,
      Axis.vertical => details.delta.dy,
    };
    _forwarding = _dragExtent * shift > 0;
    _dragExtent += shift;

    final newRatio = layoutSize!
        .getRatio(_dragExtent)
        ?.clamp(_lowerBound, _upperBound)
        .toDouble();

    if (newRatio != null && newRatio != ratio) {
      _animationValue = newRatio;
    }
  }

  /// if [shouldToggle] returns true, it will try to open or dismiss the [SlidablePanel]
  /// otherwise, it will reset the [SlidablePanel] to the previous position
  void onDragEnd(DragEndDetails details) async {
    assert(layoutSize != null);

    final target = layoutSize!.getToggleTarget(direction, ratio, _forwarding);

    final draggedRatio = _forwarding ? absoluteRatio : 1 - absoluteRatio;
    final needToggle = shouldToggle(draggedRatio);

    if (ratio != target && needToggle) {
      await _animationController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
      );
    } else if (!needToggle) {
      final target =
          _forwarding ? _middleBound : (ratio > 0 ? _upperBound : _lowerBound);

      await _animationController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
      );
    }

    _resetDrag();
  }
}
