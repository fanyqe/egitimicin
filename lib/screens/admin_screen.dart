import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border, Color, TextSpan;
import 'package:file_picker/file_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../widgets/custom_text_field.dart';
import '../models/user_model.dart';
import '../models/study_record_model.dart';
import 'student_detail_screen.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  List<DateTime> _getDaysBetween(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          // Tab değişikliklerini dinle
          tabController.addListener(() {
            // FAB'ı yeniden oluştur
            if (context.mounted) {
              (context as Element).markNeedsBuild();
            }
          });

          return Scaffold(
            appBar: AppBar(
              backgroundColor: colorScheme.primary,
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
            floatingActionButtonLocation: ExpandableFab.location,
            floatingActionButton: ExpandableFab(
              type: ExpandableFabType.fan,
              distance: 60,
              openButtonBuilder: DefaultFloatingActionButtonBuilder(
                child: const Icon(Icons.menu_rounded),
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              closeButtonBuilder: DefaultFloatingActionButtonBuilder(
                child: const Icon(Icons.close),
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              children: [
                FloatingActionButton.small(
                  heroTag: 'logout',
                  onPressed: () {
                    ref.read(authControllerProvider).signOut();
                  },
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.logout_rounded),
                ),
                if (tabController.index == 2) // Sadece Raporlar tabında göster
                  Consumer(
                    builder: (context, ref, child) {
                      final selectedClassName =
                          ref.watch(selectedClassNameProvider);
                      final selectedSection =
                          ref.watch(selectedSectionProvider);
                      final startDate = ref.watch(startDateProvider);
                      final endDate = ref.watch(endDateProvider);
                      final students = ref.watch(studentsForReportProvider);

                      return students.when(
                        data: (studentList) => FloatingActionButton.small(
                          heroTag: 'excel',
                          onPressed: studentList.isEmpty
                              ? null
                              : () async {
                                  try {
                                    // Android 13+ için izin kontrolü
                                    if (Platform.isAndroid) {
                                      final storageStatus =
                                          await Permission.storage.status;
                                      final photosStatus =
                                          await Permission.photos.status;

                                      if (storageStatus.isDenied ||
                                          photosStatus.isDenied) {
                                        // İzinleri iste
                                        Map<Permission, PermissionStatus>
                                            statuses = await [
                                          Permission.storage,
                                          Permission.photos,
                                        ].request();

                                        bool hasPermission =
                                            statuses[Permission.storage]!
                                                    .isGranted ||
                                                statuses[Permission.photos]!
                                                    .isGranted;

                                        if (!hasPermission) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Depolama izni gerekli'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }
                                    }

                                    final excel = Excel.createExcel();
                                    final sheet =
                                        excel[excel.getDefaultSheet()!];

                                    // Başlıklar
                                    sheet
                                        .cell(CellIndex.indexByColumnRow(
                                            columnIndex: 0, rowIndex: 0))
                                        .value = TextCellValue('Ad');
                                    sheet
                                        .cell(CellIndex.indexByColumnRow(
                                            columnIndex: 1, rowIndex: 0))
                                        .value = TextCellValue('Soyad');
                                    sheet
                                        .cell(CellIndex.indexByColumnRow(
                                            columnIndex: 2, rowIndex: 0))
                                        .value = TextCellValue('Okul No');
                                    sheet
                                        .cell(CellIndex.indexByColumnRow(
                                            columnIndex: 3, rowIndex: 0))
                                        .value = TextCellValue('Sınıf');
                                    sheet
                                        .cell(CellIndex.indexByColumnRow(
                                            columnIndex: 4, rowIndex: 0))
                                        .value = TextCellValue('Şube');
                                    sheet
                                            .cell(CellIndex.indexByColumnRow(
                                                columnIndex: 5, rowIndex: 0))
                                            .value =
                                        TextCellValue('Toplam Çalışma');

                                    // Tarih aralığı başlıkları
                                    final days =
                                        _getDaysBetween(startDate, endDate);
                                    for (var i = 0; i < days.length; i++) {
                                      sheet
                                              .cell(CellIndex.indexByColumnRow(
                                                  columnIndex: i + 6,
                                                  rowIndex: 0))
                                              .value =
                                          TextCellValue(DateFormat('dd.MM.yyyy')
                                              .format(days[i]));
                                    }

                                    // Veriler
                                    for (var i = 0;
                                        i < studentList.length;
                                        i++) {
                                      final student = studentList[i];
                                      sheet
                                              .cell(CellIndex.indexByColumnRow(
                                                  columnIndex: 0,
                                                  rowIndex: i + 1))
                                              .value =
                                          TextCellValue(student.name ?? '');
                                      sheet
                                              .cell(CellIndex.indexByColumnRow(
                                                  columnIndex: 1,
                                                  rowIndex: i + 1))
                                              .value =
                                          TextCellValue(student.surname ?? '');
                                      sheet
                                              .cell(CellIndex.indexByColumnRow(
                                                  columnIndex: 2,
                                                  rowIndex: i + 1))
                                              .value =
                                          TextCellValue(
                                              student.schoolNumber ?? '');
                                      sheet
                                              .cell(CellIndex.indexByColumnRow(
                                                  columnIndex: 3,
                                                  rowIndex: i + 1))
                                              .value =
                                          TextCellValue(
                                              student.className ?? '');
                                      sheet
                                              .cell(CellIndex.indexByColumnRow(
                                                  columnIndex: 4,
                                                  rowIndex: i + 1))
                                              .value =
                                          TextCellValue(student.section ?? '');

                                      // Çalışma kayıtları
                                      final records = await ref.read(
                                          studyRecordsForReportProvider.future);
                                      final studentRecords = records
                                          .where(
                                              (r) => r.studentId == student.id)
                                          .toList();

                                      // Toplam çalışma günü
                                      sheet
                                              .cell(CellIndex.indexByColumnRow(
                                                  columnIndex: 5,
                                                  rowIndex: i + 1))
                                              .value =
                                          IntCellValue(studentRecords.length);

                                      // Her gün için çalışma durumu
                                      for (var j = 0; j < days.length; j++) {
                                        final day = days[j];
                                        final hasStudied = studentRecords.any(
                                            (record) =>
                                                record.studyDate.year ==
                                                    day.year &&
                                                record.studyDate.month ==
                                                    day.month &&
                                                record.studyDate.day ==
                                                    day.day);

                                        sheet
                                                .cell(
                                                    CellIndex.indexByColumnRow(
                                                        columnIndex: j + 6,
                                                        rowIndex: i + 1))
                                                .value =
                                            TextCellValue(
                                                hasStudied ? '✓' : '✗');
                                      }
                                    }

                                    final fileBytes = excel.save();
                                    if (fileBytes != null) {
                                      final fileName =
                                          '${selectedClassName}_${selectedSection}_${DateFormat('yyyyMMdd').format(startDate)}-${DateFormat('yyyyMMdd').format(endDate)}.xlsx';

                                      // Doğrudan Downloads klasörüne kaydet
                                      final downloadsPath =
                                          '/storage/emulated/0/Download';
                                      final file =
                                          File('$downloadsPath/$fileName');
                                      await file.writeAsBytes(fileBytes);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Excel dosyası kaydedildi: ${file.path}'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Hata oluştu: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.download_rounded),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: TabBar(
                        padding: const EdgeInsets.all(4),
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: colorScheme.primary,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(
                            height: 46,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_rounded),
                                SizedBox(width: 8),
                                Text('Ekle'),
                              ],
                            ),
                          ),
                          Tab(
                            height: 46,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_rounded),
                                SizedBox(width: 8),
                                Text('Öğrenci'),
                              ],
                            ),
                          ),
                          Tab(
                            height: 46,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.analytics_rounded),
                                SizedBox(width: 8),
                                Text('Raporlar'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _AddStudentTab(),
                        _StudentsTab(),
                        _ReportsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddStudentTab extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _schoolNumberController = TextEditingController();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();

  void _clearForm() {
    _usernameController.clear();
    _passwordController.clear();
    _nameController.clear();
    _surnameController.clear();
    _schoolNumberController.clear();
    _classNameController.clear();
    _sectionController.clear();
    _parentNameController.clear();
    _parentPhoneController.clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _usernameController,
                      labelText: 'Kullanıcı Adı',
                      prefixIcon: Icons.person_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kullanıcı adı gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Şifre',
                      prefixIcon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _nameController,
                            labelText: 'Ad',
                            prefixIcon: Icons.person,
                            textCapitalization: TextCapitalization.words,
                            onlyLetters: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ad gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _surnameController,
                            labelText: 'Soyad',
                            prefixIcon: Icons.person,
                            textCapitalization: TextCapitalization.words,
                            onlyLetters: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Soyad gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _schoolNumberController,
                      labelText: 'Okul Numarası',
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      onlyNumbers: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Okul numarası gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _classNameController,
                            labelText: 'Sınıf',
                            prefixIcon: Icons.class_rounded,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            onlyNumbers: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Sınıf gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _sectionController,
                            labelText: 'Şube',
                            prefixIcon: Icons.class_rounded,
                            maxLength: 1,
                            textCapitalization: TextCapitalization.characters,
                            onlyLetters: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şube gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _parentNameController,
                      labelText: 'Veli Adı',
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      onlyLetters: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veli adı gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _parentPhoneController,
                      labelText: 'Veli Telefon',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      onlyNumbers: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veli telefonu gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await ref
                              .read(adminControllerProvider)
                              .createStudent(
                                username: _usernameController.text,
                                password: _passwordController.text,
                                name: _nameController.text,
                                surname: _surnameController.text,
                                schoolNumber: _schoolNumberController.text,
                                className: _classNameController.text,
                                section: _sectionController.text,
                                parentName: _parentNameController.text,
                                parentPhone: _parentPhoneController.text,
                              );

                          if (success) {
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.success,
                              animType: AnimType.scale,
                              title: 'Başarılı',
                              desc: 'Öğrenci başarıyla eklendi!',
                              btnOkOnPress: () {
                                _clearForm();
                              },
                            ).show();
                          } else {
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.error,
                              animType: AnimType.scale,
                              title: 'Hata',
                              desc: 'Öğrenci eklenirken bir hata oluştu!',
                              btnOkOnPress: () {},
                            ).show();
                          }
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text(
                            'Öğrenci Ekle',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  final _searchController = TextEditingController();

  List<DateTime> _getDaysBetween(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  List<StudentStudyStatus> _processStudyRecords(
    List<AppUser> students,
    List<StudyRecord> records,
    DateTime startDate,
    DateTime endDate,
  ) {
    print('Çalışma kayıtları işleniyor...');
    print('Öğrenci sayısı: ${students.length}');
    print('Kayıt sayısı: ${records.length}');

    final studyMap = <String, Map<DateTime, bool>>{};
    final days = _getDaysBetween(startDate, endDate);

    print('Tarih aralığındaki gün sayısı: ${days.length}');

    // Initialize all days as not studied
    for (final student in students) {
      if (student.id == null) continue;
      studyMap[student.id!] = {
        for (var day in days) DateTime(day.year, day.month, day.day): false
      };
    }

    // Mark studied days
    for (final record in records) {
      final dayStart = DateTime(
        record.studyDate.year,
        record.studyDate.month,
        record.studyDate.day,
      );

      print('Kayıt - Öğrenci: ${record.studentId}, Tarih: $dayStart');

      if (studyMap[record.studentId]?.containsKey(dayStart) ?? false) {
        studyMap[record.studentId]![dayStart] = true;
        print('Çalışma işaretlendi: ${record.studentId} - $dayStart');
      }
    }

    final result = students.where((s) => s.id != null).map((student) {
      final studentId = student.id!;
      final status = StudentStudyStatus(
        studentId: studentId,
        name: student.name ?? '',
        surname: student.surname ?? '',
        schoolNumber: student.schoolNumber ?? '',
        studyDays: studyMap[studentId] ?? {},
      );
      print(
          'Öğrenci $studentId - Toplam çalışma: ${status.getTotalStudyDays()}');
      return status;
    }).toList();

    print('İşlenen öğrenci sayısı: ${result.length}');
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classNames = ref.watch(classNamesProvider);
    final sections = ref.watch(sectionsProvider);
    final selectedClassName = ref.watch(selectedClassNameProvider);
    final selectedSection = ref.watch(selectedSectionProvider);
    final startDate = ref.watch(startDateProvider);
    final endDate = ref.watch(endDateProvider);
    final students = ref.watch(studentsForReportProvider);
    final studyRecords = ref.watch(studyRecordsForReportProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: classNames.when(
                          data: (classes) => DropdownButtonFormField<String>(
                            value: selectedClassName,
                            dropdownColor: Colors.grey[50],
                            decoration: InputDecoration(
                              labelText: 'Sınıf',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: classes.map((className) {
                              return DropdownMenuItem(
                                value: className,
                                child: Text(className),
                              );
                            }).toList(),
                            onChanged: (value) {
                              ref
                                  .read(selectedClassNameProvider.notifier)
                                  .state = value;
                            },
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Sınıflar yüklenemedi'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: sections.when(
                          data: (sectionList) =>
                              DropdownButtonFormField<String>(
                            value: selectedSection,
                            dropdownColor: Colors.grey[50],
                            decoration: InputDecoration(
                              labelText: 'Şube',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: sectionList.map((section) {
                              return DropdownMenuItem(
                                value: section,
                                child: Text(section),
                              );
                            }).toList(),
                            onChanged: (value) {
                              ref.read(selectedSectionProvider.notifier).state =
                                  value;
                            },
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Şubeler yüklenemedi'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              ref.read(startDateProvider.notifier).state = date;
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Başlangıç Tarihi',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              DateFormat('dd.MM.yyyy').format(startDate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              ref.read(endDateProvider.notifier).state = date;
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Bitiş Tarihi',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              DateFormat('dd.MM.yyyy').format(endDate),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _searchController,
                          labelText: 'Öğrenci Ara (Ad, Soyad veya Okul No)',
                          prefixIcon: Icons.search,
                          onChanged: (value) {
                            ref.read(reportSearchQueryProvider.notifier).state =
                                value;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () {
                          ref.invalidate(studentsForReportProvider);
                          ref.invalidate(studyRecordsForReportProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Getir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 4,
            child: Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: students.when(
                  data: (studentList) {
                    if (studentList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.class_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Lütfen sınıf ve şube seçin',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return studyRecords.when(
                      data: (records) {
                        final studyStatuses = _processStudyRecords(
                          studentList,
                          records,
                          startDate,
                          endDate,
                        );

                        final days = _getDaysBetween(startDate, endDate);

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.all(24),
                                itemCount: studyStatuses.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 32),
                                itemBuilder: (context, index) {
                                  final status = studyStatuses[index];
                                  final theme = Theme.of(context);
                                  final colorScheme = theme.colorScheme;

                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        final studentUser = AppUser(
                                          id: status.studentId,
                                          username: null,
                                          name: status.name,
                                          surname: status.surname,
                                          role: UserRole.student,
                                          schoolNumber: status.schoolNumber,
                                          className: null,
                                          section: null,
                                          parentName: null,
                                          parentPhone: null,
                                          adminId: null,
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StudentDetailScreen(
                                              student: studentUser,
                                              records: records
                                                  .where((r) =>
                                                      r.studentId ==
                                                      status.studentId)
                                                  .toList(),
                                              days: days,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary
                                                        .withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.person_rounded,
                                                    size: 32,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${status.name} ${status.surname}',
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text.rich(
                                                        TextSpan(
                                                          children: [
                                                            const TextSpan(
                                                              text: 'Okul No: ',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  '${status.schoolNumber}',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                color: colorScheme
                                                                    .onSurface
                                                                    .withOpacity(
                                                                        0.8),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .calendar_month_rounded,
                                                            color: colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                    0.6),
                                                            size: 20,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '${days.length}',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.6),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Icon(
                                                            Icons
                                                                .check_circle_rounded,
                                                            color: Colors.green,
                                                            size: 20,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '${status.getTotalStudyDays()}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Icon(
                                                            Icons
                                                                .cancel_rounded,
                                                            color: Colors.red,
                                                            size: 20,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '${days.length - status.getTotalStudyDays()}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: days.map((day) {
                                                final hasStudied =
                                                    status.studyDays[day] ??
                                                        false;

                                                return Container(
                                                  width: 48,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: hasStudied
                                                          ? Colors.green
                                                          : Colors.red,
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Center(
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              DateFormat('dd',
                                                                      'tr_TR')
                                                                  .format(day),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color: hasStudied
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .red,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Text(
                                                              DateFormat('MMM',
                                                                      'tr_TR')
                                                                  .format(day)
                                                                  .toUpperCase(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color: hasStudied
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .red,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (hasStudied &&
                                                          records
                                                                  .firstWhere(
                                                                    (r) =>
                                                                        r.studentId ==
                                                                            status
                                                                                .studentId &&
                                                                        r.studyDate.year ==
                                                                            day
                                                                                .year &&
                                                                        r.studyDate.month ==
                                                                            day
                                                                                .month &&
                                                                        r.studyDate.day ==
                                                                            day.day,
                                                                    orElse: () =>
                                                                        StudyRecord(
                                                                      id: '',
                                                                      studentId:
                                                                          '',
                                                                      studyDate:
                                                                          day,
                                                                      createdAt:
                                                                          day,
                                                                    ),
                                                                  )
                                                                  .note !=
                                                              null)
                                                        Positioned(
                                                          top: 0,
                                                          right: 0,
                                                          child: Icon(
                                                            Icons.note_rounded,
                                                            size: 14,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, __) => const Center(
                        child: Text(
                          'Çalışma kayıtları yüklenirken hata oluştu',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => const Center(
                    child: Text(
                      'Öğrenciler yüklenirken hata oluştu',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classNames = ref.watch(classNamesProvider);
    final sections = ref.watch(sectionsProvider);
    final selectedClassName = ref.watch(studentListClassNameProvider);
    final selectedSection = ref.watch(studentListSectionProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final students = ref.watch(filteredStudentsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: classNames.when(
                          data: (classes) => DropdownButtonFormField<String>(
                            value: selectedClassName,
                            dropdownColor: Colors.grey[50],
                            decoration: InputDecoration(
                              labelText: 'Sınıf',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: classes.map((className) {
                              return DropdownMenuItem(
                                value: className,
                                child: Text(className),
                              );
                            }).toList(),
                            onChanged: (value) {
                              ref
                                  .read(studentListClassNameProvider.notifier)
                                  .state = value;
                            },
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Sınıflar yüklenemedi'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: sections.when(
                          data: (sectionList) =>
                              DropdownButtonFormField<String>(
                            value: selectedSection,
                            dropdownColor: Colors.grey[50],
                            decoration: InputDecoration(
                              labelText: 'Şube',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: sectionList.map((section) {
                              return DropdownMenuItem(
                                value: section,
                                child: Text(section),
                              );
                            }).toList(),
                            onChanged: (value) {
                              ref
                                  .read(studentListSectionProvider.notifier)
                                  .state = value;
                            },
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Şubeler yüklenemedi'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _searchController,
                    labelText: 'Öğrenci Ara',
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: students.when(
                  data: (studentList) {
                    if (studentList.isEmpty) {
                      if (selectedClassName == null ||
                          selectedSection == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.class_rounded,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Lütfen sınıf ve şube seçin',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_search_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Öğrenci bulunamadı',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: studentList.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 32),
                      itemBuilder: (context, index) {
                        final student = studentList[index];
                        final hasParentInfo = student.parentName != null &&
                            student.parentPhone != null;
                        final theme = Theme.of(context);
                        final colorScheme = theme.colorScheme;

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 32,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${student.name} ${student.surname}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'Okul No: ',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '${student.schoolNumber}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (hasParentInfo) ...[
                                        const SizedBox(height: 4),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Veli: ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '${student.parentName}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Tel: ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '${student.parentPhone}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton.filledTonal(
                                  onPressed: () {
                                    if (student.id == null) return;

                                    AwesomeDialog(
                                      context: context,
                                      dialogType: DialogType.warning,
                                      animType: AnimType.scale,
                                      title: 'Emin misiniz?',
                                      desc:
                                          'Bu öğrenci kalıcı olarak silinecek.',
                                      btnCancelText: 'İptal',
                                      btnOkText: 'Sil',
                                      btnCancelOnPress: () {},
                                      btnOkOnPress: () async {
                                        final success = await ref
                                            .read(adminControllerProvider)
                                            .deleteStudent(student.id!);

                                        if (!context.mounted) return;

                                        if (success) {
                                          ref.invalidate(
                                              filteredStudentsProvider);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Öğrenci başarıyla silindi'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Öğrenci silinirken bir hata oluştu'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ).show();
                                  },
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => const Center(
                    child: Text(
                      'Öğrenciler yüklenirken hata oluştu',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}