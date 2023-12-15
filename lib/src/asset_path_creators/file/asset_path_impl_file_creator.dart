import 'dart:io';
import 'package:ssl_cli/utils/extension.dart';
import '../../../utils/enum.dart';
import '../asset_path_i_creators.dart';
import 'package:path/path.dart' as path;

class AssetPathImplFileCreator implements AssetPathIFileCreator {
  final AssetPathIDirectoryCreator directoryCreator;
  final String moduleName;

  AssetPathImplFileCreator(
    this.directoryCreator,
    this.moduleName,
  );

  @override
  Future<void> createNecessaryFiles() async {
    'creating necessary files...'.printWithColor();

    final subDirectories = directoryCreator.assetsDir
        .listSync(recursive: false, followLinks: false);
    if (subDirectories.isNotEmpty) {
      final enumNames = <String>[];
      final assetNames = <String>[];
      final extensionNames = <String>[];
      String tempAssetName = "", tempExtensionName = "";
      final pathCode = StringBuffer('enum KAssetName {\n');
      final subfolderPaths = <String, String>{};
      for (final subDirectory in subDirectories) {
        if (subDirectory is Directory) {
          final directoryName = path.basename(subDirectory.path);
          if (!(directoryName.toLowerCase() == "fonts" ||
              directoryName.toLowerCase() == "font")) {
            final files =
                subDirectory.listSync(recursive: false, followLinks: false);
            if (files.isNotEmpty) {
              for (final file in files) {
                if (file is File) {
                  final fileName = path.basename(file.path);
                  // print(fileName);
                  if (fileName.trim().isNotEmpty) {
                    List<String> parts = fileName.split('.');
                    if (parts.length == 2) {
                      tempAssetName = parts[0];
                      tempExtensionName = parts[1];
                    }
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
                  } else {
                    'Naming with $fileName exists in multiple folders as follows:'
                        .printWithColor(status: PrintType.warning);
                    subDirectories
                        .where((subDir) =>
                            subDir is Directory &&
                            // subDir.path != subDirectory.path &&
                            subDir.listSync().any((subFile) =>
                                subFile is File &&
                                path.basename(subFile.path) == fileName))
                        .map((subDir) =>
                            'assets' + subDir.path.split('assets').last)
                        .join(' & ')
                        .printWithColor(status: PrintType.warning);
                    // 'We generate paths for $fileName using folder from ${subDirectory.path},'
                    //     .printWithColor(status: PrintType.success);
                    'To prevent duplication in assets, kindly remove one file named $fileName'
                        .printWithColor(status: PrintType.warning);
                  }
                }
              }
            } else {
              "No assets found inside $directoryName directory".printWithColor(
                status: PrintType.warning,
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
        pathCode.write('}\n\n');
        pathCode.write('extension AssetsExtension on KAssetName {\n');
        pathCode.write('  String get imagePath {\n');
        pathCode.write('    const String _rootPath = \'assets\';\n');
        for (final subfolderPath in subfolderPaths.values.toSet()) {
          pathCode.write(
              '  const String _${subfolderPath}Dir = \'\$_rootPath/$subfolderPath\';\n');
        }
        pathCode.write('    switch (this) {\n');
        for (int i = 0; i < enumNames.length; i++) {
          pathCode.write('      case KAssetName.${enumNames[i]}:\n');
          final subfolderPath = subfolderPaths[enumNames[i]];
          pathCode.write(
              '        return \'\$_${subfolderPath?.toLowerCase()}Dir/${assetNames[i]}.${extensionNames[i]}\';\n');
        }
        pathCode.write('    }\n');
        if (enumNames.isEmpty) {
          pathCode.write('    return \'\';\n');
        }
        pathCode.write('  }\n');
        pathCode.write('}\n');

        await _createFile(
          directoryCreator.stylesSubDir.path,
          'k_assets',
          content: pathCode.toString(),
        );
        "Successfully generated image paths.".printWithColor(
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
