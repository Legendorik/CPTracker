import 'dart:math';

import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'my_horizontal_data_table.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  //static Widget dataTable = MyHorizontalDataTable();
      //DataTable(columnSpacing: 30, columns: columns, rows: rows);
  int filterId = 0;
  String token;
  Random r = Random();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выход',
            onPressed: () async {
              try {
                var response = await http.post(Uri.parse('http://146.185.241.101:8000/sign_out'),
                  headers: {
                    "Authorization": "Bearer $token",
                    "charset": "utf-8",
                    
                  }
                );
                print("Response status: ${response.statusCode}");
                print("Response body: ${response.body}");
                if (response.statusCode == 200) {
                  setState(() {
                    token = null;
                  });
                }
              } catch (err){
                print(err);
              }
            },
          ),
        ],
      ),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children:[
          Expanded(child: MyHorizontalDataTable(key: Key(r.nextInt(10000).toString()), filterId: filterId, token: token, tokenSetter: _setToken)),
        ]
      ),
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        backgroundColor: Colors.blue,
        items: [
          TabItem(icon: Icons.list_alt_outlined),
          TabItem(icon: Icons.check_box_outline_blank_sharp),
          TabItem(icon: Icons.check_box_outlined),
        ],
        initialActiveIndex: 0 /*optional*/,
        onTap: (int i) => setState(() {
          
          filterId = i;
          //print("success!" + filterId.toString());
        }),
      ),
    );
  }

  _setToken(String myToken){
    token = myToken;
  }

}