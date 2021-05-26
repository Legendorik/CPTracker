import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PopupAuthorization extends StatefulWidget {

  final Function(String) listener;
  //final String login = "";
  //final String pass = "";
  const PopupAuthorization({Key key, this.listener}): super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _PopupAuthorizationState(listener: listener);
  }
}

class _PopupAuthorizationState extends State<PopupAuthorization>{

  final Function(String) listener;
  String _login;
  String _pass;
  String _token;
  TextEditingController _controllerLogin;
  TextEditingController _controllerPass;
  _PopupAuthorizationState({this.listener}): super() {
    _login = "mukhamux";
    _pass = "secret";
    _controllerLogin = TextEditingController.fromValue(new TextEditingValue(text: _login));
    _controllerPass = TextEditingController.fromValue(new TextEditingValue(text: _login,));
  }

  @override
  void dispose() {
    _controllerLogin.dispose();
    _controllerPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(10, 5, 0, 5), 
          child: Text("Логин", style: TextStyle(fontSize: 16) )
        ),
        Container(
          child:
            TextField(
              controller: _controllerLogin, //default value
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
                  _login = newValue;
                });
              },

            ),
            
        ),
        Container(
          padding: EdgeInsets.fromLTRB(10, 5, 0, 5), 
          child: Text("Пароль", style: TextStyle(fontSize: 16) )
        ),
        Container(
          child: TextField(
            obscureText: true,  
            controller: _controllerPass,
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
                _pass = newValue;
              });
            },
          ),
        ),
        Row(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: _onPressedLoginButton, 
                child: Text("Войти")
              )
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.fromLTRB(0, 10, 10, 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.red, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: _onPressedRegistrationButton, 
                child: Text("Зарегистрироваться")
              )
            ),
          ],

        )
        
      ],

    );
  }

  Future<void> _onPressedLoginButton() async {
      try {
        var response = await http.post(Uri.parse('http://localhost:8000/token'), body: {'username': _login,'password': _pass});
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
        _token = json.decode(response.body)["access_token"];
        print("token $_token");
      } catch (err){
        print(err);
      }
    

    listener(_token);
    Navigator.pop(context);
  }

  Future<void> _onPressedRegistrationButton() async {
      try {
        var response = await http.post(Uri.parse('http://localhost:8000/sign_up'), body: json.encode({
          "username": _login,
          "password": _pass
        })
            );
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
        
        _token = json.decode(response.body)["access_token"];
        print("token $_token");
      } catch (err){
        print(err);
      }
    

    listener(_token);
    Navigator.pop(context);
  }

}