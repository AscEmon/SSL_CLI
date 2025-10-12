import 'dart:io';

import '../constant/constant_key.dart';
import 'enum.dart';

extension StringExtension on String {
  String convertToCamelCase() {
    return toLowerCase().split(' ').map((word) {
      String leftText = (word.length > 1) ? word.substring(1, word.length) : '';
      return word[0].toUpperCase() + leftText;
    }).join(' ');
  }
}

extension PrintExtension on String {
  void printWithColor({PrintType? status}) {
    if (status == null) {
      print(this);
    } else if (status == PrintType.success) {
      print("${AppConstant.green.key}$this${AppConstant.reset.key}");
    } else if (status == PrintType.warning) {
      print("${AppConstant.yellow.key}$this${AppConstant.reset.key}");
    } else {
      print("${AppConstant.red.key}$this${AppConstant.reset.key}");
    }
  }
}

extension PathExtension on String {
  bool isValidFilePath() {
    // Ensure it contains a valid separator, but not JUST a separator
    if (trim().isEmpty) return false; // Empty string is invalid
    if (endsWith("/") || endsWith("\\")) {
      return false; // Ends with "/" or "\" is invalid
    }
    if (!contains(Platform.pathSeparator)) {
      return false; // Must contain at least one "/"
    }

    return true; // Otherwise, it's a valid path
  }
}
