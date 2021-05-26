import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PopupAlert extends StatelessWidget {

  final String text;
  final double w;
  const PopupAlert({Key key, this.text, this.w}): super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: w - 10,
          padding: EdgeInsets.fromLTRB(10, 5, 0, 5), 
          child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 3),
        ),
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.fromLTRB(10, 5, 0, 5),
          child: ElevatedButton(
            onPressed: () => {
              _onPressedOkButton(context)
            }, 
            child: Text("Ок")
          )
        ),
      ],
    );
  }

  void _onPressedOkButton(context) {

    Navigator.pop(context);
  }

}