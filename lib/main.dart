// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rube/seven_segment_display.dart';
import 'grid.dart';

late String g;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  g = await File("world.rube").readAsString();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void subtitle(String x) {
    setState(() {
      subtitles.add(x);
    });
  }

  List<String> subtitles = [];
  static const int width = 32;
  bool paused = true;
  _MyHomePageState() {
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!paused) {
        int n = grid.length - 1;
        List<GridCell> prelist = grid.toList();
        for (GridCell cell in grid.reversed.toList()) {
          switch (cell.runtimeType) {
            case Empty:
            case Girder:
            case Ramp:
            case DozerReverser:
            case CrumbleWall:
              break;
            case Dozer:
              int nOffset = 0;
              bool pushOrRamp = false;
              if ((cell as Dozer).goingRight && n + 1 < grid.length) {
                if ((n > width - 1 && grid[n - width] is DozerReverser) ||
                    grid[n + 1] is DozerReverser) {
                  subtitle("[dozer reverses]");
                  grid[n] = Dozer(false);
                  cell = Dozer(false);
                }
              } else if (n > 1) {
                if ((n > width - 1 && grid[n - width] is DozerReverser) ||
                    grid[n - 1] is DozerReverser) {
                  subtitle("[dozer reverses]");
                  grid[n] = Dozer(true);
                  cell = Dozer(true);
                }
              }
              if (cell.goingRight && n + 1 < grid.length) {
                if (grid[n + 1] is Ramp &&
                    n > width - 1 &&
                    grid[n - width] is Empty) {
                  subtitle("[dozer moves up ramp]");
                  pushOrRamp = true;
                  grid[n - width] = Dozer(true);
                  grid[n] = Empty();
                  nOffset -= width;
                }
                if (grid[n + 1] is Crate &&
                    grid[n + 2] is Ramp &&
                    n > width - 1 &&
                    grid[n - width] is Empty &&
                    grid[n - width - 1] is Empty) {
                  subtitle("[dozer pushes crate up ramp]");
                  pushOrRamp = true;
                  grid[n - width] = Dozer(true);
                  grid[n] = Empty();
                  grid[n - width - 1] = Crate((grid[n + 1] as Crate).n);
                  grid[n + 1] = Empty();
                  nOffset -= width;
                }
                if (grid[n + nOffset + 1] is Crate &&
                    grid[n + nOffset + 2] is Empty &&
                    n % width < width - 2) {
                  subtitle("[dozer pushes crate]");
                  pushOrRamp = true;
                  grid[n + nOffset + 2] =
                      Crate((grid[n + nOffset + 1] as Crate).n);
                  grid[n + nOffset + 1] = Empty();
                }
                if (grid[n + nOffset + 1] is Empty && n % width < width - 1) {
                  if (!pushOrRamp) subtitle("[dozer moves]");
                  grid[n + nOffset + 1] = Dozer(true);
                  grid[n + nOffset] = Empty();
                  nOffset++;
                } else if (grid[n + nOffset + 1] is CrumbleWall &&
                    n % width < width) {
                  subtitle("[dozer breaks crumble wall]");
                  grid[n + nOffset + 1] = Empty();
                }
              } else if (n > 0) {
                if (n > 1 &&
                    grid[n - 1] is Crate &&
                    grid[n - 2] is Ramp &&
                    n > width &&
                    grid[n - (width - 1)] is Empty &&
                    grid[n - width] is Empty &&
                    grid[n - (width + 1)] is Empty) {
                  subtitle("[dozer pushes crate up ramp]");
                  pushOrRamp = true;
                  grid[n - width] = Dozer(false);
                  grid[n] = Empty();
                  grid[n - (width + 2)] = Crate((grid[n - 1] as Crate).n);
                  grid[n - 1] = Empty();
                  nOffset -= width;
                }
                if (grid[n - 1] is Ramp &&
                    n > width - 1 &&
                    grid[n - width] is Empty) {
                  subtitle("[dozer moves up ramp]");
                  grid[n - width] = Dozer(false);
                  pushOrRamp = true;
                  grid[n] = Empty();
                  nOffset -= width;
                }

                if (n > 1 &&
                    grid[n + nOffset - 1] is Crate &&
                    grid[n + nOffset - 2] is Empty &&
                    n % width > 1) {
                  subtitle("[dozer pushes crate]");
                  pushOrRamp = true;
                  grid[n + nOffset - 2] =
                      Crate((grid[n + nOffset - 1] as Crate).n);
                  grid[n + nOffset - 1] = Empty();
                }
                if (grid[n + nOffset - 1] is Empty && n % width > 0) {
                  if (!pushOrRamp) subtitle("[dozer moves]");
                  grid[n + nOffset - 1] = Dozer(false);
                  grid[n + nOffset] = Empty();
                  nOffset--;
                } else if (grid[n + nOffset - 1] is CrumbleWall &&
                    n % width > 0) {
                  subtitle("[dozer breaks crumble wall]");
                  grid[n + nOffset - 1] = Empty();
                }
              }
              if (n + nOffset > grid.length - (width + 1)) {
                grid[n + nOffset] = Empty();
                subtitle("[dozer falls off map]");
              } else if (grid[n + width + nOffset] is Empty) {
                grid[n + nOffset + width] = Dozer(cell.goingRight);
                grid[n + nOffset] = Empty();
                subtitle("[dozer falls]");
              }
              break;
            case Crate:
              if (n > grid.length - (width + 1)) {
                grid[n] = Empty();
                subtitle("[crate falls off map]");
              } else if (grid[n + width] is Empty) {
                grid[n + width] = Crate((cell as Crate).n);
                grid[n] = Empty();
                subtitle("[crate falls]");
              }
              break;
            case Belt:
              if (n > width - 1 &&
                  prelist[n - width] is Crate &&
                  (!(cell as Belt).goingRight
                      ? n % width > 0
                      : n % width < width - 1)) {
                if ((cell.goingRight
                    ? grid[n - (width - 1)]
                    : grid[n - (width + 1)]) is Empty) {
                  subtitle("[belt pushes crate]");
                  grid[n - (cell.goingRight ? width - 1 : width + 1)] =
                      Crate((grid[n - width] as Crate).n);
                  grid[n - width] = Empty();
                }
              }
              break;
            case Winch:
              if (n > width - 1 && n < grid.length - (width + 1)) {
                if ((cell as Winch).goingUp) {
                  if (grid[n + width] is Crate && grid[n - width] is Empty) {
                    subtitle("[winch lifts crate]");
                    grid[n - width] = Crate((grid[n + width] as Crate).n);
                    grid[n + width] = Empty();

                    if (cell.swinch) grid[n] = Winch(false, true);
                  }
                } else {
                  if (grid[n - width] is Crate && grid[n + width] is Empty) {
                    subtitle("[winch drops crate]");
                    grid[n + width] = Crate((grid[n - width] as Crate).n);
                    grid[n - width] = Empty();
                    if (cell.swinch) grid[n] = Winch(true, true);
                  }
                }
              }
              break;
            case Gate:
              if (n > width - 1 &&
                  n % 8 > 0 &&
                  n % 8 < width &&
                  grid[n + width] is Crate &&
                  grid[n - width] is Crate &&
                  grid[n - 1] is Empty &&
                  grid[n + 1] is Empty) {
                if ((grid[n - width] as Crate).n <
                    (grid[n + width] as Crate).n) {
                  grid[n - 1] = Crate((grid[n - width] as Crate).n);
                } else {
                  grid[n + 1] = Crate((grid[n - width] as Crate).n);
                }
                grid[n - width] = Empty();
              }
              break;
            case Packer:
              if (n < grid.length - (width + 1) &&
                  n % 8 > 0 &&
                  n % 8 < width &&
                  grid[n + (width - 1)] is Crate &&
                  grid[n + width] is Crate &&
                  grid[n + width + 1] is Empty) {
                grid[n + width + 1] = Crate(
                    ((grid[n + (width - 1)] as Crate).n +
                            (grid[n + width] as Crate).n) %
                        16);
                grid[n + (width - 1)] = Empty();
                grid[n + width] = Empty();
              }
              break;
            case Unpacker:
              if (n < grid.length - (width + 1) &&
                  n % 8 > 0 &&
                  n % 8 < width &&
                  grid[n + (width - 1)] is Crate &&
                  grid[n + width] is Crate &&
                  grid[n + width + 1] is Empty) {
                grid[n + width + 1] = Crate(
                    -((grid[n + (width - 1)] as Crate).n -
                            (grid[n + width] as Crate).n) %
                        16);
                grid[n + (width - 1)] = Empty();
                grid[n + width] = Empty();
              }
              break;
            case Furnace:
              if (n < grid.length - (width + 1)) {
                grid[n + width] = Empty();
              }
              if (n > width - 1) {
                grid[n - width] = Empty();
              }
              if (n % width < width - 1) {
                grid[n + 1] = Empty();
              }
              if (n % width > 0) {
                grid[n - 1] = Empty();
              }
              break;
            case Replicator:
              cell as Replicator;
              if ((n > width - 1 &&
                          n < grid.length - (width + 1) &&
                          cell.upsideDown
                      ? (grid[n - width] is Empty)
                      : (grid[n + width] is Empty)) &&
                  (!cell.cratesOnly ||
                      (cell.upsideDown
                          ? grid[n + width] is Crate
                          : grid[n - width] is Crate))) {
                if (cell.upsideDown) {
                  grid[n - width] = grid[n + width];
                } else {
                  grid[n + width] = grid[n - width];
                }
              }
              break;
            default:
              throw UnimplementedError();
          }
          n--;
        }
        setState(() {});
      }
    });
  }
  bool mouseDown = false;

  late final List<GridCell> grid =
      g.split("\n").join('').split('').map(parseGridCell).toList();

  GridCell parseGridCell(e) {
    switch (e) {
      case " ":
        return Empty();
      case "=":
        return Girder();
      case "\\":
        return Ramp(true);
      case "/":
        return Ramp(false);
      case "(":
        return Dozer(true);
      case ")":
        return Dozer(false);
      case ">":
        return Belt(true);
      case "<":
        return Belt(false);
      case "\n":
        return Empty();
      case ",":
        return DozerReverser();
      case "W":
        return Winch(true, false);
      case "M":
        return Winch(false, false);
      case "A":
        return Winch(true, true);
      case "V":
        return Winch(false, true);
      case "K":
        return Gate();
      case "+":
        return Packer();
      case "-":
        return Unpacker();
      case "F":
        return Furnace();
      case ":":
        return Replicator(false, false);
      case ";":
        return Replicator(true, false);
      case ".":
        return Replicator(true, true);
      case "*":
        return CrumbleWall();
      default:
        return Crate(int.parse(e, radix: 16));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: (PointerHoverEvent x) {
          mouseX = x.position.dx ~/ (1440 / width);
          mouseY = x.position.dy ~/ (900 / (grid.length / width));
          if(mouseDown) placeGridCell();
        },
        opaque: false,
        child: GestureDetector(
          key: const Key('test'),
          onTapDown: (TapDownDetails x) {
            print("TAP");
            mouseDown = true;
            placeGridCell();
          },
          onTapUp: (TapUpDetails x) {
            print("UN-TAP");
            mouseDown = false;
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              SizedBox.expand(
                child: GridDrawer(grid, width),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => paused = !paused),
                      child: Container(
                        child: Text(paused ? "Unpause" : "Pause"),
                        color: Colors.yellow,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        File('world.rube').writeAsStringSync(grid.join(''));
                      },
                      child: Container(
                        child: const Text("Save"),
                        color: Colors.yellow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String selected = " ";
  int mouseX = 0;
  int mouseY = 0;
  void placeGridCell() {
    GridCell gridCell = parseGridCell(selected);
    setState(() {
      grid[mouseX + mouseY * width] = gridCell;
    });
  }
}

class CrumbleWall extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    canvas.drawRect(offset & size, Paint()..color = Colors.grey);
  }

  @override
  String toString() => "*";
}

class Replicator extends GridCell {
  final bool cratesOnly;
  final bool upsideDown;

  Replicator(this.cratesOnly, this.upsideDown);
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    Path p = Path();
    p.moveTo(offset.dx, offset.dy);
    p.lineTo(
      offset.dx + size.width,
      offset.dy + (size.height / 2),
    );
    p.lineTo(offset.dx, offset.dy + size.height);
    Offset center = size.center(offset);

    if (cratesOnly) {
      canvas.drawRect(offset & size, Paint()..color = Colors.brown);
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    double radians = upsideDown ? pi * 3 / 2 : pi / 2;
    canvas.rotate(radians);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(
      p,
      ((Paint()..color = Colors.green)..style = PaintingStyle.stroke)
        ..strokeWidth = 5,
    );
    canvas.restore();
  }

  @override
  String toString() =>
      cratesOnly ? (upsideDown ? "." : ";") : (upsideDown ? "^" : ":");
}

class Furnace extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    canvas.drawRect(offset & size, Paint()..color = Colors.red);
  }

  @override
  String toString() => "F";
}

class Packer extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    Path p = Path();
    p.moveTo(offset.dx + size.width / 2, offset.dy);
    p.lineTo(
      offset.dx + size.width / 2,
      offset.dy + size.height,
    );
    p.moveTo(offset.dx, offset.dy + size.height / 2);
    p.lineTo(
      offset.dx + size.width,
      offset.dy + size.height / 2,
    );
    canvas.drawPath(
      p,
      ((Paint()..color = Colors.yellow)..style = PaintingStyle.stroke)
        ..strokeWidth = 5,
    );
  }

  @override
  String toString() => "+";
}

class Unpacker extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    Path p = Path();
    p.moveTo(offset.dx, offset.dy + size.height / 2);
    p.lineTo(
      offset.dx + size.width,
      offset.dy + size.height / 2,
    );
    canvas.drawPath(
      p,
      ((Paint()..color = Colors.yellow)..style = PaintingStyle.stroke)
        ..strokeWidth = 5,
    );
  }

  @override
  String toString() => "-";
}

class Gate extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    canvas.drawRect(offset & size, Paint()..color = Colors.yellow);
  }

  @override
  String toString() => "K";
}

class Dozer extends GridCell {
  Dozer(this.goingRight);
  final bool goingRight;

  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    Path p = Path();
    p.moveTo(offset.dx, offset.dy);
    p.lineTo(
      offset.dx + size.width,
      offset.dy + (size.height / 2),
    );
    p.lineTo(offset.dx, offset.dy + size.height);
    Offset center = size.center(offset);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    double radians = goingRight ? 0 : pi;
    canvas.rotate(radians);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(
      p,
      ((Paint()..color = Colors.orange)..style = PaintingStyle.stroke)
        ..strokeWidth = 5,
    );
    canvas.restore();
  }

  @override
  String toString() => goingRight ? "(" : ")";
}

class Winch extends GridCell {
  Winch(this.goingUp, this.swinch);
  final bool goingUp;
  final bool swinch;

  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    Path p = Path();
    p.moveTo(offset.dx, offset.dy);
    p.lineTo(
      offset.dx + size.width,
      offset.dy + (size.height / 2),
    );
    p.lineTo(offset.dx, offset.dy + size.height);
    Offset center = size.center(offset);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    double radians = goingUp ? pi * 3 / 2 : pi / 2;
    canvas.rotate(radians);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(
      p,
      ((Paint()..color = swinch ? Colors.orange : Colors.yellow)..style = PaintingStyle.stroke)
        ..strokeWidth = 5,
    );
    canvas.restore();
  }

  @override
  String toString() => goingUp
      ? swinch
          ? "A"
          : "W"
      : swinch
          ? "V"
          : "M";
}

class DozerReverser extends GridCell {
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    Path p = Path();
    p.moveTo(
      offset.dx + size.width / 2,
      offset.dy,
    );
    p.lineTo(
      offset.dx + size.width / 2,
      offset.dy + size.height * 3 / 2,
    );
    canvas.drawPath(
      p,
      ((Paint()..color = Colors.yellow)..style = PaintingStyle.stroke)
        ..strokeWidth = 5,
    );
  }

  @override
  String toString() => ",";
}

class Empty extends GridCell {
  @override
  String toString() => " ";
}

class Crate extends GridCell {
  Crate(this.n);
  final int n;
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    canvas.drawRect(offset & size, Paint()..color = Colors.brown);
    drawNumber(canvas, offset.dx + size.width / 4, offset.dy + size.height / 4,
        size.width / 2, size.height / 2, n);
    super.paint(canvas, size, offset);
  }

  @override
  String toString() => n.toRadixString(16);
}

class Girder extends GridCell {
  Girder();
  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    canvas.drawRect(offset & size, Paint()..color = Colors.black);
  }

  @override
  String toString() => "=";
}

class Belt extends GridCell {
  Belt(this.goingRight);
  final bool goingRight;

  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    canvas.drawRect(offset & size, Paint()..color = Colors.black);
    Path p = Path();
    p.moveTo(offset.dx, offset.dy);
    p.lineTo(
      offset.dx + size.width,
      offset.dy + (size.height / 2),
    );
    p.lineTo(offset.dx, offset.dy + size.height);
    Offset center = size.center(offset);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    double radians = goingRight ? 0 : pi;
    canvas.rotate(radians);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(
      p,
      ((Paint()..color = Colors.yellow)..style = PaintingStyle.stroke)
        ..strokeWidth = 5,
    );
    canvas.restore();
  }

  @override
  String toString() => goingRight ? ">" : "<";
}

class Ramp extends GridCell {
  final bool goingRight;

  Ramp(this.goingRight);

  @override
  void paint(Canvas canvas, Size size, Offset offset) {
    super.paint(canvas, size, offset);
    Path p = Path();
    p.moveTo(offset.dx, offset.dy);
    p.lineTo(
      offset.dx + size.width,
      offset.dy + (size.height),
    );
    Offset center = size.center(offset);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    double radians = goingRight ? 0 : pi / 2;
    canvas.rotate(radians);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(
      p,
      ((Paint()..color = Colors.black)..style = PaintingStyle.stroke)
        ..strokeWidth = 5,
    );
    canvas.restore();
  }

  @override
  String toString() => goingRight ? "/" : "\\";
}
