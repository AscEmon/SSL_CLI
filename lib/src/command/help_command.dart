import 'dart:io';

import 'i_command.dart';

class HelpCommand implements ICommand {
  @override
  void execute() {
    printFormattedHelp(
      'create : ssl_cli create <project_name>',
      'Create folder and file structure with predefined code, packages, flavor setup automatically for Flutter apps.',
    );
    printFormattedHelp(
      'module : ssl_cli module <module_name>',
      'Create a module with predefined code based on the repository pattern.',
    );
    printFormattedHelp(
      'generate : ssl_cli generate k_assets.dart',
      'Generate image and SVG path in utils/k_assets.dart file automatically based on your assets folder.',
    );
    printFormattedHelp(
      'generate : ssl_cli generate k_assets.dart --t',
      'Generate theme-based image and SVG paths with dark/light folder support. Use this when your assets are organized in dark/light subfolders.',
    );
    printFormattedHelp(
      'generate : ssl_cli generate <folder/file path>',
      'Generate AI-powered documentation for your project. You can generate documentation for the entire project or a single Dart file.',
    );

    printFormattedHelp(
      'build : ssl_cli build apk (e.g.--DEV, --LIVE)',
      'Build Android APK with modified name_flavor_version name_version code in your outputs APK folder.Available command in flavor type --DEV, --LIVE, --LOCAL, --STAGE.If you want to sent your apk file telegram group with build command then add --t param(eg: ssl_cli build apk --LIVE --t). It will sent you apk automatically with your group but before make sure you added telegram chat id and botToken in config.json file.',
    );
    printFormattedHelp(
      'clean : ssl_cli clean',
      'Clean your project, similar to the flutter clean command.',
    );
    printFormattedHelp(
      'pub get : ssl_cli pub get',
      'Run pub get to build your project and fetch packages, similar to the flutter pub get command.',
    );
    printFormattedHelp(
      'run : ssl_cli run (e.g.--DEV, --LIVE)',
      'Run your project with the specified flavor command. Remember, it will run in release mode.Available command in flavor type --DEV, --LIVE, --LOCAL, --STAGE.',
    );
    printFormattedHelp(
      'setup : ssl_cli setup --flavor',
      'Set up flavor for Android using this command in your existing project. It is not mandatory to create your project using ssl_cli. Remember, this setup does not require any third-party packages.',
    );
    printFormattedHelp(
      'sent : ssl_cli sent --apk',
      'Sent your apk to telegram group after create your build.Remeber check your config.json file and set your group chat_id and botToken.',
    );
    printFormattedHelp(
      'generate : ssl_cli generate <file path or folder path>',
      'Generate AI-powered documentation for your project. You can generate documentation for the entire project or a single Dart file.',
    );
    printFormattedHelp(
      'config : ssl_cli override --config.json',
      'Override config.json file for your project.',
    );
    printFormattedHelp(
      'build_runner : ssl_cli generate build_runner',
      'One-time generation',
    );
    printFormattedHelp(
      'build_runner_watch : ssl_cli generate build_runner_watch',
      'Watch mode - auto-regenerate on file changes.',
    );
    exit(0);
  }

  void printFormattedHelp(String command, String hint) {
    // Set the width for both command and hint columns
    const columnWidth = 50;
    const leftSpace = 4; // Adjust the number of spaces for left space

    // Pad the command to the specified width with left space
    final paddedCommand =
        ' ' * leftSpace + command.padRight(columnWidth - leftSpace);

    // Split the hint into multiple lines with consistent indentation
    final hintLines = _splitHintLines(hint, columnWidth);

    // Print the formatted output
    print('$paddedCommand ${hintLines.join('\n'.padRight(columnWidth + 2))}');
  }

  List<String> _splitHintLines(String hint, int columnWidth) {
    final lines = <String>[];
    final words = hint.split(' ');

    String currentLine = '';
    for (final word in words) {
      if ((currentLine.length + word.length) > columnWidth) {
        lines.add(currentLine);
        currentLine = '';
      }
      currentLine += '$word ';
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine.trim());
    }

    return lines;
  }
}
