import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/study_record_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://xhycfonowmozogszwxmp.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhoeWNmb25vd21vem9nc3p3eG1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzUxNTczMTUsImV4cCI6MjA1MDczMzMxNX0.vCwE2qR5T2fEwp49JUQnApO8KQdwDmbXvl6p3qQY1CQ';

  late final SupabaseClient _client;

  Future<void> initialize() async {
    try {
      print('Supabase başlatılıyor...');
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      _client = Supabase.instance.client;
      print('Supabase başlatıldı');
    } catch (e) {
      print('Supabase başlatma hatası: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _convertToSnakeCase(Map<String, dynamic> map) {
    final result = {
      'username': map['username'],
      'password': map['password'],
      'name': map['name'],
      'surname': map['surname'],
      'role': map['role'],
      'school_number': map['schoolNumber'],
      'class_name': map['className'],
      'section': map['section'],
      'parent_name': map['parentName'],
      'parent_phone': map['parentPhone'],
      'admin_id': map['adminId'],
    };

    // ID sadece güncelleme işlemlerinde gönderilmeli
    if (map['id'] != null) {
      result['id'] = map['id'];
    }

    return result;
  }

  Map<String, dynamic> _convertToCamelCase(Map<String, dynamic> map) {
    print('Dönüştürülecek veri: $map');
    final result = {
      'id': map['id'],
      'username': map['username'],
      'password': map['password'],
      'name': map['name'],
      'surname': map['surname'],
      'role': map['role'],
      'schoolNumber': map['school_number'],
      'className': map['class_name'],
      'section': map['section'],
      'parentName': map['parent_name'],
      'parentPhone': map['parent_phone'],
      'adminId': map['admin_id'],
    };
    print('Dönüştürülmüş veri: $result');
    return result;
  }

  // Auth işlemleri
  Future<AppUser?> signIn(String username, String password) async {
    try {
      print('Kullanıcı sorgulanıyor...');
      print(
          'SQL: SELECT * FROM users WHERE username = $username AND password = $password');

      final response = await _client
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password)
          .single();

      print('Sorgu sonucu: $response');

      if (response != null) {
        final user = AppUser.fromMap(_convertToCamelCase(response));
        print('Kullanıcı bulundu: ${user.role}');
        return user;
      }

      print('Kullanıcı bulunamadı');
      return null;
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı işlemleri
  Future<AppUser> createUser(AppUser user, String password) async {
    try {
      print('Kullanıcı oluşturuluyor...');
      final userData = _convertToSnakeCase({
        ...user.toMap(),
        'password': password,
      });
      print('Gönderilen veri: $userData');

      final response =
          await _client.from('users').insert(userData).select().single();

      print('Oluşturma sonucu: $response');
      return AppUser.fromMap(_convertToCamelCase(response));
    } catch (e) {
      print('Kullanıcı oluşturma hatası: $e');
      rethrow;
    }
  }

  Future<List<AppUser>> getStudentsByAdmin(String adminId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('admin_id', adminId)
          .eq('role', 'student');

      return (response as List)
          .map((e) => AppUser.fromMap(_convertToCamelCase(e)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Çalışma kaydı işlemleri
  Future<void> createStudyRecord(String studentId, {String? note}) async {
    await _client.from('study_records').insert({
      'student_id': studentId,
      'study_date': DateTime.now().toIso8601String(),
      'note': note,
    });
  }

  Future<List<StudyRecord>> getStudyRecords({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query =
          _client.from('study_records').select().eq('student_id', studentId);

      if (startDate != null) {
        query = query.gte('study_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('study_date', endDate.toIso8601String());
      }

      final response = await query;
      return (response as List).map((e) => StudyRecord.fromMap(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<StudyRecord>> getClassStudyRecords({
    required String className,
    required String section,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('study_records')
          .select('*, users!inner(*)')
          .eq('users.class_name', className)
          .eq('users.section', section);

      if (startDate != null) {
        query = query.gte('study_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('study_date', endDate.toIso8601String());
      }

      final response = await query;
      return (response as List).map((e) => StudyRecord.fromMap(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getUniqueClassNames() async {
    final response = await _client
        .from('users')
        .select('class_name')
        .neq('class_name', '')
        .not('class_name', 'is', null)
        .order('class_name');

    final classNames = response
        .map((record) => record['class_name'] as String)
        .toSet()
        .toList();

    return classNames;
  }

  Future<List<String>> getUniqueSections() async {
    final response = await _client
        .from('users')
        .select('section')
        .neq('section', '')
        .not('section', 'is', null)
        .order('section');

    final sections =
        response.map((record) => record['section'] as String).toSet().toList();

    return sections;
  }

  Future<List<AppUser>> getStudentsByClassAndSection(
      String className, String section) async {
    try {
      print('Öğrenciler getiriliyor...');
      print('Sınıf: $className, Şube: $section');

      final response = await _client
          .from('users')
          .select()
          .eq('role', 'student')
          .eq('class_name', className)
          .eq('section', section)
          .order('name');

      print('Veritabanı yanıtı: $response');
      final students = response
          .map((record) => AppUser.fromMap(_convertToCamelCase(record)))
          .toList();
      print('Dönüştürülen öğrenciler: $students');
      return students;
    } catch (e) {
      print('Öğrenci getirme hatası: $e');
      rethrow;
    }
  }

  Future<List<StudyRecord>> getStudyRecordsByStudentIds(
      List<String> studentIds, DateTime startDate, DateTime endDate) async {
    try {
      print('Çalışma kayıtları getiriliyor...');
      print('Öğrenci IDleri: $studentIds');
      print('Başlangıç: ${startDate.toIso8601String()}');
      print('Bitiş: ${endDate.toIso8601String()}');

      final response = await _client
          .from('study_records')
          .select()
          .inFilter('student_id', studentIds)
          .gte(
              'study_date',
              DateTime(startDate.year, startDate.month, startDate.day)
                  .toIso8601String())
          .lte(
              'study_date',
              DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
                  .toIso8601String())
          .order('study_date');

      print('Veritabanı yanıtı: $response');
      final records =
          response.map((record) => StudyRecord.fromMap(record)).toList();
      print('Dönüştürülen kayıtlar: $records');
      print('Toplam kayıt sayısı: ${records.length}');
      return records;
    } catch (e) {
      print('Çalışma kayıtları getirme hatası: $e');
      rethrow;
    }
  }

  Future<List<AppUser>> getAdmins() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('role', 'admin')
          .order('name');

      return (response as List)
          .map((e) => AppUser.fromMap(_convertToCamelCase(e)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<(bool canDelete, String message, List<AppUser> otherAdmins)>
      checkAdminDeletion(String adminId) async {
    try {
      final admins = await getAdmins();

      if (admins.length <= 1) {
        return (
          false,
          'Sistemde en az bir yönetici bulunmalıdır.',
          <AppUser>[]
        );
      }

      final otherAdmins = admins.where((a) => a.id != adminId).toList();
      return (true, '', otherAdmins as List<AppUser>);
    } catch (e) {
      print('Yönetici kontrol hatası: $e');
      return (
        false,
        'Yönetici kontrolü sırasında bir hata oluştu.',
        <AppUser>[]
      );
    }
  }

  Future<bool> transferStudentsToAdmin(
      String fromAdminId, String toAdminId) async {
    try {
      print('Öğrenci transfer işlemi başlatıldı...');
      print('Kaynak yönetici: $fromAdminId');
      print('Hedef yönetici: $toAdminId');

      await _client
          .from('users')
          .update({'admin_id': toAdminId}).eq('admin_id', fromAdminId);

      print('Öğrenciler başarıyla transfer edildi');
      return true;
    } catch (e) {
      print('Öğrenci transfer hatası: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      print('Kullanıcı silme işlemi başlatıldı...');
      print('Silinecek kullanıcı ID: $userId');

      // Önce kullanıcının çalışma kayıtlarını sil
      await _client.from('study_records').delete().eq('student_id', userId);

      print('Çalışma kayıtları silindi');

      // Şimdi kullanıcıyı sil
      await _client.from('users').delete().eq('id', userId);

      print('Kullanıcı başarıyla silindi');
      return true;
    } catch (e) {
      print('Kullanıcı silme hatası: $e');
      print('Hata detayı: ${e.toString()}');
      return false;
    }
  }

  Future<List<AppUser>> getStudentsByAdminId(String adminId) async {
    try {
      print('Yöneticiye bağlı öğrenciler getiriliyor...');
      print('Yönetici ID: $adminId');

      final response = await _client
          .from('users')
          .select()
          .eq('admin_id', adminId)
          .eq('role', 'student');

      final students = (response as List)
          .map((e) => AppUser.fromMap(_convertToCamelCase(e)))
          .toList();

      print('Bulunan öğrenci sayısı: ${students.length}');
      return students;
    } catch (e) {
      print('Öğrenci getirme hatası: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
