import '../utils.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'models.dart';
import 'dart:math';
import 'dart:io';
import 'dart:async';

class IcsParser {
  static final Random _random = Random();

  static Future<List<MyEvent>> parseFromUrl(String url) async {
    final uri = Uri.parse(url);

    try {
      final response = await http
      .get(Uri.parse(url))
      .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Failed to load calendar');
      }

      final body = response.body;

      if (body.length > 5 * 1024 * 1024) {
        throw Exception('ICS too large (>5MB)');
      }

      if (!isValidICS(body)) {
        throw Exception('Invalid ICS content');
      }

      return parseIcs(body);
    } on TimeoutException catch (e) {
      throw Exception('Error : $e');
    } on SocketException catch (_) {
      throw Exception('No network connection');
    } catch (e) {
      rethrow; 
    }
  }

  static List<MyEvent> parseIcs(String icsContent) {
    final events = <MyEvent>[];
    final lines = icsContent.split('\n');
    MyEvent? currentEvent;
    String? currentDescription;

    for (var line in lines) {
      line = line.trim();
      if (line == 'BEGIN:VEVENT') {
        currentEvent = MyEvent(
          title: '',
          startHour: 0,
          startMinute: 0,
          durationMinutes: 60,
          color: _getRandomColor(),
          description: '',
          originalDate: DateTime(0),
        );
      } else if (line == 'END:VEVENT' && currentEvent != null) {
        if (currentDescription != null) {
          currentEvent.description = _cleanDescription(currentDescription);
        }
        events.add(currentEvent);
        currentEvent = null;
        currentDescription = null;
      } else if (currentEvent != null) {
        if (line.startsWith('SUMMARY:')) {
          currentEvent.title = line.substring(8).trim();
        } else if (line.startsWith('DTSTART:')) {
          final dateTime = _parseIcsDateTime(line.substring(8));
          currentEvent.startHour = dateTime.hour;
          currentEvent.startMinute = dateTime.minute;
          currentEvent.originalDate = dateTime;
        } else if (line.startsWith('LOCATION:')) {
          currentEvent.location = line.substring(9).replaceAll(r'\\', ' ').trim();
        } else if (line.startsWith('DTEND:')) {
          final dateTime = _parseIcsDateTime(line.substring(6));
          final duration = dateTime.difference(currentEvent.originalDate).inMinutes;
          currentEvent.durationMinutes = duration;
        } else if (line.startsWith('DESCRIPTION:')) {
          currentDescription = line.substring(12).replaceAll(r'\n', '\n');
        } else if (currentDescription != null && line.isNotEmpty) {
          currentDescription += '\n${line.trim()}';
        }
      }
    }
    return events;
  }

  static String _cleanDescription(String description) {
    final exportIndex = description.indexOf('(Exporté le:');
    if (exportIndex != -1) {
      return description.substring(0, exportIndex).trim();
    }
    return description.trim();
  }

  static DateTime _parseIcsDateTime(String icsDateTime) {
    final isUtc = icsDateTime.endsWith('Z');
    final cleanDateTime = isUtc 
        ? icsDateTime.substring(0, icsDateTime.length - 1)
        : icsDateTime;

    final year = int.parse(cleanDateTime.substring(0, 4));
    final month = int.parse(cleanDateTime.substring(4, 6));
    final day = int.parse(cleanDateTime.substring(6, 8));
    final hour = int.parse(cleanDateTime.substring(9, 11));
    final minute = int.parse(cleanDateTime.substring(11, 13));

    if (isUtc) {
      final utcDate = DateTime.utc(year, month, day, hour, minute);
      return utcDate.toLocal();
    } else {
      return DateTime(year, month, day, hour, minute);
    }
  }

  static Color _getRandomColor() {
    return colorOptions[_random.nextInt(colorOptions.length)];
    //return colorOptions[DateTime.now().millisecondsSinceEpoch % colorOptions.length];
  }
}
