import 'dart:io';
import 'package:ssl_cli/utils/extension.dart';
import '../../../utils/enum.dart';
import '../asset_path_i_creators.dart';
import 'asset_scanner.dart';

class AssetPathThemedFileCreator implements AssetPathIFileCreator {
  final AssetPathIDirectoryCreator directoryCreator;
  final String moduleName;

  AssetPathThemedFileCreator(this.directoryCreator, this.moduleName);

  @override
  Future<void> createNecessaryFiles() async {
    'creating theme-based necessary files...'.printWithColor();

    final assets =
        AssetScanner(directoryCreator.assetsDir, themeAware: true).scan();

    // if no asset found on any sub directories
    if (assets.isEmpty) {
      await _createFile(
        directoryCreator.stylesSubDir.path,
        'k_assets',
        content: "",
      );
      'No Assets found on any Sub directories'.printWithColor(
        status: PrintType.warning,
      );
      return;
    }

    final pathCode = StringBuffer();
    final hasThemedAssets = assets.any((asset) => asset.isThemed);
    if (hasThemedAssets) {
      pathCode.write("import '../../theme/theme_manager.dart';\n\n");
    }
    pathCode.write('enum KAssetName {\n');
    for (final asset in assets) {
      pathCode.write('  ${asset.enumName},\n');
    }
    pathCode.write('}\n\n');

    pathCode.write('extension AssetsExtension on KAssetName {\n');
    pathCode.write('  String get root => \'assets\';\n');

    // Generate root getters for each subfolder. `images` and `svg` are
    // always emitted so the getters stay stable even when those folders
    // are empty, since app code may reference them directly.
    final rootGetters = <String, String>{'images': 'images', 'svg': 'svg'};
    for (final asset in assets) {
      rootGetters[_rootGetterName(asset.rootFolder)] = asset.rootFolder;
    }
    rootGetters.forEach((varName, folder) {
      pathCode.write('  String get ${varName}Root => \'\$root/$folder\';\n');
    });

    pathCode.write('  String get imagePath {\n');
    pathCode.write('    switch (this) {\n');
    for (final asset in assets) {
      final folderRoot =
          '\$${_rootGetterName(asset.rootFolder)}Root'
          '${asset.subPath.isEmpty ? '' : '/${asset.subPath}'}';
      pathCode.write('      case KAssetName.${asset.enumName}:\n');
      if (asset.isThemed) {
        // Use themed helper with the asset's own folder root
        pathCode.write(
          '        return _themed(${asset.subPath.isEmpty ? '${_rootGetterName(asset.rootFolder)}Root' : '"$folderRoot"'}, "${asset.fileName}");\n',
        );
      } else {
        // Direct path for common assets (not in dark/light folders)
        pathCode.write('        return "$folderRoot/${asset.fileName}";\n');
      }
    }
    pathCode.write('    }\n');
    pathCode.write('  }\n');

    // Add themed helper method only when a themed asset uses it
    if (hasThemedAssets) {
      pathCode.write('\n');
      pathCode.write(
        '  String _themed(String folderRoot, String fileName) {\n',
      );
      pathCode.write('    final isDark = ThemeManager().isDarkMode;\n');
      pathCode.write('    final folder = isDark ? \'dark\' : \'light\';\n');
      pathCode.write('    return \'\$folderRoot/\$folder/\$fileName\';\n');
      pathCode.write('  }\n');
    }
    pathCode.write('}\n');

    await _createFile(
      directoryCreator.stylesSubDir.path,
      'k_assets',
      content: pathCode.toString(),
    );
    "Successfully generated theme-based image paths (${assets.length} assets)."
        .printWithColor(status: PrintType.success);
  }

  String _rootGetterName(String folder) {
    final name = AssetScanner.toIdentifier([folder]);
    return name[0].toLowerCase() + name.substring(1);
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
        await file.writeAsString(content, flush: true);
      }
    } catch (e) {
      e.toString().printWithColor(status: PrintType.error);
      stderr.write('creating $fileName.$fileType failed!');
      exit(2);
    }
  }
}
