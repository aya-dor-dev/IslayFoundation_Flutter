import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:islay_foundation/model/auction.dart';
import 'package:islay_foundation/repo/owners.dart';

import 'owner.dart';

class Bottle {
  static final _NAME = 'name';
  static final _COST = 'cost';
  static final _OWNER = 'owner';
  static final SOLD = 'sold';
  static final _RESERVE = 'reserve';
  static final _AUCTION = 'auction';
  static final _REVENUE = 'revenue';
  static final _FEES = 'fees';

  DocumentReference reference;
  DocumentReference auctionReference;
  String name;
  num cost;
  Owner owner;
  Auction auction;
  num sold;
  num reserve;
  num fees;
  num revenue;

  Bottle(this.name,
      {@required this.cost,
      @required this.owner,
      this.sold,
      this.reserve,
      this.auction});

  bool isProfitable() => sold ?? 0 > cost;

  double getProfit() {
    if (reserve > 0.0 && (sold ?? 0) == 0.0) return 0;
    return sold - cost;
  }

  Bottle.fromMap(Map<String, dynamic> map, {this.reference})
      : name = map[_NAME],
        cost = map[_COST],
        reserve = map[_RESERVE],
        sold = map[SOLD],
        fees = map[_FEES],
        revenue = map[_REVENUE],
        auctionReference = map[_AUCTION],
        owner = Owners().getById((map[_OWNER] as DocumentReference).documentID);

  Bottle.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  Map<String, dynamic> toMap() => {
        _NAME: name,
        _OWNER: owner.reference,
        _COST: cost,
        _RESERVE: reserve,
        SOLD: sold,
        _AUCTION: auction.reference,
      };
}
