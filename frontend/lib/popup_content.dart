import 'package:flutter/material.dart';
import 'popup.dart';


class PopupContent extends StatefulWidget {
  final Widget content;

  PopupContent({
    Key key,
    this.content,
  }) : super(key: key);

  _PopupContentState createState() => _PopupContentState();
}

class _PopupContentState extends State<PopupContent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.content,
    );
  }
}

showPopup(BuildContext context, Widget widget, String title,
    {double width, double height, bool needBackButton=true, BuildContext popupContext}) {
      print(needBackButton);
  Navigator.push(
    context,
    PopupLayout(
      width: width,
      height: height,
      top: 30,
      left: 30,
      right: 30,
      bottom: 50,
      child: PopupContent(
        content: Scaffold(
          appBar: AppBar(
            title: Text(title),
            automaticallyImplyLeading: false,
            leading: needBackButton? new Builder(builder: (context) {
              return IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  try {
                    Navigator.pop(context); //close the popup
                  } catch (e) {}
                },
              );
            }) : null,
            brightness: Brightness.light,
          ),
          //resizeToAvoidBottomInset: false,
          body: widget,
        ),
      ),
    ),
  );
}