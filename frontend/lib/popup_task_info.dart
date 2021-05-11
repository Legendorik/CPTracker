import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';

import 'task_info.dart';

class PopupTaskInfo extends StatefulWidget {

  final Function(TaskInfo) listener;
  final TaskInfo taskInfo;
  const PopupTaskInfo({Key key, this.listener, this.taskInfo}): super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _PopupTaskInfoState(listener: listener, taskInfo: taskInfo);
  }
  
}

class _PopupTaskInfoState extends State<PopupTaskInfo> {

  final Function(TaskInfo) listener;
  final TaskInfo taskInfo;
  TaskInfo newTaskInfo;

  String dropdownValue;
  List<String> possibleDropdownValues = ['Задание отсутствует', 'Задано', 'Готово'];

  _PopupTaskInfoState({this.listener, this.taskInfo}): super() {
    dropdownValue = possibleDropdownValues[taskInfo.state];
    newTaskInfo = TaskInfo.full(taskInfo.state, taskInfo.description, taskInfo.deadline);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      //mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          child: Text("Описание:", style: TextStyle(fontSize: 16)),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.all(10),
        ),
        Container(
          child:
            TextField(
              controller: TextEditingController.fromValue(new TextEditingValue(text: newTaskInfo.description)), //default value
              onChanged: (value) {
                newTaskInfo.description = value;
              },
              // onSubmitted: (value) {
              //   listener(value);
              //   Navigator.pop(context);
              // },
              minLines: 5,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Введите описание...',
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                //border: OutlineInputBorder(
                //  borderRadius: BorderRadius.all(Radius.circular(32.0)),
                //),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colors.lightBlueAccent, width: 1.0),
                  //borderRadius: BorderRadius.all(Radius.circular(32.0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colors.lightBlueAccent, width: 2.0),
                  //borderRadius: BorderRadius.all(Radius.circular(32.0)),
                ),
              ),
            ),
        ),
        Container(
          child: Row(
            children: [
              Container(
                child: Text("Статус:", style: TextStyle(fontSize: 16)),
                padding: EdgeInsets.all(10),
              ),
              DropdownButton<String>(
                value: dropdownValue,
                items: possibleDropdownValues.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Container(child: Text(value)),
                  );
                }).toList(),
                onChanged: (String newValue) {
                  setState(() {
                    dropdownValue = newValue;
                    newTaskInfo.state = possibleDropdownValues.indexOf(newValue);
                  });
                },
              )
            ],
          ),
        ),
        Row(
          children: [
            Container(
              child: Text("Срок:", style: TextStyle(fontSize: 16)),
              padding: EdgeInsets.all(10)
            ),
            Material(
              color: Colors.lightBlue[0],
              child:InkWell(
                child: Container(
                  child: _setDeadlineText(),
                  width: 180,
                  height: 50,
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                  alignment: Alignment.center,
                ),
                onTap: () {
                  DatePicker.showDateTimePicker(context,
                        showTitleActions: true,
                        minTime: DateTime(2020),
                        maxTime: DateTime(2025), 
                        onChanged: (date) {
                          //print('change $date');
                          //DateFormat dateFormat = DateFormat("dd-MM-yy, hh-mm"); // how you want it to be formatted
                          //String string = dateFormat.format(date);
                          //print("string $string");
                        }, 
                        onConfirm: (date) {
                          print('confirm $date');
                          
                          setState(() {
                            newTaskInfo.deadline = date;      
                          });
                        }, 
                        currentTime: newTaskInfo.deadline == null? DateTime.now() : newTaskInfo.deadline, 
                        locale: LocaleType.ru
                    );
                },
              )
            )
          ],
        ),
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.all(10),
          child: ElevatedButton(
            onPressed: _onPressedSaveButton, 
            child: Text("Сохранить")
          )
        ),
      ],

    );
  }

  Text _setDeadlineText(){
    if (newTaskInfo.deadline == null){
      return Text("Установить срок", style: TextStyle(fontSize: 16));
    }
    else {
      DateTime dateTime = newTaskInfo.deadline; // your dateTime object
      DateFormat dateFormat = DateFormat("dd/MM/yy, до HH:mm"); // how you want it to be formatted
      String string = dateFormat.format(dateTime);
      return Text(string);
    }
  }

  void _onPressedSaveButton(){
    listener(newTaskInfo);
    Navigator.pop(context);
  }
}