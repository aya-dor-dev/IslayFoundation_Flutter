import 'package:flutter/material.dart';

class CardContainer extends StatelessWidget {
  final Widget child;
  Color color; // = kCardColor;

  CardContainer({this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
