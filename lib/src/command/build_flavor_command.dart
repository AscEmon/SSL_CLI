import 'dart:convert';
import 'dart:io';

import 'package:ssl_cli/utils/extension.dart';

import '../../utils/enum.dart';
import 'i_command.dart';

class BuildFlavorCommand implements ICommand {
  final List<String> arguments;
  const BuildFlavorCommand({
    required this.arguments,
  });
  @override
  void execute() {
    String executable = 'flutter';
    List<String> arg = List.from(arguments);
    arg.insert(0, executable);

    if (arg.length < 4 && !((arg.last == "clean") || (arg.last == "get"))) {
      "Need build flavor ex: --LIVE ,--DEV"
          .printWithColor(status: PrintType.warning);
      exit(1);
    }
    if (arg.contains("apk")) {
      print("executing build command with dart define...");
      arg[3] = '--dart-define=mode=${arguments[2].replaceAll("--", "")}';
    }

    var result = Process.runSync(arg[0], arg.sublist(1));

    if (result.exitCode == 0) {
      if (arg.last == "clean") {
        "Clean sucessfully".printWithColor(status: PrintType.success);
        exit(0);
      } else if (arg.last == "get") {
        "pub get sucessfully completed"
            .printWithColor(status: PrintType.success);
        exit(0);
      } else {
        'APK file created sucessfully.'
            .printWithColor(status: PrintType.success);
        if (apkSentTelegramBoard()) {
          sentApkTelegramFunc(arguments[2].replaceAll("--", ""));
        } else {
          exit(0);
        }
      }
    } else {
      // Process encountered an error
      print('stderr: ${result.stderr}');
      'Error: Process failed with exit code ${result.exitCode}'
          .printWithColor(status: PrintType.error);
    }

    exit(0);
  }
}

bool apkSentTelegramBoard() {
  String content = '''Would you like to sent APK to the Telegram?[y/n]\n''';

  stderr.write(content);

  final answer = stdin.readLineSync();
  final validator =
      answer?.toLowerCase() == 'y' || answer?.toLowerCase() == 'yes';

  return answer != null && validator;
}

void sentApkTelegramFunc(String mode) {
  print("Sent $mode APK to telegram initiating....");
  // Path to the directory containing APKs
  String apkDirectory = './build/app/outputs/apk/release';

  // Use the listSync method to get a list of files in the directory
  var apkFiles = Directory(apkDirectory).listSync();

  var matchingApk = apkFiles.firstWhere(
    (file) => file is File && file.path.contains("_${mode}_"),
  );

  //Data read from config.json
  String constantsFileContent =
      File("${Directory.current.path}/config.json").readAsStringSync();
  Map<String, dynamic> constants = jsonDecode(constantsFileContent);

  if (constants['telegram_chat_id'].toString().isEmpty ||
      constants['botToken']) {
    'Please check config.json file. Maybe telegram chat id and BotToken is missing.'
        .printWithColor(status: PrintType.warning);
    return;
  }

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
  } else {
    print('Failed to send APK to Telegram. Error: ${result.stderr}');
  }
}
