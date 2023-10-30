import 'package:flutter/widgets.dart';

enum SlideDirection {
  idle,
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

enum ActionPosition {
  pre,
  post,
}

enum ActionMotion {
  behind,
  stretch,
  drawer,
  scroll,
}

/// [spaceEvenly] layout is the default layout of [SlideActionPanel],
/// and all action items would be laid out evenly in the [SlideActionPanel]
/// [flex] layout is similar to the [spaceEvenly] layout, but the action items would be laid out according to their flex values
enum ActionAlignment {
  spaceEvenly,
  flex,
}

/// the layout result of [RenderSLidable]
/// [size] is the size of [SlidablePanel.child]
/// [hasPreAction] indicates whether there has [SlideActionPanel] at [ActionPosition.pre]
/// [hasPostAction] indicates whether there has [SlideActionPanel] at [ActionPosition.post]
class LayoutSize {
  final Size size;
  final bool hasPreAction;
  final bool hasPostAction;
  final Axis axis;
  final double maxSlideThreshold;

  const LayoutSize({
    required this.size,
    required this.hasPreAction,
    required this.hasPostAction,
    required this.axis,
    required this.maxSlideThreshold,
  });

  /// if no [SlideActionPanel], return null
  /// by doing so, we could disable sliding if no actions along the [axis]
  /// the ratio would be calculated: [dragExtent] / slidable space along the [axis]
  /// the slidable space is calculated by [maxSlideThreshold] * the space along the [axis]
  double? getRatio(
    double dragExtent,
  ) {
    if ((dragExtent > 0 && !hasPreAction) ||
        (dragExtent < 0 && !hasPostAction)) {
      return null;
    }

    final mainAxis = axis == Axis.horizontal
        ? size.width * maxSlideThreshold
        : size.height * maxSlideThreshold;
    final ratio = dragExtent / mainAxis;
    return ratio;
  }

  /// according to [direction], [ratio] and [isForward]
  /// calculate the target ratio when we should continue to slide after dragging ends
  double getToggleTarget(
      SlideDirection direction, double ratio, bool isForward) {
    if (ratio >= 0 && !hasPreAction) {
      return 0;
    } else if (ratio <= 0 && !hasPostAction) {
      return 0;
    }

    return switch (direction) {
      SlideDirection.leftToRight ||
      SlideDirection.topToBottom =>
        isForward ? 1 : 0,
      SlideDirection.bottomToTop ||
      SlideDirection.rightToLeft =>
        isForward ? -1 : 0,
      SlideDirection.idle => 0,
    };
  }

  /// calculate the final drag extent after animating ends
  /// so that the next dragging could start from the previous drag extent
  double getDragExtent(double ratio) {
    final mainAxis = axis == Axis.horizontal
        ? size.width * maxSlideThreshold
        : size.height * maxSlideThreshold;
    return mainAxis * ratio;
  }

  /// calculate the target ratio when we want to open the panel at [position]
  /// if there is no [SlideActionPanel] at [position], return null
  double? getOpenTarget(ActionPosition position) {
    if (position == ActionPosition.pre && !hasPreAction) {
      return null;
    } else if (position == ActionPosition.post && !hasPostAction) {
      return null;
    }

    return switch (position) {
      ActionPosition.pre => 1,
      ActionPosition.post => -1,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LayoutSize &&
        other.size == size &&
        other.hasPreAction == hasPreAction &&
        other.hasPostAction == hasPostAction &&
        other.axis == axis &&
        other.maxSlideThreshold == maxSlideThreshold;
  }

  @override
  int get hashCode {
    return size.hashCode ^
        hasPreAction.hashCode ^
        hasPostAction.hashCode ^
        axis.hashCode ^
        maxSlideThreshold.hashCode;
  }

  @override
  String toString() {
    return 'LayoutSize(size: $size, hasPreAction: $hasPreAction, hasPostAction: $hasPostAction, axis: $axis, maxSlideThreshold: $maxSlideThreshold)';
  }
}

/// [SizedConstraints] is used to calculate the constraints for the pre/post actions
/// [constraints]'s length should be the same as the number of actions at the corresponding [ActionPosition]
/// typically, it would be calculated by [BaseActionLayoutDelegate]
class SizedConstraints {
  final Size size;
  final List<BoxConstraints> constraints;
  final Axis axis;

  const SizedConstraints({
    required this.size,
    required this.constraints,
    required this.axis,
  });

  Offset getShiftFromConstraints(int index) {
    final shift = switch (axis) {
      Axis.horizontal => Offset(
          constraints[index].maxWidth,
          0,
        ),
      Axis.vertical => Offset(
          0,
          constraints[index].maxHeight,
        ),
    };

    return shift;
  }

  Offset get averageShift {
    final shift = switch (axis) {
      Axis.horizontal => Offset(size.width / constraints.length, 0),
      Axis.vertical => Offset(0, size.height / constraints.length),
    };

    return shift;
  }

  /// all [BoxConstraints] in [constraints] would be calculated according to the [size]
  Offset get totalShift {
    final shift = switch (axis) {
      Axis.horizontal => Offset(size.width, 0),
      Axis.vertical => Offset(0, size.height),
    };

    return shift;
  }
}
