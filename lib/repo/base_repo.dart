import 'package:flutter/cupertino.dart';

abstract class BaseRepo {
  bool ready();

  void init(VoidCallback onFinish);
}
