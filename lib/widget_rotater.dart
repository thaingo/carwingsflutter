import 'package:flutter/material.dart';

class WidgetRotater extends StatefulWidget {
  final Widget _widget;

  @override
  _WidgetRotaterState createState() => new _WidgetRotaterState(_widget);

  WidgetRotater(this._widget);
}

class _WidgetRotaterState extends State<WidgetRotater>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;

  Widget _widget;

  _WidgetRotaterState(this._widget);

  @override
  void initState() {
    super.initState();

    animationController = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: 2),
    );


    animationController.repeat();
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      alignment: Alignment.center,
      child: new AnimatedBuilder(
        animation: animationController,
        child: _widget,
        builder: (BuildContext context, Widget _widget) {
          return new Transform.rotate(
            angle: animationController.value * 12.3,
            child: _widget,
          );
        },
      ),
    );
  }
}