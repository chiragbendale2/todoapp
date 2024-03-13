import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_project/models/task.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of tasks for a specific user
  Stream<QuerySnapshot> streamAllTasks(String userId) {
    Stream<QuerySnapshot> snapshots =
        FirebaseFirestore.instance.collection('tasks').snapshots();

    return snapshots;
  }

  addEditorToListOfTask(
      {required String docId, required String deviceId}) async {
    await _firestore.collection('tasks').doc(docId).update(
      {
        'editors': FieldValue.arrayUnion(
          [deviceId],
        ),
      },
    );
    var task = await _firestore.collection('tasks').doc(docId).get();

    log('querySnapshot : ${task.data()}');
  }

  findIfEditorRole({
    required List editors,
    required String deviceId,
  }) {
    bool isThere = false;
    for (var item in editors) {
      if (item == deviceId) {
        isThere = true;
      }
    }
    return isThere;
  }

  Stream<List<Task>> getEditorsTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('owner', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Task.fromSnapshot(doc.data()))
              .toList(),
        );
  }

  // Add or update a task in Firestore
  Future<void> setTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toMap());
  }
}
