import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:islay_foundation/model/auctioneer.dart';
import 'package:islay_foundation/repo/auctioneers.dart';
import 'package:islay_foundation/utils.dart';

class Auction {
  static final String _AUCTIONEER = 'auctioneer';
  static final String _NAME = 'name';
  static final String _END_DATE = 'endDate';
  static final String _START_DATE = 'startDate';
  static final String _BOTTLES = 'bottles';
  static final String _FEES = 'fees';
  static final String _INVESTMENT = 'investment';
  static final String _RETURN = 'returnOnInvestment';
  static final String _REVENUE = 'revenue';

  DocumentReference reference;

  String name;
  Auctioneer auctioneer;
  List<dynamic> bottles = List();
  Timestamp startDate;
  Timestamp endDate;
  num investmentInGBP;
  num returnInGBP;
  num revenueInGBP;
  num fees;

  bool get dataReady =>
      investmentInGBP != null &&
      returnInGBP != null &&
      revenueInGBP != null &&
      fees != null;

  Auction(this.name,
      {this.bottles,
      @required this.auctioneer,
      @required this.startDate,
      @required this.endDate,
      this.investmentInGBP = 0,
      this.returnInGBP = 0,
      this.revenueInGBP = 0,
      this.fees = 0});

  @override
  String toString() =>
      '${auctioneer.name} - $name; ${startDate.prettify()} - ${endDate.prettify()}';

  Auction.fromMap(Map<String, dynamic> map, {this.reference})
      : name = map[_NAME],
        bottles = map[_BOTTLES],
        startDate = map[_START_DATE],
        endDate = map[_END_DATE],
        fees = map[_FEES],
        investmentInGBP = map[_INVESTMENT],
        returnInGBP = map[_RETURN],
        revenueInGBP = map[_REVENUE] {
    print('Auction Created');
    String id = (map[_AUCTIONEER] as DocumentReference).documentID;
    auctioneer = Auctioneers().getById(id);
  }

  Auction.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  Map<String, dynamic> toMap() => {
        _AUCTIONEER: auctioneer.reference,
        _NAME: name,
        _END_DATE: endDate,
        _START_DATE: startDate,
        _BOTTLES: bottles,
        _FEES: fees,
        _INVESTMENT: investmentInGBP,
        _REVENUE: revenueInGBP,
        _RETURN: returnInGBP,
      };
}
