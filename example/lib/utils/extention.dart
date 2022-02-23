import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_test/data_provider/pref_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'
    show AppLocalizations;

extension ConvertNum on String {
  static const english = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '.'
  ];
  static const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', '.'];

  String changeNum() {
    String input = this;
    if (PrefHelper.getLanguage() == 2) {
      for (int i = 0; i < english.length; i++) {
        input = input.replaceAll(english[i], bangla[i]);
      }
    } else {
      for (int i = 0; i < english.length; i++) {
        input = input.replaceAll(bangla[i], english[i]);
      }
    }
    return input;
  }
}

extension PhoneValid on String {
  bool phoneValid(String number) {
    if (number.isNotEmpty && number.length == 11) {
      var prefix = number.substring(0, 3);
      if (prefix == "017" ||
          prefix == "016" ||
          prefix == "018" ||
          prefix == "015" ||
          prefix == "019" ||
          prefix == "013" ||
          prefix == "014") {
        return true;
      }
      return false;
    }
    return false;
  }
}

extension StringFormat on String {
  String format(List<String> args, List<dynamic> values) {
    String input = this;
    for (int i = 0; i < args.length; i++) {
      input = input.replaceAll(args[i], "${values[i]}");
    }
    return input;
  }
}

extension Context on BuildContext {
//this extention is for localization
//its a shorter version of AppLocalizations
  AppLocalizations get loc => AppLocalizations.of(this)!;

  //get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  //get height
  double get height => MediaQuery.of(this).size.height;
  //get width
  double get width => MediaQuery.of(this).size.width;

//Customly call a provider for read method only
//It will be helpful for us for calling the read function
//without Consumer,ConsumerWidget or ConsumerStatefulWidget
//Incase if you face any issue using this then please wrap your widget
//with consumer and then call your provider

  T read<T>(ProviderBase<T> provider) {
    /// Reads a provider without listening to it
    return ProviderScope.containerOf(this, listen: false).read(provider);
  }
}

extension validationExtention on String {
  //Check email is valid or not
  bool get isValidEmail => RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+.[a-zA-Z]+")
      .hasMatch(this);

  //check mobile number contain special character or not
  bool get isMobileNumberValid =>
      RegExp(r'(^(?:[+0]9)?[0-9]{10,12}$)').hasMatch(this);
}

extension WidgetExtention on Widget {
  Widget get centerCircularProgress => Center(
        child: Container(
          child: CircularProgressIndicator(),
        ),
      );
}
