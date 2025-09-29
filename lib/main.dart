import 'package:flutter/material.dart';
import 'dart:async'; 
import 'core/models.dart';
import 'core/parsers.dart';
import 'ui/calendar_base.dart';
import 'ui/forms/new_calendar_form.dart';
import 'utils.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.light(
      primary: primaryColor, 
      onPrimary: Colors.white, 
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    fontFamily: "SF"),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentWeekIndex = 0;
  late PageController _pageController;
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  late ScrollController _dayViewScrollController;
  List<MyCalendar> calendars = [];

  final _secureStorage = const FlutterSecureStorage();

  void _reloadURLs() async {
  setState(() => isLoading = true);
  
  _pageController = PageController(initialPage: 10000);
  _dayViewScrollController = ScrollController();
  
  await _reloadCached();
  
  setState(() => isLoading = false);
}

Future<void> _reloadCached() async {
  setState(() => isLoading = true);

  final cached = await loadCalendarsFromCache();
  calendars = cached;

  for (final calendar in calendars.where((c) => c.url.isNotEmpty)) {
      if (!isValidIcsUrl(calendar.url)) {
        debugPrint('URL denied: ${calendar.url}');
        continue;
      }

      try {
        final icsData = await IcsParser.parseFromUrl(calendar.url);

        calendar.events = icsData;
      } catch (e) {
        debugPrint('Load error ${calendar.name}: $e');
        calendar.events = [];
      }
    }

  setState(() => isLoading = false);
}

  @override
void initState() {
  super.initState();
  _pageController = PageController(initialPage: 10000);
  _dayViewScrollController = ScrollController();
  _loadInitialData();
}

Future<void> _loadInitialData() async {
  setState(() => isLoading = true);
  try {
    final cached = await loadCalendarsFromCache();
    setState(() => calendars = cached);
    await _reloadCached();
  } catch (e) {
    debugPrint('Initial load error: $e');
  } finally {
    setState(() => isLoading = false);
  }
}

Future<void> saveCalendarsToCache(List<MyCalendar> calendars) async {
    final calendarsJson = calendars.map((c) => json.encode(c.toJson())).toList();
    await _secureStorage.write(
      key: 'cached_calendars',
      value: jsonEncode(calendarsJson),
    );
  }

  Future<List<MyCalendar>> loadCalendarsFromCache() async {
    final cached = await _secureStorage.read(key: 'cached_calendars');
    if (cached == null || cached.isEmpty) return [];

    final calendarsJson = (jsonDecode(cached) as List<dynamic>).cast<String>();
    return calendarsJson.map((c) => MyCalendar.fromJson(json.decode(c))).toList();
  }

  void _scrollToFirstEvent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final events = getEventsForSelectedDate();
      if (events.isNotEmpty) {
        final firstEvent = events.reduce(
          (a, b) => (a).startHour < (b).startHour ? a : b,
        );
        
        final offset = getOffsetFromTime(
          firstEvent.startHour,
          firstEvent.startMinute,
        ) - hourHeight/2;
        
        _dayViewScrollController.jumpTo(offset);
      }
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    final weeksFromNow = 0; 
    
    setState(() {
      selectedDate = today;
      currentWeekIndex = weeksFromNow;
    });
    
    _pageController.jumpToPage(10000 + weeksFromNow);
    _scrollToFirstEvent();
  }

  DateTime getStartOfWeek(int weekOffset) {
    final now = DateTime.now();
    final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    return mondayThisWeek.add(Duration(days: weekOffset * 7));
  }

  List<List<MyEvent>> groupOverlappingEvents(List<MyEvent> events) {
    events.sort((a, b) {
      final aStart = a.startHour * 60 + a.startMinute;
      final bStart = b.startHour * 60 + b.startMinute;
      return aStart.compareTo(bStart);
    });

    List<List<MyEvent>> groups = [];

    for (var event in events) {
      bool added = false;

      for (var group in groups) {
        if (group.any((e) =>
            (e.startHour * 60 + e.startMinute) <
                (event.startHour * 60 + event.startMinute + event.durationMinutes) &&
            (event.startHour * 60 + event.startMinute) <
                (e.startHour * 60 + e.startMinute + e.durationMinutes))) {
          group.add(event);
          added = true;
          break;
        }
      }

      if (!added) {
        groups.add([event]);
      }
    }

    for (var group in groups) {
      final count = group.length;
      for (var e in group) {
        e.overlapCount = count;
      }
    }

    return groups;
  }

  String getMonthName(int weekOffset) {
    final startOfWeek = getStartOfWeek(weekOffset);
    return monthNames[startOfWeek.month - 1];
  }

  List<MyEvent> getEventsForSelectedDate() {
    return calendars
        .expand((c) => c.events)
        .where((event) {
          final eventDate = DateTime(
            event.originalDate.year,
            event.originalDate.month,
            event.originalDate.day,
          );
          return eventDate.year == selectedDate.year &&
              eventDate.month == selectedDate.month &&
              eventDate.day == selectedDate.day;
        }).toList();
  }

  void _handleDayTapped(DateTime dayDate) {
    setState(() {
      selectedDate = dayDate;
    });
    _scrollToFirstEvent();
  }

  void _openCreateCalendarSheet() async {
    final existingUrls = calendars.map((c) => c.url).where((u) => u.isNotEmpty).toList();
    final existingEvents = calendars.expand((c) => c.events).toList();
    
    final result = await showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CreateCalendarForm(
                existingUrls: existingUrls, 
                existingEvents: existingEvents
              ),
            ),
          );
        },
    );

    if (result is Map<String, dynamic>) {
      final name = result['name'] ?? '';
      final url = result['url'] ?? '';
      final eventsList = result['events'] as List<dynamic>?;

      final events = eventsList?.map((e) {
        return MyEvent(
          title: e['title'],
          startHour: e['startHour'],
          startMinute: e['startMinute'],
          durationMinutes: e['durationMinutes'],
          color: Color(e['color']),
          description: e['description'],
          location: e['location'],
          originalDate: DateTime.fromMillisecondsSinceEpoch(e['originalDate']),
        );
      }).toList() ?? [];

      final calendar = MyCalendar(name: name, url: url, events: events);

      setState(() => calendars.add(calendar));
      await saveCalendarsToCache(calendars);
      _reloadURLs();
    }
  }

  void _openCalendarSettings() async {
    await showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Your Calendars',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: calendars.length,
                    itemBuilder: (context, index) {
                      final calendar = calendars[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(calendar.name),
                          subtitle: calendar.url.isNotEmpty
                              ? Text(calendar.url, maxLines: 1, overflow: TextOverflow.ellipsis)
                              : Text('${calendar.events.length} custom events'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: primaryColor),
                            onPressed: () async{
                              setState(() => calendars.removeAt(index));
                              await saveCalendarsToCache(calendars);
                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(154),
        child: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.date_range, size: 27),
                        color: primaryColor,
                        onPressed: _openCalendarSettings,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 27),
                        color: primaryColor,
                        onPressed: _goToToday,
                      ),
                      const Spacer(),
                      Text(
                        getMonthName(currentWeekIndex),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_outlined, size: 27),
                            color: primaryColor,
                            onPressed: _reloadURLs,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 27),
                            color: primaryColor,
                            onPressed: _openCreateCalendarSheet,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Days(
                  pageController: _pageController,
                  currentWeekIndex: currentWeekIndex,
                  selectedDate: selectedDate,
                  onWeekChanged: (weekIndex) {
                    setState(() => currentWeekIndex = weekIndex);
                  },
                  onDayTapped: _handleDayTapped,
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              controller: _dayViewScrollController,
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final events = getEventsForSelectedDate();
                      final groups = groupOverlappingEvents(events);
                      List<Widget> positionedTiles = [];

                      for (var group in groups) {
                        final groupSize = group.length;

                        for (int i = 0; i < group.length; i++) {
                          final event = group[i];
                          final double totalWidth = MediaQuery.of(context).size.width - timeLineWidth;
                          final double eventWidth = totalWidth / groupSize;
                          final double eventLeft = timeLineWidth + i * eventWidth;

                          positionedTiles.add(
                            EventTile(
                              title: event.title,
                              startHour: event.startHour,
                              startMinute: event.startMinute,
                              durationMinutes: event.durationMinutes,
                              hourHeight: hourHeight,
                              color: event.color,
                              location: event.location,
                              description: event.description,
                              left: eventLeft,
                              width: eventWidth,
                              overlapCount: event.overlapCount,
                            ),
                          );
                        }
                      }

                      return SimpleDayView(
                        hourHeight: hourHeight,
                        timeLineWidth: timeLineWidth,
                        events: events, 
                        scrollController: _dayViewScrollController,
                        displayedDate: selectedDate,
                        eventTileBuilder: (context, _) {
                          return Stack(children: positionedTiles);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  @override
void dispose() {
  _pageController.dispose();
  _dayViewScrollController.dispose();
  try {
    saveCalendarsToCache(calendars);
  } catch (e) {
    debugPrint('Error saving on dispose: $e');
  }
  super.dispose();
}
}