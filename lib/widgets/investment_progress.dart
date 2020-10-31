import 'package:flutter/material.dart';

class InvestmentProgress extends StatelessWidget {
  final num investment;
  final num returnOnInvestment;
  double height;

  InvestmentProgress(
      {@required this.investment, this.returnOnInvestment, this.height = 15});

  @override
  Widget build(BuildContext context) {
    int coveredRatio = returnOnInvestment.toInt();
    int uncoveredRatio = (investment - returnOnInvestment).toInt();
    final fillColors = returnOnInvestment == investment
        ? [
            Colors.grey,
            Colors.grey.shade400,
            Colors.grey.shade700,
          ]
        : [
            Colors.greenAccent,
            Colors.greenAccent.shade400,
            Colors.greenAccent.shade700,
          ];

    if (returnOnInvestment >= investment) {
      coveredRatio = 1;
      uncoveredRatio = 0;
    }
    var border = BorderSide(color: Colors.grey.shade100);
    return Container(
      height: this.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.redAccent,
            Colors.redAccent.shade400,
          ],
        ),
        border:
            Border(left: border, right: border, top: border, bottom: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: coveredRatio,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: fillColors,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Expanded(
            flex: uncoveredRatio,
            child: Container(),
          )
        ],
      ),
    );
  }
}
