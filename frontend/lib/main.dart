import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import 'my_home_page.dart';

void main() {



  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    //await myErrorsHandler.initialize();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      //myErrorsHandler.onError(details);
      //exit(1);
    };
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]).then((_) => runApp(MyApp()));
  }, (Object error, StackTrace stack) {
    //myErrorsHandler.onError(error, stack);
    //exit(1);
  });
  
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