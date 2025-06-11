import 'package:flutter/material.dart';

enum CalendarType { withLink, custom }

class MyCalendar {
  final String name;
  final String url;
  List<MyEvent> events;

  MyCalendar({
    required this.name,
    required this.url,
    required this.events,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'events': url.isEmpty
            ? events.map((e) => e.toJson()).toList()
            : [],
      };

  static MyCalendar fromJson(Map<String, dynamic> json) {
    return MyCalendar(
      name: json['name'],
      url: json['url'],
      events: json['url'].isEmpty 
          ? (json['events'] as List).map((e) => MyEvent.fromJson(e)).toList()
          : [],
    );
  }
}


class MyEvent {
  String title;
  int startHour;
  int startMinute;
  int durationMinutes;
  Color color;
  String description;
  DateTime originalDate;
  String location;
  
  int overlapCount; 

  MyEvent({
    required this.title,
    required this.startHour,
    required this.startMinute,
    this.durationMinutes = 60,
    required this.color,
    this.description = "",
    this.location = "",
    required this.originalDate,
    this.overlapCount=1,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'startHour': startHour,
    'startMinute': startMinute,
    'durationMinutes': durationMinutes,
    // ignore: deprecated_member_use
    'color': color.value,
    'description': description,
    'location': location,
    'originalDate': originalDate.millisecondsSinceEpoch,
  };

  factory MyEvent.fromJson(Map<String, dynamic> json) => MyEvent(
    title: json['title'],
    startHour: json['startHour'],
    startMinute: json['startMinute'],
    durationMinutes: json['durationMinutes'],
    color: Color(json['color']),
    description: json['description'],
    location: json['location'],
    originalDate: DateTime.fromMillisecondsSinceEpoch(json['originalDate']),
  );
}

class TempEvent {
  final title = TextEditingController();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = addDurationToTimeOfDay(TimeOfDay.now(), const Duration(hours: 1));
  final location = TextEditingController();
  final description = TextEditingController();
  Color color = Colors.blue;
  DateTime originalDate = DateTime.now();

  static TimeOfDay addDurationToTimeOfDay(TimeOfDay time, Duration duration) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final result = dt.add(duration);
    return TimeOfDay(hour: result.hour, minute: result.minute);
  }

  Map<String, dynamic> toMap() {
    final duration = calculateDurationMinutes();
    
    return {
      'title': title.text,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'durationMinutes': duration > 0 ? duration : 60,
      'location': location.text,
      'description': description.text,
      'color': color.toARGB32(),
      'originalDate': originalDate.millisecondsSinceEpoch,
    };
  }

  int calculateDurationMinutes() {
    return (endTime.hour * 60 + endTime.minute) - 
           (startTime.hour * 60 + startTime.minute);
  }

  void adjustEndTime() {
    final duration = calculateDurationMinutes();
    if (duration <= 0) {
      endTime = addDurationToTimeOfDay(startTime, const Duration(hours: 1));
    }
  }

  bool get isValid {
  final duration = (endTime.hour * 60 + endTime.minute) - 
                 (startTime.hour * 60 + startTime.minute);
  return title.text.isNotEmpty && duration > 0;
}
}