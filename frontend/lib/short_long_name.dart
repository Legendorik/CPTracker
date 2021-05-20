import 'dart:math';

class ShortLongName {

  String shortName; 
  String longName;
  //String entity;

  int id = -1;

  ShortLongName(this.longName){
    shortName = longName.substring(0, min(longName.length, 10));
  }

  ShortLongName.full(this.longName, this.shortName, this.id);

}