import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/study_record_model.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final currentUserProvider = StateProvider<AppUser?>((ref) => null);

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  Future<bool> signIn(String username, String password) async {
    try {
      print('AuthController - Giriş denemesi');
      final user =
          await _ref.read(supabaseServiceProvider).signIn(username, password);

      print('AuthController - Giriş sonucu: ${user?.role}');

      if (user != null) {
        print('AuthController - Kullanıcı state güncelleniyor');
        _ref.read(currentUserProvider.notifier).update((state) => user);
        return true;
      }
      return false;
    } catch (e) {
      print('AuthController - Giriş hatası: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _ref.read(supabaseServiceProvider).signOut();
    _ref.read(currentUserProvider.notifier).update((state) => null);
    // Beni hatırla bilgilerini temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('rememberMe');
  }
}

final studyControllerProvider = Provider<StudyController>((ref) {
  return StudyController(ref);
});

class StudyController {
  final Ref _ref;

  StudyController(this._ref);

  Future<(bool success, String message)> recordStudy({String? note}) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null || user.id == null) {
        return (false, 'Kullanıcı bilgisi bulunamadı');
      }

      // Bugünün başlangıcı ve sonu
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Bugün için kayıt var mı kontrol et
      final todayRecords =
          await _ref.read(supabaseServiceProvider).getStudyRecords(
                studentId: user.id!,
                startDate: today,
                endDate: tomorrow,
              );

      if (todayRecords.isNotEmpty) {
        return (false, 'Bugün için zaten çalışma kaydı eklediniz');
      }

      await _ref
          .read(supabaseServiceProvider)
          .createStudyRecord(user.id!, note: note);
      return (true, 'Çalışma kaydı eklendi');
    } catch (e) {
      return (false, 'Bir hata oluştu: $e');
    }
  }

  Future<List<StudyRecord>> getStudentRecords(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _ref.read(supabaseServiceProvider).getStudyRecords(
            studentId: studentId,
            startDate: startDate,
            endDate: endDate,
          );
    } catch (e) {
      return [];
    }
  }

  Future<List<StudyRecord>> getClassRecords(
    String className,
    String section, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _ref.read(supabaseServiceProvider).getClassStudyRecords(
            className: className,
            section: section,
            startDate: startDate,
            endDate: endDate,
          );
    } catch (e) {
      return [];
    }
  }
}

final adminControllerProvider = Provider<AdminController>((ref) {
  return AdminController(ref);
});

class AdminController {
  final Ref _ref;

  AdminController(this._ref);

  Future<bool> createAdmin({
    required String username,
    required String password,
    required String name,
    required String surname,
  }) async {
    try {
      print('Yönetici oluşturuluyor...');
      print('Veriler: $username, $name, $surname');

      final admin = AppUser(
        username: username,
        name: name,
        surname: surname,
        role: UserRole.admin,
        schoolNumber: null,
        className: null,
        section: null,
        parentName: null,
        parentPhone: null,
        adminId: null,
      );

      await _ref.read(supabaseServiceProvider).createUser(admin, password);
      print('Yönetici başarıyla oluşturuldu');
      return true;
    } catch (e) {
      print('Yönetici oluşturma hatası: $e');
      return false;
    }
  }

  Future<bool> deleteAdmin(String adminId) async {
    try {
      print('AdminController - Yönetici silme işlemi başlatıldı');
      print('Silinecek yönetici ID: $adminId');

      final success =
          await _ref.read(supabaseServiceProvider).deleteUser(adminId);

      print('Silme işlemi sonucu: $success');

      if (success) {
        print('Yönetici başarıyla silindi, provider yenileniyor...');
        _ref.invalidate(adminsProvider);
      } else {
        print('Silme işlemi başarısız oldu');
      }

      return success;
    } catch (e) {
      print('AdminController - Yönetici silme hatası: $e');
      print('Hata detayı: ${e.toString()}');
      return false;
    }
  }

  Future<bool> createStudent({
    required String username,
    required String password,
    required String name,
    required String surname,
    required String schoolNumber,
    required String className,
    required String section,
    String? parentName,
    String? parentPhone,
  }) async {
    try {
      final admin = _ref.read(currentUserProvider);
      if (admin == null || admin.id == null) return false;

      final student = AppUser(
        username: username,
        name: name,
        surname: surname,
        role: UserRole.student,
        schoolNumber: schoolNumber,
        className: className,
        section: section,
        parentName: parentName,
        parentPhone: parentPhone,
        adminId: admin.id,
      );

      await _ref.read(supabaseServiceProvider).createUser(student, password);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteStudent(String studentId) async {
    try {
      print('AdminController - Öğrenci silme işlemi başlatıldı');
      print('Silinecek öğrenci ID: $studentId');

      final success =
          await _ref.read(supabaseServiceProvider).deleteUser(studentId);

      print('Silme işlemi sonucu: $success');
      return success;
    } catch (e) {
      print('AdminController - Öğrenci silme hatası: $e');
      return false;
    }
  }

  Future<List<AppUser>> getStudents() async {
    try {
      final admin = _ref.read(currentUserProvider);
      if (admin == null || admin.id == null) return [];

      return await _ref
          .read(supabaseServiceProvider)
          .getStudentsByAdmin(admin.id!);
    } catch (e) {
      return [];
    }
  }

  Future<(bool success, String message, List<AppUser> otherAdmins)>
      checkAdminDeletion(String adminId) async {
    try {
      return await _ref
          .read(supabaseServiceProvider)
          .checkAdminDeletion(adminId);
    } catch (e) {
      return (false, 'Kontrol sırasında bir hata oluştu', <AppUser>[]);
    }
  }

  Future<bool> transferStudentsAndDeleteAdmin(
      String fromAdminId, String toAdminId) async {
    try {
      print('Yönetici silme ve transfer işlemi başlatıldı');

      // Önce öğrencileri transfer et
      final transferSuccess = await _ref
          .read(supabaseServiceProvider)
          .transferStudentsToAdmin(fromAdminId, toAdminId);

      if (!transferSuccess) {
        print('Öğrenci transferi başarısız oldu');
        return false;
      }

      // Sonra yöneticiyi sil
      final deleteSuccess =
          await _ref.read(supabaseServiceProvider).deleteUser(fromAdminId);

      if (deleteSuccess) {
        print('Yönetici başarıyla silindi, provider yenileniyor...');
        _ref.invalidate(adminsProvider);
      } else {
        print('Yönetici silme işlemi başarısız oldu');
      }

      return deleteSuccess;
    } catch (e) {
      print('Transfer ve silme işlemi hatası: $e');
      return false;
    }
  }

  Future<List<AppUser>> getStudentsByAdminId(String adminId) async {
    try {
      return await _ref
          .read(supabaseServiceProvider)
          .getStudentsByAdminId(adminId);
    } catch (e) {
      print('Öğrenci getirme hatası: $e');
      return [];
    }
  }
}

final classNamesProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  return await supabase.getUniqueClassNames();
});

final sectionsProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  return await supabase.getUniqueSections();
});

final selectedClassNameProvider = StateProvider<String?>((ref) => null);
final selectedSectionProvider = StateProvider<String?>((ref) => null);
final startDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final endDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final reportSearchQueryProvider = StateProvider<String>((ref) => '');

final studentsForReportProvider = FutureProvider<List<AppUser>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  final className = ref.watch(selectedClassNameProvider);
  final section = ref.watch(selectedSectionProvider);
  final searchQuery = ref.watch(reportSearchQueryProvider).toLowerCase();

  if (className == null || section == null) {
    return [];
  }

  final students =
      await supabase.getStudentsByClassAndSection(className, section);

  if (searchQuery.isEmpty) {
    return students;
  }

  return students.where((student) {
    final fullName = '${student.name} ${student.surname}'.toLowerCase();
    final schoolNumber = student.schoolNumber?.toLowerCase() ?? '';
    return fullName.contains(searchQuery) || schoolNumber.contains(searchQuery);
  }).toList();
});

final studyRecordsForReportProvider =
    FutureProvider<List<StudyRecord>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  final students = await ref.watch(studentsForReportProvider.future);
  final startDate = ref.watch(startDateProvider);
  final endDate = ref.watch(endDateProvider);

  if (students.isEmpty) {
    return [];
  }

  final studentIds = students.map((s) => s.id!).toList();
  return await supabase.getStudyRecordsByStudentIds(
      studentIds, startDate, endDate);
});

final studentListClassNameProvider = StateProvider<String?>((ref) => null);
final studentListSectionProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredStudentsProvider = FutureProvider<List<AppUser>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  final className = ref.watch(studentListClassNameProvider);
  final section = ref.watch(studentListSectionProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  if (className == null || section == null) {
    return [];
  }

  final students =
      await supabase.getStudentsByClassAndSection(className, section);

  if (searchQuery.isEmpty) {
    return students;
  }

  return students.where((student) {
    final fullName = '${student.name} ${student.surname}'.toLowerCase();
    return fullName.contains(searchQuery);
  }).toList();
});

final adminsProvider = FutureProvider<List<AppUser>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  return await supabase.getAdmins();
});
