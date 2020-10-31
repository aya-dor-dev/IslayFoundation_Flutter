import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const String format = 'dd MMM yy';

extension DateTimePrettify on DateTime {
  String prettify() => DateFormat(format).format(this);
}

extension TimestampPrettify on Timestamp {
  String prettify() => this.toDate().prettify();
}

extension KeyboardUtils on BuildContext {
  void hideKeyboard() {
    FocusScopeNode currentFocus = FocusScope.of(this);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }
}
