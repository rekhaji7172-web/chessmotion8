import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';

const _uuid = Uuid();

class ProjectProvider extends ChangeNotifier {
  List<ChessProject> _projects = [];
  bool _loading = false;

  List<ChessProject> get projects => List.unmodifiable(_projects);
  bool get loading => _loading;

  List<ChessProject> get sortedProjects {
    final list = List<ChessProject>.from(_projects);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<void> loadProjects() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList('chess_projects') ?? [];
      _projects = data.map((s) {
        try {
          return ChessProject.fromJson(jsonDecode(s));
        } catch (_) {
          return null;
        }
      }).whereType<ChessProject>().toList();
    } catch (_) {
      _projects = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> saveProject(ChessProject project) async {
    final idx = _projects.indexWhere((p) => p.id == project.id);
    final updated = project.copyWith(updatedAt: DateTime.now());
    if (idx >= 0) {
      _projects[idx] = updated;
    } else {
      _projects.add(updated);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> duplicateProject(String id) async {
    final src = _projects.firstWhere((p) => p.id == id);
    final copy = src.copyWith(
      id: _uuid.v4(),
      title: '${src.title} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _projects.add(copy);
    await _persist();
    notifyListeners();
  }

  ChessProject? getProject(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _projects.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList('chess_projects', data);
    } catch (_) {}
  }
}
