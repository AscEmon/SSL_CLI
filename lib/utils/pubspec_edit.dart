import 'dart:io';

import 'package:ssl_cli/utils/extension.dart';

import 'enum.dart';

class PubspecEdit {
  void pubspecEditConfig(
    String filePath, {
    String? patternNumber,
    String? stateManagement,
  }) {
    try {
      // Read the content of the file
      final file = File(filePath);
      List<String> lines = file.readAsLinesSync();

      // Remove lines containing '#'
      lines = lines.where((line) => !line.contains('#')).toList();
      int indexOfDescriptionFlutter = lines.indexOf(
        'description: A new Flutter project.',
      );
      lines.insert(indexOfDescriptionFlutter + 1, 'publish_to: "none"');

      int indexOfSdkFlutter = lines.indexOf('dependencies:');
      lines.insert(
        indexOfSdkFlutter + 1,
        '  flutter_localizations:\n    sdk: flutter',
      );

      // Find the index of 'cupertino_icons: ^1.0.2'
      // Find the index of the line containing 'cupertino_icons'
      int indexOfCupertinoIcons = lines.indexWhere(
        (line) => line.contains('cupertino_icons'),
      );

      if (indexOfCupertinoIcons != -1) {
        // Add lines for dio and shared_preferences after 'cupertino_icons: ^1.0.2'
        lines.insert(indexOfCupertinoIcons + 1, '  dio: ^5.9.0');
        lines.insert(indexOfCupertinoIcons + 2, '  shared_preferences: ^2.5.3');
        lines.insert(indexOfCupertinoIcons + 3, '  intl: ^0.20.2');
        lines.insert(indexOfCupertinoIcons + 4, '  connectivity_plus: ^7.0.0');
        lines.insert(indexOfCupertinoIcons + 5, '  flutter_screenutil: ^5.9.3');
        lines.insert(indexOfCupertinoIcons + 6, '  package_info_plus: ^9.0.0');
        lines.insert(indexOfCupertinoIcons + 7, '  flutter_svg: ^2.2.1');
        lines.insert(indexOfCupertinoIcons + 8, '  google_fonts: ^6.2.1');
        if (patternNumber != null && patternNumber == "3") {
          // for bloc pattern
          lines.insert(indexOfCupertinoIcons + 9, '  flutter_bloc: ^8.1.6');
        }
        if (patternNumber != null && patternNumber == "4") {
          // for clean architecture pattern
          int currentIndex = indexOfCupertinoIcons + 9;
          lines.insert(currentIndex++, '  equatable: ^2.0.7');
          lines.insert(currentIndex++, '  dartz: ^0.10.1');
          lines.insert(currentIndex++, '  get_it: ^8.2.0');

          // Add state management specific packages
          if (stateManagement == "1") {
            // Riverpod
            lines.insert(currentIndex++, '  flutter_riverpod: ^3.0.1');
            lines.insert(currentIndex++, '  riverpod_annotation: ^3.0.1');
          } else if (stateManagement == "2") {
            // Bloc
            lines.insert(currentIndex++, '  flutter_bloc: ^8.1.6');
          }
        }

        // Add dev_dependencies for Riverpod if selected
        if (patternNumber == "4" && stateManagement == "1") {
          int devDepsIndex = lines.indexOf('dev_dependencies:');
          if (devDepsIndex != -1) {
            // Find the last dev dependency
            int lastDevDepIndex = devDepsIndex + 1;
            while (lastDevDepIndex < lines.length &&
                lines[lastDevDepIndex].startsWith('  ')) {
              lastDevDepIndex++;
            }
            // Insert Riverpod dev dependencies
            lines.insert(lastDevDepIndex, '  build_runner: ^2.4.8');
            lines.insert(lastDevDepIndex + 1, '  riverpod_generator: ^3.0.1');
            lines.insert(lastDevDepIndex + 2, '  custom_lint: ^0.8.0');
            lines.insert(lastDevDepIndex + 3, '  riverpod_lint: ^3.0.1');
          }
        }

        int indexOfUsesMaterialDesign = lines.indexOf(
          '  uses-material-design: true',
        );
        lines.insert(indexOfUsesMaterialDesign + 1, '  generate: true');
        lines.insert(
          indexOfUsesMaterialDesign + 2,
          '  assets:\n    - assets/images/\n    - assets/svg/\n    - assets/svg/light/\n    - assets/svg/dark/\n    - assets/images/light/\n    - assets/images/dark/ ',
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
        'Packages added successfully.'.printWithColor(
          status: PrintType.success,
        );
      } else {
        'Something went wrong'.printWithColor(status: PrintType.warning);
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
