import 'dart:async';
import 'package:flutter/material.dart';

import '../models/dm_user_model.dart';
import '../services/dm_search_service.dart';

class DmSearchProvider extends ChangeNotifier {
  final DmSearchService _service = DmSearchService();

  bool _loading = false;
  bool get loading => _loading;

  List<DmUserModel> _results = [];
  List<DmUserModel> get results => _results;

  Timer? _debounce;

  void clear() {
    _results = [];
    notifyListeners();
  }

  void search({
    required String token,
    required String query,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      await _searchNow(token: token, query: query);
    });
  }

  Future<void> _searchNow({
    required String token,
    required String query,
  }) async {
    final q = query.trim();
    if (q.isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    try {
      _loading = true;
      notifyListeners();

      final data = await _service.searchUsers(token: token, query: q);
      final list = (data['users'] as List? ?? []);

      _results = list
          .whereType<Map<String, dynamic>>()
          .map((e) => DmUserModel.fromJson(e))
          .toList();
    } catch (_) {
      _results = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
