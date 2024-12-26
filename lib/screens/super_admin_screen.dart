import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_text_field.dart';
import '../models/user_model.dart';

class SuperAdminScreen extends ConsumerStatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  ConsumerState<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends ConsumerState<SuperAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(adminControllerProvider).createAdmin(
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
            name: _nameController.text.trim(),
            surname: _surnameController.text.trim(),
          );

      if (!mounted) return;

      if (success) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: 'Başarılı',
          desc: 'Yönetici başarıyla eklendi!',
          btnOkOnPress: () {
            _usernameController.clear();
            _passwordController.clear();
            _nameController.clear();
            _surnameController.clear();
          },
        ).show();
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.scale,
          title: 'Hata',
          desc: 'Yönetici eklenirken bir hata oluştu!',
          btnOkOnPress: () {},
        ).show();
      }
    } catch (e) {
      if (!mounted) return;

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: 'Hata',
        desc: 'Yönetici eklenirken bir hata oluştu: $e',
        btnOkOnPress: () {},
      ).show();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _signOut() {
    ref.read(authControllerProvider).signOut();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(
                        height: 46,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded),
                            SizedBox(width: 8),
                            Text('Admin Ekle'),
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
                            Text('Adminler'),
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
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.admin_panel_settings_rounded,
                                        size: 48,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Yönetici Ekle',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),
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
                                      prefixIcon: Icons.lock_rounded,
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
                                            prefixIcon: Icons.badge_rounded,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
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
                                            prefixIcon: Icons.badge_rounded,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Soyad gerekli';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    FilledButton(
                                      onPressed: _isLoading ? null : _addAdmin,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              'Yönetici Ekle',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _AdminsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.group_rounded,
                          size: 32,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Mevcut Yöneticiler',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final admins = ref.watch(adminsProvider);
                          return FilledButton.tonalIcon(
                            onPressed: () {
                              ref.invalidate(adminsProvider);
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Yenile'),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, child) {
                      final admins = ref.watch(adminsProvider);

                      return admins.when(
                        data: (adminList) {
                          if (adminList.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Henüz yönetici bulunmuyor',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: adminList.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 32),
                            itemBuilder: (context, index) {
                              final admin = adminList[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                tileColor:
                                    colorScheme.primary.withOpacity(0.05),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      colorScheme.primary.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  '${admin.name} ${admin.surname}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  admin.username ?? '',
                                  style: TextStyle(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                                trailing: IconButton.filledTonal(
                                  onPressed: () async {
                                    if (admin.id == null) return;

                                    final check = await ref
                                        .read(adminControllerProvider)
                                        .checkAdminDeletion(admin.id!);

                                    if (!check.$1) {
                                      if (!context.mounted) return;

                                      AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.error,
                                        animType: AnimType.scale,
                                        title: 'Hata',
                                        desc: check.$2,
                                        btnOkOnPress: () {},
                                      ).show();
                                      return;
                                    }

                                    if (!context.mounted) return;

                                    // Yönetici seçme dialogu
                                    final students = await ref
                                        .read(adminControllerProvider)
                                        .getStudentsByAdminId(admin.id!);

                                    if (!context.mounted) return;

                                    if (students.isEmpty) {
                                      // Öğrenci yoksa direkt sil
                                      AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.warning,
                                        animType: AnimType.scale,
                                        title: 'Emin misiniz?',
                                        desc:
                                            'Bu yönetici kalıcı olarak silinecek.',
                                        btnCancelText: 'İptal',
                                        btnOkText: 'Sil',
                                        btnCancelOnPress: () {},
                                        btnOkOnPress: () async {
                                          final success = await ref
                                              .read(adminControllerProvider)
                                              .deleteAdmin(admin.id!);

                                          if (!context.mounted) return;

                                          if (success) {
                                            ref.invalidate(adminsProvider);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Yönetici başarıyla silindi',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Yönetici silinirken bir hata oluştu',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ).show();
                                    } else {
                                      // Öğrenci varsa transfer seçeneği sun
                                      AppUser? selectedAdmin;

                                      await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Yönetici Seçin'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'Bu yöneticiye bağlı ${students.length} öğrenci bulunuyor.',
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Öğrencileri transfer etmek istediğiniz yöneticiyi seçin:',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              const SizedBox(height: 16),
                                              ...check.$3.map(
                                                (otherAdmin) =>
                                                    RadioListTile<AppUser>(
                                                  title: Text(
                                                      '${otherAdmin.name} ${otherAdmin.surname}'),
                                                  value: otherAdmin,
                                                  groupValue: selectedAdmin,
                                                  onChanged: (value) {
                                                    selectedAdmin = value;
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );

                                      if (selectedAdmin != null &&
                                          selectedAdmin?.id != null) {
                                        if (!context.mounted) return;

                                        AwesomeDialog(
                                          context: context,
                                          dialogType: DialogType.warning,
                                          animType: AnimType.scale,
                                          title: 'Emin misiniz?',
                                          desc:
                                              'Öğrenciler ${selectedAdmin?.name} ${selectedAdmin?.surname} adlı yöneticiye transfer edilecek ve mevcut yönetici silinecek.',
                                          btnCancelText: 'İptal',
                                          btnOkText: 'Onayla',
                                          btnCancelOnPress: () {},
                                          btnOkOnPress: () async {
                                            final success = await ref
                                                .read(adminControllerProvider)
                                                .transferStudentsAndDeleteAdmin(
                                                  admin.id!,
                                                  selectedAdmin!.id!,
                                                );

                                            if (!context.mounted) return;

                                            if (success) {
                                              ref.invalidate(adminsProvider);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Transfer ve silme işlemi başarılı',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'İşlem sırasında bir hata oluştu',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                        ).show();
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Yöneticiler yüklenirken bir hata oluştu',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    },
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
