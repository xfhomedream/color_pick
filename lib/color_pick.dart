import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:math';

typedef SelectColor = Color Function(Color color);

class ColorPickView extends StatefulWidget {
  Size size;
  double selectRadius;
  double padding;
  Color selectColor;
  final SelectColor selectColorCallBack;

  ColorPickView(
      {this.size,
      this.selectColorCallBack,
      this.selectRadius,
      this.padding,
      this.selectColor}) {
    assert(size == null || (size != null && size.height == size.width),
        '控件宽高必须相等');
  }

  @override
  State<StatefulWidget> createState() {
    return ColorPickState();
  }
}

class ColorPickState extends State<ColorPickView> {
  double radius;
  Color currentColor = Color(0xff00ff);
  Offset currentOffset;
  Offset topLeftPosition;
  Size screenSize;
  GlobalKey globalKey = new GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(new Duration(seconds: 1)).then((val) {
      setState(() {
        if (widget.selectColor != null) _setColor(widget.selectColor);
        print('ewrarererwew');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    screenSize ??= MediaQuery.of(context).size;
    widget.size ??= screenSize;
    widget.selectRadius ??= 10;
    widget.padding ??= 40;
    print("screenSize=$screenSize");
    print(widget.size);
    assert(
        widget.size == null ||
            (widget.size != null && screenSize.width >= widget.size.width),
        '控件宽度太宽');
    radius = widget.size.width / 2 - widget.padding;
    currentOffset ??= Offset(radius, radius);
    _initLeftTop();
    return GestureDetector(
      key: globalKey,
      child: Container(
        width: widget.size.width,
        height: widget.size.width,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              painter: ColorPick(radius: radius),
              size: widget.size,
            ),
            Positioned(
              left: currentOffset.dx -
                  (topLeftPosition == null ? 0 : (topLeftPosition.dx)),
              top: currentOffset.dy -
                  (topLeftPosition == null ? 0 : (topLeftPosition.dy)),
              //这里减去80，是因为上下边距各40 所以需要减去还有半径
              child: Container(
                width: widget.selectRadius,
                height: widget.selectRadius,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.selectRadius),
                    border: Border.fromBorderSide(BorderSide())),
                child: ClipOval(
                  child: Container(
                    color: currentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      onTapDown: (e) {
        setState(() {
          _initLeftTop();
          if (!isOutSide(e.globalPosition.dx, e.globalPosition.dy)) {
            currentColor =
                getColorAtPoint(e.globalPosition.dx, e.globalPosition.dy);
            currentOffset = e.globalPosition;
          }
        });
      },
      onPanUpdate: (e) {
        _initLeftTop();
        setState(() {
          if (!isOutSide(e.globalPosition.dx, e.globalPosition.dy)) {
            currentOffset = e.globalPosition;
            currentColor =
                getColorAtPoint(e.globalPosition.dx, e.globalPosition.dy);
            if (widget.selectColorCallBack != null) {
              widget.selectColorCallBack(currentColor);
            }
          }
        });
      },
    );
  }

  void _initLeftTop() {
    if (globalKey.currentContext != null && topLeftPosition == null) {
      print("================");
      final RenderBox box = globalKey.currentContext.findRenderObject();
      topLeftPosition = box.localToGlobal(Offset.zero);
    }
  }

  bool isOutSide(double eventX, double eventY) {
    double x = eventX -
        (topLeftPosition.dx +
            radius +
            widget.padding -
            widget.selectRadius / 2);
    double y = eventY -
        (topLeftPosition.dy +
            radius +
            widget.padding -
            widget.selectRadius / 2);
    double r = sqrt(x * x + y * y);
    print('r=$r--------------radius=$radius');
    if (r >= radius) return true;
    return false;
  }

  void _setColor(Color color) {
    _initLeftTop();
    //设置颜色值
    var hsvColor = HSVColor.fromColor(color);
    double r = hsvColor.saturation * radius;
    double radian = hsvColor.hue / -180.0 * pi;
    _updateSelector(r * cos(radian), -r * sin(radian));
    currentColor = color;
  }

  void _updateSelector(double eventX, double eventY) {
    //更新选中颜色值
    double r = sqrt(eventX * eventX + eventY * eventY);
    double x = eventX, y = eventY;
    if (r > radius) {
      x *= radius / r;
      y *= radius / r;
    }
    currentOffset = new Offset(x + topLeftPosition.dx + radius + widget.padding,
        y + topLeftPosition.dy + radius + widget.padding);
  }

  Color getColorAtPoint(double eventX, double eventY) {
    //获取坐标在色盘中的颜色值
    double x = eventX - (topLeftPosition.dx + radius + widget.padding);
    double y = eventY - (topLeftPosition.dy + radius + widget.padding);
    double r = sqrt(x * x + y * y);
    List<double> hsv = [0.0, 0.0, 1.0];
    hsv[0] = (atan2(-y, -x) / pi * 180).toDouble() + 180;
    hsv[1] = max(0, min(1, (r / radius)));
    return HSVColor.fromAHSV(1.0, hsv[0], hsv[1], hsv[2]).toColor();
  }
}

class ColorPick extends CustomPainter {
  Paint mPaint;
  Paint saturationPaint;
  final List<Color> mCircleColors = new List();
  final List<Color> mStatColors = new List();
  SweepGradient hueShader;
  final radius;
  RadialGradient saturationShader;

  ColorPick({this.radius}) {
    _init();
  }

  void _init() {
    //{Color.RED, Color.YELLOW, Color.GREEN, Color.CYAN, Color.BLUE, Color.MAGENTA, Color.RED}
    mPaint = new Paint();
    saturationPaint = new Paint();
    mCircleColors.add(Color.fromARGB(255, 255, 0, 0));
    mCircleColors.add(Color.fromARGB(255, 255, 255, 0));
    mCircleColors.add(Color.fromARGB(255, 0, 255, 0));
    mCircleColors.add(Color.fromARGB(255, 0, 255, 255));
    mCircleColors.add(Color.fromARGB(255, 0, 0, 255));
    mCircleColors.add(Color.fromARGB(255, 255, 0, 255));
    mCircleColors.add(Color.fromARGB(255, 255, 0, 0));

    mStatColors.add(Color.fromARGB(255, 255, 255, 255));
    mStatColors.add(Color.fromARGB(0, 255, 255, 255));
    hueShader = new SweepGradient(colors: mCircleColors);
    saturationShader = new RadialGradient(colors: mStatColors);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    mPaint.shader = hueShader.createShader(rect);
    saturationPaint.shader = saturationShader.createShader(rect);
    // 注意这一句
    canvas.clipRect(rect);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, mPaint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), radius, saturationPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
