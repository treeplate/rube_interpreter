import 'dart:math';

import 'package:flutter/material.dart';

class GridDrawer extends StatelessWidget {
  const GridDrawer(this.grid, this.width, {Key? key}): super(key: key);
  final List<GridCell> grid;
  final int width;
  int get height => grid.length ~/ width;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(
        width,
        height,
        grid,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  GridPainter(this.width, this.height, this.grid);
  final int width;
  final int height;
  final List<GridCell> grid;
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
  @override
  void paint(Canvas canvas, Size size) {
    double cellDim = min(size.width/width, size.height/height);
    Size cellSize = Size.square(cellDim);
    for (int y = 0; y < height; y += 1) {
      for (int x = 0; x < width; x += 1) {
        grid[x + (y * width)].paint(canvas, cellSize, Offset(x * cellDim, y * cellDim));
      }
    }
  }
}

abstract class GridCell {
  @mustCallSuper
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(offset & size, Paint()..color=Colors.black..style = PaintingStyle.stroke..strokeWidth=5);
  }
}