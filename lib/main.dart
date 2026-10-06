import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const DailyHabitApp());

const _alarmChannel = MethodChannel('com.example.daily_habit/alarms');

class HabitItem {
  HabitItem({
    required this.title,
    this.description = '',
    required this.color,
    required this.time,
    this.icon,
    this.reminderDate,
    this.isHabit = false,
    this.done = false,
    int? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch;
  String title;
  String description;
  Color color;
  TimeOfDay? time;
  IconData? icon;
  DateTime? reminderDate;
  bool isHabit;
  bool done;
  final int id;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'color': color.toARGB32(),
    'timeHour': time?.hour,
    'timeMinute': time?.minute,
    'icon': icon?.codePoint,
    'reminderDate': reminderDate?.toIso8601String(),
    'isHabit': isHabit,
    'done': done,
  };

  factory HabitItem.fromJson(Map<String, dynamic> json) => HabitItem(
    id: json['id'] as int?,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    color: Color(json['color'] as int? ?? 0xFFE9B892),
    time: json['timeHour'] == null || json['timeMinute'] == null
        ? null
        : TimeOfDay(
            hour: json['timeHour'] as int,
            minute: json['timeMinute'] as int,
          ),
    icon: json['icon'] == null
        ? null
        : IconData(
            json['icon'] as int,
            fontFamily: 'MaterialIcons',
          ),
    reminderDate: json['reminderDate'] == null
        ? null
        : DateTime.tryParse(json['reminderDate'] as String),
    isHabit: json['isHabit'] as bool? ?? false,
    done: json['done'] as bool? ?? false,
  );
}

const _ink = Color(0xFF202B2A);
const _green = Color(0xFF356B5B);
const _mint = Color(0xFFE8F2ED);

class DailyHabitApp extends StatefulWidget {
  const DailyHabitApp({super.key});
  @override
  State<DailyHabitApp> createState() => _DailyHabitAppState();
}

class _DailyHabitAppState extends State<DailyHabitApp> {
  ThemeMode themeMode = ThemeMode.system;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Day by Day',
    themeMode: themeMode,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _green,
        surface: const Color(0xFFF8F9F6),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9F6),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9F6),
        foregroundColor: _ink,
      ),
      fontFamily: 'Roboto',
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF81B9A5),
        brightness: Brightness.dark,
      ),
    ),
    home: TrackerHome(
      themeMode: themeMode,
      onTheme: (value) => setState(() => themeMode = value),
    ),
  );
}

class TrackerHome extends StatefulWidget {
  const TrackerHome({super.key, required this.themeMode, required this.onTheme});
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onTheme;
  @override
  State<TrackerHome> createState() => _TrackerHomeState();
}

class _TrackerHomeState extends State<TrackerHome> with WidgetsBindingObserver {
  static const _itemsStorageKey = 'daily_habit_items_v1';
  bool _isLoadingItems = true;
  Future<void> _saveQueue = Future<void>.value();
  int tab = 0;
  String userName = 'Rosie';
  int avatarIndex = 0;
  final List<IconData> avatars = const [
    Icons.face_3_rounded,
    Icons.face_4_rounded,
    Icons.face_5_rounded,
    Icons.face_6_rounded,
    Icons.sentiment_satisfied_alt_rounded,
  ];
  static const List<Color> _pastelColors = [
    Color(0xFFF6D6D6),
    Color(0xFFFFE3C2),
    Color(0xFFFFF0B3),
    Color(0xFFDDF0CF),
    Color(0xFFD5EEE9),
    Color(0xFFD9E5FA),
    Color(0xFFE6DDF8),
    Color(0xFFF3DDED),
  ];
  static const List<IconData> _taskIcons = [
    Icons.water_drop_rounded,
    Icons.menu_book_rounded,
    Icons.fitness_center_rounded,
    Icons.self_improvement_rounded,
    Icons.favorite_rounded,
    Icons.home_rounded,
    Icons.star_rounded,
    Icons.check_circle_rounded,
    Icons.music_note_rounded,
    Icons.restaurant_rounded,
    Icons.directions_walk_rounded,
    Icons.spa_rounded,
  ];
  DateTime selectedDate = DateTime.now();
  DateTime calendarMonth = DateTime(
    DateTime.now().year == 2026 ? DateTime.now().year : 2026,
    DateTime.now().year == 2026 ? DateTime.now().month : 1,
  );
  final ScrollController _homeScrollController = ScrollController();
  final List<HabitItem> items = [
    HabitItem(
      title: 'Morning stretch',
      color: const Color(0xFFE9B892),
      time: const TimeOfDay(hour: 7, minute: 30),
      isHabit: true,
      done: true,
    ),
    HabitItem(
      title: 'Read 10 pages',
      color: const Color(0xFF9DBBC6),
      time: const TimeOfDay(hour: 12, minute: 0),
      isHabit: true,
    ),
    HabitItem(
      title: 'Take a mindful walk',
      color: const Color(0xFFB4C79C),
      time: const TimeOfDay(hour: 17, minute: 0),
      isHabit: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadItems();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final savedItems = preferences.getString(_itemsStorageKey);
      if (savedItems != null) {
        final decoded = jsonDecode(savedItems) as List<dynamic>;
        items
          ..clear()
          ..addAll(
            decoded.map(
              (value) => HabitItem.fromJson(value as Map<String, dynamic>),
            ),
          );
      } else {
        await _saveItems();
      }
    } catch (error) {
      debugPrint('Could not load saved tasks: $error');
    } finally {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _saveItems() {
    _saveQueue = _saveQueue.then((_) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _itemsStorageKey,
        jsonEncode(items.map((item) => item.toJson()).toList()),
      );
    });
    return _saveQueue;
  }
  int get done => items.where((e) => e.done).length;
  int get percent => items.isEmpty ? 0 : (done / items.length * 100).round();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _tasks(), _stats(), _profile()];
    return Scaffold(
      drawer: _drawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.spa_rounded, color: _green, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'day by day',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Light mode'
                : 'Dark mode',
            onPressed: () => widget.onTheme(
              Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingItems
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(child: IndexedStack(index: tab, children: pages)),
      floatingActionButton: _isLoadingItems || tab != 1
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _editItem(),
              backgroundColor: _green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New habit',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _home() => ListView(
    key: const PageStorageKey<String>('home-scroll'),
    controller: _homeScrollController,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
    children: [
      Text(
        _greeting(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Make today count.',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 20),
      _overviewCard(),
      const SizedBox(height: 20),
      _calendarCard(),
      const SizedBox(height: 22),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isSameDate(selectedDate, DateTime.now())
                ? "Today's Routine"
                : '${_month(selectedDate.month)} ${selectedDate.day} Routine',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          TextButton(
            onPressed: () => setState(() => tab = 1),
            child: const Text('See all'),
          ),
        ],
      ),
      if (_itemsForDate(selectedDate).isEmpty)
        _emptyState()
      else
        ..._itemsForDate(selectedDate).map((item) => _itemCard(item)),
      const SizedBox(height: 12),
      _quoteCard(),
    ],
  );

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12
        ? 'GOOD MORNING'
        : h < 17
        ? 'GOOD AFTERNOON'
        : 'GOOD EVENING';
  }

  Widget _overviewCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _green,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: _green.withOpacity(.20),
          blurRadius: 20,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR DAILY MOMENTUM',
                style: TextStyle(
                  color: Color(0xFFD6E8DF),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '$done of ${items.length} complete',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                done == items.length && items.isNotEmpty
                    ? 'Wonderful work. Keep it up!'
                    : 'Small steps make a big difference.',
                style: const TextStyle(color: Color(0xFFD6E8DF), fontSize: 12),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: items.isEmpty ? 0 : done / items.length,
                  minHeight: 7,
                  backgroundColor: Colors.white24,
                  color: const Color(0xFFE6C991),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: items.isEmpty ? 0 : done / items.length,
                strokeWidth: 7,
                backgroundColor: Colors.white24,
                color: const Color(0xFFE6C991),
              ),
              Center(
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _calendarCard() {
    final month = calendarMonth;
    final firstDay = DateTime(month.year, month.month, 1);
    final numberOfDays = DateTime(month.year, month.month + 1, 0).day;
    final weeks = (firstDay.weekday - 1 + numberOfDays + 6) ~/ 7;
    final today = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: month.month == 1
                        ? null
                        : () => setState(
                            () =>
                                calendarMonth = DateTime(month.year, month.month - 1),
                          ),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _chooseCalendarMonth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_month(month.month)} ${month.year}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_drop_down_rounded, size: 21),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: month.month == 12
                        ? null
                        : () => setState(
                            () =>
                                calendarMonth = DateTime(month.year, month.month + 1),
                          ),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFD99454),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_streak()} day streak',
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 7),
          for (var week = 0; week < weeks; week++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (var weekday = 0; weekday < 7; weekday++)
                    Expanded(
                      child: _calendarDay(
                        week * 7 + weekday - firstDay.weekday + 2,
                        numberOfDays,
                        today.year == month.year && today.month == month.month
                            ? today.day
                            : -1,
                        month.month,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _chooseCalendarMonth() async {
    final today = DateTime.now();
    final chosenMonth = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a month',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  childAspectRatio: 2.1,
                ),
                itemBuilder: (context, index) {
                  final monthNumber = index + 1;
                  final isSelected = monthNumber == calendarMonth.month;
                  final isCurrentMonth =
                      monthNumber == today.month &&
                      calendarMonth.year == today.year;
                  final colors = Theme.of(context).colorScheme;
                  return Material(
                    color: isSelected ? _green : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () => Navigator.pop(sheetContext, monthNumber),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            _month(monthNumber),
                            style: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: isSelected || isCurrentMonth
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (isCurrentMonth)
                            Positioned(
                              bottom: 5,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : _green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (chosenMonth == null || !mounted) return;
    final targetYear = calendarMonth.year;
    final targetDay = chosenMonth == today.month && targetYear == today.year
        ? today.day
        : 1;
    setState(() {
      calendarMonth = DateTime(targetYear, chosenMonth);
      selectedDate = DateTime(targetYear, chosenMonth, targetDay);
    });
  }

  Widget _calendarDay(int day, int numberOfDays, int today, int month) {
    if (day < 1 || day > numberOfDays) return const SizedBox(height: 34);
    final isToday = day == today;
    final hasTasks = _itemsForDate(
      DateTime(calendarMonth.year, month, day),
    ).isNotEmpty;
    final isSelected =
        selectedDate.year == calendarMonth.year &&
        selectedDate.month == month &&
        selectedDate.day == day;
    return Center(
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(
          () => selectedDate = DateTime(calendarMonth.year, month, day),
        ),
        child: Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: isSelected || isToday
                ? _green
                : hasTasks
                ? _mint
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  color: isSelected || isToday ? Colors.white : null,
                  fontSize: 12,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
              if (hasTasks && !isToday && !isSelected)
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _month(int m) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m - 1];
  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  List<HabitItem> _itemsForDate(DateTime date) => items.where((item) {
    final reminderDate = item.reminderDate;
    if (reminderDate == null) return _isSameDate(date, DateTime.now());
    if (_isSameDate(date, reminderDate)) return true;
    return item.isHabit && date.isAfter(reminderDate);
  }).toList()..sort((first, second) {
    if (first.time == null) return second.time == null ? 0 : 1;
    if (second.time == null) return -1;
    final firstMinutes = first.time!.hour * 60 + first.time!.minute;
    final secondMinutes = second.time!.hour * 60 + second.time!.minute;
    return firstMinutes.compareTo(secondMinutes);
  });

  int _streak() => done > 0 ? (done + 2).clamp(1, 12).toInt() : 0;
  Widget _quoteCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF2EDE4),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.format_quote_rounded, color: Color(0xFFB58A54), size: 24),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A little progress each day adds up to big results.',
                style: TextStyle(
                  color: Color(0xFF544638),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'YOUR DAILY REMINDER',
                style: TextStyle(
                  color: Color(0xFF927959),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tasks() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
    children: [
      const Text(
        'Your routine',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        '${items.length} habits to build a better day',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _surface(),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: _green),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '${_weekday(DateTime.now().weekday)}, ${_month(DateTime.now().month)} ${DateTime.now().day}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$done/${items.length} done',
              style: const TextStyle(
                color: _green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (items.isEmpty) _emptyState() else ...items.map((i) => _itemCard(i)),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => _editItem(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add a habit'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _green,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFBDD3C8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    ],
  );
  String _weekday(int d) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][d - 1];

  Widget _itemCard(HabitItem item) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: _surface(),
    child: Row(
      children: [
        InkWell(
          onTap: () {
            setState(() => item.done = !item.done);
            _saveItems();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: item.done ? _green : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: item.done ? _green : const Color(0xFFBFCBC5),
                width: 1.6,
              ),
            ),
            child: item.done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ),
        const SizedBox(width: 13),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: item.color.withOpacity(.28),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            item.icon ?? Icons.spa_rounded,
            color: _green,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: item.done ? TextDecoration.lineThrough : null,
                  color: item.done
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    item.isHabit
                        ? Icons.repeat_rounded
                        : Icons.task_alt_rounded,
                    size: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  if (item.description.isNotEmpty)
                    Expanded(
                      child: Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (item.time != null) ...[
                    const SizedBox(width: 9),
                    Icon(
                      Icons.alarm_rounded,
                      size: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item.time!.format(context),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.reminderDate != null) ...[
                      const SizedBox(width: 5),
                      Text(
                        '${item.reminderDate!.month}/${item.reminderDate!.day}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (v) {
            if (v == 'edit')
              _editItem(item);
            else
              _deleteItem(item);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
    ),
  );

  Widget _stats() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
    children: [
      const Text(
        'Your progress',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Every small win deserves a moment.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TODAY'S COMPLETION",
                    style: TextStyle(
                      color: Color(0xFFD6E8DF),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 37,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$done out of ${items.length} habits completed',
                    style: const TextStyle(
                      color: Color(0xFFD6E8DF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.auto_awesome_rounded,
              size: 55,
              color: Color(0xFFE6C991),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          _statTile('Completed', '$done', Icons.check_circle_outline_rounded),
          const SizedBox(width: 10),
          _statTile(
            'Pending',
            '${items.length - done}',
            Icons.pending_actions_rounded,
          ),
        ],
      ),
      const SizedBox(height: 19),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: _surface(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This week',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final value = i == DateTime.now().weekday - 1
                    ? (items.isEmpty ? 0.04 : done / items.length)
                    : [.6, .4, .8, .55, .72, .3, .45][i];
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 19,
                          height: (value * 82).clamp(5, 82).toDouble(),
                          decoration: BoxDecoration(
                            color: i == DateTime.now().weekday - 1
                                ? _green
                                : const Color(0xFFC7D9D0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _quoteCard(),
    ],
  );
  Widget _statTile(String label, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: icon == Icons.check_circle_outline_rounded
                  ? const Color(0xFFE3F2E8)
                  : const Color(0xFFFFEDE4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: icon == Icons.check_circle_outline_rounded
                  ? const Color(0xFF398461)
                  : const Color(0xFFE28C59),
              size: 20,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
  BoxDecoration _surface() => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.35)),
  );
  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(26),
    decoration: _surface(),
    child: const Column(
      children: [
        Icon(Icons.spa_outlined, color: _green, size: 35),
        SizedBox(height: 10),
        Text(
          'A fresh start',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        SizedBox(height: 5),
        Text(
          'Add your first habit and make today count.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _profile() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
    children: [
      const Text(
        'Your profile',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Make your reminders feel personal.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFECE8FF), Color(0xFFE5F3EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 43,
              backgroundColor: Colors.white.withOpacity(.8),
              child: Icon(
                avatars[avatarIndex],
                size: 45,
                color: const Color(0xFF7368C7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your habits, your pace.',
              style: TextStyle(color: Color(0xFF687477)),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_rounded, size: 17),
              label: const Text('Edit profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                backgroundColor: Colors.white.withOpacity(.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: _surface(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminder preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0D8),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFE39B45),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$userName, you need to check your tasks',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your name will appear in your in-app reminders.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _editProfile() async {
    final controller = TextEditingController(text: userName);
    var selectedAvatar = avatarIndex;
    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Your profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(
                  avatars.length,
                  (index) => ChoiceChip(
                    label: Icon(
                      avatars[index],
                      color: selectedAvatar == index ? Colors.white : _green,
                      size: 20,
                    ),
                    selected: selectedAvatar == index,
                    selectedColor: _green,
                    onSelected: (_) =>
                        setDialogState(() => selectedAvatar = index),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                setState(() {
                  userName = controller.text.trim();
                  avatarIndex = selectedAvatar;
                });
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (updated == true && mounted) setState(() {});
  }

  Widget _drawer() => Drawer(
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 25, 22, 24),
            color: _green,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.spa_rounded, color: Colors.white, size: 33),
                const SizedBox(height: 14),
                Text(
                  'day by day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'A little better, every day.',
                  style: TextStyle(color: Color(0xFFD6E8DF), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _drawerItem(Icons.home_rounded, 'Home', 0),
          _drawerItem(Icons.checklist_rounded, 'My habits', 1),
          _drawerItem(Icons.insights_rounded, 'Progress', 2),
          _drawerItem(Icons.person_rounded, 'Profile', 3),
          const Divider(height: 28),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Reminders'),
            subtitle: const Text('Manage habit reminder times'),
            onTap: () {
              Navigator.pop(context);
              setState(() => tab = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Appearance'),
            subtitle: Text(_themeModeName(widget.themeMode)),
            trailing: PopupMenuButton<ThemeMode>(
              tooltip: 'Choose appearance',
              initialValue: widget.themeMode,
              onSelected: widget.onTheme,
              itemBuilder: (context) => [
                _themeModeMenuItem(ThemeMode.system, 'System'),
                _themeModeMenuItem(ThemeMode.light, 'Light'),
                _themeModeMenuItem(ThemeMode.dark, 'Dark'),
              ],
            ),
            onTap: () => widget.onTheme(ThemeMode.system),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'DAILY HABIT TRACKER | V1.0',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                color: Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _themeModeName(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  PopupMenuItem<ThemeMode> _themeModeMenuItem(ThemeMode mode, String label) =>
      PopupMenuItem<ThemeMode>(
        value: mode,
        child: Row(
          children: [
            Icon(
              widget.themeMode == mode
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      );

  Widget _drawerItem(IconData icon, String title, int index) => ListTile(
    leading: Icon(icon, color: tab == index ? _green : null),
    title: Text(
      title,
      style: TextStyle(
        fontWeight: tab == index ? FontWeight.w800 : FontWeight.w500,
      ),
    ),
    selected: tab == index,
    onTap: () {
      Navigator.pop(context);
      setState(() => tab = index);
    },
  );

  Future<void> _editItem([HabitItem? item]) async {
    final title = TextEditingController(text: item?.title ?? '');
    final description = TextEditingController(text: item?.description ?? '');
    var habit = item?.isHabit ?? true;
    var time = item?.time;
    var reminderDate = item?.reminderDate ?? selectedDate;
    var selectedColor = item?.color ?? _pastelColors.first;
    var selectedIcon = item?.icon ?? Icons.spa_rounded;
    var titleError = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            MediaQuery.of(sheetContext).viewInsets.bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  item == null ? 'Create a habit' : 'Edit habit',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 17),
                TextField(
                  controller: title,
                  autofocus: true,
                  maxLength: 48,
                  onChanged: (value) {
                    if (value.trim().isNotEmpty && titleError) {
                      setSheet(() => titleError = false);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'What would you like to do?',
                    hintText: 'e.g. Drink a glass of water',
                    errorText: titleError
                        ? 'Please put your habit/tasks to do'
                        : null,
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: description,
                  maxLength: 120,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add a note or reminder message',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Choose a color',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: _pastelColors
                      .map(
                        (color) => InkWell(
                          onTap: () => setSheet(() => selectedColor = color),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color
                                    ? _green
                                    : Colors.white,
                                width: selectedColor == color ? 3 : 1,
                              ),
                            ),
                            child: selectedColor == color
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 17,
                                    color: _ink,
                                  )
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Choose an icon',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _taskIcons
                      .map(
                        (icon) => InkWell(
                          onTap: () => setSheet(() => selectedIcon = icon),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: selectedIcon == icon
                                  ? selectedColor
                                  : Theme.of(
                                      sheetContext,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedIcon == icon
                                    ? _green
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(icon, color: _green, size: 20),
                          ),
                        ),
                      )
                      .toList(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeat as a daily habit'),
                  value: habit,
                  activeColor: _green,
                  onChanged: (value) => setSheet(() => habit = value),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_month_rounded,
                    color: _green,
                  ),
                  title: const Text('Reminder date'),
                  subtitle: Text(
                    '${_month(reminderDate.month)} ${reminderDate.day}, ${reminderDate.year}',
                  ),
                  trailing: const Icon(Icons.edit_calendar_rounded),
                  onTap: () async {
                    final today = DateTime.now();
                    final minimum = today.year == 2026
                        ? DateTime(today.year, today.month, today.day)
                        : DateTime(2026, 1, 1);
                    final maximum = DateTime(2026, 12, 31);
                    final initial = reminderDate.isBefore(minimum)
                        ? minimum
                        : reminderDate.isAfter(maximum)
                        ? maximum
                        : reminderDate;
                    final selected = await showDatePicker(
                      context: sheetContext,
                      initialDate: initial,
                      firstDate: minimum,
                      lastDate: maximum,
                      helpText: 'Choose a reminder date in 2026',
                    );
                    if (selected != null) {
                      setSheet(
                        () => reminderDate = DateTime(
                          selected.year,
                          selected.month,
                          selected.day,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm_rounded, color: _green),
                  title: Text(
                    time == null
                        ? 'Add a reminder'
                        : 'Reminder at ${time!.format(sheetContext)}',
                  ),
                  subtitle: Text(
                    'Rings on ${_month(reminderDate.month)} ${reminderDate.day}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.schedule_rounded),
                    onPressed: () async {
                      final selected = await showTimePicker(
                        context: sheetContext,
                        initialTime: time ?? TimeOfDay.now(),
                      );
                      if (selected != null) setSheet(() => time = selected);
                    },
                  ),
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: sheetContext,
                      initialTime: time ?? TimeOfDay.now(),
                    );
                    if (selected != null) setSheet(() => time = selected);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (item != null) ...[
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text('Cancel edit'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            if (title.text.trim().isEmpty) {
                              setSheet(() => titleError = true);
                              return;
                            }
                            if (item == null) {
                              setState(
                                () => items.add(
                                  HabitItem(
                                    title: title.text.trim(),
                                    description: description.text.trim(),
                                    color: selectedColor,
                                    icon: selectedIcon,
                                    time: time,
                                    reminderDate: reminderDate,
                                    isHabit: habit,
                                  ),
                                ),
                              );
                            } else {
                              setState(() {
                                item.title = title.text.trim();
                                item.description = description.text.trim();
                                item.color = selectedColor;
                                item.icon = selectedIcon;
                                item.time = time;
                                item.reminderDate = reminderDate;
                                item.isHabit = habit;
                              });
                            }
                            Navigator.pop(sheetContext, true);
                          },
                          child: Text(
                            item == null ? 'Add to my routine' : 'Save changes',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == true && item != null) {
      await _saveItems();
      await _cancelReminder(item.id);
      if (time != null) {
        await _scheduleReminder(
          item,
          title.text.trim(),
          description.text.trim(),
          time!,
          reminderDate,
          habit,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Successfully edit')));
      }
    } else if (result == true && item == null) {
      final added = items.last;
      await _saveItems();
      if (time != null) {
        await _scheduleReminder(
          added,
          title.text.trim(),
          description.text.trim(),
          time!,
          reminderDate,
          habit,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task Added')));
      }
    }
    title.dispose();
    description.dispose();
  }

  Future<void> _scheduleReminder(
    HabitItem item,
    String title,
    String description,
    TimeOfDay time,
    DateTime date,
    bool repeatDaily,
  ) async {
    try {
      await _alarmChannel.invokeMethod<void>('schedule', {
        'id': item.id.toString(),
        'title': title,
        'description': description,
        'profileName': userName,
        'hour': time.hour,
        'minute': time.minute,
        'year': date.year,
        'month': date.month,
        'day': date.day,
        'repeatDaily': repeatDaily,
      });
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not set reminder: ${error.message}')),
        );
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Alarms are available in the Android app, not in the web version.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _cancelReminder(int id) async {
    try {
      await _alarmChannel.invokeMethod<void>('cancel', {'id': id.toString()});
    } on PlatformException {
      // On platforms without native alarm support there is nothing to cancel.
    } on MissingPluginException {
      // Web does not have the Android alarm channel.
    }
  }

  Future<void> _deleteItem(HabitItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this habit?'),
        content: Text('"${item.title}" will be removed from your routine.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _cancelReminder(item.id);
      setState(() => items.remove(item));
      await _saveItems();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task Deleted')));
      }
    }
  }
}
