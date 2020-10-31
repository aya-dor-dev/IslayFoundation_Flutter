import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:islay_foundation/widgets/oval_container.dart';

const String NAME = 'name';
const String IMAGE_URL = 'image_url';
const String INVESTMENT = 'investment';
const String WITHDRAWLS = 'withdrawls';
const String BOTTLES = 'bottles';

class Owner {
  DocumentReference reference;
  final String name;
  final String imageUrl;
  final num investment;
  final List<dynamic> bottles;
  List<Withdrawal> withdrawls = [];

  Owner(
      {@required this.name,
      this.imageUrl,
      this.investment,
      this.withdrawls,
      this.bottles});

  Widget getAvatar(BuildContext context) => imageUrl != null
      ? CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
          backgroundColor: Colors.transparent,
        )
      : OvalContainer(
          child: Icon(
            FontAwesomeIcons.piggyBank,
            color: Theme.of(context).accentColor,
          ),
          color: Theme.of(context).accentColor.withAlpha(64),
        );

  Owner.fromMap(Map<String, dynamic> map, {this.reference})
      : name = map[NAME],
        imageUrl = map[IMAGE_URL],
        bottles = map[BOTTLES],
        investment = map[INVESTMENT] ?? 0 {
    if (map[WITHDRAWLS] != null) {
      withdrawls = [];
      map[WITHDRAWLS]
          .forEach((item) => withdrawls.add(Withdrawal.fromMap(item)));
    }
  }

  Owner.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);
}

const String AMOUNT = 'amount';
const String DATE = 'date';

class Withdrawal {
  num amount;
  Timestamp date;

  Withdrawal({this.amount, this.date});

  Withdrawal.fromMap(Map<dynamic, dynamic> map)
      : date = map[DATE],
        amount = map[AMOUNT];
}
