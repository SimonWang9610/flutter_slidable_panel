import 'package:flutter/widgets.dart';

import '../renders/slide_action_render.dart';
import '../renders/slidable_render.dart';
import '../delegates/action_layout_delegate.dart';
import '../models.dart';

/// By wrapping [child] using [ActionItem], you can specify the flex value of the child.
/// it would have no effect if [ActionLayout.alignment] is [ActionAlignment.spaceEvenly].
class ActionItem extends ParentDataWidget<SlideActionBoxData> {
  final int flex;
  const ActionItem({
    super.key,
    required this.flex,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is SlideActionBoxData);
    final parentData = renderObject.parentData as SlideActionBoxData;

    if (parentData.flex != flex) {
      parentData.flex = flex;

      final targetParent = renderObject.parent as RenderObject;
      targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => SlideActionPanel;
}

/// if [actionLayout] is aligned using [ActionAlignment.flex], [actions] could be wrapped in [ActionItem] to specify its flex value.
/// if some of [actions] are not wrapped in [ActionItem], each of them would have a default flex value of 1
///
/// if [actionLayout] is aligned using [ActionAlignment.spaceEvenly],
/// each action item would have the same [BoxConstraints] determined by the size of [SlidablePanel.child].
///
/// [controller] would be used to expand/collapse a specific action item.
/// the expanded item would occupy the total space of [SlideActionPanel],
/// while other items would eventually be invisible and not respond to pointer events.
///
/// if [actions] is empty, the [SlidablePanel] can still slide but no widget would be shown.
/// if you do not want to slide the [SlidablePanel] at a specific [ActionPosition],
/// just not passing [SlideActionPanel] at the corresponding [ActionPosition] in [SlidablePanel]
///
/// [slidePercent] should be from [SlideController.slidePercent]
class SlideActionPanel<T extends Widget> extends MultiChildRenderObjectWidget {
  final ActionLayout actionLayout;
  final List<T> actions;
  final ActionPosition position;

  const SlideActionPanel({
    Key? key,
    required this.actionLayout,
    required this.actions,
    required this.position,
  }) : super(
          key: key,
          children: actions,
        );

  /// although this [RenderSlideAction] has not been attached to [RenderSlidable] during [createRenderObject],
  /// its [Element] has been mounted to the element tree.
  /// Therefore, we can use [BuildContext.findAncestorRenderObjectOfType] to get the [RenderSlidable]
  @override
  RenderSlideAction createRenderObject(BuildContext context) {
    final slidableRender = of(context);

    final controller = position == ActionPosition.pre
        ? slidableRender.preActionController
        : slidableRender.postActionController;

    return RenderSlideAction(
      actionLayout: actionLayout,
      slidePercent: slidableRender.slidePercent,
      controller: controller,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSlideAction renderObject) {
    final slidableRender = of(context);
    final controller = position == ActionPosition.pre
        ? slidableRender.preActionController
        : slidableRender.postActionController;

    renderObject
      ..actionLayout = actionLayout
      ..slidePercent = slidableRender.slidePercent
      ..controller = controller;
  }

  static RenderSlidable of(BuildContext context) {
    final slidableRender =
        context.findAncestorRenderObjectOfType<RenderSlidable>();

    assert(
      slidableRender != null,
      'RenderSlideAction must be a descendant of RenderSlidable.'
      'Typically, it means [SlideActionPanel] must be a descendant of [SlidablePanel].',
    );

    return slidableRender!;
  }
}
