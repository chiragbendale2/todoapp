import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:todo_project/models/task.dart';
import 'package:todo_project/services/dynamic_link_service.dart';
import 'package:todo_project/services/firestore_service.dart';
import 'package:todo_project/view_models/task_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController titleCtrl = TextEditingController();
  TextEditingController descriptionCtrl = TextEditingController();

  late TaskViewModel taskViewModel;

  @override
  void initState() {
    taskViewModel = Provider.of<TaskViewModel>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Todo App'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          clearFields();
          addOrUpdateTask(
            context: context,
            isEdit: false,
            document: null,
          );
        },
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().streamAllTasks(taskViewModel.userId),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text("Loading"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tasks'));
          }

          // var noTasks = false;

          // for (var item in snapshot.data!.docs) {
          //   List editors = item['editors'];
          //   if (item['owner'] == taskViewModel.userId ||
          //       (!editors.contains(taskViewModel.userId))) {
          //     noTasks = true;
          //   } else {
          //     noTasks = false;
          //   }
          // }
          // if (noTasks) {
          //   return const Center(child: Text('No tasks'));
          // }

          return ListView(
            shrinkWrap: true,
            children: snapshot.data!.docs.map(
              (document) {
                List editors = document['editors'];

                if (document['owner'] == taskViewModel.userId ||
                    (editors.isNotEmpty &&
                        editors.contains(taskViewModel.userId))) {
                  return ListTile(
                    dense: true,
                    leading: document['owner'] == taskViewModel.userId
                        ? Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              color: Colors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'Owner',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(),
                    minLeadingWidth: 55,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    horizontalTitleGap: 5,
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          document['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    subtitle: Text(
                      document['description'],
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        (FirestoreService().findIfEditorRole(
                                  editors: editors,
                                  deviceId: taskViewModel.userId,
                                ) ||
                                document['owner'] == taskViewModel.userId)
                            ? IconButton.filledTonal(
                                onPressed: () {
                                  titleCtrl.text = document['title'];
                                  descriptionCtrl.text =
                                      document['description'];
                                  addOrUpdateTask(
                                    context: context,
                                    isEdit: true,
                                    document: document,
                                  );
                                },
                                icon: const Icon(Icons.edit_outlined),
                              )
                            : const SizedBox(),
                        document['owner'] == taskViewModel.userId
                            ? IconButton.filledTonal(
                                onPressed: () => shareTask(document),
                                icon: const Icon(Icons.share_outlined),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  );
                }
                return SizedBox();
              },
            ).toList(),
          );
        },
      ),
    );
  }

  void shareTask(QueryDocumentSnapshot<Object?> document) async {
    final uri = await DynamicLinkService().createDynamicLink(document.id);

    await Share.share(uri.toString(), subject: 'Task Share to collaborator');
  }

  clearFields() {
    titleCtrl.clear();
    descriptionCtrl.clear();
  }

  void addOrUpdateTask({
    required BuildContext context,
    required bool isEdit,
    QueryDocumentSnapshot<Object?>? document,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${isEdit ? 'Edit' : 'Add'} Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                clearFields();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Add the task to Firestore
                if (document != null) {
                  _saveTask(
                    context: context,
                    isEdit: isEdit,
                    document: document,
                  );
                } else {
                  _saveTask(
                    context: context,
                    isEdit: isEdit,
                    document: null,
                  );
                }
                clearFields();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Task ${isEdit ? 'Updated' : 'Created'} Successfully.'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Save the task to Firestore
  void _saveTask({
    required BuildContext context,
    required bool isEdit,
    QueryDocumentSnapshot<Object?>? document,
  }) {
    String title = titleCtrl.text.trim();
    String description = descriptionCtrl.text.trim();
    if (document != null) {
      if (title.isNotEmpty && description.isNotEmpty) {
        Task task = Task(
          id: document['id'],
          owner: document['owner'],
          title: title,
          description: description,
          editors: document['editors'] ?? [],
        );

        Provider.of<TaskViewModel>(context, listen: false)
            .addOrUpdateTask(task);
      }
    } else {
      if (title.isNotEmpty && description.isNotEmpty) {
        Task task = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          owner: Provider.of<TaskViewModel>(context, listen: false).userId,
          title: title,
          description: description,
          editors: [],
        );

        Provider.of<TaskViewModel>(context, listen: false)
            .addOrUpdateTask(task);
      }
    }
  }
}
