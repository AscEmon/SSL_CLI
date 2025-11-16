import 'dart:io';
import 'package:ssl_cli/utils/extension.dart';
import '../../../utils/enum.dart';
import '../asset_path_i_creators.dart';
import 'package:path/path.dart' as path;

class AssetPathThemedFileCreator implements AssetPathIFileCreator {
  final AssetPathIDirectoryCreator directoryCreator;
  final String moduleName;

  AssetPathThemedFileCreator(
    this.directoryCreator,
    this.moduleName,
  );

  @override
  Future<void> createNecessaryFiles() async {
    'creating theme-based necessary files...'.printWithColor();

    final subDirectories = directoryCreator.assetsDir
        .listSync(recursive: false, followLinks: false);
    if (subDirectories.isNotEmpty) {
      final enumNames = <String>[];
      final assetNames = <String>[];
      final extensionNames = <String>[];
      final subfolderPaths = <String, String>{};
      final hasThemeFolder = <String, bool>{};
      final darkOnlyPaths = <String, String>{}; // Track files only in dark folder

      final pathCode = StringBuffer('enum KAssetName {\n');

      for (final subDirectory in subDirectories) {
        if (subDirectory is Directory) {
          final directoryName = path.basename(subDirectory.path);
          if (!(directoryName.toLowerCase() == "fonts" ||
              directoryName.toLowerCase() == "font")) {
            // Check if this directory has dark/light subfolders
            final hasThemed = _hasThemeFolders(subDirectory);

            if (hasThemed) {
              // Process themed assets (dark/light folders)
              await _processThemedAssets(
                subDirectory,
                directoryName,
                enumNames,
                assetNames,
                extensionNames,
                pathCode,
                subfolderPaths,
                hasThemeFolder,
                darkOnlyPaths,
              );
              // Also process common assets in parent folder
              await _processCommonAssetsInParent(
                subDirectory,
                directoryName,
                enumNames,
                assetNames,
                extensionNames,
                pathCode,
                subfolderPaths,
                hasThemeFolder,
              );
            } else {
              // Process common assets (no theme folders)
              await _processCommonAssets(
                subDirectory,
                directoryName,
                enumNames,
                assetNames,
                extensionNames,
                pathCode,
                subfolderPaths,
                hasThemeFolder,
              );
            }
          }
        }
      }

      // if no asset found on any sub directories
      if (pathCode.toString() == "enum KAssetName {\n") {
        await _createFile(
          directoryCreator.stylesSubDir.path,
          'k_assets',
          content: "",
        );
        'No Assets found on any Sub directories'.printWithColor(
          status: PrintType.warning,
        );
      } else {
        // Insert import at the beginning
        final finalCode = StringBuffer();
        finalCode.write("import '../../theme/theme_manager.dart';\n\n");
        finalCode.write(pathCode.toString());
        finalCode.write('}\n\n');
        finalCode.write('extension AssetsExtension on KAssetName {\n');
        pathCode.clear();
        pathCode.write(finalCode.toString());
        pathCode.write('  String get root => \'assets\';\n');

        // Generate root getters for each subfolder
        for (final subfolderPath in subfolderPaths.values.toSet()) {
          final varName = subfolderPath.toLowerCase();
          pathCode.write(
              '  String get ${varName}Root => \'\$root/$subfolderPath\';\n');
        }

        pathCode.write('  String get imagePath {\n');
        pathCode.write('    switch (this) {\n');

        for (int i = 0; i < enumNames.length; i++) {
          pathCode.write('      case KAssetName.${enumNames[i]}:\n');
          final subfolderPath = subfolderPaths[enumNames[i]];
          final isThemed = hasThemeFolder[enumNames[i]] ?? false;

          if (isThemed) {
            // Use themed helper
            final ext = extensionNames[i];
            if (ext == 'svg') {
              pathCode.write(
                  '        return _themedSvg("${assetNames[i]}.${extensionNames[i]}");\n');
            } else {
              pathCode.write(
                  '        return _themedPng("${assetNames[i]}.${extensionNames[i]}");\n');
            }
          } else {
            // Direct path for common assets (not in dark/light folders)
            pathCode.write(
                '        return "\$${subfolderPath?.toLowerCase()}Root/${assetNames[i]}.${extensionNames[i]}";\n');
          }
        }

        pathCode.write('    }\n');
        pathCode.write('  }\n\n');

        // Add themed helper methods
        pathCode.write('  String _themedSvg(String fileName) {\n');
        pathCode.write('    final isDark = ThemeManager().isDarkMode;\n');
        pathCode.write('    final folder = isDark ? \'dark\' : \'light\';\n');
        pathCode.write('    return \'\$svgRoot/\$folder/\$fileName\';\n');
        pathCode.write('  }\n\n');

        pathCode.write('  String _themedPng(String fileName) {\n');
        pathCode.write('    final isDark = ThemeManager().isDarkMode;\n');
        pathCode.write('    final folder = isDark ? \'dark\' : \'light\';\n');
        pathCode.write('    return \'\$imagesRoot/\$folder/\$fileName\';\n');
        pathCode.write('  }\n');

        pathCode.write('}\n');

        await _createFile(
          directoryCreator.stylesSubDir.path,
          'k_assets',
          content: pathCode.toString(),
        );
        "Successfully generated theme-based image paths.".printWithColor(
          status: PrintType.success,
        );
      }
    } else {
      await _createFile(
        directoryCreator.stylesSubDir.path,
        'k_assets',
        content: "",
      );
      "No sub-Directories found inside assets".printWithColor(
        status: PrintType.warning,
      );
    }
  }

  bool _hasThemeFolders(Directory directory) {
    final subDirs = directory
        .listSync(recursive: false, followLinks: false)
        .whereType<Directory>();
    final dirNames =
        subDirs.map((d) => path.basename(d.path).toLowerCase()).toSet();
    return dirNames.contains('dark') && dirNames.contains('light');
  }

  Future<void> _processThemedAssets(
    Directory subDirectory,
    String directoryName,
    List<String> enumNames,
    List<String> assetNames,
    List<String> extensionNames,
    StringBuffer pathCode,
    Map<String, String> subfolderPaths,
    Map<String, bool> hasThemeFolder,
    Map<String, String> darkOnlyPaths,
  ) async {
    final lightDir = Directory('${subDirectory.path}/light');
    final darkDir = Directory('${subDirectory.path}/dark');
    final processedFiles = <String>{};
    
    // Process light folder files
    if (await lightDir.exists()) {
      final files = lightDir.listSync(recursive: false, followLinks: false);
      for (final file in files) {
        if (file is File) {
          final fileName = path.basename(file.path);
          if (fileName.trim().isNotEmpty) {
            processedFiles.add(fileName);
            
            List<String> parts = fileName.split('.');
            String tempAssetName = "";
            String tempExtensionName = "";
            if (parts.length == 2) {
              tempAssetName = parts[0];
              tempExtensionName = parts[1];
            }

            String assetName = "";
            List<String> fileNameSplitList =
                fileName.split(RegExp(r'[-_.]'));
            for (int i = 0; i < fileNameSplitList.length; i++) {
              assetName =
                  "$assetName${i == 0 ? fileNameSplitList[i] : fileNameSplitList[i].convertToCamelCase()}";
            }

            if (!enumNames.contains(assetName)) {
              enumNames.add(assetName);
              assetNames.add(tempAssetName);
              extensionNames.add(tempExtensionName);
              pathCode.write('  $assetName,\n');
              subfolderPaths[assetName] = directoryName;
              // Mark as themed since it's in dark/light folder
              hasThemeFolder[assetName] = true;
            }
          }
        }
      }
    }
    
    // Process dark folder files that don't exist in light
    if (await darkDir.exists()) {
      final files = darkDir.listSync(recursive: false, followLinks: false);
      for (final file in files) {
        if (file is File) {
          final fileName = path.basename(file.path);
          if (fileName.trim().isNotEmpty && !processedFiles.contains(fileName)) {
            List<String> parts = fileName.split('.');
            String tempAssetName = "";
            String tempExtensionName = "";
            if (parts.length == 2) {
              tempAssetName = parts[0];
              tempExtensionName = parts[1];
            }

            String assetName = "";
            List<String> fileNameSplitList =
                fileName.split(RegExp(r'[-_.]'));
            for (int i = 0; i < fileNameSplitList.length; i++) {
              assetName =
                  "$assetName${i == 0 ? fileNameSplitList[i] : fileNameSplitList[i].convertToCamelCase()}";
            }

            if (!enumNames.contains(assetName)) {
              enumNames.add(assetName);
              assetNames.add(tempAssetName);
              extensionNames.add(tempExtensionName);
              pathCode.write('  $assetName,\n');
              subfolderPaths[assetName] = directoryName;
              // Mark as themed since it's in dark/light folder
              hasThemeFolder[assetName] = true;
            }
          }
        }
      }
    }
  }

  Future<void> _processCommonAssetsInParent(
    Directory subDirectory,
    String directoryName,
    List<String> enumNames,
    List<String> assetNames,
    List<String> extensionNames,
    StringBuffer pathCode,
    Map<String, String> subfolderPaths,
    Map<String, bool> hasThemeFolder,
  ) async {
    // Process files directly in parent folder (not in dark/light subfolders)
    final items = subDirectory.listSync(recursive: false, followLinks: false);
    for (final item in items) {
      if (item is File) {
        final fileName = path.basename(item.path);
        if (fileName.trim().isNotEmpty) {
          List<String> parts = fileName.split('.');
          String tempAssetName = "";
          String tempExtensionName = "";
          if (parts.length == 2) {
            tempAssetName = parts[0];
            tempExtensionName = parts[1];
          }

          String assetName = "";
          List<String> fileNameSplitList =
              fileName.split(RegExp(r'[-_.]'));
          for (int i = 0; i < fileNameSplitList.length; i++) {
            assetName =
                "$assetName${i == 0 ? fileNameSplitList[i] : fileNameSplitList[i].convertToCamelCase()}";
          }

          if (!enumNames.contains(assetName)) {
            enumNames.add(assetName);
            assetNames.add(tempAssetName);
            extensionNames.add(tempExtensionName);
            pathCode.write('  $assetName,\n');
            subfolderPaths[assetName] = directoryName;
            hasThemeFolder[assetName] = false; // Common asset
          }
        }
      }
    }
  }

  Future<void> _processCommonAssets(
    Directory subDirectory,
    String directoryName,
    List<String> enumNames,
    List<String> assetNames,
    List<String> extensionNames,
    StringBuffer pathCode,
    Map<String, String> subfolderPaths,
    Map<String, bool> hasThemeFolder,
  ) async {
    final files = subDirectory.listSync(recursive: false, followLinks: false);
    for (final file in files) {
      if (file is File) {
        final fileName = path.basename(file.path);
        if (fileName.trim().isNotEmpty) {
          List<String> parts = fileName.split('.');
          String tempAssetName = "";
          String tempExtensionName = "";
          if (parts.length == 2) {
            tempAssetName = parts[0];
            tempExtensionName = parts[1];
          }

          String assetName = "";
          List<String> fileNameSplitList =
              fileName.split(RegExp(r'[-_.]')); // Split by '-' or '_'
          for (int i = 0; i < fileNameSplitList.length; i++) {
            assetName =
                "$assetName${i == 0 ? fileNameSplitList[i] : fileNameSplitList[i].convertToCamelCase()}";
          }

          if (!enumNames.contains(assetName)) {
            enumNames.add(assetName);
            assetNames.add(tempAssetName);
            extensionNames.add(tempExtensionName);
            pathCode.write('  $assetName,\n');
            subfolderPaths[assetName] = directoryName;
            hasThemeFolder[assetName] = false;
          } else {
            'Naming with $fileName exists in multiple folders'
                .printWithColor(status: PrintType.warning);
          }
        }
      }
    }
  }

  Future<void> _createFile(
    String basePath,
    String fileName, {
    String? content,
    String? fileExtention = 'dart',
  }) async {
    String fileType;
    if (fileExtention == 'yaml') {
      fileType = 'yaml';
    } else if (fileExtention == 'arb') {
      fileType = 'arb';
    } else {
      fileType = 'dart';
    }
    try {
      late File file;

      if (await File('$basePath/$fileName.$fileType').exists()) {
        // Perform actions if the file exists
        file = File('$basePath/$fileName.$fileType');
      } else {
        // Perform actions if the file not exists
        file = await File('$basePath/$fileName.$fileType').create();
        "Successfully created $fileName.$fileType".printWithColor(
          status: PrintType.success,
        );
      }

      if (content != null) {
        final writer = file.openWrite();
        writer.write(content);
        writer.close();
      }
    } catch (e) {
      e.toString().printWithColor(
            status: PrintType.error,
          );
      stderr.write('creating $fileName.$fileType failed!');
      exit(2);
    }
  }
}
