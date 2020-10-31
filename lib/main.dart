import 'package:flutter/material.dart';
import 'package:islay_foundation/add_auction/add_auction_screen.dart';
import 'package:islay_foundation/auction_screen/auction_screen.dart';
import 'package:islay_foundation/constants.dart';
import 'package:islay_foundation/home_screen/home_screen.dart';
import 'package:islay_foundation/owner_screen/owner_screen.dart';

import 'add_auction/edit_bottle_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blueGrey.shade700),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: kFontNunito,
            ),
      ),
      routes: {
        HomeScreen.SCREEN_NAME: (context) => HomeScreen(),
        AuctionScreen.SCREEN_NAME: (context) => AuctionScreen(),
        AddAuctionScreen.SCREEN_NAME: (context) => AddAuctionScreen(),
        EditBottleScreen.SCREEN_NAME: (context) => EditBottleScreen(),
        OwnerScreen.SCREEN_NAME: (context) => OwnerScreen(),
      },
      initialRoute: HomeScreen.SCREEN_NAME,
    );
  }
}
