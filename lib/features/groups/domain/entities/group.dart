library; // Group domain entities.

class Group {
  final String id;
  final String name;
  final String role;

  const Group({required this.id, required this.name, required this.role});

  bool get isOwner => role == 'owner';

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      role: (json['role'] as String?) ?? 'member',
    );
  }
}

class GroupMember {
  final String id;
  final String email;
  final String fullName;
  final String role;

  const GroupMember({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  bool get isOwner => role == 'owner';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      // Respons /users memakai `id`, sedangkan respons anggota grup
      // memakai `user_id`. Seluruh aksi keanggotaan membutuhkan user ID.
      id: (json['user_id'] ?? json['id']) as String,
      email: (json['email'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'member',
    );
  }
}
