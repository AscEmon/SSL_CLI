import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_test/data_provider/pref_helper.dart';
import 'package:riverpod_test/utils/navigation_service.dart';
import 'package:riverpod_test/utils/styles/styles.dart';
//localization
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServices();
  //Set Potraite Mode only
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(ProviderScope(child: MyApp()));
}

/// Make sure you always init shared pref first. It has token and token is need
/// to make API call
initServices() async {
  await PrefHelper.init();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    return MaterialApp(
      title: '',
      navigatorKey: Navigation.key,
      debugShowCheckedModeBanner: false,
//localization
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: (PrefHelper.getLanguage() == 1)
          ? const Locale('en', 'US')
          : const Locale('bn', 'BD'),
      theme: ThemeData(
        progressIndicatorTheme: ProgressIndicatorThemeData(color: Colors.green),
        textTheme: GoogleFonts.robotoMonoTextTheme(),
        primaryColor: KColors.primary,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ThemeData().colorScheme.copyWith(
              secondary: KColors.accent,
            ),
        primarySwatch: KColors.createMaterialColor(KColors.primary),
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(size: 16),
          actionsIconTheme: IconThemeData(size: 16),
          backgroundColor: KColors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: KColors.charcoal,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      home: ,
    );
  }
}
