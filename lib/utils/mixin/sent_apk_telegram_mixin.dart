import 'dart:convert';
import 'dart:io';

import 'package:ssl_cli/utils/extension.dart';

import '../enum.dart';

mixin SentApkTelegramMixin {
  void sentApkTelegramFunc() {
    //Data read from config.json
    String constantsFileContent =
        File("${Directory.current.path}/config.json").readAsStringSync();
    Map<String, dynamic> constants = jsonDecode(constantsFileContent);

    if (constants['telegram_chat_id'].toString().isEmpty ||
        constants['botToken'].toString().isEmpty) {
      'Please check config.json file. Maybe telegram chat id and BotToken is missing.'
          .printWithColor(status: PrintType.warning);
      exit(0);
    }
    print("Sent APK to telegram initiating....");
    // Path to the directory containing APKs
    String apkDirectory = './build/app/outputs/apk/release';

    // Use the listSync method to get a list of files in the directory
    var apkFiles = Directory(apkDirectory).listSync();

    var matchingApk = apkFiles.firstWhere(
      (file) => file is File && file.path.contains(".apk"),
    );

    var result = Process.runSync(
      'curl',
      [
        '-F',
        'chat_id=${constants['telegram_chat_id']}',
        '-F',
        'document=@${matchingApk.path}',
        'https://api.telegram.org/bot${constants['botToken']}/sendDocument',
      ],
    );

    // Check the result and handle accordingly
    if (result.exitCode == 0) {
      'APK sent to Telegram successfully.'
          .printWithColor(status: PrintType.success);
      exit(0);
    } else {
      print('Failed to send APK to Telegram. Error: ${result.stderr}');
      exit(0);
    }
  }
}
