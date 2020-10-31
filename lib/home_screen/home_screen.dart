import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:islay_foundation/add_auction/add_auction_screen.dart';
import 'package:islay_foundation/auction_screen/auction_screen.dart';
import 'package:islay_foundation/home_screen/auction_card.dart';
import 'package:islay_foundation/model/auction.dart';
import 'package:islay_foundation/my_app_bar.dart';
import 'package:islay_foundation/owner_screen/owner_screen.dart';
import 'package:islay_foundation/repo/auctioneers.dart';
import 'package:islay_foundation/repo/auctions.dart';
import 'package:islay_foundation/repo/owners.dart';
import 'package:islay_foundation/widgets/oval_container.dart';

import '../Header.dart';

class HomeScreen extends StatefulWidget {
  static const SCREEN_NAME = '/';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var loading = true;

  _HomeScreenState() {
    final onLoaded = () {
      if (Owners().ready() && Auctioneers().ready()) {
        setState(() {
          loading = false;
        });
      }
    };
    Auctioneers().init(onLoaded);
    Owners().init(onLoaded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: loading ? _buildLoading() : _buildMainScreenBody(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AddAuctionScreen.SCREEN_NAME);
        },
        child: SvgPicture.asset(
          'assets/add_auction.svg',
          height: 36,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildMainScreenBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        _owners(),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('auctions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        var auctions = snapshot.data.documents.map((data) {
          final auction = Auction.fromSnapshot(data);
          return auction;
        }).toList();
        Auctions().recalc(auctions);
        if (!Auctions().ready()) return CircularProgressIndicator();
        return Header(
          title: 'Total Portfolio',
          investment:
              Auctions().totalInvestment - (Owners().getById('POT').investment),
          returnOnInvestment:
              Auctions().totalReturn - (Owners().getById('POT').investment),
          revenue: Auctions().totalRevenue,
        );
      },
    );
  }

  Widget _owners() => Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: Owners()
              .owners
              .map(
                (owner) => InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, OwnerScreen.SCREEN_NAME,
                        arguments: owner);
                  },
                  child: Hero(
                    tag: owner.name,
                    child: Container(
                      width: 50,
                      height: 50,
                      child: OvalContainer(
                        child: owner.getAvatar(context),
                        padding: 2,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('auctions')
          .orderBy('endDate')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: Container(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(),
            ),
          );
        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    snapshot.add(null);
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    if (data == null)
      return SizedBox(
        height: 80,
      );

    final auction = Auction.fromSnapshot(data);

    return AuctionCard(
      auction: auction,
      onTap: () {
        _viewAuction(context, auction);
      },
    );
  }

  void _viewAuction(BuildContext context, Auction auction) {
    Navigator.pushNamed(context, AuctionScreen.SCREEN_NAME, arguments: auction);
  }
}
