import 'dart:async';
import 'package:flutter/material.dart';
void main() => runApp(const DailyHabitApp());

class HabitItem {
  HabitItem({
    required this.title,
    required this.category,
    required this.color,
    required this.time,
    this.icon,
    this.isHabit = false,
    this.done = false,
  });
  String title;
  String category;
  Color color;
  TimeOfDay? time;
  IconData? icon;
  bool isHabit;
  bool done;
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
  bool dark = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Day by Day',
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
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
    home: TrackerHome(dark: dark, onTheme: () => setState(() => dark = !dark)),
  );
}

class TrackerHome extends StatefulWidget {
  const TrackerHome({super.key, required this.dark, required this.onTheme});
  final bool dark;
  final VoidCallback onTheme;
  @override
  State<TrackerHome> createState() => _TrackerHomeState();
}

class _TrackerHomeState extends State<TrackerHome> {
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
  final Set<int> completedDays = {DateTime.now().day};
  final List<HabitItem> items = [
    HabitItem(
      title: 'Morning stretch',
      category: 'Wellness',
      color: const Color(0xFFE9B892),
      time: const TimeOfDay(hour: 7, minute: 30),
      isHabit: true,
      done: true,
    ),
    HabitItem(
      title: 'Read 10 pages',
      category: 'Learning',
      color: const Color(0xFF9DBBC6),
      time: const TimeOfDay(hour: 12, minute: 0),
      isHabit: true,
    ),
    HabitItem(
      title: 'Take a mindful walk',
      category: 'Wellness',
      color: const Color(0xFFB4C79C),
      time: const TimeOfDay(hour: 17, minute: 0),
      isHabit: true,
    ),
  ];
  final Map<int, Timer> reminders = {};
  int get done => items.where((e) => e.done).length;
  int get percent => items.isEmpty ? 0 : (done / items.length * 100).round();
  @override
  void dispose() {
    for (final timer in reminders.values) {
      timer.cancel();
    }
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
            tooltip: widget.dark ? 'Light mode' : 'Dark mode',
            onPressed: widget.onTheme,
            icon: Icon(
              widget.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: tab, children: pages),
      ),
      floatingActionButton: tab != 1
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
          const Text(
            "Today's Routine",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          TextButton(
            onPressed: () => setState(() => tab = 1),
            child: const Text('See all'),
          ),
        ],
      ),
      if (items.isEmpty)
        _emptyState()
      else
        ...items.take(3).map((item) => _itemCard(item)),
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
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final numberOfDays = DateTime(now.year, now.month + 1, 0).day;
    final weeks = (firstDay.weekday - 1 + numberOfDays + 6) ~/ 7;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_month(now.month)} ${now.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
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
                        now.day,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _calendarDay(int day, int numberOfDays, int today) {
    if (day < 1 || day > numberOfDays) return const SizedBox(height: 34);
    final isToday = day == today;
    final isComplete = completedDays.contains(day);
    return Center(
      child: Container(
        width: 31,
        height: 31,
        decoration: BoxDecoration(
          color: isToday
              ? _green
              : isComplete
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
                color: isToday ? Colors.white : null,
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            if (isComplete && !isToday)
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

  IconData _categoryIcon(String category) => switch (category) {
    'Fitness' => Icons.fitness_center_rounded,
    'Learning' => Icons.auto_stories_rounded,
    'Mindfulness' => Icons.self_improvement_rounded,
    'Productivity' => Icons.bolt_rounded,
    'Personal' => Icons.favorite_rounded,
    _ => Icons.spa_rounded,
  };

  Widget _itemCard(HabitItem item) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: _surface(),
    child: Row(
      children: [
        InkWell(
          onTap: () => setState(() {
            item.done = !item.done;
            if (item.done) {
              completedDays.add(DateTime.now().day);
            } else if (items.every((entry) => !entry.done)) {
              completedDays.remove(DateTime.now().day);
            }
          }),
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
            item.icon ?? _categoryIcon(item.category),
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
                  Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            leading: Icon(
              widget.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            title: Text(widget.dark ? 'Light appearance' : 'Dark appearance'),
            onTap: widget.onTheme,
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
    var category = item?.category ?? 'Wellness';
    var habit = item?.isHabit ?? true;
    var time = item?.time;
    var selectedColor = item?.color ?? _pastelColors.first;
    var selectedIcon = item?.icon ?? _categoryIcon(category);
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
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  items:
                      const [
                            'Wellness',
                            'Learning',
                            'Fitness',
                            'Mindfulness',
                            'Productivity',
                            'Personal',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setSheet(() => category = value ?? category),
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
                  leading: const Icon(Icons.alarm_rounded, color: _green),
                  title: Text(
                    time == null
                        ? 'Add a reminder'
                        : 'Reminder at ${time!.format(sheetContext)}',
                  ),
                  subtitle: const Text('Reminder appears when the app is open'),
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
                SizedBox(
                  width: double.infinity,
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
                              category: category,
                              color: selectedColor,
                              icon: selectedIcon,
                              time: time,
                              isHabit: habit,
                            ),
                          ),
                        );
                      } else {
                        setState(() {
                          item.title = title.text.trim();
                          item.category = category;
                          item.color = selectedColor;
                          item.icon = selectedIcon;
                          item.time = time;
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
              ],
            ),
          ),
        ),
      ),
    );
    if (result == true && time != null && item == null) {
      _scheduleReminder(title.text.trim(), time!);
    }
    title.dispose();
  }

  void _scheduleReminder(String title, TimeOfDay time) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
    final duration = target.difference(now);
    final id = items.length - 1;
    reminders[id]?.cancel();
    reminders[id] = Timer(duration, () {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.notifications_active_rounded,
            color: _green,
            size: 34,
          ),
          title: const Text('A gentle reminder'),
          content: Text('$userName, you need to check your tasks: $title.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    });
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
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => items.remove(item));
  }
}
