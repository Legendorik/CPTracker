import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

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
  static bool selected = true;

  void _addColumn() {
    setState(() {
      List<DataColumn> new_columns = dataTable.columns;
      List<DataRow> new_rows = dataTable.rows;
      new_columns.add(DataColumn(label: Text("ЛРХ")));
      for (DataRow row in new_rows) {
        row.cells.add(DataCell(Text("-")));
      }
      dataTable = DataTable(columns: new_columns, rows: new_rows);
    });
  }

  static List<DataColumn> columns = [
    DataColumn(label: Text("")),
    DataColumn(label: Text("ЛР1")),
    DataColumn(label: Text("ЛР2")),
    DataColumn(label: Text("ЛР3")),
    DataColumn(label: Text("ЛР4")),
    DataColumn(label: Text("ЛР5")),
  ];

  static List<DataRow> rows = [
    DataRow(selected: selected, cells: [
      DataCell(Text("Математика")),
      DataCell(Text("+")),
      DataCell(Text("-")),
      DataCell(Text("-")),
      DataCell(Text("+")),
      DataCell(Text("+"))
    ]),
    DataRow(selected: selected, cells: [
      DataCell(Text("Математика")),
      DataCell(Text("+")),
      DataCell(Text("-")),
      DataCell(Text("-")),
      DataCell(Text("+")),
      DataCell(Text("+"))
    ]),
    DataRow(selected: selected, cells: [
      DataCell(Text("Математика")),
      DataCell(Text("+")),
      DataCell(Text("-")),
      DataCell(Text("-")),
      DataCell(Text("+")),
      DataCell(Text("+"))
    ]),
    DataRow(selected: selected, cells: [
      DataCell(Text("Математика")),
      DataCell(Text("+")),
      DataCell(Text("-")),
      DataCell(Text("-")),
      DataCell(Text("+")),
      DataCell(Text("+"))
    ]),
    DataRow(selected: selected, cells: [
      DataCell(Text("Математика")),
      DataCell(Text("+")),
      DataCell(Text("-")),
      DataCell(Text("-")),
      DataCell(Text("+")),
      DataCell(Text("+"))
    ]),
  ];

  static DataTable dataTable =
      DataTable(columnSpacing: 30, columns: columns, rows: rows);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              dataTable,
              Container(
                  width: 30,
                  height: 30,
                  child: RawMaterialButton(
                    shape: new CircleBorder(),
                    onPressed: _addColumn,
                    child: Icon(Icons.add, color: Colors.blue),
                  ))
            ])),
      ),
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        backgroundColor: Colors.blue,
        items: [
          TabItem(icon: Icons.list_alt_outlined),
          TabItem(icon: Icons.check_box_outline_blank_sharp),
          TabItem(icon: Icons.check_box_outlined),
        ],
        initialActiveIndex: 1 /*optional*/,
        onTap: (int i) => print('click index=$i'),
      ),
    );
  }
}
