import 'dart:io';
import 'package:args/args.dart';
import 'package:ssl_cli/src/command/config_command.dart';
import 'package:ssl_cli/src/command/build_flavor_command.dart';
import 'package:ssl_cli/utils/setup_flavor.dart';
import 'package:ssl_cli/utils/extension.dart';
import '../utils/doc_generation.dart';
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
        switch (res.command!.name) {
          case 'create':
            command = _handleCreateCommand(arguments);
            break;
          case 'module':
            command = _handleModuleCommand(arguments);
            break;
          case 'setup':
            if (res.command!.arguments.first == "--flavor") {
              _handleSetupCommand();
            }
            break;
          case 'build':
          case 'clean':
          case 'pub':
          case 'run':
            command = _handleBuildCommand(res.arguments);
            break;
          case 'generate':
            command = _handleGenerateCommand(arguments);
            break;
          case 'sent':
            if (res.command!.arguments.first == "--apk") {
              _handleSentCommand();
            }
            break;
          case 'override':
            if (res.command!.arguments.isNotEmpty && res.command!.arguments.first == "--config.json") {
              command = _handleOverrideCommand();
            }
            break;
          case 'help':
            command = HelpCommand();
            break;
          default:
            _errorAndExit(res.command!.name);
            break;
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
      ..addCommand('override')
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
    final String? modulePattern = formatModuleBoard();
    if (modulePattern != null) {
      return CreateCommand(
        moduleName: arguments.last,
        modulePattern: modulePattern,
      );
    }
    return null;
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
    } else if (assetName.isValidFilePath()) {
      DocGenerator docGen = DocGenerator();
      docGen.generateDocs(arguments[1]);
    } else {
      "Wrong Command, please use ssl_cli help --all".printWithColor(
        status: PrintType.warning,
      );
      exit(0);
    }
    return null;
  }

  void _errorAndExit([String? command]) {
    stderr.writeln('Command not available!');
    stderr.writeln('try ssl_cli help --all to check all available commands.');
    exit(2);
  }

  ICommand _handleOverrideCommand() {
    return ConfigCommand(isOverride: true);
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
     3 for Bloc Pattern     
\n''';

  stderr.write(content);

  final answer = stdin.readLineSync();

  return answer;
}

String? formatModuleBoard() {
  String content = '''
     Please select module pattern
     1 for Bloc pattern 
     2 for Others
\n''';

  stderr.write(content);

  final answer = stdin.readLineSync();

  return answer;
}
