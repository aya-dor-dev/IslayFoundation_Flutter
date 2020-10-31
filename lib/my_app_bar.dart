import 'dart:io';

import 'package:flutter/material.dart';
import 'package:islay_foundation/constants.dart';

const _appBarTitleTextStyle = TextStyle(
    fontFamily: kFontPacifico, fontWeight: FontWeight.w200, fontSize: 20);

AppBar getAppBar({String title = kAppName, List<Widget> actions}) => AppBar(
      elevation: Platform.isAndroid ? 4.0 : 0.0,
      title: getTitle(title: title),
      actions: actions,
    );

Text getTitle({String title = kAppName}) => Text(
      title,
      style: _appBarTitleTextStyle,
    );
