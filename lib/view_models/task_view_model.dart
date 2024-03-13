import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:todo_project/models/task.dart';
import 'package:todo_project/services/firestore_service.dart';

class TaskViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  late String _userId;

  String get userId => _userId;

  TaskViewModel(String userId) {
    _userId = userId;
  }

  Stream<QuerySnapshot> get tasks => _firestoreService.streamAllTasks(_userId);

  Future<void> addOrUpdateTask(Task task) async {
    await _firestoreService.setTask(task);
  }
}
