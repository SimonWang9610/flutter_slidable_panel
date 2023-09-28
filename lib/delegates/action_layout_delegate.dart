import 'package:flutter/widgets.dart';

import '../renders/slide_action_render.dart' show SlideActionBoxData;
import '../controllers/action_controller.dart';
import '../models.dart';

/// [ActionLayoutDelegate] is a base class for laying out [SlideActionPanel]
/// [RenderSlideAction] would always create a new [ActionLayoutDelegate] from [ActionLayout],
/// and will invoke [layout] when doing [RenderSlideAction.performLayout]
abstract class ActionLayoutDelegate {
  final ActionPosition position;
  final ActionMotion motion;
  final ActionController? controller;
  ActionLayoutDelegate({
    required this.position,
    required this.motion,
    this.controller,
  });

  /// different [ActionLayoutDelegate] may return different [SizedConstraints] in [getSizedConstraints]
  /// so that each action item could be laid out using s specific [BoxConstraints]
  /// and each action item would be positioned at a specific offset calculated by [getRelativeOffset]
  void layout(
    RenderBox child,
    Size size,
    int childCount, {
    double ratio = 1.0,
    required Axis axis,
  }) {
    assert(childCount > 0);

    final sizedConstraints = getSizedConstraints(
      size: size,
      axis: axis,
      childCount: childCount,
    );

    RenderBox? current = child;

    int index = 0;

    while (current != null) {
      current.layout(sizedConstraints.constraints[index],
          parentUsesSize: false);

      final parentData = current.parentData as SlideActionBoxData;

      parentData.offset = getRelativeOffset(
        sizedConstraints: sizedConstraints,
        index: index,
        ratio: ratio,
      );
      current = parentData.nextSibling;
      index++;
    }
  }

  /// if no action item is expanded by [ActionController],
  /// [SpaceEvenlyLayoutDelegate] would give each action item the same [BoxConstraints]
  /// calculated by averaging the total space along the [axis];
  ///
  /// [FlexLayoutDelegate] would give each action item different [BoxConstraints] determined by their flex value.
  ///
  /// if one action item is expanded by [ActionController],
  /// other action items would eventually have an empty size, while the expanded action item would occupy the total space
  /// the remained space would be added into the expanded action item in [_fillRemainSpace] to ensure it occupies the total space
  SizedConstraints getSizedConstraints({
    required Size size,
    required Axis axis,
    required int childCount,
  });

  Offset _previousShift = Offset.zero;

  /// [index]'s offset would be relative to the previous [index]'s offset
  /// currently, each action item is laid out using a tight [BoxConstraints]
  /// so [SizedConstraints.getShiftFromConstraints] is used to get the size of the previous action item
  /// for [ActionMotion.stretch] and [ActionMotion.drawer], the previous action item's size is multiplied by [ratio],
  /// which is changed by the [SlideController.animationValue]
  /// for [ActionMotion.behind], action items' origin do not change during animation,
  /// for [ActionMotion.scroll], action items' origin are translated during animation
  ///
  ///! different [ActionPosition] would translate differently based on its [ActionMotion]
  /// e.g. the translation is same for [ActionPosition.pre]/[ActionMotion.scroll] and [ActionPosition.post]/[ActionMotion.behind]
  ///
  /// todo: to position action items based on its [ActionMotion] and [ActionPosition] when expanding
  Offset getRelativeOffset({
    required SizedConstraints sizedConstraints,
    required int index,
    required double ratio,
  }) {
    assert(ratio >= 0 && ratio <= 1);
    final shift = _previousShift;

    switch (motion) {
      case ActionMotion.stretch || ActionMotion.drawer:
        _previousShift +=
            sizedConstraints.getShiftFromConstraints(index) * ratio;
        break;
      case ActionMotion.behind || ActionMotion.scroll:
        _previousShift += sizedConstraints.getShiftFromConstraints(index);
        break;
    }

    final shouldChangeOrigin =
        (motion == ActionMotion.scroll && position == ActionPosition.pre) ||
            (motion == ActionMotion.behind && position == ActionPosition.post);

    return shift +
        (shouldChangeOrigin
            ? sizedConstraints.totalShift * (ratio - 1)
            : Offset.zero);
  }

  /// if [controller] is not null, the [controller]'s index would be expanded to occupy the total space of the [SlideActionPanel]
  /// the other action items would be compressed to empty during animation of the [controller]
  /// if [controller] is null, all action items would have the same ratio and be laid out normally
  /// based on the subclasses of [ActionLayoutDelegate]
  (double, double) get _itemControllerRatios {
    final unExpandedRatio = 1 - (controller?.progress ?? 0.0);
    final expandedRatio = 1 + (controller?.progress ?? 0.0);

    return (expandedRatio, unExpandedRatio);
  }

  /// if [controller] is not null, the [controller]'s index would be expanded to occupy the total space of the [SlideActionPanel]
  /// once the [controller] completes animation, other action items would have a empty size.
  /// therefore, we should add the remained space to the expanded action item to ensure it occupies the total space
  void _fillRemainSpace(
    List<BoxConstraints> constraints, {
    required Axis axis,
    double remainWidth = 0.0,
    double remainHeight = 0.0,
  }) {
    if (controller?.index != null) {
      final indexConstraints = constraints[controller!.index!];

      switch (axis) {
        case Axis.horizontal:
          constraints[controller!.index!] = BoxConstraints.tightFor(
            width: indexConstraints.maxWidth + remainWidth,
            height: indexConstraints.maxHeight,
          );
          break;
        case Axis.vertical:
          constraints[controller!.index!] = BoxConstraints.tightFor(
            width: indexConstraints.maxWidth,
            height: indexConstraints.maxHeight + remainHeight,
          );
          break;
      }
    }
  }
}

class _SpaceEvenlyLayoutDelegate extends ActionLayoutDelegate {
  _SpaceEvenlyLayoutDelegate({
    required super.motion,
    required super.position,
    super.controller,
  });

  @override
  SizedConstraints getSizedConstraints({
    required Size size,
    required Axis axis,
    required int childCount,
  }) {
    // assert(!size.isEmpty && childCount > 0);
    assert(childCount > 0);

    final averageWidth = size.width / childCount;
    final averageHeight = size.height / childCount;

    final (expandedRatio, unExpandedRatio) = _itemControllerRatios;

    final constraints = <BoxConstraints>[];

    double remainWidth = size.width;
    double remainHeight = size.height;

    for (int i = 0; i < childCount; i++) {
      final indexExpanded = controller?.index == i;

      switch (axis) {
        case Axis.horizontal:
          final width = indexExpanded
              ? averageWidth * expandedRatio
              : averageWidth * unExpandedRatio;
          final height = width != 0 ? size.height : 0.0;

          final indexConstraints = BoxConstraints.tightFor(
            width: width,
            height: height,
          );
          remainWidth -= indexConstraints.maxWidth;
          constraints.add(indexConstraints);
          break;
        case Axis.vertical:
          final height = indexExpanded
              ? averageHeight * expandedRatio
              : averageHeight * unExpandedRatio;

          final width = height != 0 ? size.width : 0.0;
          final indexConstraints = BoxConstraints.tightFor(
            width: width,
            height: height,
          );
          remainHeight -= indexConstraints.maxHeight;
          constraints.add(indexConstraints);
          break;
      }
    }

    _fillRemainSpace(
      constraints,
      axis: axis,
      remainWidth: remainWidth,
      remainHeight: remainHeight,
    );

    return SizedConstraints(
      size: size,
      axis: axis,
      constraints: constraints,
    );
  }
}

class _FlexLayoutDelegate extends ActionLayoutDelegate {
  final List<int> flexes = [];
  _FlexLayoutDelegate({
    required super.motion,
    required super.position,
    super.controller,
  });

  @override
  void layout(
    RenderBox child,
    Size size,
    int childCount, {
    double ratio = 1.0,
    required Axis axis,
  }) {
    assert(childCount > 0);

    flexes.clear();
    RenderBox? current = child;

    while (current != null) {
      final parentData = current.parentData as SlideActionBoxData;
      final flex = parentData.flex ?? 1;
      flexes.add(flex);
      current = parentData.nextSibling;
    }

    super.layout(
      child,
      size,
      childCount,
      ratio: ratio,
      axis: axis,
    );
  }

  @override
  SizedConstraints getSizedConstraints({
    required Size size,
    required Axis axis,
    required int childCount,
  }) {
    final totalFlex = flexes.reduce((a, b) => a + b);

    assert(childCount == flexes.length && totalFlex > 0,
        "At least one action widget should have a flex value greater than 0");

    final widthForEachFlex = size.width / totalFlex;
    final heightForEachFlex = size.height / totalFlex;

    final constraints = <BoxConstraints>[];
    final (expandedRatio, unExpandedRatio) = _itemControllerRatios;

    double remainWidth = size.width;
    double remainHeight = size.height;

    for (int i = 0; i < childCount; i++) {
      final flex = flexes[i];
      final indexExpanded = controller?.index == i;

      switch (axis) {
        case Axis.horizontal:
          final width = indexExpanded
              ? widthForEachFlex * flex * expandedRatio
              : widthForEachFlex * flex * unExpandedRatio;

          final height = width != 0 ? size.height : 0.0;
          final indexConstraints = BoxConstraints.tightFor(
            width: width,
            height: height,
          );
          remainWidth -= indexConstraints.maxWidth;
          constraints.add(indexConstraints);
          break;

        case Axis.vertical:
          final height = indexExpanded
              ? heightForEachFlex * flex * expandedRatio
              : heightForEachFlex * flex * unExpandedRatio;
          final width = height != 0 ? size.width : 0.0;
          final indexConstraints = BoxConstraints.tightFor(
            width: width,
            height: height,
          );
          remainHeight -= indexConstraints.maxHeight;
          constraints.add(indexConstraints);
          break;
      }
    }

    _fillRemainSpace(
      constraints,
      axis: axis,
      remainHeight: remainHeight,
      remainWidth: remainWidth,
    );

    return SizedConstraints(
      size: size,
      axis: axis,
      constraints: constraints,
    );
  }
}

/// describe how to layout action items in [RenderSlideAction]
/// [ActionLayout.spaceEvenly] would layout action items with equal space
/// [ActionLayout.flex] would layout action items according to their flex value
/// it would [buildDelegate] to create a [ActionLayoutDelegate] when [RenderSlideAction.performLayout] is invoked
class ActionLayout {
  final ActionMotion motion;

  /// when using [ActionLayout.flex], it would create a [FlexLayoutDelegate] to layout action items in [RenderSlideAction]
  /// otherwise, it would create a [SpaceEvenlyLayoutDelegate] to layout action items in [RenderSlideAction]
  final ActionAlignment alignment;

  const ActionLayout({
    required this.motion,
    required this.alignment,
  });

  ActionLayoutDelegate buildDelegate(
    ActionPosition position, {
    ActionController? controller,
  }) {
    switch (alignment) {
      case ActionAlignment.spaceEvenly:
        return _SpaceEvenlyLayoutDelegate(
          motion: motion,
          position: position,
          controller: controller,
        );
      case ActionAlignment.flex:
        return _FlexLayoutDelegate(
          motion: motion,
          position: position,
          controller: controller,
        );
    }
  }

  factory ActionLayout.spaceEvenly(
          [ActionMotion motion = ActionMotion.behind]) =>
      ActionLayout(
        motion: motion,
        alignment: ActionAlignment.spaceEvenly,
      );

  factory ActionLayout.flex([ActionMotion motion = ActionMotion.behind]) =>
      ActionLayout(
        motion: motion,
        alignment: ActionAlignment.flex,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionLayout &&
          runtimeType == other.runtimeType &&
          motion == other.motion &&
          alignment == other.alignment;

  @override
  int get hashCode => motion.hashCode ^ alignment.hashCode;

  @override
  String toString() {
    return 'ActionLayout{motion: $motion, alignment: $alignment}';
  }
}
