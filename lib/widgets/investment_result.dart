import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:islay_foundation/constants.dart';

class InvestmentResult extends StatelessWidget {
  final num investment;
  final num returnOnInvestment;
  num revenue;

  InvestmentResult({this.investment, this.returnOnInvestment, this.revenue}) {
    if (revenue == null) {
      revenue = returnOnInvestment - investment;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey;
    if (revenue > 0) {
      bg = Colors.greenAccent.shade400;
    } else if (revenue < 0) {
      bg = Colors.redAccent.shade400;
    }
    return new Container(
      padding: EdgeInsets.all(4),
      decoration: new BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(
            kGBP_SIGN +
                NumberFormat.compact().format((revenue).abs()).toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(
            width: 5,
          )
        ],
      ),
    );
  }
}
