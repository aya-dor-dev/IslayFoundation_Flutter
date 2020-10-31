import 'package:flutter/material.dart';

class OvalContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final double padding;

  OvalContainer(
      {@required this.child, this.color = Colors.white, this.padding = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: child,
      padding: EdgeInsets.all(padding),
      decoration: new BoxDecoration(
        color: color, // border color
        shape: BoxShape.circle,
      ),
    );
  }
}
