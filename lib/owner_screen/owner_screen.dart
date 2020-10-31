import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:islay_foundation/constants.dart';
import 'package:islay_foundation/model/bottle.dart';
import 'package:islay_foundation/model/owner.dart';
import 'package:islay_foundation/repo/auctions.dart';
import 'package:islay_foundation/utils.dart';
import 'package:islay_foundation/widgets/bottle_list_item.dart';
import 'package:islay_foundation/widgets/oval_container.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class OwnerScreen extends StatefulWidget {
  static const SCREEN_NAME = '/owner';

  @override
  _OwnerScreenState createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  Owner _owner;
  List<Stream<DocumentSnapshot>> bottlesRefs;
  var dialogOpened = false;

  @override
  Widget build(BuildContext context) {
    if (_owner == null) _owner = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      body: SafeArea(
        child: SlidingUpPanel(
          parallaxEnabled: true,
          parallaxOffset: 0.5,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular((25)),
            topRight: Radius.circular(25),
          ),
          body: _getBody(),
          panelBuilder: (ScrollController sc) => _buildList(sc),
          color: Theme.of(context).cardColor,
          // Theme.of(context).cardColor,
          collapsed: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular((25)),
                topRight: Radius.circular(25),
              ),
            ),
            child: Center(
              child: Text(
                "Bottles",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    ScrollController sc,
  ) {
    bottlesRefs = _owner.bottles
        .map((bottle) => (bottle as DocumentReference).snapshots())
        .toList();
    return ListView(
      controller: sc,
      padding: const EdgeInsets.only(top: 20.0),
      children: bottlesRefs
          .map((snapshot) => _buildListItem(context, snapshot))
          .toList(),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Stream<DocumentSnapshot> snapshot,
  ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: snapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data.data == null)
          return Center(child: CircularProgressIndicator());

        var bottle = Bottle.fromSnapshot(snapshot.data);

        return BottleListItem(
          bottle: bottle,
          overrideOwnerName:
              Auctions().getAuctionByReference(bottle.auctionReference).name,
        );
      },
    );
  }

  Widget _getBody() => Wrap(
        children: [
          Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.center,
                        child: Hero(
                          tag: _owner.name,
                          child: Container(
                            decoration: BoxDecoration(shape: BoxShape.circle,
                                // BoxShape.circle or BoxShape.retangle
                                //color: const Color(0xFF66BB6A),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade700,
                                    blurRadius: 5.0,
                                  ),
                                ]),
                            margin: EdgeInsets.only(top: 10),
                            height: 80,
                            width: 80,
                            child: OvalContainer(
                              padding: 3,
                              child: _owner.getAvatar(context),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: _backButton(),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.all(20),
                    child: Text(
                      _owner.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _info(
                        value: kGBP_SIGN + _owner.investment.toString(),
                        title: 'Investment',
                        icon: Icon(
                          FontAwesomeIcons.poundSign,
                          color: Colors.greenAccent,
                          size: 25,
                        ),
                        iconColor: Colors.greenAccent.withAlpha(64),
                      ),
                      _info(
                        value: _owner.bottles.length.toString(),
                        title: 'Bottles',
                        icon: Icon(
                          FontAwesomeIcons.wineBottle,
                          color: Colors.cyanAccent,
                          size: 25,
                        ),
                        iconColor: Colors.cyanAccent.withAlpha(64),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.all(15),
                    child: Text(
                      'Withdrawls',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    elevation: 3.0,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 8.0, right: 8, top: 8, bottom: 36),
                        child: _withdrawlsContent()),
                  ),
                  Container(
                    height: 28,
                  ),
                ],
              ),
              Positioned.fill(
                child: new LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  return SizedBox(
                    width: constraints.maxWidth - (8 * 2),
                    height: constraints.maxHeight - (36 * 2),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          dialogOpened = !dialogOpened;
                        });
                      },
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 100,
                          maxHeight: 100,
                        ),
                        child: Container(color: Colors.red),
                      ),
                    ),
                  );
//                  return Positioned(
//                    bottom: 8,
//                    right: 36,
//                    child: AnimatedContainer(
//                      color: Colors.red,
//                      duration: Duration(seconds: 2),
//                      width:
//                          dialogOpened ? constraints.maxWidth - (8 * 2) : 100,
//                      height:
//                          dialogOpened ? constraints.maxHeight - (36 * 2) : 100,
//                    ),
//                  );
                }),
              ),
//              WithdrawlDialog(),
            ],
          )
        ],
      );

  Widget _backButton() => InkWell(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(
            CupertinoIcons.back,
            size: 30,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      );

  Widget _info({String value, String title, Icon icon, Color iconColor}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            child: OvalContainer(
              color: iconColor,
              child: icon,
              padding: 10,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 15),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: Text(
              title,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          )
        ],
      );

  Widget _withdrawlButton() => FloatingActionButton.extended(
        elevation: 10,
        backgroundColor: Colors.white,
        label: Text(
          'Withdraw',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).cardColor,
          ),
        ),
        icon: Icon(
          FontAwesomeIcons.moneyCheckAlt,
          color: Theme.of(context).cardColor,
        ),
        onPressed: () {
          setState(() {
            dialogOpened = !dialogOpened;
          });
        },
      );

  Widget _withdrawlsContent() => _owner.withdrawls.isEmpty
      ? Container(
          child: Text(
            'No withdrawls',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _owner.withdrawls
              .map(
                (item) => Container(
                  margin: EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        '$kGBP_SIGN${item.amount}',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ' @ ${item.date.prettify()}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
}

class WithdrawlDialog extends StatefulWidget {
  @override
  _WithdrawlDialogState createState() => _WithdrawlDialogState();
}

class _WithdrawlDialogState extends State<WithdrawlDialog>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: FlutterLogo(size: 150.0),
      ),
    );
  }
}
