import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quizapp/models/models.dart';
import 'package:quizapp/screens/screens.dart' show LeaderBoardScreen;
import 'package:quizapp/utils/logger.dart';

class NotificationService extends GetxService {
  final _notifications = FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    _initNotifications();
    super.onInit();
  }

  Future<void> _initNotifications() async {
    const androidInitializationSettings =
        AndroidInitializationSettings('@drawable/app_notification_icon');
    const iosInitializationSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: androidInitializationSettings,
            iOS: iosInitializationSettings);
    _notifications.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (payload) {
      if (payload != null) {
        final QuizPaperModel quizPaperModel =
            QuizPaperModel.fromJson(json.decode(payload as String));
        Get.toNamed(LeaderBoardScreen.routeName, arguments: quizPaperModel);
        //MyApp.navigatorKey.currentState!.pushNamed(LeaderBoardScreen.routeName, arguments:quizPaperModel);
      }
    });
  }

  Future<void> showQuizCompletedNotification(
      {required int id,
      String? title,
      String? body,
      String? imageUrl,
      String? payload}) async {
    BigPictureStyleInformation? bigPictureStyleInformation;
    String? largeIconPath;

    if (imageUrl != null) {
      largeIconPath = await _downloadAndSaveFile(imageUrl, 'largeIcon');
      final String? bigPicturePath =
          await _downloadAndSaveFile(imageUrl, 'bigPicture');

      if (bigPicturePath != null) {
        bigPictureStyleInformation = BigPictureStyleInformation(
            FilePathAndroidBitmap(bigPicturePath),
            hideExpandedLargeIcon: true,
            contentTitle: '<b>$title</b>',
            htmlFormatContentTitle: true,
            summaryText: '<b>$body</b>',
            htmlFormatSummaryText: true);
      }
    }

    _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
            android: AndroidNotificationDetails('quizcomplete', 'quizcomplete',
                channelDescription: 'Skor tablosunu aç',
                importance: Importance.max,
                largeIcon: FilePathAndroidBitmap(largeIconPath!),
                styleInformation: bigPictureStyleInformation,
                priority: Priority.max),
            iOS: const DarwinNotificationDetails(
                presentAlert: true, presentBadge: true, presentSound: true)),
        payload: payload);
  }

  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName';
      final http.Response response = await http.get(Uri.parse(url));
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      AppLogger.e(e);
    }
  }
}