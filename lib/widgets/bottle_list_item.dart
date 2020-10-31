import 'package:flutter/material.dart';
import 'package:islay_foundation/model/bottle.dart';

import '../constants.dart';

const _ownerNameTextStyle = TextStyle(
  color: Colors.grey,
  fontStyle: FontStyle.italic,
  fontSize: 15,
);

class BottleListItem extends StatelessWidget {
  final Bottle bottle;
  var _editMode = false;
  final ValueChanged<num> onSoldEdited;
  final Function onNext;
  final FocusNode focusNode;
  final String overrideOwnerName;
  double height;

  BottleListItem({
    @required this.bottle,
    this.onSoldEdited,
    this.onNext,
    this.focusNode,
    this.overrideOwnerName,
  }) {
    _editMode = this.onSoldEdited != null;
    this.height = _editMode ? 60 : 45;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  bottle.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                overrideOwnerName != null
                    ? overrideOwnerName
                    : bottle.owner.name,
                style: _ownerNameTextStyle,
              ),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          AnimatedContainer(
            height: height,
            duration: Duration(milliseconds: 300),
            child: _editMode
                ? TextFormField(
                    initialValue: bottle.sold != null && bottle.sold > 0
                        ? bottle.sold.toString()
                        : "",
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Sold'),
                    onChanged: (value) {
                      onSoldEdited(double.parse(value));
                    },
                    onFieldSubmitted: (value) {
                      onNext();
                    },
                    focusNode: focusNode,
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _getInfoField(
                                'Cost:', kGBP_SIGN + bottle.cost.toString()),
                            bottle.sold == null
                                ? Container()
                                : (bottle.reserve != null &&
                                        bottle.reserve > 0 &&
                                        bottle.sold == 0)
                                    ? Text(
                                        'Failed to meet reserve',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.redAccent,
                                        ),
                                      )
                                    : _getInfoField('Sold:',
                                        kGBP_SIGN + bottle.sold.toString()),
                          ],
                        ),
                      ),
                      Text(
                        (bottle.revenue != null && bottle.revenue > 0
                                ? "+"
                                : "") +
                            (bottle.revenue ?? 0).toString(),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: bottle.revenue == null || bottle.revenue == 0
                              ? kColorEven
                              : bottle.revenue > 0 ? kColorProfit : kColorLoss,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _getInfoField(String key, String value) => Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
//        textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              key,
              style: kInfoKeyTextStyle,
            ),
            SizedBox(
              width: 5,
            ),
            value != null
                ? Text(
                    value,
                    style: kInfoValueTextStyle,
                  )
                : CircularProgressIndicator(),
          ],
        ),
      );
}
