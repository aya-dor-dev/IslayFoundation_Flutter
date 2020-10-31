import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:islay_foundation/model/auction.dart';
import 'package:islay_foundation/model/auctioneer.dart';
import 'package:islay_foundation/repo/auctioneers.dart';
import 'package:islay_foundation/utils.dart';
import 'package:islay_foundation/widgets/save_fab.dart';
import 'package:progress_dialog/progress_dialog.dart';

class AddAuctionScreen extends StatefulWidget {
  static const SCREEN_NAME = '/add_auction';

  @override
  _AddAuctionScreenState createState() => _AddAuctionScreenState();
}

class _AddAuctionScreenState extends State<AddAuctionScreen> {
  final _formKey = GlobalKey<FormState>();

  Auction _auction;

  @override
  Widget build(BuildContext context) {
    if (_auction == null) {
      _auction = ModalRoute.of(context).settings.arguments;

      if (_auction == null) {
        Timestamp endDate = Timestamp.fromDate(DateTime.now());
        Timestamp startDate = Timestamp.fromDate(
            DateTime.now().subtract(Auctioneers().auctioneers.first.duration));
        _auction = Auction("",
            auctioneer: Auctioneers().auctioneers.first,
            bottles: [],
            endDate: endDate,
            startDate: startDate);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('New Auction'),
      ),
      floatingActionButton: SaveFab(
        onPressed: () {
          context.hideKeyboard();
          if (_formKey.currentState.validate()) {
            _showSaveDialog();
          }
        },
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Auctioneer',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                AuctioneerStep(
                  selected: _auction.auctioneer,
                  onChange: (auctioneer) {
                    setState(() {
                      _auction.auctioneer = auctioneer;
                    });
                  },
                ),
                TextFormField(
                  initialValue: _auction.name,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: 'Auction Name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please fill in auction name';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _auction.name = value;
                    });
                  },
                  onFieldSubmitted: (value) {
                    context.hideKeyboard();
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  'End Date',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 30),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        _auction.startDate.prettify() + " - ",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        _auction.endDate.prettify(),
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      FlatButton(
                        child: Icon(FontAwesomeIcons.calendarAlt),
                        onPressed: () {
                          context.hideKeyboard();
                          _showDatePicker().then(
                            (date) {
                              if (date != null) {
                                setState(() {
                                  _auction.endDate = Timestamp.fromDate(date);
                                  _auction.startDate = Timestamp.fromDate(date
                                      .subtract(_auction.auctioneer.duration));
                                });
                              }
                            },
                          );
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<DateTime> _showDatePicker() {
    return showDatePicker(
      context: context,
      initialDate: _auction.endDate.toDate(),
      firstDate: DateTime(2018),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget child) {
        return Theme(
          data: ThemeData.dark(),
          child: child,
        );
      },
    );
  }

  void _showSaveDialog() {
    AwesomeDialog(
        context: context,
        dialogType: DialogType.INFO,
        animType: AnimType.BOTTOMSLIDE,
        tittle: 'Save Auction',
        desc: '${_auction.name} @ ${_auction.auctioneer.name}.\n'
            'Between ${_auction.startDate.prettify()} - ${_auction.endDate.prettify()}',
        btnCancelOnPress: () {},
        btnOkOnPress: () {
          _saveAuction(_auction);
        }).show();
  }

  void _saveAuction(Auction auction) {
    ProgressDialog pd = ProgressDialog(context, isDismissible: false);
    pd.style(message: 'Saving Auction...');
    pd.show();
    Firestore.instance.collection('auctions').add(auction.toMap()).then((dr) {
      pd.dismiss();
      _auctionSavedSuccess();
    }, onError: (exception) {
      pd.dismiss();
      _auctionSaveFail();
    });
  }

  void _auctionSavedSuccess() {
    AwesomeDialog(
        context: context,
        dialogType: DialogType.SUCCES,
        animType: AnimType.BOTTOMSLIDE,
        tittle: 'Auction Saved!',
        desc: 'Auction ${_auction.name} @ ${_auction.auctioneer.name}.\n'
            'Between ${_auction.startDate.prettify()} - ${_auction.endDate.prettify()}',
        btnCancel: null,
        btnOkOnPress: () {
          Navigator.pop(context);
        }).show();
  }

  void _auctionSaveFail() {
    AwesomeDialog(
            context: context,
            dialogType: DialogType.ERROR,
            animType: AnimType.BOTTOMSLIDE,
            tittle: 'Oops!',
            desc: 'Unable to save auction at the moment\n'
                'Please try again later.',
            btnCancel: null,
            btnOkOnPress: () {})
        .show();
  }
}

class AuctioneerStep extends StatelessWidget {
  final Auctioneer selected;
  final ValueChanged<Auctioneer> onChange;

  AuctioneerStep({@required this.selected, @required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Auctioneers()
          .auctioneers
          .map((auctioneer) => Container(
                padding: EdgeInsets.all(5),
                child: RadioListTile<Auctioneer>(
                  value: auctioneer,
                  groupValue: selected,
                  onChanged: (index) {
                    this.onChange(auctioneer);
                  },
                  title: Text(auctioneer.name),
                ),
              ))
          .toList(),
    );
  }
}
