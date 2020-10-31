import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:islay_foundation/model/auction.dart';

import 'base_repo.dart';

class Auctions extends BaseRepo {
  static final Auctions _singleton = Auctions._internal();
  HashMap<String, Auction> _map = HashMap();

  factory Auctions() {
    return _singleton;
  }

  Auctions._internal();

  List<Auction> auctions;

  num _totalInvestment = 0.0;
  num _totalRevenue = 0.0;
  num _totalReturn = 0.0;

  num get totalInvestment => _totalInvestment;

  num get totalReturn => _totalReturn;

  num get totalRevenue => _totalRevenue;

  @override
  void init(onFinish) {}

  @override
  bool ready() =>
      !auctions.map((auction) => auction.dataReady).toList().contains(false);

  void recalc(List<Auction> auctions) {
    _totalRevenue = 0;
    _totalReturn = 0;
    _totalInvestment = 0;
    this.auctions = auctions;
    _map.clear();
    auctions.forEach((auction) {
      _totalInvestment += auction.investmentInGBP;
      _totalReturn += auction.returnInGBP - auction.fees;
      _totalRevenue += auction.revenueInGBP;

      _map[auction.reference.documentID] = auction;
    });
  }

  Auction getAuctionByReference(DocumentReference ref) =>
      getAuctionById(ref.documentID);

  Auction getAuctionById(String id) => _map[id];
}
