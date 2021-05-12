import 'dart:math';

import 'package:flutter/material.dart';
import 'package:homework_task_tracker/popup_task_info.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'popup_content.dart';
import 'popup_authorization.dart';
import 'popup_edit_titles.dart';
import 'task_info.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyHorizontalDataTable extends StatefulWidget {

  final int filterId;
  MyHorizontalDataTable({Key key, this.filterId}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HorizontalDataTableState(filterId: filterId);
  }

}

class _HorizontalDataTableState extends State<MyHorizontalDataTable> {

  static List<String> columns = ["Предмет"];
  static List<String> rows = [];
  static List<List<TaskInfo>> cells = [ //0 - no task, 1 - in progress, 2 - completed

  ];

  // static List<String> columns = ["Предмет", "Lab1", "Lab2", "Lab3", "Lab4", "Lab5", "Lab6", "Lab7"];
  // static List<String> rows = ["Математика", "Русский", "Информатика", "Физика"];
  // static List<List<TaskInfo>> cells = [ //0 - no task, 1 - in progress, 2 - completed
  //   [TaskInfo(1), TaskInfo(2), TaskInfo(1), TaskInfo(2), TaskInfo(2), TaskInfo(0), TaskInfo(0)],
  //   [TaskInfo(1), TaskInfo(2), TaskInfo(1), TaskInfo(1), TaskInfo(2), TaskInfo(1), TaskInfo(1)],
  //   [TaskInfo(2), TaskInfo(2), TaskInfo(2), TaskInfo(2), TaskInfo(2), TaskInfo(1), TaskInfo(1)],
  //   [TaskInfo(2), TaskInfo(2), TaskInfo(2), TaskInfo(1), TaskInfo(2), TaskInfo(1), TaskInfo(1)]
  // ];

  int _lastRowTitleChosenIndex;
  int _lastColumnTitleChosenIndex;
  List<int> _lastCellChosenIndex;
  String token;

  int filterId;

  _HorizontalDataTableState({this.filterId}): super();

  @override
  Widget build(BuildContext context) {

    int itemCount = filterId == 0? rows.length+1 : rows.length;
    double rightHandSideColumnWidth = filterId == 0? (columns.length-1)*100.0+100 : (columns.length-1)*100.0;
    if (token == null){
      Timer(Duration(milliseconds: 200), (){
        showPopup(context, PopupAuthorization(listener: _authorizationListener), "Авторизация", width: 500, height: 200, needBackButton: false);
      });
    }
    return Container(
      child: HorizontalDataTable(
        leftHandSideColumnWidth: 100,
        rightHandSideColumnWidth: rightHandSideColumnWidth,//MediaQuery.of(context).size.width-100,
        isFixedHeader: true,
        headerWidgets: _getTitlesWidget(),
        leftSideItemBuilder: _generateFirstColumnRow,
        rightSideItemBuilder: _generateRightHandSideColumnRow,
        itemCount: itemCount,
        rowSeparatorWidget: const Divider(
          color: Colors.black54,
          height: 0.0,
          thickness: 1.0,
        ),
      ),
      height: MediaQuery.of(context).size.height,
      
    );
  }


  List<Widget> _getTitlesWidget(){
    //TODO get title list from server 
    List<Widget> res = [];
    


    for (int i=0; i<columns.length; i++) {
      //print(i);
      Widget button = Material(
        color: Colors.white,
        child:InkWell(
          child: Container(
            child: Text(columns[i], style: TextStyle(fontWeight: FontWeight.bold)),
            width: 100,
            height: 52,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            alignment: Alignment.center,

          ),
          onTap: () {
            _lastColumnTitleChosenIndex = i;
            //print(columns[i]);
            showPopup(context, PopupEditTitles(listener: _changeColumnTitleListener, name: columns[_lastColumnTitleChosenIndex]), 
                      "Название контрольной точки", width: 500, height: 125
            );
          },
        )
        
      );
      Widget text = Text(columns[i], style: TextStyle(fontWeight: FontWeight.bold));

      res.add(Container(
        child: i == 0? text : filterId == 0? button : null,
        width: 100,
        height: 52,
        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
        alignment: Alignment.center,
      ));

    }
    if (filterId == 0)
      res.add(_createButton(0));
    return res;
  }

  Widget _generateFirstColumnRow(BuildContext context, int index) {
    //TODO get list from server 
    //print("index in first: $index");

    if (index == rows.length){
      return _createButton(1);
    }
    else {

      Widget button = Material(
        color: Colors.white,
        child:InkWell(
          child: Container(
            child: Text(rows[index]),
            width: 100,
            height: 52,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            alignment: Alignment.center,

          ),
          onTap: () {
            _lastRowTitleChosenIndex = index;
            showPopup(context, PopupEditTitles(listener: _changeRowTitleListener, name: rows[_lastRowTitleChosenIndex]), 
                      "Название предмета", width: 500,height: 125
            );
          },
        )
        
      );


      return Container(
        child: button,
        width: 100,
        height: 52,
        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
        alignment: Alignment.centerLeft,
      );
    }
    
  }

  Widget _generateRightHandSideColumnRow(BuildContext context, int index) {
    //print("index in right: $index");
    List<Widget> cellsList = [];
    if (index < cells.length){
      for (int i=0; i<cells[index].length; i++) {
        if ((filterId == 0) || (filterId == 1 && cells[index][i].state == 1) || (filterId == 2 && cells[index][i].state == 2))
          cellsList.add(
            
            Material(
              color: Colors.white,
              //key: Key("changeCell"),
              child:InkWell(
                child: Container(
                  child: _createTableCell(cells[index][i], columns[i+1]),
                  width: 100,
                  height: 52,
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                  alignment: Alignment.center,

                ),
                onTap: () {
                  //print("tap!");
                  _changeCell(index, i);
                },
              )
              
            )
          );
          
      }
    }
    else {
      for (int i=0; i<columns.length; i++){
        cellsList.add(Container( 
          width: 100,
          height: 52,
          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          alignment: Alignment.center,)
        );
      }
    }
    return Row(children: cellsList);
    
  }

  Widget _createButton(int type){ //TODO перечисления вместо инта?
    return Material(
      color: Colors.blue,
      key: Key(type == 0 ? "addColumn":"addRow"),
      child:InkWell(
        child: Container(
          child: Icon(Icons.add, size: 40, color: Colors.white),
          width: 100,
          height: 52,
          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          alignment: Alignment.center,
        ),
        onTap: () {
          //print("tap!");
          if (type == 0)
            _addColumn();
          else
            _addRow();

          
        },
      )
    
    );
  }

  Widget _createTableCell(TaskInfo info, String title){

    Widget icon = Icon(info.state == 2 ? Icons.check_box: info.state == 1 ? Icons.check_box_outline_blank : Icons.clear, size:20, color: Colors.blue);

    Widget titlePlusIcon = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(title.substring(0, min(title.length, 6)) + (title.length > 5 ? "..." : ""), style: TextStyle(fontSize: 14)),
        icon
      ],
    );

    if (info.deadline == null){
      return filterId == 0 ? icon : titlePlusIcon;
    }
    else{
      DateTime dateTime = info.deadline; // your dateTime object
      DateFormat dateFormat = DateFormat("dd/MM/yy, HH:mm"); // how you want it to be formatted
      String string = dateFormat.format(dateTime);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          filterId == 0 ? icon : titlePlusIcon,
          Text(string, style: TextStyle(fontSize: 12))
        ],
      );
    }
  }

  void _addColumn(){
    setState(() {
      int next = columns.length;
      columns.add("Lab $next");
      for (List<TaskInfo> v in cells){
        v.add(TaskInfo(0));
      }
      _lastColumnTitleChosenIndex = columns.length-1;
      showPopup(context, PopupEditTitles(listener: _changeColumnTitleListener, name: columns[_lastColumnTitleChosenIndex]), 
               "Название контрольной точки", width: 500, height: 125
      );
    });
  }
  void _addRow(){
    setState(() {
      int next = rows.length+1;
      rows.add("Предмет $next");
      List<TaskInfo> newCells = [];
      for (int i=0; i<columns.length-1; i++){
        newCells.add(TaskInfo(0));
      }
      cells.add(newCells);  
      _lastRowTitleChosenIndex = rows.length-1;
      showPopup(context, PopupEditTitles(listener: _changeRowTitleListener, name: rows[_lastRowTitleChosenIndex]), 
                "Название предмета", width: 500,height: 125, needBackButton: false
      );
    });
  }
  void _changeCell(int i, int j){
    //setState(() {
    //  cells[i][j] = !cells[i][j];  
    //});
    _lastCellChosenIndex = [i, j];
    showPopup(context, PopupTaskInfo(listener: _changeCellInfoListener, taskInfo: cells[i][j]), "Задание " + rows[i] + " " + columns[j+1], width: 600,height: 475);
  }

  void _changeColumnTitleListener(String value){
    setState(() {
      if (columns.length > _lastColumnTitleChosenIndex && value.length > 0){
        columns[_lastColumnTitleChosenIndex] = value;
      }
    });
  }
  void _changeRowTitleListener(String value){
    setState(() {
      //print(_lastRowTitleChosenIndex);
      if (rows.length > _lastRowTitleChosenIndex && value.length > 0){
        rows[_lastRowTitleChosenIndex] = value;
      }
    });
  }
  void _changeCellInfoListener(TaskInfo value){
    //print(value.description);
    //print(cells[_lastCellChosenIndex[0]][_lastCellChosenIndex[1]].description);
    setState(() {
      cells[_lastCellChosenIndex[0]][_lastCellChosenIndex[1]].state = value.state;
      cells[_lastCellChosenIndex[0]][_lastCellChosenIndex[1]].description = value.description;
      cells[_lastCellChosenIndex[0]][_lastCellChosenIndex[1]].deadline = value.deadline;
    });
  }

  Future<void> _authorizationListener(String token) async {

    if (token != null){
      try {
        var response = await http.post(Uri.parse('http://localhost:8000/get_dashboard'), 
          headers: {
            "Authorization": "Bearer $token",
            "charset": "utf-8",
            
          }
        );
        setState(() {
          this.token = token;
          print("Response status: ${response.statusCode}");
          print("Response body: ${response.body}");
          var body = json.decode(utf8.decode(response.body.codeUnits));
          List<String> newRows = [];
          List<String> newColumns = ["Предмет"];
          List<List<TaskInfo>> newCells = [];
          for (var v in body["rows"]){ //id, short_name, name
            print(v[2]);
            newRows.add(v[2]);
          }
          for (var v in body["columns"]){ //id, short_name, name
            newColumns.add(v[2]);
          }
          for (var v in body["cells"]){ //id, short_name, name
            //newColumns.add(v[2]);
          }
          rows = newRows;
          columns = newColumns;
          cells = newCells;
          
        });
      } catch (err){
        print(err);
      }
      

    }
    else {
      //recall authorization window
      showPopup(context, PopupAuthorization(listener: _authorizationListener), "Авторизация", width: 500, height: 200, needBackButton: false);
    }
    

  }

  
}