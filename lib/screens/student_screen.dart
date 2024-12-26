import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/study_record_model.dart';

class StudentScreen extends ConsumerStatefulWidget {
  const StudentScreen({super.key});

  @override
  ConsumerState<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends ConsumerState<StudentScreen> {
  List<StudyRecord> _weeklyRecords = [];
  List<StudyRecord> _monthlyRecords = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.id == null) return;

    // Haftalık kayıtlar için
    final now = DateTime.now();
    // Pazartesi gününü bul (1 = Pazartesi, 7 = Pazar)
    final weekStartDate = now.subtract(Duration(days: now.weekday - 1));
    final weekEndDate = weekStartDate.add(const Duration(days: 6));

    final weeklyRecords = await ref
        .read(studyControllerProvider)
        .getStudentRecords(
          user.id!,
          startDate: DateTime(
              weekStartDate.year, weekStartDate.month, weekStartDate.day),
          endDate: DateTime(
              weekEndDate.year, weekEndDate.month, weekEndDate.day, 23, 59, 59),
        );

    // Aylık kayıtlar için
    final monthStartDate = DateTime(now.year, now.month, 1);
    final monthEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final monthlyRecords =
        await ref.read(studyControllerProvider).getStudentRecords(
              user.id!,
              startDate: monthStartDate,
              endDate: monthEndDate,
            );

    setState(() {
      _weeklyRecords = weeklyRecords;
      _monthlyRecords = monthlyRecords;
    });

    print('Haftalık kayıt sayısı: ${_weeklyRecords.length}');
    print('Aylık kayıt sayısı: ${_monthlyRecords.length}');

    // Haftalık kayıtların tarihlerini yazdır
    for (var record in _weeklyRecords) {
      print(
          'Haftalık kayıt: ${DateFormat('dd.MM.yyyy').format(record.studyDate)}');
    }

    // Aylık kayıtların tarihlerini yazdır
    for (var record in _monthlyRecords) {
      print(
          'Aylık kayıt: ${DateFormat('dd.MM.yyyy').format(record.studyDate)}');
    }
  }

  bool _hasStudiedOnDay(DateTime day) {
    return _monthlyRecords.any((record) =>
        record.studyDate.year == day.year &&
        record.studyDate.month == day.month &&
        record.studyDate.day == day.day);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE67817),
        title: Text(
          'Hoş geldin, ${user.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(authControllerProvider).signOut();
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE67817).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE67817).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 40,
                          color: Color(0xFFE67817),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bugün ders çalıştıysan aşağıdaki butona tıkla!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: 'Not ekle (isteğe bağlı)',
                          hintText: 'Bugün neler çalıştığını not edebilirsin',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.note_rounded),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          backgroundColor: const Color(0xFFE67817),
                        ),
                        onPressed: () async {
                          final result = await ref
                              .read(studyControllerProvider)
                              .recordStudy(note: _noteController.text.trim());

                          if (!mounted) return;

                          AwesomeDialog(
                            context: context,
                            dialogType: result.$1
                                ? DialogType.success
                                : DialogType.error,
                            animType: AnimType.scale,
                            title: result.$1 ? 'Başarılı' : 'Hata',
                            desc: result.$2,
                            btnOkOnPress: () {
                              if (result.$1) {
                                _loadRecords();
                                _noteController.clear();
                              }
                            },
                          ).show();
                        },
                        icon: const Icon(Icons.check_circle_rounded,
                            color: Colors.white),
                        label: const Text(
                          'Çalıştım',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Haftalık çalışma
                          Column(
                            children: [
                              Text(
                                'Bu Hafta',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFE67817).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 28,
                                      color: const Color(0xFFE67817),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_weeklyRecords.length} gün',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            color: const Color(0xFFE67817),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'çalışma yaptın',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            color: const Color(0xFFE67817)
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Aylık çalışma
                          Column(
                            children: [
                              Text(
                                'Bu Ay',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFE67817).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 28,
                                      color: const Color(0xFFE67817),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_monthlyRecords.length} gün',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            color: const Color(0xFFE67817),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'çalışma yaptın',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            color: const Color(0xFFE67817)
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_weeklyRecords.length >= 5) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tebrikler! Bu hafta ${_weeklyRecords.length} gün çalıştığınız için +5 puan aldınız!',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Çalışma Takvimi',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE67817).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: const Color(0xFFE67817),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('MMMM yyyy', 'tr_TR')
                                      .format(_focusedDay),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFFE67817),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TableCalendar(
                        locale: 'tr_TR',
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.now(),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                          _loadRecords();
                        },
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Hafta',
                          CalendarFormat.twoWeeks: 'Ay',
                          CalendarFormat.week: '2 Hafta',
                        },
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: true,
                          weekendTextStyle: TextStyle(color: colorScheme.error),
                          holidayTextStyle: TextStyle(color: colorScheme.error),
                          defaultTextStyle: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          outsideTextStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          todayTextStyle: TextStyle(
                            color: const Color(0xFFE67817),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: const Color(0xFFE67817),
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFFE67817).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE67817),
                              width: 1,
                            ),
                          ),
                          markerDecoration: BoxDecoration(
                            color: colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          formatButtonTextStyle: TextStyle(
                            color: const Color(0xFFE67817),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          formatButtonDecoration: BoxDecoration(
                            color: const Color(0xFFE67817).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            if (_hasStudiedOnDay(date)) {
                              return Positioned(
                                bottom: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  width: 8,
                                  height: 8,
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
