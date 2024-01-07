import 'dart:convert';
import 'dart:io';

import 'package:ssl_cli/src/command/i_command.dart';
import 'package:ssl_cli/utils/extension.dart';

import '../../utils/enum.dart';
import '../../utils/mixin/sent_apk_telegram_mixin.dart';

class BuildFlavorCommand with SentApkTelegramMixin implements ICommand {
  final List<String> arguments;

  BuildFlavorCommand({required this.arguments});

  @override
  void execute() async {
    String executable = 'flutter';
    List<String> arg = List.from(arguments);
    arg.insert(0, executable);

    // printArguments(arg);

    validateArguments(arg);

    await processCommand(arg);
  }

  void printArguments(List<String> arguments) {
    print(arguments);
  }

  void validateArguments(List<String> arguments) {
    if (arguments.length < 4 &&
        !((arguments.contains("clean")) ||
            (arguments.contains("get")) ||
            (arguments.contains("run")) ||
            (arguments.contains("appbundle")))) {
      "Need build flavor ex: --LIVE ,--DEV"
          .printWithColor(status: PrintType.warning);
      exit(1);
    }
  }

  Future<void> processCommand(List<String> arguments) async {
    if (arguments.contains("apk")) {
      print("executing build command with dart define...");
      arguments[3] = '--dart-define=mode=${arguments[3].replaceAll("--", "")}';
    }

    if (arguments.contains("run")) {
      await runCommand(arguments);
    } else {
      Process process;

      if (arguments.contains("--t")) {
        process = await Process.start(arguments[0], arguments.sublist(1, 4));
      } else {
        process = await Process.start(arguments[0], arguments.sublist(1));
      }

      await handleProcessResult(process, arguments);
    }
  }

  Future<void> runCommand(List<String> arguments) async {
    print(
        "executing run command for ${arguments[2].replaceAll("--", "")} mode with dart define for release build...");
    arguments[2] = '--dart-define=mode=${arguments[2].replaceAll("--", "")}';
    arguments.add("--release");
    var process = await Process.start(arguments[0], arguments.sublist(1));

    await handleProcessResult(process, arguments);
  }

  Future<void> handleProcessResult(
      Process process, List<String> arguments) async {
    var stdoutSubscription = process.stdout.listen((List<int> data) {
      print(utf8.decode(data));
    });

    var stderrSubscription = process.stderr.listen((List<int> data) {
      print(utf8.decode(data));
    });

    stdin.lineMode = false;
    stdin.listen((List<int> data) {
      for (int charCode in data) {
        handleKeyPress(String.fromCharCode(charCode));
      }
    });

    var exitCode = await process.exitCode;

    await stdoutSubscription.cancel();
    await stderrSubscription.cancel();

    if (exitCode == 0) {
      handleSuccessExitCode(arguments);
    } else {
      handleFailureExitCode();
    }
  }

  void handleSuccessExitCode(List<String> arguments) {
    if (arguments.contains("clean")) {
      "Clean successfully".printWithColor(status: PrintType.success);
      exit(0);
    } else if (arguments.contains("get")) {
      "pub get successfully completed"
          .printWithColor(status: PrintType.success);
      exit(0);
    } else if (arguments.contains("run")) {
      print("Run successfully completed. Installing.....");
      exit(0);
    } else if (arguments.contains("apk")) {
      'APK file created successfully.'
          .printWithColor(status: PrintType.success);
      if (arguments.contains("--t")) {
        sentApkTelegramFunc();
      } else {
        handleApkProcessing();
      }
    } else if (arguments.contains("appbundle")) {
      'App Bundle file created successfully.'
          .printWithColor(status: PrintType.success);
      exit(0);
    }
  }

  void handleFailureExitCode() {
    print('Error: Process failed with exit code $exitCode');
    exit(0);
  }

  Future<void> handleApkProcessing() async {
    if (apkSentTelegramBoard()) {
      sentApkTelegramFunc();
    } else {
      exit(0);
    }
  }
}

void handleKeyPress(String key) {
  switch (key) {
    case 'c':
      clearScreen();
      break;
    case 'q':
      quitApplication();
      break;
  }
}

void clearScreen() {
  if (Platform.isWindows) {
    // For Windows
    print(Process.runSync("cls", [], runInShell: true).stdout);
  } else {
    // For other platforms (Linux, macOS)
    print(Process.runSync("clear", [], runInShell: true).stdout);
  }
}

void quitApplication() {
  print(" Quitting the application");
  exit(0);
}

bool apkSentTelegramBoard() {
  String content = '''Would you like to sent APK to the Telegram?[y/n]\n''';

  stderr.write(content);

  final answer = stdin.readLineSync();
  final validator =
      answer?.toLowerCase() == 'y' || answer?.toLowerCase() == 'yes';

  return answer != null && validator;
}
