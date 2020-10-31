import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:islay_foundation/constants.dart';
import 'package:islay_foundation/model/auction.dart';
import 'package:islay_foundation/utils.dart';
import 'package:islay_foundation/widgets/investment_result.dart';

class AuctionCard extends StatelessWidget {
  final Auction auction;
  final Function onTap;

  AuctionCard({this.auction, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 3.0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${auction.startDate.prettify()} - ${auction.endDate.prettify()}',
                style: kAuctionDateStyle,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    auction.auctioneer.name,
                    style: kAuctionNameStyle,
                  ),
                  Text(
                    '(${auction.name})',
                    style: kAuctionSubNameStyle,
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Text(
                    kGBP_SIGN + auction.investmentInGBP.toString(),
                    style: kInvestedAmountStyle,
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Expanded(
                    child: getAuctionData(
                        SvgPicture.asset(
                          'assets/bottle_full.svg',
//                          color: kAccentColor,
                          height: 18,
                        ),
                        "${auction.bottles.length} Bottles"),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Expanded(
                    child: auction.dataReady
                        ? InvestmentResult(
                            revenue: auction.revenueInGBP,
                          )
                        : CircularProgressIndicator(),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getAuctionData(Widget icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          icon,
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      );
}
