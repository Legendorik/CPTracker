import 'package:flutter/material.dart';
import 'package:homework_task_tracker/popup_task_info.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'popup_content.dart';
import 'popup_edit_titles.dart';
import 'task_info.dart';

class MyHorizontalDataTable extends StatefulWidget {
  MyHorizontalDataTable({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HorizontalDataTableState();
  }

}

class _HorizontalDataTableState extends State<MyHorizontalDataTable> {

  static List<String> columns = ["Предмет", "Lab1", "Lab2", "Lab3", "Lab4", "Lab5", "Lab6", "Lab7"];
  static List<String> rows = ["Математика", "Русский", "Информатика", "Физика"];
  static List<List<TaskInfo>> cells = [ //0 - no task, 1 - in progress, 2 - completed
    [TaskInfo(1), TaskInfo(2), TaskInfo(1), TaskInfo(2), TaskInfo(2), TaskInfo(0), TaskInfo(0)],
    [TaskInfo(1), TaskInfo(2), TaskInfo(1), TaskInfo(1), TaskInfo(2), TaskInfo(1), TaskInfo(1)],
    [TaskInfo(2), TaskInfo(2), TaskInfo(2), TaskInfo(2), TaskInfo(2), TaskInfo(1), TaskInfo(1)],
    [TaskInfo(2), TaskInfo(2), TaskInfo(2), TaskInfo(1), TaskInfo(2), TaskInfo(1), TaskInfo(1)]
  ];

  int _lastRowTitleChosenIndex;
  int _lastColumnTitleChosenIndex;
  List<int> _lastCellChosenIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: HorizontalDataTable(
        leftHandSideColumnWidth: 100,
        rightHandSideColumnWidth: (columns.length-1)*100.0+100,//MediaQuery.of(context).size.width-100,
        isFixedHeader: true,
        headerWidgets: _getTitlesWidget(),
        leftSideItemBuilder: _generateFirstColumnRow,
        rightSideItemBuilder: _generateRightHandSideColumnRow,
        itemCount: rows.length+1,
        rowSeparatorWidget: const Divider(
          color: Colors.black54,
          height: 1.0,
          thickness: 0.0,
        ),
      ),
      height: MediaQuery.of(context).size.height,
    );
  }

  List<Widget> _getTitlesWidget(){
    //TODO get title list from server 
    List<Widget> res = [];
    


    for (int i=0; i<columns.length; i++) {
      print(i);
      Widget button = Material(
        color: Colors.white,
        child:InkWell(
          child: Container(
            child: Text(columns[i], style: TextStyle(fontWeight: FontWeight.bold)),
            //width: 100,
            //height: 56,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            alignment: Alignment.center,

          ),
          onTap: () {
            _lastColumnTitleChosenIndex = i;
            print(columns[i]);
            showPopup(context, PopupEditTitles(listener: _changeColumnTitleListener), "Название контрольной точки", width: 500, height: 125);
          },
        )
        
      );
      Widget text = Text(columns[i], style: TextStyle(fontWeight: FontWeight.bold));

      res.add(Container(
        child: i == 0? text : button,
        width: 100,
        height: 56,
        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
        alignment: Alignment.center,
      ));

    }
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
            //width: 100,
            //height: 56,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            alignment: Alignment.center,

          ),
          onTap: () {
            _lastRowTitleChosenIndex = index;
            showPopup(context, PopupEditTitles(listener: _changeRowTitleListener), "Название предмета", width: 500,height: 125);
          },
        )
        
      );


      return Container(
        child: button,
        width: 100,
        height: 56,
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
        cellsList.add(
          
          Material(
            color: Colors.white,
            //key: Key("changeCell"),
            child:InkWell(
              child: Container(
                child: Icon(cells[index][i].state == 2 ? Icons.check_box: cells[index][i].state == 1 ? Icons.check_box_outline_blank : Icons.clear, size:20, color: Colors.blue),
                width: 100,
                height: 56,
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                alignment: Alignment.center,

              ),
              onTap: () {
                print("tap!");
                _changeCell(index, i);
              },
            )
            
          )
        );
      }
    }
    else {
      for (int i=0; i<columns.length; i++){
        cellsList.add(Container( width: 100,
          height: 56,
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
          height: 56,
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

  void _addColumn(){
    setState(() {
      int next = columns.length;
      columns.add("Lab $next");
      for (List<TaskInfo> v in cells){
        v.add(TaskInfo(0));
      }
      _lastColumnTitleChosenIndex = columns.length-1;
      showPopup(context, PopupEditTitles(listener: _changeColumnTitleListener), "Название контрольной точки", width: 500, height: 125);
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
      showPopup(context, PopupEditTitles(listener: _changeRowTitleListener), "Название предмета", width: 500,height: 125);
    });
  }
  void _changeCell(int i, int j){
    //setState(() {
    //  cells[i][j] = !cells[i][j];  
    //});
    _lastCellChosenIndex = [i, j];
    showPopup(context, PopupTaskInfo(listener: _changeCellInfoListener), "Задание", width: 600,height: 500);
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
      print(_lastRowTitleChosenIndex);
      if (rows.length > _lastRowTitleChosenIndex && value.length > 0){
        rows[_lastRowTitleChosenIndex] = value;
      }
    });
  }
  void _changeCellInfoListener(String value){
    setState(() {
      
    });
  }

  
}