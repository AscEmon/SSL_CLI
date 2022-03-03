import 'dart:io';

import 'i_command.dart';

class HelpCommand implements ICommand {
  @override
  void execute() {
    stdout.writeln('Usage: ssl_cli <command> <project_name>\n');

    stdout.writeln('Available commands:');
    stdout.writeln(
      'Create folder and file structure for Flutter Apps',
    );

    exit(0);
  }
}
