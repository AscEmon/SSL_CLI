enum AppConstant { red, green, yellow, reset }

extension AppConstantExtention on AppConstant {
  String get key {
    switch (this) {
      case AppConstant.red:
        return "\x1B[31m";
      case AppConstant.green:
        return "\x1B[32m";
      case AppConstant.yellow:
        return "\x1B[33m";
      case AppConstant.reset:
        return "\x1B[0m";
    }
  }
}
