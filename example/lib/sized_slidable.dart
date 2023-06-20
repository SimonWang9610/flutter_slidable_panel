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
