import 'core/models.dart';
import 'package:flutter/material.dart';

const double hourHeight = 60;
const double timeLineWidth = 60;
const double dayCircleSize = 40;
const int minEventDuration = 30;
const int maxEventsAtSameTime = 4;

const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

List<Color> colorOptions = [
    Color.fromARGB(255, 255, 243, 162),
    Color.fromARGB(255, 203, 181, 248),
    Color.fromARGB(255, 164, 195, 248),
    Color.fromARGB(255, 193, 143, 212),
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

CalendarType calendarType = CalendarType.withLink;

const Color primaryColor = Color(0xFF3FA176);
const Color primaryShadowColor = Color.fromARGB(255, 56, 143, 105);

double getOffsetFromTime(int hour, int minute) {
  return (hour * 60 + minute) * (hourHeight / 60) + hourHeight / 4;
}