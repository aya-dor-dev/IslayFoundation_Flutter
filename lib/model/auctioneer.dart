import 'package:cloud_firestore/cloud_firestore.dart';

import 'bottle.dart';

const String NAME = 'name';
const String LISTING_FEE = 'listing_fee';
const String RESERVE_FEE = 'reserve_fee';
const String DURATION_IN_DAYS = 'duration_in_days';

class Auctioneer {
  DocumentReference reference;

  final String name;
  final int listingFee;
  final int reserveFee;
  final Duration duration;

  Auctioneer({this.name, this.listingFee, this.reserveFee, this.duration});

  int calculateBottleFee(Bottle bottle) =>
      listingFee + (bottle.reserve > 0 ? reserveFee : 0);

  Auctioneer.fromMap(Map<String, dynamic> map, {this.reference})
      : name = map[NAME],
        listingFee = map[LISTING_FEE],
        reserveFee = map[RESERVE_FEE],
        duration = Duration(days: map[DURATION_IN_DAYS]);

  Auctioneer.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);
}
