import 'dart:collection';
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:islay_foundation/add_auction/edit_bottle_screen.dart';
import 'package:islay_foundation/constants.dart';
import 'package:islay_foundation/model/auction.dart';
import 'package:islay_foundation/model/bottle.dart';
import 'package:islay_foundation/repo/owners.dart';
import 'package:islay_foundation/utils.dart';
import 'package:islay_foundation/widgets/bottle_list_item.dart';
import 'package:progress_dialog/progress_dialog.dart';

import '../Header.dart';
import '../my_app_bar.dart';

class AuctionScreen extends StatefulWidget {
  static const SCREEN_NAME = '/auction';

  @override
  _AuctionScreenState createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  HashMap<DocumentReference, double> _bottles = HashMap();
  List<FocusNode> focusNodes = <FocusNode>[];
  List<Stream<DocumentSnapshot>> bottlesRefs;
  Auction auction;
  bool editMode = false;

  @override
  Widget build(BuildContext context) {
    auction = ModalRoute.of(context).settings.arguments;
    DocumentReference auctionRef = auction.reference;

    return Scaffold(
      floatingActionButtonAnimator: NoScalingAnimation(),
      floatingActionButton: editMode
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FloatingActionButton(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.check_circle,
                    color: kColorProfit,
                    size: 35,
                  ),
                  onPressed: () {
                    _updatePrices();
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                FloatingActionButton(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.cancel,
                    color: kColorLoss,
                    size: 35,
                  ),
                  onPressed: () {
                    setState(() {
                      editMode = !editMode;
                    });
                  },
                )
              ],
            )
          : FloatingActionButton.extended(
              label: Text(
                'Update Prices'.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                _bottles = HashMap();
                setState(() {
                  editMode = !editMode;
                });
              },
            ),
      floatingActionButtonLocation: editMode
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerFloat,
      appBar: getAppBar(actions: [
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, EditBottleScreen.SCREEN_NAME,
                arguments: BottleScreenArguments(auction));
          },
          child: Container(
            margin: EdgeInsets.only(right: 10),
            child: SvgPicture.asset(
              'assets/add_bottle.svg',
              height: 36,
            ),
          ),
        )
      ]),
      body: SafeArea(
        child: Container(
          child: Column(
            children: <Widget>[
              _buildHeader(
                  Firestore.instance.document(auctionRef.path).snapshots(),
                  context),
              SizedBox(
                height: 10,
              ),
              Expanded(child: _buildBody(auctionRef.snapshots(), context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Stream<DocumentSnapshot> snapshot, BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: snapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        final auction = Auction.fromSnapshot(snapshot.data);
        if (!auction.dataReady)
          return Center(child: CircularProgressIndicator());

        return Header(
          title:
              '${auction.startDate.prettify()} - ${auction.endDate.prettify()}',
          investment: auction.investmentInGBP,
          returnOnInvestment: auction.returnInGBP - auction.fees,
          revenue: auction.revenueInGBP,
        );
      },
    );
  }

  Widget _buildBody(Stream<DocumentSnapshot> snapshot, BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: snapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        final auction = Auction.fromSnapshot(snapshot.data);
        bottlesRefs = auction.bottles
            .map((bottle) => (bottle as DocumentReference).snapshots())
            .toList();

        return _buildList(context, bottlesRefs);
      },
    );
  }

  Widget _buildList(
      BuildContext context, List<Stream<DocumentSnapshot>> snapshot) {
    snapshot.add(null);
    final List<Widget> children = <Widget>[];
    focusNodes = <FocusNode>[];
    for (int i = 0; i < snapshot.length; i++) {
      children.add(_buildListItem(context, snapshot[i], i));
      focusNodes.add(FocusNode());
    }
    focusNodes.removeLast(); // Remove focusnode for empty space

    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: children,
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Stream<DocumentSnapshot> snapshot,
    int pos,
  ) {
    if (snapshot == null)
      return SizedBox(
        height: editMode ? 100 : 70,
      );

    return StreamBuilder<DocumentSnapshot>(
      stream: snapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data.data == null)
          return Center(child: CircularProgressIndicator());

        var bottle = Bottle.fromSnapshot(snapshot.data);

        final onTap = () {
          _bottleOptionsBottomSheet(context, bottle);
        };

        FocusNode focusNode = focusNodes[pos];

        return Container(
          child: InkWell(
            onTap: editMode ? null : onTap,
            child: BottleListItem(
              bottle: bottle,
              onSoldEdited: editMode
                  ? (value) {
                      _bottles[bottle.reference] = value;
                    }
                  : null,
              onNext: editMode
                  ? () {
                      focusNode.unfocus();
                      if (pos + 1 < bottlesRefs.length) {
                        focusNodes[pos + 1].requestFocus();
                      }
                    }
                  : null,
              focusNode: editMode ? focusNode : null,
            ),
          ),
        );
      },
    );
  }

  void _bottleOptionsBottomSheet(context, Bottle bottle) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: new Icon(Icons.edit),
                    title: new Text('Edit'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, EditBottleScreen.SCREEN_NAME,
                          arguments:
                              BottleScreenArguments(auction, bottle: bottle));
                    }),
                ListTile(
                    leading: new Icon(Icons.delete),
                    title: new Text('Delete'),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteDialog(bottle);
                    }),
              ],
            ),
          );
        });
  }

  void _showDeleteDialog(Bottle bottle) {
    AwesomeDialog(
        context: context,
        dialogType: DialogType.WARNING,
        animType: AnimType.BOTTOMSLIDE,
        tittle: 'Warning!',
        btnOkText: 'Delete',
        btnCancelText: 'CANCEL',
        desc:
            'Are you sure you would like to delete this bottle from the current auction?\n'
            'This cannot be undone',
        btnCancelOnPress: () {},
        btnOkOnPress: () {
          bottle.reference.delete().then((reference) {
            _bottleDeletedSuccess(bottle);
          }, onError: (error) {
            _bottleDeleteFail();
          });
        }).show();
  }

  void _bottleDeletedSuccess(Bottle bottle) {
    AwesomeDialog(
            context: context,
            dialogType: DialogType.SUCCES,
            animType: AnimType.BOTTOMSLIDE,
            tittle: 'Bottle Deleted!',
            desc: '${bottle.name} removed from auction ${auction.name}',
            btnCancel: null,
            btnOkOnPress: () {})
        .show();
  }

  void _bottleDeleteFail() {
    AwesomeDialog(
            context: context,
            dialogType: DialogType.ERROR,
            animType: AnimType.BOTTOMSLIDE,
            tittle: 'Oops!',
            desc: 'Unable to remove bottle at the moment\n'
                'Please try again later.',
            btnCancel: null,
            btnOkOnPress: () {})
        .show();
  }

  void _updatePrices() {
    ProgressDialog pd = ProgressDialog(context, isDismissible: false);
    pd.style(message: 'Updating Prices...');
    pd.show();

    final batch = Firestore.instance.batch();
    _bottles.forEach((docRef, sold) {
      batch.updateData(docRef, {Bottle.SOLD: sold});
    });

    batch.commit().then((value) {
      pd.dismiss();
      setState(() {
        editMode = false;
      });
    }, onError: (error) {
      pd.dismiss();
    });
  }

  void _mockBottles() async {
    for (var i = 0; i < 3; i++) {
      await Firestore.instance.collection('bottles').add(Bottle('Test $i',
              cost: 10 * (i + 1),
              owner: Owners().owners.first,
              auction: auction)
          .toMap());
      sleep(Duration(seconds: 2));
    }
  }
}

class NoScalingAnimation extends FloatingActionButtonAnimator {
  double _x;
  double _y;

  @override
  Offset getOffset({Offset begin, Offset end, double progress}) {
    _x = begin.dx + (end.dx - begin.dx) * progress;
    _y = begin.dy + (end.dy - begin.dy) * progress;
    return Offset(_x, _y);
  }

  @override
  Animation<double> getRotationAnimation({Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }

  @override
  Animation<double> getScaleAnimation({Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }
}
