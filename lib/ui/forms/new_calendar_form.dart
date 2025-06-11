import 'fields.dart';
import 'package:flutter/material.dart';
import '../../utils.dart';
import '../../core/models.dart';

class CreateCalendarForm extends StatefulWidget {
  final List<String> existingUrls;
  final List<MyEvent> existingEvents;
  
  const CreateCalendarForm({
    super.key, 
    this.existingUrls = const [], 
    this.existingEvents = const []
  });

  @override
  State<CreateCalendarForm> createState() => CreateCalendarFormState();
}

class CreateCalendarFormState extends State<CreateCalendarForm> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  final List<TempEvent> _events = [];
  String? _errorMessage;

  void _submit() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final DateTime targetDate = _events.isNotEmpty ? _events[0].originalDate : DateTime.now();

    final sameDayEvents = widget.existingEvents.where((e) =>
      e.originalDate.year == targetDate.year &&
      e.originalDate.month == targetDate.month &&
      e.originalDate.day == targetDate.day
    ).toList();

    setState(() => _errorMessage = null);

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Name is required');
      return;
    }

    if (calendarType == CalendarType.withLink) {
      if (url.isEmpty) {
        setState(() => _errorMessage = 'URL is required when using a calendar link');
        return;
      }
    } else {
      if (_events.isEmpty) {
        setState(() => _errorMessage = 'Please add at least one event for custom calendar');
        return;
      }

      for (final event in _events) {
        final duration = event.calculateDurationMinutes();

        if (event.title.text.trim().isEmpty) {
          setState(() => _errorMessage = 'All events must have a title');
          return;
        }

        if (duration < minEventDuration) {
          setState(() => _errorMessage = 'Each event must be at least $minEventDuration minutes long');
          return;
        }

        if (duration <= 0) {
          setState(() => _errorMessage = 'Each event must have a valid start and end time');
          return;
        }
      }

      final timeSlots = List<int>.filled(24 * 60, 0); 

      for (final event in sameDayEvents) {
        final start = event.startHour * 60 + event.startMinute;
        final end = start + event.durationMinutes;
        for (int i = start; i < end && i < 1440; i++) {
          timeSlots[i]++;
        }
      }

      for (final event in _events) {
        final start = event.startTime.hour * 60 + event.startTime.minute;
        final end = event.endTime.hour * 60 + event.endTime.minute;

        for (int i = start; i < end && i < 1440; i++) {
          timeSlots[i]++;
          if (timeSlots[i] > maxEventsAtSameTime) {
            final hour = i ~/ 60;
            final minute = i % 60;
            setState(() {
              _errorMessage = 'Too many overlapping events at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} — max is $maxEventsAtSameTime';
            });
            return;
          }
        }
      }
    }

    if (url.isNotEmpty && widget.existingUrls.contains(url)) {
      setState(() => _errorMessage = 'This URL is already used by another calendar');
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'url': url,
      'events': _events.map((e) => e.toMap()).toList(),
    });
  }

  void _addEvent() {
    setState(() {
      final now = TimeOfDay.now();
      _events.add(TempEvent()
        ..startTime = now
        ..endTime = TempEvent.addDurationToTimeOfDay(now, const Duration(hours: 1)));
    });
  }

  void _removeEvent(int index) {
    setState(() => _events.removeAt(index));
  }

  String _formatDuration(TempEvent event) {
    final duration = event.calculateDurationMinutes();
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    
    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} $minutes min';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          "New Calendar",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red[100],
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabeledTextField(
                  label: "Calendar name *",
                  controller: _nameController,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Calendar type *",
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            calendarType = CalendarType.withLink;
                            _events.clear();
                          }),
                          child: Icon(
                            calendarType == CalendarType.withLink 
                              ? Icons.check_box
                              : Icons.check_box_outline_blank_outlined,  
                            color: primaryColor 
                          ),  
                        ),
                        const SizedBox(width: 8),
                        const Text('Link calendar'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            calendarType = CalendarType.custom;
                            _events.clear();
                          }),
                          child: Icon(
                            calendarType == CalendarType.custom 
                              ? Icons.check_box
                              : Icons.check_box_outline_blank_outlined,  
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Custom calendar'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (calendarType == CalendarType.withLink) ...[
                  LabeledTextField(
                    label: "URL *",
                    controller: _urlController,
                    primaryColor: primaryColor,
                    hintText: "https://example.com",
                  ),
                  const SizedBox(height: 24),
                ],
                
                if (calendarType == CalendarType.custom) ...[
                  const SizedBox(height: 8),
                  if (_events.isEmpty)
                    const Text("No events added yet", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 15),
                  
                  if (_events.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final e = _events[index];
                        return Card(
                          color: const Color.fromARGB(255, 248, 248, 248),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                LabeledTextField(
                                  label: "Event Title *",
                                  controller: e.title,
                                  primaryColor: primaryColor,
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: buildTimePicker(
                                        context: context,
                                        label: "Start Time *",
                                        time: e.startTime,
                                        onChanged: (time) {
                                          setState(() {
                                            e.startTime = time;
                                            if (e.endTime.hour < time.hour || 
                                                (e.endTime.hour == time.hour && e.endTime.minute <= time.minute)) {
                                              e.endTime = TimeOfDay(
                                                hour: (time.hour + 1) % 24,
                                                minute: time.minute,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: buildTimePicker(
                                        context: context,
                                        label: "End Time *",
                                        time: e.endTime,
                                        onChanged: (time) {
                                          setState(() {
                                            if (time.hour > e.startTime.hour || 
                                                (time.hour == e.startTime.hour && time.minute > e.startTime.minute)) {
                                              e.endTime = time;
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("End time must be after start time"))
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Duration: ${_formatDuration(e)}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),

                                LabeledTextField(
                                  label: "Location",
                                  controller: e.location,
                                  primaryColor: primaryColor,
                                  height: 65,
                                ),
                                const SizedBox(height: 8),
                                LabeledTextField(
                                  label: "Description",
                                  controller: e.description,
                                  primaryColor: primaryColor,
                                  height: 65,
                                ),

                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 40,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: colorOptions.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                                    itemBuilder: (context, index) {
                                      final color = colorOptions[index];
                                      return GestureDetector(
                                        onTap: () => setState(() => e.color = color),
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: e.color == color ? Colors.black : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: e.originalDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (date != null) setState(() => e.originalDate = date);
                                      },
                                      child: Text(
                                        '${e.originalDate.day}/${e.originalDate.month}/${e.originalDate.year}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: primaryColor),
                                      onPressed: () => _removeEvent(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    label: const Text("Add Event", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                    onPressed: _addEvent,
                  ),
                  const SizedBox(height: 16),
                ],
                
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  label: const Text("Create", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}