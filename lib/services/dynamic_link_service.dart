import 'dart:developer';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:todo_project/main.dart';
import 'package:todo_project/services/firestore_service.dart';

class DynamicLinkService {
  Future<void> retrieveDynamicLink() async {
    try {
      final PendingDynamicLinkData? data =
          await FirebaseDynamicLinks.instance.getInitialLink();

      if (data != null) {
        final params = data.link.queryParameters;

        log('params : $params');
        if (params.isNotEmpty) {
          log('dynamicLink : $params');
          FirestoreService().addEditorToListOfTask(
            deviceId: deviceId,
            docId: params['taskId'].toString(),
          );
        }
      }

      FirebaseDynamicLinks.instance.onLink
          .listen((PendingDynamicLinkData dynamicLink) async {
        var params = dynamicLink.link.queryParameters;

        if (params.isNotEmpty) {
          log('dynamicLink : $params');
          FirestoreService().addEditorToListOfTask(
            deviceId: deviceId,
            docId: params['taskId'].toString(),
          );
        }
      });
    } catch (e) {
      log(e.toString());
    }
  }

  Future<Uri> createDynamicLink(String id) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://todochirag.page.link',
      link: Uri.parse('https://todochirag.page.link.com?taskId=$id'),
      androidParameters: const AndroidParameters(
        packageName: 'com.example.todo_project',
        minimumVersion: 1,
      ),
    );

    final uri = await FirebaseDynamicLinks.instance.buildLink(parameters);

    return uri;
  }
}
