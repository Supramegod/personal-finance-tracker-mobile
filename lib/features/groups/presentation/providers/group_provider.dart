library; // Group presentation provider.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/group.dart';
import '../../data/repositories/group_repository.dart';
import '../../domain/repositories/group_repository_contract.dart';

class GroupState {
  final List<Group> groups;
  final String? activeGroupId;
  final bool isLoading;
  final String? errorMessage;

  const GroupState({
    this.groups = const [],
    this.activeGroupId,
    this.isLoading = false,
    this.errorMessage,
  });

  GroupState copyWith({
    List<Group>? groups,
    String? activeGroupId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GroupState(
      groups: groups ?? this.groups,
      activeGroupId: activeGroupId ?? this.activeGroupId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Group? get activeGroup {
    if (activeGroupId == null) return null;
    try {
      return groups.firstWhere((g) => g.id == activeGroupId);
    } catch (_) {
      return null;
    }
  }
}

class GroupNotifier extends StateNotifier<GroupState> {
  GroupNotifier(this._repo) : super(const GroupState()) {
    load();
  }

  @visibleForTesting
  GroupNotifier.test([GroupState initialState = const GroupState()])
    : _repo = null,
      super(initialState);

  final GroupRepositoryContract? _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final groups = await _repo!.list();
      final storedGroupId = await _repo.activeGroupId();
      final activeGroupId = groups.any((group) => group.id == storedGroupId)
          ? storedGroupId
          : (groups.isEmpty ? null : groups.first.id);
      state = state.copyWith(
        groups: groups,
        activeGroupId: activeGroupId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setActiveGroup(String groupId) {
    state = state.copyWith(activeGroupId: groupId);
  }

  Future<void> switchGroup(String groupId) async {
    await _repo!.switchGroup(groupId);
    state = state.copyWith(activeGroupId: groupId);
  }

  Future<void> createGroup(String name) async {
    await _repo!.create(name);
    await load();
  }
}

final groupProvider = StateNotifierProvider<GroupNotifier, GroupState>((ref) {
  return GroupNotifier(ref.watch(groupRepositoryProvider));
});
