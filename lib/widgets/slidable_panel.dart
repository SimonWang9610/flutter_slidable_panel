import 'package:flutter/widgets.dart';
import 'package:flutter_slidable_panel/flutter_slidable_panel.dart';

import '../renders/slidable_render.dart';
import 'slide_action_panel.dart';

class _SlidablePanel extends MultiChildRenderObjectWidget {
  final SlideController controller;
  final Axis axis;
  final double maxSlideThreshold;
  const _SlidablePanel({
    required this.controller,
    required super.children,
    required this.axis,
    required this.maxSlideThreshold,
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSlidable(
      controller: controller,
      axis: axis,
      maxSlideThreshold: maxSlideThreshold,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSlidable renderObject) {
    renderObject
      ..controller = controller
      ..axis = axis
      ..maxSlideThreshold = maxSlideThreshold;
  }
}

/// [SlidablePanel] is a widget that can slide to show actions
/// it can slide along [Axis.horizontal] or [Axis.vertical]
/// it can slide to show actions at [ActionPosition.pre] or [ActionPosition.post]
///
/// Use [SlideController] to control the sliding of [SlidablePanel]
///             pre
///     -------------------------
///     |                       |
/// pre |         child         | post
///     |                       |
///     -------------------------
///             post
///
/// See also:
///   * [SlideController]
///   * [SlideActionPanel]
///   * [ActionLayout]
class SlidablePanel extends StatelessWidget {
  /// [maxSlideThreshold] would be used to determine the max ratio of the panel that can slide, it should be in [0, 1]
  ///
  /// for example, if [child]'s size is Size(200, 100) along [Axis.horizontal],
  /// the max sliding distance would be 200 * [maxSlideThreshold] along [Axis.horizontal],
  /// and the max sliding distance would be converted to a tight [BoxConstraints] for layouting [SlideActionPanel]s
  final double maxSlideThreshold;

  /// [child] would be the main child of the panel
  /// its size would be used to layout the actions of [SlideActionPanel]s
  final Widget child;

  /// [axis] would be used to determine the direction of sliding
  final Axis axis;

  /// [controller] would be used to open/dismiss the panel,
  /// it can also be used to expand/collapse the actions of [SlideActionPanel]s
  final SlideController controller;

  /// describe how to layout the actions at [ActionPosition.pre].
  /// defaults to [ActionLayout] with [ActionAlignment.spaceEvenly] and [ActionMotion.behind]
  final ActionLayout preActionLayout;

  /// describe how to layout the actions at [ActionPosition.post].
  /// defaults to [ActionLayout] with [ActionAlignment.spaceEvenly] and [ActionMotion.behind]
  final ActionLayout postActionLayout;

  /// [preActions] would be used to show actions at [ActionPosition.pre].
  /// if not provided or empty, the panel would not be able to slide to show actions at [ActionPosition.pre],
  /// since no content could be shown
  final List<Widget>? preActions;

  /// [postActions] would be used to show actions at [ActionPosition.post].
  /// if not provided or empty, the panel would not be able to slide to show actions at [ActionPosition.post],
  /// since no content could be shown
  final List<Widget>? postActions;

  /// invoke when the panel starts to slide
  /// as long as there are some actions, [onSlideStart] would be invoked if provided
  /// by providing [onSlideStart], you can do some work when the panel starts to slide,
  /// e.g., dismiss other [SlidablePanel]s
  final VoidCallback? onSlideStart;

  /// [gestureDisabled] would be used to determine whether the panel should be able to slide using gestures
  /// if true, users can only slide the panel via [SlideController] programmatically;
  /// if false, users can slide the panel via gestures or [SlideController] programmatically;
  /// defaults to false
  final bool gestureDisabled;

  const SlidablePanel({
    super.key,
    required this.child,
    required this.controller,
    this.maxSlideThreshold = 0.6,
    this.axis = Axis.horizontal,
    this.preActionLayout = const ActionLayout(
      alignment: ActionAlignment.spaceEvenly,
      motion: ActionMotion.behind,
    ),
    this.postActionLayout = const ActionLayout(
      alignment: ActionAlignment.spaceEvenly,
      motion: ActionMotion.behind,
    ),
    this.preActions,
    this.postActions,
    this.onSlideStart,
    this.gestureDisabled = false,
  }) : assert(
          maxSlideThreshold >= 0 && maxSlideThreshold <= 1,
          'maxSlideThreshold should be in [0, 1]',
        );

  @override
  Widget build(BuildContext context) {
    final preActionPanel = preActions != null && preActions!.isNotEmpty
        ? SlideActionPanel(
            position: ActionPosition.pre,
            actionLayout: preActionLayout,
            actions: preActions!,
          )
        : null;

    final postActionPanel = postActions != null && postActions!.isNotEmpty
        ? SlideActionPanel(
            position: ActionPosition.post,
            actionLayout: postActionLayout,
            actions: postActions!,
          )
        : null;

    assert(() {
      if (controller.initOpenedPosition == null) {
        return true;
      } else if (preActionPanel != null &&
          controller.initOpenedPosition == ActionPosition.pre) {
        return true;
      } else if (postActionPanel != null &&
          controller.initOpenedPosition == ActionPosition.post) {
        return true;
      } else {
        return false;
      }
    }(),
        "Bad usage of SlidableController.initOpenedPosition, ensure there are actions at ${controller.initOpenedPosition}");

    final widget = GestureDetector(
      onHorizontalDragStart: axis == Axis.horizontal ? _onDragStart : null,
      onVerticalDragStart: axis == Axis.vertical ? _onDragStart : null,
      onHorizontalDragUpdate:
          axis == Axis.horizontal ? controller.onDragUpdate : null,
      onVerticalDragUpdate:
          axis == Axis.vertical ? controller.onDragUpdate : null,
      onHorizontalDragEnd:
          axis == Axis.horizontal ? controller.onDragEnd : null,
      onVerticalDragEnd: axis == Axis.vertical ? controller.onDragEnd : null,
      child: _SlidablePanel(
        key: key,
        controller: controller,
        axis: axis,
        maxSlideThreshold: maxSlideThreshold,
        children: [
          if (preActionPanel != null) preActionPanel,
          child,
          if (postActionPanel != null) postActionPanel,
        ],
      ),
    );

    return IgnorePointer(
      ignoring: gestureDisabled,
      child: widget,
    );
  }

  void _onDragStart(DragStartDetails details) {
    final hasActions = preActions != null && preActions!.isNotEmpty ||
        postActions != null && postActions!.isNotEmpty;

    if (hasActions) {
      onSlideStart?.call();
    }
  }
}
