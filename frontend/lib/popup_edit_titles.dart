import 'package:flutter/material.dart';
import 'short_long_name.dart';

class PopupEditTitles extends StatefulWidget {

  final Function(ShortLongName) listener;
  final ShortLongName title;
  const PopupEditTitles({Key key, this.listener, this.title}): super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _PopupEditTitlesState(listener: listener, title: title);
  } 

} 

class _PopupEditTitlesState extends State<PopupEditTitles>{

  final Function(ShortLongName) listener;
  ShortLongName title;
  ShortLongName newTitle;

  TextEditingController _controllerShort;
  TextEditingController _controllerLong;
  _PopupEditTitlesState({this.listener, this.title}): super() {
    newTitle = ShortLongName.full(title.longName, title.shortName, title.id);
    _controllerLong = TextEditingController.fromValue(new TextEditingValue(text: newTitle.longName));
    _controllerShort = TextEditingController.fromValue(new TextEditingValue(text: newTitle.shortName));

    
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(10, 5, 0, 5), 
          child: Text("Полное название", style: TextStyle(fontSize: 16) )
        ),
        getTextField(0),
        Container(
          padding: EdgeInsets.fromLTRB(10, 5, 0, 5), 
          child: Text("Сокращенное название", style: TextStyle(fontSize: 16)),
        ),
        getTextField(1),
        Row(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.fromLTRB(10, 5, 0, 5),
              child: ElevatedButton(
                onPressed: _onPressedSaveButton, 
                child: Text("Сохранить")
              )
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.red, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: _onPressedSaveButton, 
                child: Text("Удалить")
              )
            ),
          ],
        )
        
        
      ],

    );
  }

  Widget getTextField(int type){ //0 - поле полного названия, 1 - короткого
    return Container(
      child:
        TextField(
          onChanged: (String newVal) {
            setState(() {
              if (type == 0)
                newTitle.longName = newVal;
              else
                newTitle.shortName = newVal;
            });
          },
          controller: type == 0? _controllerLong : _controllerShort,
          maxLength: type == 0? 70 : 10,
          decoration: InputDecoration(
            hintText: 'Введите название...',
            contentPadding:
                EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            //border: OutlineInputBorder(
            //  borderRadius: BorderRadius.all(Radius.circular(32.0)),
            //),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Colors.lightBlueAccent, width: 1.0),
              //borderRadius: BorderRadius.all(Radius.circular(32.0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Colors.lightBlueAccent, width: 2.0),
              //borderRadius: BorderRadius.all(Radius.circular(32.0)),
            ),
          ),
        ),
    );
  }

  @override
  void dispose() {
    _controllerLong.dispose();
    _controllerShort.dispose();
    super.dispose();
  }

  void _onPressedSaveButton() {

    listener(newTitle);
    Navigator.pop(context);
  }
}