import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';

enum _Role {
  seeker('Job seeker'),
  recruiter('Recruiter'),
  admin('Admin');

  const _Role(this.label);
  final String label;
}

class _User {
  _User(this.name, this.email, this.role, this.active);

  final String name;
  final String email;
  _Role role;
  bool active;
}

// Made-up people for the sample list (real accounts arrive in Phase 5).
List<_User> _sampleUsers() {
  const first = [
    'Aina',
    'Hafiz',
    'Wei Jie',
    'Priya',
    'Daniel',
    'Nurul',
    'Kumar',
    'Mei Ling',
    'Arif',
    'Siti',
    'Jason',
    'Farah',
  ];
  const last = ['Rahman', 'Tan', 'Lim', 'Raj', 'Wong', 'Ismail', 'Lee', 'Abdullah', 'Chong', 'Nair'];
  return [
    for (var i = 0; i < 240; i++)
      _User(
        '${first[i % first.length]} ${last[(i * 7) % last.length]}',
        '${first[i % first.length].toLowerCase().replaceAll(' ', '')}.${last[(i * 7) % last.length].toLowerCase()}$i@example.com',
        i % 60 == 0 ? _Role.admin : (i % 5 == 1 ? _Role.recruiter : _Role.seeker),
        i % 60 == 0 || i % 9 != 4,
      ),
  ];
}

/// Admin list of all accounts: search, filter by role, change role, turn access on or off.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  static const _pageSize = 20;

  final _users = _sampleUsers();
  String _query = '';
  _Role? _roleFilter;
  int _page = 0;

  List<_User> get _shown {
    final q = _query.trim().toLowerCase();
    return _users
        .where((u) => _roleFilter == null || u.role == _roleFilter)
        .where((u) => q.isEmpty || u.name.toLowerCase().contains(q) || u.email.contains(q))
        .toList();
  }

  // Ask first, because these changes lock people out or give them new rights.
  Future<void> _confirm(String title, String message, String action, String done, VoidCallback onYes) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    if (yes == true && mounted) {
      setState(onYes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    }
  }

  void _toggle(_User u) => u.active
      ? _confirm(
          'Disable ${u.name}?',
          'They will not be able to log in until you enable the account again.',
          'Disable',
          '${u.name} is disabled.',
          () => u.active = false,
        )
      : _confirm(
          'Enable ${u.name}?',
          'They will be able to log in again.',
          'Enable',
          '${u.name} is enabled.',
          () => u.active = true,
        );

  void _changeRole(_User u, _Role role) => _confirm(
    'Make ${u.name} a ${role.label.toLowerCase()}?',
    'Their menu and pages change the next time they log in.',
    'Change role',
    '${u.name} is now a ${role.label.toLowerCase()}.',
    () => u.role = role,
  );

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final shown = _shown;
    final pages = (shown.length / _pageSize).ceil().clamp(1, 1 << 20);
    final page = _page.clamp(0, pages - 1);
    final start = page * _pageSize;
    final slice = shown.skip(start).take(_pageSize).toList();
    int count(bool Function(_User) test) => _users.where(test).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          kicker: 'Admin',
          title: 'Users and roles',
          subtitle: 'Find an account, change its role, or turn its access off and on.',
          trailing: GlassChip(label: 'Sample data'),
        ),
        const SizedBox(height: Gaps.section),
        StatStrip(
          items: [
            StatItem('Total users', '${_users.length}', 'All accounts'),
            StatItem('Active', '${count((u) => u.active)}', 'Can log in'),
            StatItem('Recruiters', '${count((u) => u.role == _Role.recruiter)}', 'Employer accounts'),
            StatItem('Admins', '${count((u) => u.role == _Role.admin)}', 'Granted by the developer'),
          ],
        ),
        const SizedBox(height: Gaps.block),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('user-search'),
                      decoration: const InputDecoration(
                        labelText: 'Search by name or email',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() {
                        _query = v;
                        _page = 0;
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<_Role?>(
                      initialValue: _roleFilter,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All roles')),
                        for (final r in _Role.values) DropdownMenuItem(value: r, child: Text(r.label)),
                      ],
                      onChanged: (v) => setState(() {
                        _roleFilter = v;
                        _page = 0;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _HeaderRow(),
              if (slice.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No accounts match. Try a shorter search or another role.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: t.textSub),
                  ),
                ),
              for (final u in slice) _UserRow(user: u, onToggle: () => _toggle(u), onRole: (r) => _changeRole(u, r)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    shown.isEmpty ? '0 accounts' : 'Showing ${start + 1}–${start + slice.length} of ${shown.length}',
                    style: TextStyle(fontSize: 14, color: t.textSub),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Previous page',
                    onPressed: page > 0 ? () => setState(() => _page = page - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page ${page + 1} of $pages', style: TextStyle(fontSize: 14, color: t.text)),
                  IconButton(
                    tooltip: 'Next page',
                    onPressed: page < pages - 1 ? () => setState(() => _page = page + 1) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Column widths shared by the header and every row.
const _flex = [5, 2, 2, 3];

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final style = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.textSub);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.cardEdge)),
      ),
      child: Row(
        children: [
          for (final (i, label) in ['Name', 'Role', 'Status', 'Actions'].indexed)
            Expanded(
              flex: _flex[i],
              child: Text(label, style: style),
            ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onToggle, required this.onRole});

  final _User user;
  final VoidCallback onToggle;
  final ValueChanged<_Role> onRole;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final isAdmin = user.role == _Role.admin;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.cardEdge.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: _flex[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
                ),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 14, color: t.textSub),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: _flex[1],
            child: Text(user.role.label, style: TextStyle(fontSize: 15, color: t.text)),
          ),
          Expanded(
            flex: _flex[2],
            child: Align(
              alignment: Alignment.centerLeft,
              child: GlassChip(label: user.active ? 'Active' : 'Disabled', color: user.active ? t.success : t.danger),
            ),
          ),
          Expanded(
            flex: _flex[3],
            // Admin accounts are managed by the developer, so they cannot be changed here.
            child: isAdmin
                ? Text('Protected', style: TextStyle(fontSize: 14, color: t.textFaint))
                : Wrap(
                    spacing: 4,
                    children: [
                      TextButton(onPressed: onToggle, child: Text(user.active ? 'Disable' : 'Enable')),
                      PopupMenuButton<_Role>(
                        tooltip: 'Change role',
                        onSelected: onRole,
                        itemBuilder: (context) => [
                          for (final r in [_Role.seeker, _Role.recruiter])
                            if (r != user.role) PopupMenuItem(value: r, child: Text('Make ${r.label.toLowerCase()}')),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(
                            'Change role',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
