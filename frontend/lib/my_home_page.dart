import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'my_horizontal_data_table.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children:[
          Expanded(child: MyHorizontalDataTable(key: Key(filterId.toString()), filterId: filterId, token: token, tokenSetter: _setToken)),
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