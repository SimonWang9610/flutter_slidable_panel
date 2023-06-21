import 'package:flutter/material.dart';
import 'package:flutter_slidable_panel/flutter_slidable_panel.dart';

class SlidableListExample extends StatefulWidget {
  const SlidableListExample({super.key});

  @override
  State<SlidableListExample> createState() => _SlidableListExampleState();
}

class _SlidableListExampleState extends State<SlidableListExample> {
  final _titles = List.generate(40, (index) => "Item $index");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slidable List Example'),
      ),
      body: Center(
        child: SizedBox(
          width: 300,
          height: 600,
          child: ListView.builder(
            itemCount: _titles.length,
            shrinkWrap: true,
            itemBuilder: (_, index) => SlidableListTile(
              index: index,
              title: _titles[index],
              onDeleted: () {
                _titles.removeAt(index);
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SlidableListTile extends StatefulWidget {
  final int index;
  final String title;
  final VoidCallback? onDeleted;
  const SlidableListTile({
    super.key,
    required this.title,
    required this.index,
    this.onDeleted,
  });

  @override
  State<SlidableListTile> createState() => _SlidableListTileState();
}

class _SlidableListTileState extends State<SlidableListTile> {
  final SlideController _slideController = SlideController(
    usePreActionController: true,
  );

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlidablePanel(
      controller: _slideController,
      maxSlideThreshold: 0.8,
      axis: Axis.horizontal,
      onSlideStart: () {
        print("onSlideStart: ${widget.index}");
      },
      preActions: [
        TextButton(
          onPressed: () {
            _slideController.preActionController?.toggle(0);
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            shape: const RoundedRectangleBorder(),
          ),
          child: const Text("Archive"),
        ),
        TextButton(
          onPressed: () {
            final expanded = _slideController.hasExpandedAt(1);

            if (expanded) {
              _slideController.dismiss();
              widget.onDeleted?.call();
            } else {
              _slideController.expand(0);
            }
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: const RoundedRectangleBorder(),
          ),
          child: const Text("Delete"),
        ),
      ],
      child: TextButton(
        onPressed: () {
          _slideController.dismiss();
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(),
          side: const BorderSide(color: Colors.black),
        ),
        child: Text(widget.title),
      ),
    );
  }
}
