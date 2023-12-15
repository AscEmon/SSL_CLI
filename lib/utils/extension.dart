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
