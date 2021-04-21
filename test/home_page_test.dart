// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homework_task_tracker/main.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';


void main() {

  
  group('Home page tests: ', (){
    
    setUp(() {

    });
    tearDown(() {

    });
    testWidgets('Add info into table', (WidgetTester tester) async {

      await tester.pumpWidget(MyApp());

      expect(find.byType(HorizontalDataTable), findsOneWidget);
      
      int minuses = find.byIcon(Icons.clear).evaluate().length;

      await tester.tap(find.byKey(Key("addRow")));
      await tester.pump();

      expect(minuses, lessThan(find.byIcon(Icons.clear).evaluate().length));

      //await tester.tap(find.byKey(Key("addColumn")));
      //await tester.pump();


    });
  });
}
