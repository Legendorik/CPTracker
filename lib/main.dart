import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Homework task tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  static Widget dataTable = MyHorizontalDataTable();
      //DataTable(columnSpacing: 30, columns: columns, rows: rows);

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
          Expanded(child: dataTable),
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
        onTap: (int i) => print('click index=$i'),
      ),
    );
  }

}

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
            child:InkWell(
              child: Container(
                child: Icon(cells[index][i] ? Icons.add: Icons.remove),
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
      child:InkWell(
        child: Container(
          child: Icon(Icons.add, size: 40, color: Colors.white),
          width: 100,
          height: 56,
          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          alignment: Alignment.center,
        ),
        onTap: () {
          print("tap!");
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
      for (List<bool> v in cells){
        v.add(false);
      }
    });
  }
  void _addRow(){
    setState(() {
      int next = rows.length;
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
  
}