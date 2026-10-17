import 'dart:io';
import 'package:ssl_cli/utils/extension.dart';
import 'package:path/path.dart' as path;
import '../../../utils/enum.dart';

/// A single asset discovered under `assets/<rootFolder>/...`.
class ScannedAsset {
  /// Valid Dart identifier used as the `KAssetName` value.
  final String enumName;

  /// Top-level folder inside `assets/` (e.g. `images`, `svg`).
  final String rootFolder;

  /// Sub path between [rootFolder] and the file, using `/`, excluding any
  /// `light`/`dark` segment for themed assets. Empty when directly inside.
  final String subPath;

  final String fileName;

  /// True when the file lives in a `light`/`dark` folder pair.
  final bool isThemed;

  ScannedAsset({
    required this.enumName,
    required this.rootFolder,
    required this.subPath,
    required this.fileName,
    required this.isThemed,
  });
}

/// Walks every folder inside `assets/` (except fonts) recursively and returns
/// one [ScannedAsset] per file, with collision-free, valid enum names.
///
/// When [themeAware] is true, a folder that contains both `light` and `dark`
/// sub folders is treated as themed: a file present in either one becomes a
/// single themed asset.
class AssetScanner {
  final Directory assetsDir;
  final bool themeAware;

  AssetScanner(this.assetsDir, {required this.themeAware});

  List<ScannedAsset> scan() {
    final candidates = <_Candidate>[];

    final rootFolders =
        assetsDir.listSync(followLinks: false).whereType<Directory>().where((
            dir,
          ) {
            final name = path.basename(dir.path).toLowerCase();
            return name != 'fonts' && name != 'font' && !name.startsWith('.');
          }).toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final rootDir in rootFolders) {
      final rootFolder = path.basename(rootDir.path);
      final files =
          rootDir
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      if (files.isEmpty) {
        "No assets found inside $rootFolder directory".printWithColor(
          status: PrintType.warning,
        );
      }

      final seenThemed = <String>{};
      for (final file in files) {
        final relative = path.split(
          path.relative(file.path, from: rootDir.path),
        );
        final fileName = relative.last;
        final dirSegments = relative.sublist(0, relative.length - 1);

        // Skip hidden files/folders such as .DS_Store or .gitkeep
        if (relative.any((segment) => segment.startsWith('.'))) continue;

        var isThemed = false;
        var subSegments = dirSegments;
        if (themeAware) {
          final themeIndex = _themeSegmentIndex(rootDir, dirSegments);
          if (themeIndex != -1) {
            isThemed = true;
            subSegments = [
              ...dirSegments.sublist(0, themeIndex),
              ...dirSegments.sublist(themeIndex + 1),
            ];
          }
        }

        final subPath = subSegments.join('/');
        if (isThemed) {
          // light/x.png and dark/x.png describe the same themed asset
          final key = '$subPath/$fileName';
          if (!seenThemed.add(key)) continue;
        }

        candidates.add(
          _Candidate(
            rootFolder: rootFolder,
            subSegments: subSegments,
            fileName: fileName,
            isThemed: isThemed,
          ),
        );
      }
    }

    return _assignEnumNames(candidates);
  }

  /// Index of the `light`/`dark` segment in [dirSegments] whose parent folder
  /// contains both `light` and `dark`, or -1.
  int _themeSegmentIndex(Directory rootDir, List<String> dirSegments) {
    for (int i = 0; i < dirSegments.length; i++) {
      final segment = dirSegments[i].toLowerCase();
      if (segment != 'light' && segment != 'dark') continue;
      final parent = path.joinAll([rootDir.path, ...dirSegments.sublist(0, i)]);
      if (hasThemeFolders(Directory(parent))) return i;
    }
    return -1;
  }

  static bool hasThemeFolders(Directory directory) {
    final names =
        directory
            .listSync(followLinks: false)
            .whereType<Directory>()
            .map((d) => path.basename(d.path).toLowerCase())
            .toSet();
    return names.contains('light') && names.contains('dark');
  }

  List<ScannedAsset> _assignEnumNames(List<_Candidate> candidates) {
    final used = <String>{};
    final result = <ScannedAsset>[];

    for (final candidate in candidates) {
      var enumName = toIdentifier([candidate.fileName]);
      if (used.contains(enumName)) {
        // Same file name in another folder: prefix with its folder path
        final prefixed = toIdentifier([
          candidate.rootFolder,
          ...candidate.subSegments,
          candidate.fileName,
        ]);
        'Naming with ${candidate.fileName} exists in multiple folders, '
                'generated as $prefixed'
            .printWithColor(status: PrintType.warning);
        enumName = prefixed;
      }
      if (!used.add(enumName)) {
        'Skipping ${candidate.rootFolder}/${candidate.fileName}: '
                'duplicate name $enumName'
            .printWithColor(status: PrintType.warning);
        continue;
      }

      result.add(
        ScannedAsset(
          enumName: enumName,
          rootFolder: candidate.rootFolder,
          subPath: candidate.subSegments.join('/'),
          fileName: candidate.fileName,
          isThemed: candidate.isThemed,
        ),
      );
    }
    return result;
  }

  /// Builds a lowerCamelCase Dart identifier from [parts], splitting on any
  /// non alphanumeric character (`ic_home.png` -> `icHomePng`).
  static String toIdentifier(List<String> parts) {
    final words =
        parts
            .expand((part) => part.split(RegExp(r'[^A-Za-z0-9]+')))
            .where((word) => word.isNotEmpty)
            .toList();
    if (words.isEmpty) return 'asset';

    final buffer = StringBuffer(words.first);
    for (final word in words.skip(1)) {
      buffer.write(word.convertToCamelCase());
    }
    final name = buffer.toString();
    return RegExp(r'^[0-9]').hasMatch(name) ? 'asset$name' : name;
  }
}

class _Candidate {
  final String rootFolder;
  final List<String> subSegments;
  final String fileName;
  final bool isThemed;

  _Candidate({
    required this.rootFolder,
    required this.subSegments,
    required this.fileName,
    required this.isThemed,
  });
}
