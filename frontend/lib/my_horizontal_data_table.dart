import 'dart:math';

import 'package:flutter/material.dart';
import 'package:homework_task_tracker/popup_alert.dart';
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
import 'short_long_name.dart';


class MyHorizontalDataTable extends StatefulWidget {

  final int filterId;
  final Function(String) tokenSetter;
  final String token;
  MyHorizontalDataTable({Key key, this.filterId, this.token, this.tokenSetter}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HorizontalDataTableState(filterId: filterId, token: token, tokenSetter: this.tokenSetter);
  }

}

class _HorizontalDataTableState extends State<MyHorizontalDataTable> {

  static const double authorizationWindowHeight = 270;
  static const double editTitlesWindowHeight = 320;
  static const double alertWindowHeight = 175;
  static const double taskInfoWindowHeight = 475;

  static List<ShortLongName> columns = [ShortLongName("Предмет")];
  static List<ShortLongName> rows = [];
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
  Function(String) tokenSetter;

  int filterId;

  _HorizontalDataTableState({this.filterId, this.token, this.tokenSetter}): super();

  @override
  Widget build(BuildContext context) {

    
    if (token == null){
      columns = [ShortLongName("Предмет")];
      rows = [];
      cells = [];

      Timer(Duration(milliseconds: 200), (){
        showPopup(context, PopupAuthorization(listener: _authorizationListener), "Авторизация", width: 500, height: authorizationWindowHeight, needBackButton: false);
      });
    }

    int itemCount = filterId == 0? rows.length+1 : rows.length;
    double rightHandSideColumnWidth = filterId == 0? (columns.length-1)*100.0+100 : (columns.length-1)*100.0;
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

    List<Widget> res = [];
    


    for (int i=0; i<columns.length; i++) {
      //print(i);
      Widget button = Material(
        color: Colors.white,
        child:InkWell(
          child: Container(
            child: Text(columns[i].shortName, style: TextStyle(fontWeight: FontWeight.bold)),
            width: 100,
            height: 52,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            alignment: Alignment.center,

          ),
          onTap: () {
            _lastColumnTitleChosenIndex = i;
            //print(columns[i]);
            showPopup(context, PopupEditTitles(listener: _changeColumnTitleListener, deleteListener: _deleteColumnListener, title: columns[_lastColumnTitleChosenIndex]), 
                      "Название контрольной точки", width: 500, height: editTitlesWindowHeight
            );
          },
        )
        
      );
      Widget text = Text(columns[i].shortName, style: TextStyle(fontWeight: FontWeight.bold));

      res.add(Container(
        child: i == 0? text : filterId == 0? button : null,
        width: 100,
        height: 52,
        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
        alignment: Alignment.center,
      ));

    }
    if (filterId == 0 && rows.length != 0)
      res.add(_createButton(0));
    return res;
  }

  Widget _generateFirstColumnRow(BuildContext context, int index) {

    //print("index in first: $index");

    if (index == rows.length){
      return _createButton(1);
    }
    else {

      Widget button = Material(
        color: Colors.white,
        child:InkWell(
          child: Container(
            child: Text(rows[index].shortName),
            width: 100,
            height: 52,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            alignment: Alignment.center,

          ),
          onTap: () {
            _lastRowTitleChosenIndex = index;
            showPopup(context, PopupEditTitles(listener: _changeRowTitleListener, deleteListener: _deleteRowListener, title: rows[_lastRowTitleChosenIndex]), 
                      "Название предмета", width: 500,height: editTitlesWindowHeight
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
        if ((filterId == 0) || (filterId == 1 && cells[index][i].state == 1) || (filterId == 2 && cells[index][i].state == 2)){
          cellsList.add(
            
            Material(
              color: Colors.white,
              //key: Key("changeCell"),
              child:InkWell(
                child: Container(
                  child: _createTableCell(cells[index][i], columns[i+1].shortName),
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

        if (i == cells[index].length - 1 && cellsList.isEmpty)  {
          cellsList.add(Container(width: 100, height: 52, padding: EdgeInsets.fromLTRB(0, 0, 0, 0), alignment: Alignment.center));
        }
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
      DateTime now = DateTime.now();
      Color textColor;

      if (dateTime.isBefore(now)){
        textColor = Colors.red[700];
      }
      else if (dateTime.subtract(Duration(days:1)).isBefore(now)) {
        textColor = Colors.orange[700];
      }
      else if (dateTime.subtract(Duration(days:3)).isBefore(now)) {
        textColor = Colors.yellow[700];
      }
      else if (dateTime.subtract(Duration(days:7)).isBefore(now)) {
        textColor = Colors.green;
      }
      else {
        textColor = Colors.black;
      }

      if (info.state == 2){
        textColor = Colors.black;
      }
      DateFormat dateFormat = DateFormat("dd/MM/yy, HH:mm"); // how you want it to be formatted
      String string = dateFormat.format(dateTime);
      
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          filterId == 0 ? icon : titlePlusIcon,
          Text(string, style: TextStyle(fontSize: 12, color: textColor))
        ],
      );
    }
  }

  void _addColumn(){
    setState(() {
      int next = columns.length;
      columns.add(ShortLongName("Лаб $next"));
      for (List<TaskInfo> v in cells){
        v.add(TaskInfo(0));
      }
      _lastColumnTitleChosenIndex = columns.length-1;
      showPopup(context, PopupEditTitles(listener: _changeColumnTitleListener, deleteListener: _deleteColumnListener, title: columns[_lastColumnTitleChosenIndex]), 
               "Название контрольной точки", width: 500, height: editTitlesWindowHeight, needBackButton: false
      );
    });
  }
  void _addRow(){
    setState(() {
      int next = rows.length+1;
      rows.add(ShortLongName("Предмет $next"));
      List<TaskInfo> newCells = [];
      for (int i=0; i<columns.length-1; i++){
        newCells.add(TaskInfo(0));
      }
      cells.add(newCells);  
      _lastRowTitleChosenIndex = rows.length-1;
      showPopup(context, PopupEditTitles(listener: _changeRowTitleListener, deleteListener: _deleteRowListener, title: rows[_lastRowTitleChosenIndex]), 
                "Название предмета", width: 500,height: editTitlesWindowHeight, needBackButton: false
      );
    });
  }
  Future<void> _deleteColumnListener() async {
    if (columns[_lastColumnTitleChosenIndex].id != -1){
      try {
        var response = await http.delete(Uri.parse('http://localhost:8000/control_point'), 
          headers: {
            "Authorization": "Bearer $token",
            "charset": "utf-8", 
          },
          body: json.encode({
            "short_name": columns[_lastColumnTitleChosenIndex].shortName,
            "full_name": columns[_lastColumnTitleChosenIndex].longName
          })
      
        );
        _checkNetworkErrors(response, "Ошибка удаления КТ");
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
        
      } catch (err){
        print(err);
        //_checkNetworkErrors({"statusCode": 0, "body": err}, "Ошибка удаления КТ");
      }
    }
    setState(() {
      for (List<TaskInfo> v in cells){
        v.removeAt(_lastColumnTitleChosenIndex-1);
      }
      columns.removeAt(_lastColumnTitleChosenIndex);
    });
  }
  Future<void> _deleteRowListener() async {
    if (rows.length == 1 && columns.length > 0){

      //удалять нельзя
      return;
    }
    if (rows[_lastRowTitleChosenIndex].id != -1){
      try {
        var response = await http.delete(Uri.parse('http://localhost:8000/subject'), 
          headers: {
            "Authorization": "Bearer $token",
            "charset": "utf-8", 
          },
          body: json.encode({
            "short_name": rows[_lastRowTitleChosenIndex].shortName,
            "full_name": rows[_lastRowTitleChosenIndex].longName
          })
      
        );
        _checkNetworkErrors(response, "Ошибка удаления предмета");
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
        
      } catch (err){
        print(err);
        //_checkNetworkErrors({"statusCode": 0, "body": err}, "Ошибка удаления предмета");
      }
    }
      
    setState(() {
      cells.removeAt(_lastRowTitleChosenIndex);
      rows.removeAt(_lastRowTitleChosenIndex);
    });
  }

  void _changeCell(int i, int j){
    //setState(() {
    //  cells[i][j] = !cells[i][j];  
    //});
    _lastCellChosenIndex = [i, j];
    showPopup(context, PopupTaskInfo(listener: _changeCellInfoListener, taskInfo: cells[i][j]), "Задание " + rows[i].shortName + " " + columns[j+1].shortName, width: 600,height: taskInfoWindowHeight);
  }

  Future<void> _changeColumnTitleListener(ShortLongName value) async {

    try {
      if (value.id == -1){ //только что добавленный предмет
          var response = await http.post(Uri.parse('http://localhost:8000/control_point'), 
            headers: {
              "Authorization": "Bearer $token",
              "charset": "utf-8", 
            },
            body: json.encode({
              "short_name": value.shortName,
              "full_name": value.longName
            })
        
          );
          _checkNetworkErrors(response, "Ошибка создания КТ");
          print("Response status: ${response.statusCode}");
          print("Response body: ${response.body}");
          //add real id
          value.id = 0;
      }
      else {
          var response = await http.put(Uri.parse('http://localhost:8000/control_point'), 
            headers: {
              "Authorization": "Bearer $token",
              "charset": "utf-8", 
            },
            body: json.encode({
              "old_subject" : {
                "short_name": columns[_lastColumnTitleChosenIndex].shortName,
                "full_name": columns[_lastColumnTitleChosenIndex].longName
              },
              "new_subject": {
                "short_name": value.shortName,
                "full_name": value.longName
              }
            })
          );
          _checkNetworkErrors(response, "Ошибка изменения КТ");
          print("Response status: ${response.statusCode}");
          print("Response body: ${response.body}");
          //add real id
          //value.id = 0;
      }
    } catch (err){
      print(err);
      //_checkNetworkErrors({"statusCode": 0, "body": err}, "Ошибка изменения КТ");
    }


    setState(() {
      if (columns.length > _lastColumnTitleChosenIndex){
        columns[_lastColumnTitleChosenIndex] = value;
      }
    });
  }
  Future<void> _changeRowTitleListener(ShortLongName value) async {


    try {
      if (value.id == -1){ //только что добавленный предмет
          var response = await http.post(Uri.parse('http://localhost:8000/subject'), 
            headers: {
              "Authorization": "Bearer $token",
              "charset": "utf-8", 
            },
            body: json.encode({
              "short_name": value.shortName,
              "full_name": value.longName
            })
        
          );
          print("Response status: ${response.statusCode}");
          print("Response body: ${response.body}");
          _checkNetworkErrors(response, "Ошибка добавления предмета");
          //add real id
          value.id = 0;
      }
      else {
          var response = await http.put(Uri.parse('http://localhost:8000/subject'), 
            headers: {
              "Authorization": "Bearer $token",
              "charset": "utf-8", 
            },
            body: json.encode({
              "old_subject" : {
                "short_name": rows[_lastRowTitleChosenIndex].shortName,
                "full_name": rows[_lastRowTitleChosenIndex].longName
              },
              "new_subject": {
                "short_name": value.shortName,
                "full_name": value.longName
              }
            })
          );
          _checkNetworkErrors(response, "Ошибка изменения предмета");
          print("Response status: ${response.statusCode}");
          print("Response body: ${response.body}");
          //add real id
          //value.id = 0;
      }
    } catch (err){
      print(err);
      //_checkNetworkErrors({"statusCode": 0, "body": err}, "Ошибка изменения предмета");
    }
    setState(() {
      //print(_lastRowTitleChosenIndex);
      if (rows.length > _lastRowTitleChosenIndex){
        rows[_lastRowTitleChosenIndex] = value;
        
      }
    });
  }
  Future<void> _changeCellInfoListener(TaskInfo value) async {



    try {
      print(rows[_lastCellChosenIndex[0]].shortName + "  " + columns[_lastCellChosenIndex[1]+1].shortName);
      var response = await http.put(Uri.parse('http://localhost:8000/cell'), 
        headers: {
          "Authorization": "Bearer $token",
          "charset": "utf-8", 
        },
        body: json.encode({
            "subject": {
              "short_name": rows[_lastCellChosenIndex[0]].shortName,
              "full_name": rows[_lastCellChosenIndex[0]].longName
            },
            "control_point": {
              "short_name": columns[_lastCellChosenIndex[1]+1].shortName,
              "full_name": columns[_lastCellChosenIndex[1]+1].longName
            },
            "new_cell": {
              "deadline": value.deadline == null ? null : value.deadline.toString(),
              "description": value.description,
              "complete": value.state == 2 ? true : value.state == 1 ? false : null
            }
        })
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      _checkNetworkErrors(response, "Ошибка изменения задания");
    } catch (err){
      print(err);
      //_checkNetworkErrors({"statusCode": 0, "body": err}, "Ошибка изменения задания");
    }

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
        _checkNetworkErrors(response, "Ошибка получения таблицы");
        _authorize(token, response);
      } catch (err){
        print(err);
        //_checkNetworkErrors({"statusCode": 0, "body": {"error": err}}, "Ошибка получения таблицы");
      }
      

    }
    else {
      //recall authorization window
      showPopup(context, PopupAuthorization(listener: _authorizationListener), "Авторизация", width: 500, height: authorizationWindowHeight, needBackButton: false);
    }
  }

  void _authorize(token, response){

    setState(() {
      this.token = token;
      tokenSetter(token); // передача вышестоящему виджету
      //print("Response status: ${response.statusCode}");
      //print("Response body: ${response.body}");

      var body = json.decode(utf8.decode(response.body.codeUnits));

      List<ShortLongName> newRows = [];
      List<ShortLongName> newColumns = [ShortLongName("Предмет")];
      List<List<TaskInfo>> newCells = [];

      for (int i=0; i<body["rows"].length; i++){
        var v = body["rows"][i.toString()];
        print("$v \n\n");
        newRows.add(ShortLongName.full(v["full_name"], v["short_name"], v["id"]));
      }

      for (int i=0; i<body["columns"].length; i++){
        var v = body["columns"][i.toString()];
        print("$v \n\n");
        newColumns.add(ShortLongName.full(v["full_name"], v["short_name"], v["id"]));
      }

      for (int i=0; i<body["cells"].length; i++){
        List<TaskInfo> newCellsRow = [];
        var v = body["cells"][i.toString()];
        for (int ii=0; ii<v.length; ii++){
          var vv = v[ii.toString()];
          int myState = vv["status"] == null ? 0 : vv["status"] ? 2 : 1;
          newCellsRow.add(TaskInfo.full(myState, vv["description"] == null ? "" : vv["description"], DateTime.tryParse(vv["deadline"] == null? "" : vv["deadline"]), 1));
        }
        newCells.add(newCellsRow);
      } 
      rows = newRows;
      columns = newColumns;
      cells = newCells;
      
    });

    
  }

  _checkNetworkErrors(response, problemTitle, [problemText = ""]){
    
    var body = json.decode(utf8.decode(response.body.codeUnits));
    if (body == null) return;
    if (response.statusCode != null && response.statusCode != 200 || body["error"] != null){

      showPopup(context, PopupAlert(
        text: "Status Code: " + response.statusCode.toString() + ", " + body["info"].toString(), w: 500), 
        problemTitle, width: 500, height: alertWindowHeight
      );
    }
    
  }
}