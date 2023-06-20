import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../delegates/action_layout_delegate.dart';
import '../controllers/action_controller.dart';
import '../models.dart';
import 'slidable_render.dart';

/// if the action item is not wrapped in [ActionItem]
/// [flex] would default to 1 when the [ActionLayout.alignment] is [ActionAlignment.flex]
/// [flex] would have no effect when the [ActionLayout.alignment] is [ActionAlignment.spaceEvenly]
class SlideActionBoxData extends ContainerBoxParentData<RenderBox> {
  int? flex;
}

/// [RenderSlideAction] is used to render the action items of [SlideActionPanel]
/// all action items are sized according to the size of [SlidablePanel.child]
class RenderSlideAction extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, SlideActionBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, SlideActionBoxData> {
  RenderSlideAction({
    List<RenderBox>? children,
    required ActionLayout actionLayout,
    required ValueListenable<double> slidePercent,
    ActionController? controller,
  })  : _actionLayout = actionLayout,
        _slidePercent = slidePercent,
        _controller = controller {
    addAll(children);
  }

  /// if provided, users can invoke [ActionController.expand] ot [ActionController.collapse]
  /// to expand/collapse a specific action item by its index in the [SlideActionPanel.actions]
  ActionController? _controller;
  ActionController? get controller => _controller;
  set controller(ActionController? value) {
    if (_controller != value) {
      final old = _controller;
      _controller = value;

      if (attached) {
        old?.removeListener(_markNeedsLayoutIfNeeded);
        _controller?.addListener(_markNeedsLayoutIfNeeded);
      }
    }
  }

  /// the [slidePercent] is used to determine the position of the action items
  /// each update of [slidePercent] would trigger [performLayout] to layout and position the action items
  /// if this update is related to its [ActionPosition]
  ValueListenable<double> _slidePercent;
  ValueListenable<double> get slidePercent => _slidePercent;
  set slidePercent(ValueListenable<double> value) {
    if (_slidePercent != value) {
      final old = _slidePercent;
      _slidePercent = value;

      if (attached) {
        old.removeListener(_markNeedsLayoutIfCorrectPosition);
        value.addListener(_markNeedsLayoutIfCorrectPosition);
      }
    }
  }

  /// determines the layout of the action items,
  /// either [SpaceEvenlyLayoutDelegate] or [FlexLayoutDelegate]
  ActionLayout _actionLayout;
  ActionLayout get actionLayout => _actionLayout;
  set actionLayout(ActionLayout value) {
    if (_actionLayout != value) {
      _actionLayout = value;
      markNeedsLayout();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller?.addListener(_markNeedsLayoutIfNeeded);
    _slidePercent.addListener(_markNeedsLayoutIfCorrectPosition);
  }

  @override
  void detach() {
    _controller?.removeListener(_markNeedsLayoutIfNeeded);
    _slidePercent.removeListener(_markNeedsLayoutIfCorrectPosition);
    super.detach();
  }

  void _markNeedsLayoutIfNeeded() {
    if (_controller != null && _controller!.index != null) {
      markNeedsLayout();
    }
  }

  /// if the update of [slidePercent] is related to the [ActionPosition] of the action items
  void _markNeedsLayoutIfCorrectPosition() {
    final position = (parentData as SlidableBoxData).position;

    final shouldRelayout =
        position == ActionPosition.pre && slidePercent.value >= 0 ||
            position == ActionPosition.post && slidePercent.value <= 0;

    if (shouldRelayout) {
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! SlideActionBoxData) {
      child.parentData = SlideActionBoxData();
    }
  }

  /// by setting [sizedByParent] to true, the size of [RenderSlideAction] would be determined by its parent
  /// and the re-layout caused by [ActionController] would not propagate to its parent
  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.smallest;
  }

  // todo: report no valid action children
  /// if no child or the size of [RenderSlideAction] is empty, do nothing
  /// typically, if [RenderSlideAction] is not visible, its size would be empty
  /// only the visible [RenderSlideAction] would be laid out and painted
  /// the layout process is delegated to the [BaseActionLayoutDelegate] created from [ActionLayout]
  @override
  void performLayout() {
    final child = firstChild;
    final position = (parentData as SlidableBoxData).position!;

    if (child == null || size.isEmpty) {
      return;
    }

    final layoutDelegate = _actionLayout.buildDelegate(
      position,
      controller: controller,
    );

    layoutDelegate.layout(
      firstChild!,
      size,
      childCount,
      ratio: slidePercent.value.abs(),
      axis: _slideAxis,
    );
  }

  /// do not paint anything if the size of [RenderSlideAction] is empty
  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  Axis get _slideAxis => _slidableRender.axis;

  RenderSlidable get _slidableRender {
    RenderObject? parentNode = parent as RenderObject?;

    while (parentNode != null) {
      if (parentNode is RenderSlidable) {
        return parentNode;
      }

      parentNode = parentNode.parent as RenderObject?;
    }

    throw FlutterError(
        'RenderSlideAction must be a descendant of [RenderSlidable]');
  }
}
