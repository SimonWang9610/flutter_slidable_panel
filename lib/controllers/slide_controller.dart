import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable_panel/flutter_slidable_panel.dart';

import 'action_controller.dart';

const double _lowerBound = -1;
const double _upperBound = 1;
const double _middleBound = 0;
const double _kSlideRatioTolerance = 0.15;

/// if you want to [expand]/[collapse] the actions at the pre- or post- position
/// you could set [usePreActionController] or [usePostActionController] to true
/// to enable controlling the actions at the pre- or post- position
///
/// if [usePreActionController] or [usePostActionController] is set to true,
/// the corresponding [ActionController] would be created and bound to [RenderSlideAction] automatically
///
/// invoking [expand]/[collapse]/[toggleAction] only takes effects for two cases:
/// 1) [usePreActionController] is true and the current [openedPosition] is [ActionPosition.pre]
/// 2) [usePostActionController] is true and the current [openedPosition] is [ActionPosition.post]
///
/// See also:
///   * [SlideActionPanel], the widget is used to configure [RenderSlideAction]
///   * [RenderSlideAction], the render object is used to render the actions at the specific position
class SlideController extends SlideAnimator
    with DragForSlide, PositionedActionControlMixin {
  /// the ratio of triggering the [SlideActionPanel] to the next position
  /// when users try to drag the [SlidablePanel]
  /// default to [_kSlideRatioTolerance]
  final double slideTolerance;

  /// whether to use [ActionController] for the pre-action panel
  /// default to false
  /// if set to true, [preActionController] would be created
  /// using [toggleAction], [expand] or [collapse] to control the actions at [ActionPosition.pre]
  final bool usePreActionController;

  /// whether to use [ActionController] for the post-action panel
  /// default to false
  /// if set to true, [postActionController] would be created
  /// using [toggleAction], [expand] or [collapse] to control the actions at [ActionPosition.post]
  final bool usePostActionController;

  SlideController({
    this.usePreActionController = false,
    this.usePostActionController = false,
    this.slideTolerance = _kSlideRatioTolerance,
  }) : assert(slideTolerance >= 0 && slideTolerance <= 1) {
    _animationController.addListener(() {
      notifyListeners();
    });

    if (usePreActionController) {
      _preActionController = ActionController();
    }

    if (usePostActionController) {
      _postActionController = ActionController();
    }
  }

  /// if [usePreActionController] is set to true, the [ActionController] would be created
  /// otherwise, it would be null
  ActionController? _preActionController;
  @override
  ActionController? get preActionController => _preActionController;

  /// if [usePostActionController] is set to true, the [ActionController] would be created
  /// otherwise, it would be null
  ActionController? _postActionController;
  @override
  ActionController? get postActionController => _postActionController;

  /// the current position of the [SlideActionPanel]
  /// it would be null if the [SlideActionPanel] is not opened
  /// it would be [ActionPosition.pre] if the current animation value is greater than 0
  /// it would be [ActionPosition.post] if the current animation value is less than 0
  @override
  ActionPosition? get openedPosition {
    return switch (ratio) {
      > 0 => ActionPosition.pre,
      < 0 => ActionPosition.post,
      _ => null,
    };
  }

  /// should toggle the [SlideActionPanel] when the drag distance is greater than [slideTolerance]
  /// if the [dragDiff] is less than or equal to [slideTolerance], the [SlideActionPanel] would be reset to the previous position
  /// if the [dragDiff] is greater than [slideTolerance], the [SlideActionPanel] would be toggled to the next position
  @override
  bool _shouldToggle(double dragDiff) {
    return dragDiff.abs() > slideTolerance;
  }

  /// open the [SlidablePanel] to the [position]
  /// it will make the actions of [SlideActionPanel] visible at the [position]
  /// [onOpened] would be called when the [SlideActionPanel] at [position] is opened if provided
  ///
  /// if there are no actions to show at [position], it would have no effect
  /// if the [position] has been visible/opened, it would have no effect
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

  /// indicates if the panel is closed/dismissed
  bool get dismissed => ratio == _middleBound;

  /// close the [SlidablePanel]
  /// it will make all [SlideActionPanel] invisible
  /// it will have no effect if the [SlidablePanel] is already dismissed/closed
  /// [onDismissed] would be called when the [SlidablePanel] is actually dismissed by this operations
  Future<void> dismiss({
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
    VoidCallback? onDismissed,
  }) async {
    if (!dismissed) {
      await _animationController.animateTo(
        _middleBound,
        curve: curve,
        duration: duration,
      );
      _resetDrag();
      _postActionController?.reset();
      _preActionController?.reset();
      onDismissed?.call();
    }
  }

  @override
  void dispose() {
    _preActionController?.dispose();
    _postActionController?.dispose();
    super.dispose();
  }
}

class SlideAnimator extends TickerProvider with ChangeNotifier {
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

mixin DragForSlide on SlideAnimator {
  LayoutSize? _layoutSize;

  /// the layout result of [RenderSlidable] for all actions
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
  /// if [ratio] is 0, it will be [SlideDirection.idle], indicating not sliding (this panel is closed)
  ///
  /// if [ratio] > 0, it will be [SlideDirection.leftToRight] or [SlideDirection.topToBottom]
  /// indicating sliding to see the pre actions (this panel is opened and at [ActionPosition.pre])
  ///
  /// if [ratio] < 0, it will be [SlideDirection.rightToLeft] or [SlideDirection.bottomToTop]
  /// indicating sliding to see the post actions (this panel is opened and at [ActionPosition.post])
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

  bool _shouldToggle(double dragDiff) => true;

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

  /// if [_shouldToggle] returns true, it will try to open or dismiss the [SlidablePanel] continually
  /// otherwise, it will reset the [SlidablePanel] to the previous position
  void onDragEnd(DragEndDetails details) async {
    assert(layoutSize != null);

    final target = layoutSize!.getToggleTarget(direction, ratio, _forwarding);

    final draggedRatio = _forwarding ? absoluteRatio : 1 - absoluteRatio;
    final needToggle = _shouldToggle(draggedRatio);

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
