import 'dart:io';
import 'package:args/args.dart';
import 'command/create_command.dart';
import 'command/help_command.dart';
import 'command/i_command.dart';

class SSLCommandRunner {
  void run(List<String> arguments) {
    final argParser = ArgParser();

    argParser.addCommand('create');
    argParser.addCommand('help');

    final res = argParser.parse(arguments);

    try {
      if (res.command != null && res.command!.name != null) {
        ICommand? command;
        if (res.command!.name!.startsWith('create')) {
          final projectName = arguments[1];
          final isWelcome = welcomeBoard();
          if (isWelcome) {
            command = CreateCommand(projectName: projectName);
          } else {
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

void _errorAndExit([String? command]) {
  stderr.writeln('Command not available!');
  stderr.writeln('try SSL_cli help for commands.');
  exit(2);
}
