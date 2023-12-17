import 'dart:io';

import 'package:ssl_cli/utils/extension.dart';

import 'enum.dart';

class PubspecEdit {
  void pubspecEditConfig(String filePath) {
    try {
      // Read the content of the file
      final file = File(filePath);
      List<String> lines = file.readAsLinesSync();

      // Remove lines containing '#'
      lines = lines.where((line) => !line.contains('#')).toList();
      int indexOfDescriptionFlutter =
          lines.indexOf('description: A new Flutter project.');
      lines.insert(indexOfDescriptionFlutter + 1, 'publish_to: "none"');

      int indexOfSdkFlutter = lines.indexOf('dependencies:');
      lines.insert(
          indexOfSdkFlutter + 1, '  flutter_localizations:\n    sdk: flutter');

      // Find the index of 'cupertino_icons: ^1.0.2'
      int indexOfCupertinoIcons = lines.indexOf('  cupertino_icons: ^1.0.2');

      if (indexOfCupertinoIcons != -1) {
        // Add lines for dio and shared_preferences after 'cupertino_icons: ^1.0.2'
        lines.insert(indexOfCupertinoIcons + 1, '  dio: ^5.0.1');
        lines.insert(
            indexOfCupertinoIcons + 2, '  shared_preferences: ^2.0.18');
        lines.insert(indexOfCupertinoIcons + 3, '  intl: ^0.18.0');
        lines.insert(indexOfCupertinoIcons + 4, '  connectivity_plus: ^3.0.3');
        lines.insert(indexOfCupertinoIcons + 5, '  flutter_screenutil: ^5.6.1');
        lines.insert(indexOfCupertinoIcons + 6, '  package_info_plus: ^3.0.3');
        lines.insert(indexOfCupertinoIcons + 7, '  flutter_svg: ^2.0.2');
        lines.insert(indexOfCupertinoIcons + 8, '  google_fonts: ^4.0.3');

        int indexOfUsesMaterialDesign =
            lines.indexOf('  uses-material-design: true');
        lines.insert(indexOfUsesMaterialDesign + 1, '  generate: true');
        lines.insert(
          indexOfUsesMaterialDesign + 2,
          '  assets:\n    - assets/images/\n    - assets/svg/',
        );
        lines.insert(indexOfUsesMaterialDesign + 3, '''\n
  # fonts:
  #   - family: Hero New
  #     fonts:
  #       - asset: assets/fonts/Hero_New_Bold.otf
  #       - asset: assets/fonts/Hero_New_Medium.otf
  #       - asset: assets/fonts/Hero_New_Regular.otf
  #       - asset: assets/fonts/Hero_New_SemiBold.otf
  #       - asset: assets/fonts/Hero_New_Light.otf
 ''');

        // Write the modified content back to the file
        file.writeAsStringSync(lines.join('\n'));

        // Run 'flutter pub get' to fetch and add the specified versions of the packages
        Process.runSync('flutter', ['pub', 'get']);
        'Packages added successfully.'
            .printWithColor(status: PrintType.success);
      } else {
        'Something went wrong'.printWithColor(status: PrintType.warning);
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
