import 'dart:io';
import 'package:args/args.dart';
import 'package:ssl_cli/utils/extension.dart';
import '../utils/enum.dart';
import 'command/asset_generation_command.dart';
import 'command/create_command.dart';
import 'command/help_command.dart';
import 'command/i_command.dart';

class SSLCommandRunner {
  void run(List<String> arguments) {
    final argParser = ArgParser();

    argParser.addCommand('create');
    argParser.addCommand('module');
    argParser.addCommand('generate');
    argParser.addCommand('help');

    final res = argParser.parse(arguments);

    try {
      if (res.command != null && res.command!.name != null) {
        ICommand? command;
        if (res.command!.name!.startsWith('create')) {
          final projectName = arguments[1];
          final isWelcome = welcomeBoard();
          if (isWelcome) {
            final String? patternCheck = formatBoard();
            if (patternCheck != null) {
              command = CreateCommand(
                projectName: projectName,
                patternNumber: patternCheck,
              );
            }
          } else {
            exit(0);
          }
        } else if (res.command!.name!.contains('module')) {
          command = CreateCommand(
            moduleName: arguments.last,
          );
        } else if (res.command!.name!.startsWith('generate')) {
          final assetName = arguments[1];
          if (assetName == "k_assets.dart") {
            command = AssetGenerationCommand();
          } else {
            "Wrong Command, please use command".printWithColor(
              status: PrintType.warning,
            );
            "ssl_cli generate k_assets.dart".printWithColor(
              status: PrintType.success,
            );
            exit(0);
          }
        } else if (res.command!.name!.startsWith('help')) {
          command = HelpCommand();
        } else {
          _errorAndExit(res.command!.name);
        }

        command!.execute();
      } else {
        _errorAndExit();
      }
    } catch (e) {
      _errorAndExit();
    }
  }
}

bool welcomeBoard() {
  String content = '''
+---------------------------------------------------+
|           Welcome to the SSL CLI!               |
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

void _errorAndExit([String? command]) {
  stderr.writeln('Command not available!');
  stderr.writeln('try SSL_cli help for commands.');
  exit(2);
}
