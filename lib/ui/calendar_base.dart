import 'package:flutter/material.dart';
import '../core/models.dart';
import 'dart:async'; 
import '../utils.dart';

class Days extends StatelessWidget {
  final PageController pageController;
  final int currentWeekIndex;
  final DateTime selectedDate;
  final Function(int) onWeekChanged;
  final Function(DateTime) onDayTapped;

  const Days({
    super.key,
    required this.pageController,
    required this.currentWeekIndex,
    required this.selectedDate,
    required this.onWeekChanged,
    required this.onDayTapped,
  });

  DateTime getStartOfWeek(int weekOffset) {
    final now = DateTime.now();
    final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    return mondayThisWeek.add(Duration(days: weekOffset * 7));
  }

  static const List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: PageView.builder(
        controller: pageController,
        onPageChanged: (pageIndex) {
          final newWeekIndex = pageIndex - 10000;
          onWeekChanged(newWeekIndex);
        },
        itemBuilder: (context, pageIndex) {
          final weekIndex = pageIndex - 10000;
          final startOfWeek = getStartOfWeek(weekIndex);
          final dates = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (index) {
                final dayDate = dates[index];
                final isSelected = isSameDate(dayDate, selectedDate);

                return Padding(
                  padding: EdgeInsets.only(right: index < 6 ? 15 : 0),
                  child: Day(
                    text: _weekDays[index],
                    selected: isSelected,
                    index: index,
                    date: dayDate.day.toString(),
                    onTap: () => onDayTapped(dayDate),
                  ),
                );
              }),
            ),
          );
        },
        itemCount: 20000,
      ),
    );
  }
}


class EventTile extends StatelessWidget {
  final String title;
  final int startHour;
  final int startMinute;
  final int durationMinutes;
  final double hourHeight;
  final double left;
  final double width;
  final Color color;
  final String description;
  final String location;
  final int overlapCount;

  const EventTile({
    super.key,
    required this.title,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    required this.hourHeight,
    this.left = timeLineWidth,
    required this.width,
    required this.color,
    this.description = "",
    this.location = "", 
    required  this.overlapCount,
  });


  String _formatTimeRange() {
    final startTime = DateTime(2023, 1, 1, startHour, startMinute);
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${startTime.hour}:${twoDigits(startTime.minute)} - ${endTime.hour}:${twoDigits(endTime.minute)}';
  }


  
  @override
  Widget build(BuildContext context) {
    final top = getOffsetFromTime(startHour, startMinute);
    final height = durationMinutes * (hourHeight / 60);

    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 15,
            vertical: durationMinutes < 40 ? 4 : 10,
          ),

          child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: durationMinutes < 40 ? 12 : 15,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (overlapCount<3)
          Text(
            _formatTimeRange(),
            style: TextStyle(
              color: const Color(0xFF7A7A7A),
              fontSize: durationMinutes < 40 ? 12 : 13,
            ),
          ),
      ],
    ),
    if (durationMinutes>=60 && location.trim().isNotEmpty)
        Flexible(
          child: Text(
            location,
            style: const TextStyle(color: Color.fromARGB(255, 69, 69, 69)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
    if (durationMinutes>60 && description.trim().isNotEmpty)
        Flexible(
          child: Text(
            description,
            style: const TextStyle(
              color: Color(0xFF343434),
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
  ],
),


        ),
      ),
    );
  }
}


class Day extends StatelessWidget {
  final String text;
  final bool selected;
  final int index;
  final String date;
  final VoidCallback onTap;

  const Day({
    super.key,
    required this.text,
    required this.selected,
    required this.index,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: dayCircleSize,
            height: dayCircleSize,
            decoration: BoxDecoration(
              color: selected ? primaryColor : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: selected ? primaryShadowColor : Colors.white,
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
              border: Border.all(
                color: selected ? primaryShadowColor : Colors.white,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              date,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SimpleDayView extends StatefulWidget {
  final double hourHeight;
  final double timeLineWidth;
  final List<MyEvent> events;
  final Widget Function(BuildContext, MyEvent event) eventTileBuilder;
  final ScrollController? scrollController;
  final DateTime displayedDate;
  
  const SimpleDayView({
    super.key,
    required this.hourHeight,
    required this.timeLineWidth,
    required this.events,
    required this.eventTileBuilder,
    this.scrollController,
    required this.displayedDate,
  });

  @override
  State<SimpleDayView> createState() => _SimpleDayViewState();
}

class _SimpleDayViewState extends State<SimpleDayView> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFirstEvent());

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    _scrollController.dispose(); 
    super.dispose();
  }

  void _scrollToFirstEvent() {
    if (widget.events.isNotEmpty) {
      final firstEvent = widget.events.reduce(
        (a, b) => (a).startHour < (b).startHour ? a : b,
      );
      
      final offset = getOffsetFromTime(
        (firstEvent).startHour,
        (firstEvent).startMinute,
      ) ;
      
      _scrollController.jumpTo(offset);
    }
  }
  

  double _getLiveTimeOffset() {
    final now = DateTime.now();
    return getOffsetFromTime(now.hour, now.minute);
  }

  @override
  Widget build(BuildContext context) {
    final totalHeight = hourHeight * 24;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
        maxHeight: totalHeight,
      ),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            Positioned.fill(child: _buildTimeline()),
            ...widget.events.map((event) => widget.eventTileBuilder(context, event)),
            _buildLiveIndicator(),
          ],
        ),
      ),
    );
  }

 Widget _buildTimeline() {
  return Column(
    children: List.generate(48, (index) {
      final hour = index ~/ 2;
      final isFullHour = index % 2 == 0;
      final label = isFullHour ? '$hour:00' : '';

      final scaleY = isFullHour ? 1.0 : 0.5; 

      return Row(
        children: [
          SizedBox(
            width: timeLineWidth,
            height: hourHeight / 2,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: Transform.scale(
              scaleY: scaleY,
              alignment: Alignment.center,
              child: Container(
                height: 1.0,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      );
    }),
  );
}


  Widget _buildLiveIndicator() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final displayedDate = DateTime(
      widget.displayedDate.year,
      widget.displayedDate.month,
      widget.displayedDate.day,
    );

    if (displayedDate != today) {
      return Divider(color: Colors.transparent);
    }

    return Positioned(
      top: _getLiveTimeOffset(),
      left: 0,
      right: 0,
      child: Row(
        children: [
          SizedBox(width: timeLineWidth),
          Expanded(
            child: Container(
              height: 8,
              alignment: Alignment.centerLeft,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Divider(color: Colors.red, thickness: 1.5),
                    ),
                  ),
                  Positioned(
                    left: -1,
                    top: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
