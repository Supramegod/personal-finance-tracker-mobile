library; // Group data repository.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository_contract.dart';

class GroupRepository implements GroupRepositoryContract {
  GroupRepository(this._dio, this._storage);
  final Dio _dio;
  final TokenStorage _storage;

  @override
  Future<String?> activeGroupId() => _storage.activeGroupId;

  @override
  Future<List<Group>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/groups');
      final data =
          (res.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Group> create(String name) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/groups',
        data: {'name': name},
      );
      return Group.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> switchGroup(String groupId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/switch-group',
        data: {'group_id': groupId},
      );
      final data = res.data as Map<String, dynamic>;
      await _storage.saveTokens(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
        activeGroupId: groupId,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<GroupMember>> members(String groupId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/groups/$groupId/members',
      );
      final data =
          (res.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> addMember(String groupId, String userId, String role) async {
    try {
      await _dio.post<void>(
        '/groups/$groupId/members',
        data: {'user_id': userId, 'role': role},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _dio.delete<void>('/groups/$groupId/members/$userId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Samakan perilaku drag-and-drop web: tambah ke tujuan terlebih dahulu,
  /// kemudian hapus dari grup asal.
  @override
  Future<void> moveMember(
    String fromGroupId,
    String toGroupId,
    String userId,
  ) async {
    if (fromGroupId == toGroupId) return;
    await addMember(toGroupId, userId, 'member');
    await removeMember(fromGroupId, userId);
  }

  @override
  Future<List<GroupMember>> managedUsers() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users');
      final data =
          (res.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> createUser(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      await _dio.post<void>(
        '/users',
        data: {'email': email, 'password': password, 'full_name': fullName},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final groupRepositoryProvider = Provider<GroupRepositoryContract>((ref) {
  return GroupRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});
