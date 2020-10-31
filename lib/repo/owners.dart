import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:islay_foundation/model/owner.dart';
import 'package:islay_foundation/repo/base_repo.dart';

const COLLECTION_NAME = 'owners';

class Owners extends BaseRepo {
  static final Owners _singleton = Owners._internal();

  factory Owners() {
    return _singleton;
  }

  Owners._internal();

  List<Owner> owners;

  @override
  void init(VoidCallback onFinish) {
    Firestore.instance
        .collection(COLLECTION_NAME)
        .snapshots()
        .listen((snapshot) {
      owners = snapshot.documents
          .map((dss) => Owner.fromMap(dss.data, reference: dss.reference))
          .toList();
      owners.sort(
          (o1, o2) => (o2.imageUrl ?? "").length - (o1.imageUrl ?? "").length);

      onFinish();
    });
  }

  Owner getById(String id) {
    Owner res;
    owners.forEach((owner) {
      if (owner.reference.documentID == id) {
        res = owner;
      }
    });
    return res;
  }

  @override
  bool ready() => owners != null;
}
