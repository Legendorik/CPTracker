import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'popup_content.dart';
import 'popup_edit_titles.dart';

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
  static List<List<bool>> cells = [
    [true, false, true, false, true, true, false],
    [true, false, true, false, true, true, false],
    [true, false, true, false, true, true, false],
    [true, false, true, false, true, true, false]
  ];
  
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
    
    for (String v in columns) {
      res.add(Container(
        child: Text(v, style: TextStyle(fontWeight: FontWeight.bold)),
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
      return Container(
        child: Text(rows[index]),
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
                child: Icon(cells[index][i] ? Icons.add: Icons.remove, size:20),
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

          showPopup(context, PopupEditTitles(listener: _listener), "test");
        },
      )
    
    );
  }

  void _addColumn(){
    setState(() {
      int next = columns.length;
      columns.add("Lab $next");
      for (List<bool> v in cells){
        v.add(false);
      }
    });
  }
  void _addRow(){
    setState(() {
      int next = rows.length+1;
      rows.add("Предмет $next");
      List<bool> newCells = [];
      for (int i=0; i<columns.length-1; i++){
        newCells.add(false);
      }
      cells.add(newCells);  
    });
  }
  void _changeCell(int i, int j){
    setState(() {
      cells[i][j] = !cells[i][j];  
    });
  }

  String _listener(String value){
    print(value);
    return "abc";
  }
  
}