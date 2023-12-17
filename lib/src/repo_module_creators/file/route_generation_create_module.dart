import 'dart:io';

import 'package:ssl_cli/utils/enum.dart';
import 'package:ssl_cli/utils/extension.dart';

class RouteGenerationCreateModule {
  void moduleToRouteCreate(String filePath, String moduleName) {
    try {
      // Create a File object representing the file
      File file = File(filePath);

      // Check if the file exists
      if (!file.existsSync()) {
        'File not found: $filePath'.printWithColor(status: PrintType.error);
        return;
      }

      // Read the content of the file as a string
      String existingContent = file.readAsStringSync();

      // Check if the new module already exists
      if (existingContent.contains(moduleName)) {
        '$moduleName module already exists in the file.'
            .printWithColor(status: PrintType.error);
        return;
      }

      // Add the new module to the enum and extension
      String updatedContent = updateFileContent(existingContent, moduleName);

      // Write the updated content back to the file
      file.writeAsStringSync(updatedContent);

      'File updated successfully.'.printWithColor(status: PrintType.success);
    } catch (e) {
      'Error reading or modifying file: $e'
          .printWithColor(status: PrintType.error);
    }
  }

  String updateFileContent(String existingContent, String moduleName) {
    String newRouteEnum = '  $moduleName,';
    String newImportFile =
        "import '../modules/$moduleName/views/${moduleName}_screen.dart';\n";

    String newAppRoutesAdded = '''
      case AppRoutes.$moduleName:
        return const ${moduleName.convertToCamelCase()}Screen();''';

    // Find the position to replace the existing enum and extension content
    int enumStartIndex =
        existingContent.indexOf('enum AppRoutes {') + 'enum AppRoutes {'.length;

    int enumEndIndex = existingContent.indexOf(',', enumStartIndex) + 1;

    int extensionStartIndex =
        existingContent.indexOf('''extension AppRoutesExtention on AppRoutes {
  Widget buildWidget<T extends Object>({T? arguments}) {
    switch (this) {''') +
            '''extension AppRoutesExtention on AppRoutes {
  Widget buildWidget<T extends Object>({T? arguments}) {
    switch (this) {'''
                .length;
    int extensionEndIndex =
        existingContent.indexOf('', extensionStartIndex) + 1;

    // Extract existing enum and extension content
    String existingEnumContent =
        existingContent.substring(enumStartIndex, enumEndIndex);

    String existingExtensionContent =
        existingContent.substring(extensionStartIndex, extensionEndIndex);

    // Insert the new module into the existing enum and extension content
    String updatedEnum =
        existingEnumContent + '\n${newRouteEnum.toCamelCase()}';
    String updatedExtension =
        existingExtensionContent + '${newAppRoutesAdded.toCamelCase()}\n';

    // Replace the existing enum and extension content in the original file content
    String updatedContent =
        existingContent.replaceRange(enumStartIndex, enumEndIndex, updatedEnum);

    updatedContent = updatedContent.replaceRange(
      extensionStartIndex + newRouteEnum.length + 1,
      extensionEndIndex + newRouteEnum.length + 1,
      updatedExtension,
    );
    updatedContent = updatedContent.replaceRange(0, 0, newImportFile);

    return updatedContent;
  }
}

extension ClassToCamelCase on String {
  String toCamelCase() {
    List<String> words = split('_');
    String camelCase = '';

    for (String word in words) {
      camelCase += word[0].toUpperCase() + word.substring(1);
    }

    return camelCase;
  }
}
