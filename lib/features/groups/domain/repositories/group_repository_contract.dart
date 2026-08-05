import '../entities/group.dart';

abstract interface class GroupRepositoryContract {
  Future<String?> activeGroupId();
  Future<List<Group>> list();
  Future<Group> create(String name);
  Future<void> switchGroup(String groupId);
  Future<List<GroupMember>> members(String groupId);
  Future<void> addMember(String groupId, String userId, String role);
  Future<void> removeMember(String groupId, String userId);
  Future<void> moveMember(String fromGroupId, String toGroupId, String userId);
  Future<List<GroupMember>> managedUsers();
  Future<void> createUser(String email, String password, String fullName);
}
