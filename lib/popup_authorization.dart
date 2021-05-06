import 'package:flutter/material.dart';

class PopupAuthorization extends StatefulWidget {

  final Function(String, String) listener;
  //final String login = "";
  //final String pass = "";
  const PopupAuthorization({Key key, this.listener}): super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _PopupAuthorizationState(listener: listener);
  }
}

class _PopupAuthorizationState extends State<PopupAuthorization>{

  final Function(String, String) listener;
  String login;
  String pass;

  _PopupAuthorizationState({this.listener}): super() {
    login = "";
    pass = "";
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          child:
            TextField(
              controller: TextEditingController.fromValue(new TextEditingValue(text: login)), //default value
              decoration: InputDecoration(
                hintText: 'Введите логин...',
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

              onChanged: (String newValue) {
                setState(() {
                  login = newValue;
                });
              },

            ),
            
        ),
        Container(
          child: TextField(
              controller: TextEditingController.fromValue(new TextEditingValue(text: pass)), //default value
              decoration: InputDecoration(
                hintText: 'Введите пароль...',
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
              onChanged: (String newValue) {
                setState(() {
                  pass = newValue;
                });
              },
            ),
        ),
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.all(10),
          child: ElevatedButton(
            onPressed: _onPressedSaveButton, 
            child: Text("Войти")
          )
        ),
        
      ],

    );
  }

    void _onPressedSaveButton(){
    listener(login, pass);
    Navigator.pop(context);
  }

}