import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

class UsersAdminPage extends StatefulWidget {
  const UsersAdminPage({
    super.key,
    this.adminService,
    this.embedded = false,
  });

  final AdminService? adminService;
  final bool embedded;

  @override
  State<UsersAdminPage> createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  late final AdminService _adminService;
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    _adminService = widget.adminService ?? AdminService();
  }

  List<UserModel> _filterUsers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) {
      return UserModel.fromMap({...doc.data(), 'uid': doc.id});
    }).where((user) {
      if (filter == 'all') return true;
      if (filter == 'suspended') return user.status == UserStatus.suspended;
      return user.role == filter;
    }).toList();
  }

  Future<void> _setStatus(UserModel user, String status) async {
    try {
      await _adminService.updateUserStatus(userId: user.uid, status: status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur mis a jour')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mise a jour impossible: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _adminService.watchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: MotoFixUi.orange),
            );
          }

          if (snapshot.hasError) {
            return _UsersMessage(message: '${snapshot.error}');
          }

          final users = _filterUsers(snapshot.data ?? const []);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _UsersFilter(
                value: filter,
                onChanged: (value) => setState(() => filter = value),
              ),
              const SizedBox(height: 12),
              Text(
                '${users.length} utilisateurs',
                style: const TextStyle(color: MotoFixUi.textSoft),
              ),
              const SizedBox(height: 10),
              if (users.isEmpty)
                const _UsersMessage(message: 'Aucun utilisateur trouve.')
              else
                for (final user in users)
                  _UserTile(
                    user: user,
                    onSuspend: () =>
                        _setStatus(user, UserStatus.suspended),
                    onActivate: () => _setStatus(user, UserStatus.active),
                  ),
            ],
          );
        },
      ),
    );

    if (widget.embedded) return body;

    return MotoFixUi.page(
      appBar: MotoFixUi.appBar('Utilisateurs'),
      child: body,
    );
  }
}

class _UsersFilter extends StatelessWidget {
  const _UsersFilter({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = {
      'all': 'Tous',
      UserRole.client: 'Clients',
      UserRole.admin: 'Admins',
      'suspended': 'Suspendus',
    };

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: MotoFixUi.panel,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final item in values.entries)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(item.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: value == item.key
                        ? MotoFixUi.orange
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.value,
                      style: TextStyle(
                        color: value == item.key
                            ? Colors.white
                            : MotoFixUi.textSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.onSuspend,
    required this.onActivate,
  });

  final UserModel user;
  final VoidCallback onSuspend;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    final suspended = user.status == UserStatus.suspended;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: suspended ? Colors.redAccent : MotoFixUi.orange,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'Utilisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${user.email} - ${user.role}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MotoFixUi.textSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: suspended ? onActivate : onSuspend,
            child: Text(suspended ? 'Activer' : 'Suspendre'),
          ),
        ],
      ),
    );
  }
}

class _UsersMessage extends StatelessWidget {
  const _UsersMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: MotoFixUi.panelDecoration(radius: 8),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: MotoFixUi.textSoft),
      ),
    );
  }
}
