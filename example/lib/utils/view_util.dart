import 'package:flutter/material.dart';
import 'package:riverpod_test/utils/navigation_service.dart';

class ViewUtil {
  static SSLSnackbar(String msg) {
    //Using ScaffoldMessenger we can easily access
//this snackbar from anywhere
    return ScaffoldMessenger.of(Navigation.key.currentContext!).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(
          label: '',
          textColor: Colors.transparent,
          onPressed: () {},
        ),
      ),
    );
  }
}
