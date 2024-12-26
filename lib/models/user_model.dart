import 'dart:convert';

enum UserRole { superAdmin, admin, student }

class AppUser {
  final String? id;
  final String? username;
  final String? name;
  final String? surname;
  final UserRole role;
  final String? schoolNumber;
  final String? className;
  final String? section;
  final String? parentName;
  final String? parentPhone;
  final String? adminId;

  AppUser({
    this.id,
    this.username,
    this.name,
    this.surname,
    required this.role,
    this.schoolNumber,
    this.className,
    this.section,
    this.parentName,
    this.parentPhone,
    this.adminId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'surname': surname,
      'role': role.toString().split('.').last,
      'schoolNumber': schoolNumber,
      'className': className,
      'section': section,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'adminId': adminId,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      username: map['username'] ?? '',
      name: map['name'],
      surname: map['surname'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.student,
      ),
      schoolNumber: map['schoolNumber'],
      className: map['className'],
      section: map['section'],
      parentName: map['parentName'],
      parentPhone: map['parentPhone'],
      adminId: map['adminId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AppUser.fromJson(String source) =>
      AppUser.fromMap(json.decode(source));

  AppUser copyWith({
    String? id,
    String? username,
    String? name,
    String? surname,
    UserRole? role,
    String? schoolNumber,
    String? className,
    String? section,
    String? parentName,
    String? parentPhone,
    String? adminId,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      role: role ?? this.role,
      schoolNumber: schoolNumber ?? this.schoolNumber,
      className: className ?? this.className,
      section: section ?? this.section,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      adminId: adminId ?? this.adminId,
    );
  }
}
