<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

A Slidable Panel that can show actions in different positions. Also can expand the action item when the panel is opening

## Features

### All action widgets can be expanded when the `SlidablePanel` is opening.

<div> 
    <img src="https://github.com/SimonWang9610/flutter_slidable_panel/blob/main/images/list_example.gif?raw=true" width="320">
</div>

### Different Motions

- `ActionMotion.drawer`
<div> 
    <img src="https://github.com/SimonWang9610/flutter_slidable_panel/blob/main/images/drawer_motion.gif?raw=true" width="320">
</div>

- `ActionMotion.scroll`
<div> 
    <img src="https://github.com/SimonWang9610/flutter_slidable_panel/blob/main/images/scroll_motion.gif?raw=true" width="320">
</div>

- `ActionMotion.behind`
<div> 
    <img src="https://github.com/SimonWang9610/flutter_slidable_panel/blob/main/images/behind_motion.gif?raw=true" width="320">
</div>

## Getting started

```dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable_panel/flutter_slidable_panel.dart';

class SizedSlidableExample extends StatefulWidget {
  const SizedSlidableExample({super.key});

  @override
  State<SizedSlidableExample> createState() => _SizedSlidableExampleState();
}

class _SizedSlidableExampleState extends State<SizedSlidableExample> {
  final SlideController _slideController = SlideController();
  final ActionController _actionController = ActionController();

  @override
  void dispose() {
    _slideController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sized Slidable Example'),
      ),
      body: Center(
        child: SlidablePanel(
          controller: _slideController,
          maxSlideThreshold: 0.8,
          axis: Axis.horizontal,
          preActionPanel: SlideActionPanel(
            actionLayout: ActionLayout.spaceEvenly(ActionMotion.scroll),
            slidePercent: _slideController.slidePercent,
            /// bind [ActionController] with the [SlideActionPanel]
            controller: _actionController,
            actions: [
              TextButton(
                onPressed: () {
                  _actionController.toggle(0);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text("Archive"),
              ),
              TextButton(
                onPressed: () {
                  _actionController.toggle(1);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text("Delete"),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              _slideController.dismiss(
                onDismissed: () {
                  _actionController.reset();
                },
              );
            },
            child: const DecoratedBox(
              decoration: BoxDecoration(color: Colors.blue),
              child: SizedBox(
                width: 200,
                height: 100,
                child: Center(
                  child: Text(
                    'Slide me',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Usage

### Animating during sliding

- When creating `SlideActionPanel`, you should pass `SlideController.slidePercent` to `SlideActionPanel.slidePercent`, so that `SlideActionPanel` could listen to the changes during sliding, like:

```dart
SlideActionPanel(
    /// other codes
    slidePercent: _slideController.slidePercent,
    /// other codes
),
```

### Expand a specific action widget

When the `SlidablePanel` is opening, you could use `ActionController` to expand/collapse an action widget at the specific `index`

1. bind `ActionController` with the `SlideActionPanel`.
   > if you does not pass an `ActionController` to `SlideActionPanel`, invoking `ActionController.expand/collapse` would have no effect.

```dart
final _actionController = ActionController();
/// other codes
SlideActionPanel(
    /// other codes
    controller: _actionController,
    /// other codes
),
```

2. invoking `ActionController.expand/collapse`

```dart
TextButton(
    onPressed: () {
        _actionController.expand(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.linear,
        )
    },
    style: TextButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        shape: const RoundedRectangleBorder(),
    ),
    child: const Text("Archive"),
),
```

## Limitations

- `ActionController` must be reset manually by invoking `ActionController.reset()`; otherwise, the `SlidablePanel` would keep the expanded state after dismissing and opening again`.

```dart
_slideController.dismiss(
    onDismissed: () {
        _actionController.reset();
    },
);
```
