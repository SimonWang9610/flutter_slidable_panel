import 'package:flutter/material.dart';
import 'package:flutter_slidable_panel/flutter_slidable_panel.dart';

class SizedSlidableExample extends StatefulWidget {
  const SizedSlidableExample({super.key});

  @override
  State<SizedSlidableExample> createState() => _SizedSlidableExampleState();
}

class _SizedSlidableExampleState extends State<SizedSlidableExample> {
  final SlideController _slideController = SlideController(
    usePreActionController: true,
    usePostActionController: true,
  );

  @override
  void dispose() {
    _slideController.dispose();
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
          preActionLayout: ActionLayout.flex(),
          preActions: [
            TextButton(
              onPressed: () {
                _slideController.toggleAction(0);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text("PreAction"),
            ),
            TextButton(
              onPressed: () {
                _slideController.toggleAction(1);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text("PreAction"),
            ),
          ],
          postActions: [
            TextButton(
              onPressed: () {
                _slideController.toggleAction(0);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text("PostAction"),
            ),
            TextButton(
              onPressed: () {
                _slideController.toggleAction(1);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text("PostAction"),
            ),
          ],
          child: GestureDetector(
            onTap: () {
              _slideController.dismiss();
            },
            child: const DecoratedBox(
              decoration: BoxDecoration(color: Colors.blue),
              child: SizedBox(
                width: 250,
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
