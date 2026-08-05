library; // Group members presentation page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/repositories/group_repository.dart';
import '../../domain/entities/group.dart';
import '../providers/group_provider.dart';

class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key});

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  List<GroupMember>? _managedUsers;
  Map<String, List<GroupMember>> _membersByGroup = {};
  bool _loading = false;
  bool _processingDrop = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(groupRepositoryProvider);
      final users = await repo.managedUsers();
      final groups = ref
          .read(groupProvider)
          .groups
          .where((g) => g.isOwner)
          .toList();
      final map = <String, List<GroupMember>>{};
      for (final g in groups) {
        map[g.id] = await repo.members(g.id);
      }
      setState(() {
        _managedUsers = users;
        _membersByGroup = map;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _createUser() async {
    final emailC = TextEditingController();
    final pwC = TextEditingController();
    final nameC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah User'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
              ),
              TextFormField(
                controller: emailC,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
              ),
              TextFormField(
                controller: pwC,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 karakter' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref
            .read(groupRepositoryProvider)
            .createUser(emailC.text.trim(), pwC.text, nameC.text.trim());
        _loadData();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User berhasil dibuat')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.error,
            ),
          );
      }
    }
  }

  Future<void> _createGroup() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Grup'),
        content: TextFormField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Nama Grup'),
          validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (c.text.isNotEmpty) Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(groupProvider.notifier).createGroup(c.text.trim());
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Grup berhasil dibuat')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.error,
            ),
          );
      }
    }
  }

  Future<void> _addToGroup(String groupId, String userId) async {
    try {
      await ref
          .read(groupRepositoryProvider)
          .addMember(groupId, userId, 'member');
      _loadData();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  Future<void> _dropOnGroup(_MemberDragData data, String targetGroupId) async {
    if (_processingDrop || data.fromGroupId == targetGroupId) return;
    setState(() => _processingDrop = true);
    try {
      final repo = ref.read(groupRepositoryProvider);
      if (data.fromGroupId == null) {
        await repo.addMember(targetGroupId, data.member.id, 'member');
      } else {
        await repo.moveMember(data.fromGroupId!, targetGroupId, data.member.id);
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data.fromGroupId == null
                  ? '${data.member.fullName} ditambahkan'
                  : '${data.member.fullName} dipindahkan',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses anggota: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingDrop = false);
    }
  }

  Widget _memberTile(GroupMember member, {String? fromGroupId}) {
    final tile = ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: member.isOwner
            ? AppColors.warning.withValues(alpha: .15)
            : AppColors.primary.withValues(alpha: .13),
        child: Icon(
          member.isOwner ? Icons.star_rounded : Icons.person_outline_rounded,
          size: 17,
          color: member.isOwner ? AppColors.warning : AppColors.primary,
        ),
      ),
      title: Text(member.fullName, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        member.isOwner ? 'Owner' : member.email,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: member.isOwner
          ? null
          : const Icon(Icons.drag_indicator_rounded, size: 20),
    );

    if (member.isOwner) return tile;
    final data = _MemberDragData(member: member, fromGroupId: fromGroupId);
    return LongPressDraggable<_MemberDragData>(
      data: data,
      maxSimultaneousDrags: _processingDrop ? 0 : 1,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 260,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: tile,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: tile),
      child: tile,
    );
  }

  Future<void> _removeFromGroup(String groupId, String userId) async {
    try {
      await ref.read(groupRepositoryProvider).removeMember(groupId, userId);
      _loadData();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref
        .watch(groupProvider)
        .groups
        .where((g) => g.isOwner)
        .toList();

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Anggota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _createUser,
            tooltip: 'Tambah User',
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _createGroup,
            tooltip: 'Buat Grup',
          ),
        ],
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text(
                'Kamu belum punya grup. Buat grup dulu.',
                style: TextStyle(color: AppColors.textHint),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                Card(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengguna tersedia',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Tekan lama lalu seret pengguna ke kartu grup tujuan.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: .6),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (_managedUsers == null || _managedUsers!.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            child: Text(
                              'Belum ada user. Tambah user dulu.',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ..._managedUsers!.map((u) => _memberTile(u)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...groups.map((g) {
                  final members = _membersByGroup[g.id] ?? [];
                  return DragTarget<_MemberDragData>(
                    onWillAcceptWithDetails: (details) =>
                        details.data.fromGroupId != g.id,
                    onAcceptWithDetails: (details) =>
                        _dropOnGroup(details.data, g.id),
                    builder: (context, candidates, rejected) => AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        boxShadow: candidates.isNotEmpty
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: .24,
                                  ),
                                  blurRadius: 0,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Card(
                        color: candidates.isNotEmpty
                            ? AppColors.primary.withValues(alpha: .10)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    g.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${members.length} anggota',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.textHint),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (members.isEmpty)
                                const Text(
                                  'Belum ada anggota',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 13,
                                  ),
                                )
                              else
                                ...members.map(
                                  (m) => Row(
                                    children: [
                                      Expanded(
                                        child: _memberTile(
                                          m,
                                          fromGroupId: g.id,
                                        ),
                                      ),
                                      if (!m.isOwner)
                                        IconButton(
                                          tooltip: 'Hapus dari grup',
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: AppColors.expense,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _removeFromGroup(g.id, m.id),
                                        ),
                                    ],
                                  ),
                                ),
                              if (_managedUsers != null &&
                                  _managedUsers!.isNotEmpty) ...[
                                const Divider(),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final userId = await showDialog<String>(
                                        context: context,
                                        builder: (ctx) {
                                          final available = _managedUsers!
                                              .where(
                                                (u) => !members.any(
                                                  (m) => m.id == u.id,
                                                ),
                                              )
                                              .toList();
                                          if (available.isEmpty)
                                            return AlertDialog(
                                              title: const Text('Info'),
                                              content: const Text(
                                                'Semua user sudah masuk grup.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            );
                                          return AlertDialog(
                                            title: Text('Tambah ke ${g.name}'),
                                            content: SizedBox(
                                              width: double.maxFinite,
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: available.length,
                                                itemBuilder: (_, i) => ListTile(
                                                  title: Text(
                                                    available[i].fullName,
                                                  ),
                                                  subtitle: Text(
                                                    available[i].email,
                                                  ),
                                                  onTap: () => Navigator.pop(
                                                    ctx,
                                                    available[i].id,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                      if (userId != null)
                                        await _addToGroup(g.id, userId);
                                    },
                                    icon: const Icon(
                                      Icons.person_add,
                                      size: 18,
                                    ),
                                    label: const Text('Tambah Anggota'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _MemberDragData {
  const _MemberDragData({required this.member, this.fromGroupId});
  final GroupMember member;
  final String? fromGroupId;
}
