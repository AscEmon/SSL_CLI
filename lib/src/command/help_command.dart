import 'dart:io';

import 'i_command.dart';

class HelpCommand implements ICommand {
  @override
  void execute() {
    stdout.writeln('Usage: ssl_cli <command>\n');

    stdout.writeln('Available commands:');
    stdout.writeln(
      'Create folder and file structure for Fluter Apps',
    );

    exit(0);
  }
}
