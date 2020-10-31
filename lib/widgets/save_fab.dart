import 'package:flutter/material.dart';

class SaveFab extends StatelessWidget {
  final VoidCallback onPressed;

  SaveFab({@required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      label: Text(
        'SAVE',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      icon: Icon(
        Icons.check,
        color: Colors.white,
      ),
    );
  }
}
