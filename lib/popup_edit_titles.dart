import 'package:flutter/material.dart';

class PopupEditTitles extends StatelessWidget {

  final Function(String) listener;
  const PopupEditTitles({Key key, this.listener}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(listener("a")),

    );
  }
}