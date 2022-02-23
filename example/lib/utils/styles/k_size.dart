import 'package:flutter/material.dart';
import 'package:riverpod_test/utils/navigation_service.dart';

//zeplin size
// width 414
// height 896
extension KSizes on num {
  static Size get screenSize =>
      MediaQuery.of(Navigation.key.currentContext!).size;

  //height
  double get h =>
      (this / 896) * (screenSize.height > 896 ? 896 : screenSize.height);

  //Width
  double get w =>
      (this / 414) * (screenSize.width > 414 ? 414 : screenSize.width);

  //fontSize    
  double get sp {
    // For small devices.
    if (screenSize.height < 600) {
      return 0.7 * this;
    }
    // For normal device
    return 1.0 * this;
  }
}
