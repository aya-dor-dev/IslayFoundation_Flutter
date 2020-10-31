import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:islay_foundation/model/auctioneer.dart';
import 'package:islay_foundation/repo/base_repo.dart';

const COLLECTION_NAME = 'auctioneers';

class Auctioneers extends BaseRepo {
  static final Auctioneers _singleton = Auctioneers._internal();

  factory Auctioneers() {
    return _singleton;
  }

  Auctioneers._internal();

  List<Auctioneer> auctioneers;

  @override
  void init(VoidCallback onFinish) {
    Firestore.instance
        .collection(COLLECTION_NAME)
        .snapshots()
        .listen((snapshot) {
      auctioneers = snapshot.documents
          .map((dss) => Auctioneer.fromMap(dss.data, reference: dss.reference))
          .toList();

      onFinish();
    });
  }

  Auctioneer getById(String id) {
    Auctioneer res;
    auctioneers.forEach((auctioneer) {
      if (auctioneer.reference.documentID == id) {
        res = auctioneer;
      }
    });
    return res;
  }

  @override
  bool ready() => auctioneers != null;
}
