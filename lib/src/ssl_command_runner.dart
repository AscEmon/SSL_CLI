import 'dart:io';
import 'package:args/args.dart';
import 'package:ssl_cli/src/command/build_flavor_command.dart';
import 'package:ssl_cli/utils/setup_flavor.dart';
import 'package:ssl_cli/utils/extension.dart';
import '../utils/enum.dart';
import '../utils/mixin/sent_apk_telegram_mixin.dart';
import 'command/asset_generation_command.dart';
import 'command/create_command.dart';
import 'command/help_command.dart';
import 'command/i_command.dart';

class SSLCommandRunner with SentApkTelegramMixin {
  void run(List<String> arguments) {
    final argParser = ArgParser();

    _setupArgParser(argParser);

    final res = argParser.parse(arguments);

    try {
      if (res.command != null && res.command!.name != null) {
        ICommand? command;

        if (res.command!.name!.startsWith('create')) {
          command = _handleCreateCommand(arguments);
        } else if (res.command!.name!.contains('module')) {
          command = _handleModuleCommand(arguments);
        } else if (res.command!.name!.contains('setup') &&
            res.command!.arguments.first.contains("flavor")) {
          _handleSetupCommand();
        } else if (res.command!.name!.contains('build') ||
            res.command!.name!.contains('clean') ||
            res.command!.name!.contains('pub') ||
            res.command!.name!.contains('run') ||
            res.command!.arguments.first.contains("t")) {
          command = _handleBuildCommand(res.arguments);
        } else if (res.command!.name!.startsWith('generate')) {
          command = _handleGenerateCommand(arguments);
        } else if (res.command!.name!.startsWith('sent') &&
            res.command!.arguments.first.contains("apk")) {
          _handleSentCommand();
        } else if (res.command!.name!.startsWith('help')) {
          command = HelpCommand();
        } else {
          _errorAndExit(res.command!.name);
        }

        command?.execute();
      } else {
        _errorAndExit();
      }
    } catch (e) {
      print(e);
      _errorAndExit();
    }
  }

  void _setupArgParser(ArgParser argParser) {
    argParser
      ..addCommand('create')
      ..addCommand('module')
      ..addCommand('generate')
      ..addCommand('build')
      ..addCommand('clean')
      ..addCommand('pub')
      ..addCommand('run')
      ..addCommand('setup')
      ..addCommand("sent")
      ..addFlag('flavor', negatable: false, help: 'Enable flavor')
      ..addFlag('apk', negatable: false, help: 'Sent Apk to telegram group.')
      ..addFlag('t',
          negatable: false, help: 'Sent Apk to telegram group automatically.')
      ..addFlag('DEV', negatable: false, help: 'Enable DEV mode')
      ..addFlag('LIVE', negatable: false, help: 'Enable LIVE mode')
      ..addFlag('STAGE', negatable: false, help: 'Enable STAGE mode')
      ..addFlag('LOCAL', negatable: false, help: 'Enable LOCAL mode');
    argParser.addCommand('help').addFlag('all',
        negatable: false, help: 'Show all available commands and options');
  }

  ICommand? _handleCreateCommand(List<String> arguments) {
    final projectName = arguments[1];
    final isWelcome = welcomeBoard();
    if (isWelcome) {
      final String? patternCheck = formatBoard();
      if (patternCheck != null) {
        return CreateCommand(
          projectName: projectName,
          patternNumber: patternCheck,
        );
      }
    } else {
      exit(0);
    }
    return null;
  }

  ICommand? _handleModuleCommand(List<String> arguments) {
    return CreateCommand(
      moduleName: arguments.last,
    );
  }

  void _handleSetupCommand() {
    final appBuildGradleEdit = SetupFlavor();
    appBuildGradleEdit.appBuildGradleEditFunc();
    appBuildGradleEdit.createConfigFile();
    appBuildGradleEdit.mainEdit();
  }

  ICommand? _handleBuildCommand(List<String> arguments) {
    return BuildFlavorCommand(arguments: arguments);
  }

  void _handleSentCommand() {
    sentApkTelegramFunc();
  }

  ICommand? _handleGenerateCommand(List<String> arguments) {
    final assetName = arguments[1];
    if (assetName == "k_assets.dart") {
      return AssetGenerationCommand();
    } else {
      "Wrong Command, please use command".printWithColor(
        status: PrintType.warning,
      );
      "ssl_cli generate k_assets.dart".printWithColor(
        status: PrintType.success,
      );
      exit(0);
    }
  }

  void _errorAndExit([String? command]) {
    stderr.writeln('Command not available!');
    stderr.writeln('try ssl_cli help --all to check all available commands.');
    exit(2);
  }
}

bool welcomeBoard() {
  String content = '''
+---------------------------------------------------+
|           Welcome to the SSL CLI!                 |
+---------------------------------------------------+
|        Do you want to continue? [y/n]             |
+---------------------------------------------------+\n''';

  stderr.write(content);

  final answer = stdin.readLineSync();
  final validator =
      answer?.toLowerCase() == 'y' || answer?.toLowerCase() == 'yes';

  return answer != null && validator;
}

String? formatBoard() {
  String content = '''
     Please Enter Your Pattern 
     1 for Mvc 
     2 for Repository     
\n''';

  stderr.write(content);

  final answer = stdin.readLineSync();

  return answer;
}
