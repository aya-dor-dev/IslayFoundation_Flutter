import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:islay_foundation/widgets/investment_progress.dart';

import 'constants.dart';

const _overAllTextStyle = TextStyle(
  fontSize: 30,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

final _revenueTextStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold,
);
final _profitTextStyle = _revenueTextStyle.copyWith(color: kColorProfit);
final _lossTextStyle = _revenueTextStyle.copyWith(color: kColorLoss);
final _evenTextStyle = _revenueTextStyle.copyWith(color: kColorEven);

class Header extends StatelessWidget {
  final String title;
  final num investment;
  final num returnOnInvestment;
  final num revenue;

  Header(
      {@required this.title,
      @required this.investment,
      @required this.returnOnInvestment,
      @required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: kInfoKeyTextStyle,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Icon(
                    FontAwesomeIcons.poundSign,
                    color: Colors.white,
                    size: 14,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        returnOnInvestment.toString(),
                        style: _overAllTextStyle,
                      ),
                      Text(
                        '($investment)',
                        style: kInfoKeyTextStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 5,
              ),
              child: InvestmentProgress(
                investment: investment,
                returnOnInvestment: returnOnInvestment,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Icon(
                  FontAwesomeIcons.poundSign,
                  color: revenue == 0
                      ? kColorEven
                      : revenue > 0 ? kColorProfit : kColorLoss,
                  size: 10,
                ),
                Text(
                  NumberFormat.compact().format(revenue.abs()),
                  style: revenue == 0
                      ? _evenTextStyle
                      : revenue > 0 ? _profitTextStyle : _lossTextStyle,
                ),
                SizedBox(
                  width: 2,
                ),
                Text(
                  (revenue == 0) ? 'even' : (revenue > 0) ? 'revenue' : 'loss',
                  style: kInfoKeyTextStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
