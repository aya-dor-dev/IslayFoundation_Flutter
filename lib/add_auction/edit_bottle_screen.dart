import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:islay_foundation/api.dart' as api;
import 'package:islay_foundation/model/auction.dart';
import 'package:islay_foundation/model/bottle.dart';
import 'package:islay_foundation/model/owner.dart';
import 'package:islay_foundation/repo/owners.dart';
import 'package:islay_foundation/utils.dart';
import 'package:islay_foundation/widgets/save_fab.dart';
import 'package:progress_dialog/progress_dialog.dart';

const STEP_BOTTLE_NAME = 0;
const STEP_OWNER = 1;
const STEP_COST = 2;
const STEP_RESERVE = 3;
const STEP_SOLD = 4;

class BottleScreenArguments {
  Auction auction;
  Bottle bottle;

  BottleScreenArguments(this.auction, {this.bottle});
}

class EditBottleScreen extends StatefulWidget {
  static const SCREEN_NAME = '/edit_bottle';

  @override
  _EditBottleScreenState createState() => _EditBottleScreenState();
}

class _EditBottleScreenState extends State<EditBottleScreen> {
  var isUpdating = false;
  final _formKey = GlobalKey<FormState>();
  int _currentStep = STEP_BOTTLE_NAME;

  Auction _auction;
  Bottle _bottle;
  TextEditingController bottleNameController;

  final nameNode = FocusNode();
  final costNode = FocusNode();
  final reserveNode = FocusNode();
  List<String> options = [];

  @override
  Widget build(BuildContext context) {
    if (_bottle == null && _auction == null) {
      BottleScreenArguments args = ModalRoute.of(context).settings.arguments;
      _auction = args.auction;
      isUpdating = args.bottle != null;
      _bottle =
          args.bottle ?? Bottle("", owner: Owners().owners.first, cost: 0);
    }

    if (bottleNameController == null) {
      bottleNameController = TextEditingController(text: _bottle.name);
      bottleNameController.selection = TextSelection.fromPosition(
        TextPosition(
          offset: bottleNameController.text.length,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('New Bottle'),
      ),
      floatingActionButton: SaveFab(
        onPressed: () {
          if (_formKey.currentState.validate()) {
            context.hideKeyboard();
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
                TypeAheadFormField(
                  textFieldConfiguration: TextFieldConfiguration(
                      focusNode: nameNode,
                      controller: bottleNameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (value) {
                        costNode.requestFocus();
                      }),
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Name cannot be empty";
                    }
                    return null;
                  },
                  suggestionsCallback: (q) async {
                    final prevQ = _bottle.name;
                    _bottle.name = q;
                    if (q.isNotEmpty &&
                        prevQ.isNotEmpty &&
                        q.startsWith(prevQ)) {
                      List<String> newList = [];
                      options.forEach((option) {
                        if (option.toLowerCase().contains(q.toLowerCase())) {
                          newList.add(option);
                        }
                      });
                      options = newList;
                    } else if (q.isNotEmpty) {
                      options = [];
                      var res = await api.getAutoComplete(q);
                      var decoded =
                          json.decode(res.body, reviver: (key, value) {
                        if (value is String) options.add(value);
                      });
                    } else {
                      options = [];
                    }
                    return options.isEmpty ? null : options;
                  },
                  itemBuilder: (context, suggestion) {
                    return Container(
                      padding: EdgeInsets.all(15),
                      child: Text(suggestion),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    _bottle.name = suggestion;
                    bottleNameController.text = suggestion;
                    nameNode.unfocus();
                    costNode.requestFocus();
                  },
                ),
                TextFormField(
                  initialValue: _bottle.cost != null && _bottle.cost > 0
                      ? _bottle.cost.toString()
                      : "",
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'Cost'),
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  focusNode: costNode,
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Cost cannot be empty";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _bottle.cost = value.isEmpty ? null : double.parse(value);
                    });
                  },
                  onFieldSubmitted: (value) {
                    costNode.unfocus();
                    reserveNode.requestFocus();
                  },
                ),
                TextFormField(
                  initialValue: _bottle.reserve != null && _bottle.reserve > 0
                      ? _bottle.reserve.toString()
                      : "",
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                      hintText: 'No reserve', labelText: 'Reserve'),
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  focusNode: reserveNode,
                  onChanged: (value) {
                    setState(() {
                      _bottle.reserve =
                          value.isEmpty ? null : double.parse(value);
                    });
                  },
                  onFieldSubmitted: (value) {
                    reserveNode.unfocus();
                  },
                ),
                SizedBox(
                  height: 30,
                ),
                Text(
                  'Owner',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                OwnerStep(
                  selected: _bottle.owner,
                  onChange: (owner) {
                    setState(() {
                      _bottle.owner = owner;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canContinue() {
    switch (_currentStep) {
      case STEP_BOTTLE_NAME:
        return _bottle.name.isNotEmpty;
      case STEP_OWNER:
        return _bottle.owner != null;
      case STEP_COST:
        return (_bottle.cost ?? 0) > 0;
      default:
        return true;
    }
  }

  void _showSaveDialog() {
    AwesomeDialog(
        context: context,
        dialogType: DialogType.INFO,
        animType: AnimType.BOTTOMSLIDE,
        tittle: 'Save Bottle',
        desc: _dialogDescription(),
        btnCancelOnPress: () {},
        btnOkOnPress: () {
          _saveBottle();
        }).show();
  }

  void _saveBottle() async {
    ProgressDialog pd = ProgressDialog(context, isDismissible: false);
    pd.style(message: 'Saving Bottle...');
    pd.show();
    _bottle.auction = _auction;

    try {
      if (_bottle.reference != null)
        await _bottle.reference.updateData(_bottle.toMap());
      else
        await Firestore.instance.collection('bottles').add(_bottle.toMap());

      pd.dismiss();
      _bottleSavedSuccess();
    } catch (exception) {
      pd.dismiss();
      _bottleSaveFail();
    }
  }

  void _bottleSavedSuccess() {
    final dialog = isUpdating
        ? AwesomeDialog(
            context: context,
            dialogType: DialogType.SUCCES,
            animType: AnimType.BOTTOMSLIDE,
            tittle: 'Bottle Updated!',
            desc: _dialogDescription(),
            btnCancel: null,
            btnOkText: 'Close',
            btnOkOnPress: () {
              Navigator.pop(context);
            })
        : AwesomeDialog(
            context: context,
            dialogType: DialogType.SUCCES,
            animType: AnimType.BOTTOMSLIDE,
            tittle: 'Bottle Saved!',
            desc: _dialogDescription(),
            btnCancelText: 'Add Another',
            btnCancelOnPress: () {
              _restart();
            },
            btnOkText: 'Close',
            btnOkOnPress: () {
              Navigator.pop(context);
            });

    dialog.show();
  }

  void _restart() {
    setState(() {
      bottleNameController = null;
      _bottle = Bottle('', owner: _bottle.owner, cost: 0);
      nameNode.requestFocus();
    });
  }

  void _bottleSaveFail() {
    AwesomeDialog(
            context: context,
            dialogType: DialogType.ERROR,
            animType: AnimType.BOTTOMSLIDE,
            tittle: 'Oops!',
            desc: 'Unable to save bottle at the moment\n'
                'Please try again later.',
            btnCancel: null,
            btnOkOnPress: () {})
        .show();
  }

  String _dialogDescription() =>
      '${_bottle.name}.\n' +
      'Bought for ${_bottle.cost} and will be sold @ ${_auction.toString()}';
}

class Actions extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onStepContinue;
  final String text;

  Actions(
      {@required this.onStepContinue,
      this.text = 'CONTINUE',
      this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      child: FlatButton(
        child: Text(text),
        onPressed: isEnabled
            ? () {
                onStepContinue();
              }
            : null,
      ),
    );
  }
}

class OwnerStep extends StatelessWidget {
  final Owner selected;
  final ValueChanged<Owner> onChange;

  OwnerStep({@required this.selected, @required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Owners()
          .owners
          .map(
            (owner) => GestureDetector(
              onTap: () {
                this.onChange(owner);
              },
              child: Container(
                padding: EdgeInsets.all(5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: RadioListTile<Owner>(
                        value: owner,
                        groupValue: selected,
                        onChanged: (index) {
                          this.onChange(owner);
                        },
                        title: Text(owner.name),
                      ),
                    ),
                    Container(
                      child: owner.getAvatar(context),
                      padding: const EdgeInsets.all(1.0),
                      decoration: new BoxDecoration(
                        color: owner.imageUrl != null
                            ? const Color(0xFFFFFFFF)
                            : Colors.transparent, // border color
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

//child: Container(
//child: Stepper(
//onStepTapped: (index) {
//setState(() {
//if (_canContinue() || index < _currentStep) {
//_currentStep = index;
//context.hideKeyboard();
//}
//});
//},
//onStepContinue: () {
//if (_canContinue()) {
//context.hideKeyboard();
//if (_currentStep == STEP_SOLD) {
//_showSaveDialog();
//} else {
//setState(() {
//_currentStep++;
//});
//}
//}
//},
//controlsBuilder: (BuildContext context,
//{VoidCallback onStepContinue, VoidCallback onStepCancel}) =>
//Actions(
//text: _currentStep == STEP_SOLD ? 'FINISH' : 'CONTINUE',
//onStepContinue: onStepContinue,
//isEnabled: _canContinue(),
//),
//currentStep: _currentStep,
//steps: [
//Step(
//title: Text("Bottle Name"),
//subtitle: _bottle.name.isNotEmpty ? Text(_bottle.name) : null,
//content: Container(
//child: TextFormField(
//focusNode: nameNode,
//textCapitalization: TextCapitalization.words,
//initialValue: _bottle.name,
//decoration: InputDecoration(labelText: 'Bottle name'),
//onChanged: (text) {
//setState(() {
//_bottle.name = text;
//});
//},
//textInputAction: TextInputAction.next,
//onFieldSubmitted: (value) {
//if (value.isEmpty) return;
//setState(() {
//context.hideKeyboard();
//nameNode.unfocus();
//_currentStep++;
//});
//},
//),
//),
//state:
//_bottle.name.isEmpty ? StepState.error : StepState.complete,
//),
//Step(
//title: Text('Owner'),
//subtitle: Text(_bottle.owner.name),
//content: OwnerStep(
//selected: _bottle.owner,
//onChange: (owner) {
//setState(() {
//_bottle.owner = owner;
//});
//},
//),
//state: _bottle.owner != null
//? StepState.complete
//    : StepState.error,
//),
//Step(
//title: Text("Cost"),
//subtitle: (_bottle.cost ?? 0) > 0
//? Text(_bottle.cost.toString())
//: null,
//content: Container(
//child: Row(
//crossAxisAlignment: CrossAxisAlignment.baseline,
//textBaseline: TextBaseline.alphabetic,
//children: <Widget>[
//Icon(
//FontAwesomeIcons.poundSign,
//size: 18,
//),
//SizedBox(
//width: 5,
//),
//Expanded(
//child: TextFormField(
//focusNode: costNode,
//initialValue: (_bottle.cost ?? 0) == 0
//? ""
//: _bottle.cost.toString(),
//decoration: InputDecoration(labelText: 'Cost'),
//textInputAction: TextInputAction.next,
//onFieldSubmitted: (value) {
//if (value.isEmpty) return;
//context.hideKeyboard();
//setState(() {
//_currentStep++;
//FocusScope.of(context).requestFocus(reserveNode);
//});
//},
//keyboardType: TextInputType.numberWithOptions(
//decimal: true,
//),
//onChanged: (text) {
//setState(() {
//if (text.isNotEmpty) {
//_bottle.cost = double.parse(text);
//} else {
//_bottle.cost = null;
//}
//});
//},
//),
//),
//],
//),
//),
//state: (_bottle.cost == null || _bottle.cost == 0)
//? StepState.error
//    : StepState.complete,
//),
//Step(
//title: Text("Reserve"),
//subtitle: (_bottle.reserve ?? 0) > 0
//? Text(_bottle.reserve.toString())
//: Text('None'),
//content: Container(
//child: Row(
//crossAxisAlignment: CrossAxisAlignment.baseline,
//textBaseline: TextBaseline.alphabetic,
//children: <Widget>[
//Icon(
//FontAwesomeIcons.poundSign,
//size: 18,
//),
//SizedBox(
//width: 5,
//),
//Expanded(
//child: TextFormField(
//textInputAction: TextInputAction.next,
//onFieldSubmitted: (value) {
//if (value.isEmpty) return;
//
//context.hideKeyboard();
//setState(() {
//_currentStep++;
//FocusScope.of(context).requestFocus(soldNode);
//});
//},
//initialValue: (_bottle.reserve ?? 0) == 0
//? ""
//: _bottle.reserve.toString(),
//decoration: InputDecoration(labelText: 'No reserve'),
//keyboardType: TextInputType.numberWithOptions(
//decimal: true,
//),
//onChanged: (text) {
//setState(() {
//if (text.isNotEmpty) {
//_bottle.reserve = double.parse(text);
//} else {
//_bottle.reserve = null;
//}
//});
//},
//),
//),
//],
//),
//),
//),
//Step(
//title: Text("Sold"),
//subtitle: (_bottle.sold != null)
//? Text(_bottle.sold.toString())
//: Text('Not sold'),
//content: Container(
//child: Row(
//crossAxisAlignment: CrossAxisAlignment.baseline,
//textBaseline: TextBaseline.alphabetic,
//children: <Widget>[
//Icon(
//FontAwesomeIcons.poundSign,
//size: 18,
//),
//SizedBox(
//width: 5,
//),
//Expanded(
//child: TextFormField(
//textInputAction: TextInputAction.done,
//onFieldSubmitted: (value) {
//if (value.isEmpty) return;
//
//context.hideKeyboard();
//setState(() {
//_saveBottle();
//});
//},
//initialValue: (_bottle.sold == null)
//? ""
//: _bottle.sold.toString(),
//decoration: InputDecoration(labelText: 'Sold'),
//keyboardType: TextInputType.numberWithOptions(
//decimal: true,
//),
//onChanged: (text) {
//setState(() {
//if (text.isNotEmpty) {
//_bottle.sold = double.parse(text);
//} else {
//_bottle.sold = null;
//}
//});
//},
//),
//),
//],
//),
//),
//),
//],
//),
//),
