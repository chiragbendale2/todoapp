import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_project/services/dynamic_link_service.dart';
import 'package:todo_project/utils/device_util.dart';
import 'package:todo_project/view_models/task_view_model.dart';
import 'package:todo_project/views/home_screen.dart';

String deviceId = '';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  deviceId = await DeviceUtil().getId() ?? '';

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAr5o39yOi-bDUaShX9vXMvoOE65ns9xZs",
      appId: "1:601509253054:android:8d5ac8d4cdd5686e1033ef",
      messagingSenderId: "601509253054",
      projectId: "todoapp-d1c75",
    ),
  );
  await DynamicLinkService().retrieveDynamicLink();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaskViewModel(deviceId),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ToDo App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
