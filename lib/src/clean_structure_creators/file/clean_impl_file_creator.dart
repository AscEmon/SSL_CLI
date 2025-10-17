import 'dart:io';
import 'package:ssl_cli/src/repo_module_creators/file/repo_module_impl_file_creator.dart';
import 'package:ssl_cli/utils/enum.dart';
import 'package:ssl_cli/utils/extension.dart';

import '../clean_i_creators.dart';

class CleanImplFileCreator implements IFileCreator {
  final IDirectoryCreator directoryCreator;
  final String projectName;
  final String? stateManagement;

  CleanImplFileCreator(
    this.directoryCreator,
    this.projectName,
    this.stateManagement,
  );

  @override
  Future<void> createNecessaryFiles() async {
    'Creating Clean Architecture files...'.printWithColor(
      status: PrintType.success,
    );

    final corePath = directoryCreator.coreDir.path;
    final featuresPath = directoryCreator.featuresDir.path;

    // Core files
    await _createCoreFiles(corePath);

    // Feature files
    await _createFeatureFiles(featuresPath);
    await _createLocalizationFiles();

    // Main file
    await _createMainFile();

    // Create .gitignore
    await _createGitignoreFile();

    // Create analysis_options.yaml
    await _createAnalysisOptionsFile();

    'All Clean Architecture files created successfully!'.printWithColor(
      status: PrintType.success,
    );
  }

  Future<void> _createCoreFiles(String corePath) async {
    // Constants
    await _createFile('$corePath/constants', 'api_urls', '''
enum UrlLink { isLive, isDev, isLocalServer }

enum ApiUrl { base, baseImage, products }

extension ApiUrlExtention on ApiUrl {
  static String _baseUrl = '';
  static String _baseImageUrl = '';

  static void setUrl(UrlLink urlLink) {
    switch (urlLink) {
      case UrlLink.isLive:
        _baseUrl = '';
        _baseImageUrl = '';
        break;
      case UrlLink.isDev:
        _baseUrl = '';
        _baseImageUrl = '';
        break;
      case UrlLink.isLocalServer:
        _baseUrl = '';
        break;
    }
  }

  String get url {
    switch (this) {
      case ApiUrl.base:
        return _baseUrl;
      case ApiUrl.baseImage:
        return _baseImageUrl;
      case ApiUrl.products:
        return "/products";
    }
  }
}

''');

    await _createFile(
      '$corePath/constants',
      'app_constants',
      '''enum AppConstants {
  bearer('Bearer'),
  applicationJson('application/json'),
  multipartFormData('multipart/form-data'),
  contentType('application/json'),
  accept('application/json'),
  android('android'),
  ios('ios'),
  en('en'),
  bn('bn'),
  userId('userId'),
  token('token'),
  language('language'),
  yyyyMmDd('dd-MM-yyyy'),
  ddMmYyyy('dd/MM/yyyy'),
  ddMmYyyySlash('dd/MM/yyyy'),
  dMmmYHm('d MMMM y hh:mm a'),
  dMmmY('d MMM y'),
  dMmY('d MMM y'),
  yyyyMm('yyyy-MM'),
  mmm('mmm'),
  mmmm('mmmm'),
  mmmmY('mmmmY'),
  isSwitched('isSwitched'),
  deviceId('deviceId'),
  deviceOs('deviceOs'),
  userAgent('userAgent'),
  appVersion('appVersion'),
  buildNumber('buildNumber'),
  ipnUrl('ipnUrl'),
  storeId('storeId'),
  storePassword('storePassword'),
  mobile('mobile'),
  email('email'),
  pushId('pushId'),
  refreshToken('refreshToken'),
  accessToken('accessToken'),
  fontFamily('fontFamily'),
  loginResponse('loginResponse'),
  cashCartItems('cashCartItems'),
  isDarkMode('isDarkMode'),
  username('username');

  final String key;
  const AppConstants(this.key);
}
''',
    );

    // Error
    await _createFile(
      '$corePath/error',
      'failures',
      '''import 'package:equatable/equatable.dart';
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server failures for API errors
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Cache failures for local storage errors
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.statusCode});
}

/// Network failures for connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.statusCode});
}

/// Authentication failures for auth-related errors
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.statusCode});
}

/// Validation failures for input validation errors
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.statusCode});
}

''',
    );

    await _createFile(
      '$corePath/error',
      'exceptions',
      '''/// Base exception class for the application
class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException({required this.message, this.statusCode});

  @override
  String toString() =>
      statusCode != null ? message : '\$message (Status Code: \$statusCode)';
}

/// Server exception for API errors
class ServerException extends AppException {
  ServerException({required super.message, super.statusCode});
}

/// Cache exception for local storage errors
class CacheException extends AppException {
  CacheException({required super.message, super.statusCode});
}

/// Network exception for connectivity issues
class NetworkException extends AppException {
  NetworkException({required super.message, super.statusCode});
}

/// Authentication exception for auth-related errors
class AuthenticationException extends AppException {
  AuthenticationException({required super.message, super.statusCode});
}

/// Validation exception for input validation errors
class ValidationException extends AppException {
  ValidationException({required super.message, super.statusCode});
}

/// Bad request exception for 400 errors
class BadRequestException extends AppException {
  BadRequestException({required super.message, super.statusCode = 400});
}

/// Unauthorized exception for 401/403 errors
class UnauthorizedException extends AppException {
  UnauthorizedException({required super.message, super.statusCode = 401});
}

/// Not found exception for 404 errors
class NotFoundException extends AppException {
  NotFoundException({required super.message, super.statusCode = 404});
}

/// Timeout exception for connection timeouts
class TimeoutException extends AppException {
  TimeoutException({required super.message, super.statusCode});
}

/// Request cancelled exception
class RequestCancelledException extends AppException {
  RequestCancelledException({required super.message, super.statusCode});
}

''',
    );

    await _createFile(
      '$corePath/models',
      'global_paginator',
      '''class GlobalPaginator {
  GlobalPaginator({
    this.currentPage,
    this.totalPages,
    this.recordPerPage,
  });

  int? currentPage;
  int? totalPages;
  int? recordPerPage;

  factory GlobalPaginator.fromJson(Map<String, dynamic> json) =>
      GlobalPaginator(
        currentPage: json["current_page"],
        totalPages: json["total_pages"],
        recordPerPage:
            json["record_per_page"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "total_pages": totalPages,
        "record_per_page": recordPerPage,
      };
    }''',
    );

    await _createFile('$corePath/models', 'global_response', '''
class GlobalResponse {
  GlobalResponse({this.message, this.errors, this.code});

  String? message;
  List<String>? errors;
  int? code;

  factory GlobalResponse.fromJson(Map<String, dynamic> json) => GlobalResponse(
    message: json['message'],
    errors:
        json['errors'] == null
            ? null
            : List<String>.from(json['errors'].map((x) => x)),
    code: json['code'],
  );

  Map<String, dynamic> toJson() => {
    'message': message,
    'errors': errors == null ? null : List<dynamic>.from(errors!.map((x) => x)),
    'code': code,
  };
}
''');

    await _createFile('$corePath/routes', 'app_routes', '''
import 'package:flutter/material.dart';
import '../../features/products/presentation/pages/product_page.dart';

enum AppRoutes { product }

extension AppRoutesExtention on AppRoutes {
  Widget buildWidget<T extends Object>({T? arguments}) {
    switch (this) {
      case AppRoutes.product:
        return const ProductPage();
    }
  }
}

''');

    await _createFile('$corePath/routes', 'navigation', '''
import 'package:flutter/material.dart';
import 'app_routes.dart';

class Navigation {
  static GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// Holds the information about parent context
  /// For example when navigation from Screen A to Screen B
  /// we can access context of Screen A from Screen B to check if it
  /// came from Screen A. So we can trigger different logic depending on
  /// which screen we navigated from.

  //it will navigate you to one screen to another
  static Future push<T extends Object>(
    context, {
    required AppRoutes appRoutes,
    String? routeName,
    T? arguments,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (context) => appRoutes.buildWidget(arguments: arguments),
      ),
    );
  }

  //it will pop all the screen  and take you to the new screen
  //E:g : when you will goto the login to home page then you will use this
  static Future pushAndRemoveUntil<T extends Object>(
    context, {
    required AppRoutes appRoutes,
    String? routeName,
    T? arguments,
  }) {
    return Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (context) => appRoutes.buildWidget(arguments: arguments),
      ),
      (route) => false,
    );
  }

  //It will replace the screen with current screen
  //E:g :  screen A
  //  GestureDetector(
  // onTap: (){
  //   ScreenB().pushReplacement
  // },
  // it means screen B replace in screen A .
  //if you pressed back then you will not find screen A. it remove from stack

  static Future pushReplacement<T extends Object>(
    context, {
    required AppRoutes appRoutes,
    String? routeName,
    T? arguments,
  }) {
    return Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder:
            (BuildContext context) =>
                appRoutes.buildWidget(arguments: arguments),
      ),
    );
  }

  //it will pop all the screen and take you to the first screen of the stack
  //that means you will go to the Home page
  static Future pushAndRemoveSpecificScreen<T extends Object>(
    context, {
    required AppRoutes appRoutes,
    String? routeName,
    T? arguments,
  }) {
    return Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (context) => appRoutes.buildWidget(arguments: arguments),
      ),
      (route) => route.isFirst,
    );
  }

  // when you remove previous x count of  route
  //from stack then please use this way
  //E.g : if you remove 3 route from stack then pass the argument to 3
  static popUntil(context, int removeProviousPage) {
    int screenPop = 0;
    return Navigator.of(
      context,
    ).popUntil((_) => screenPop++ >= removeProviousPage);
  }

  //Remove single page from stack
  static void pop(context) {
    return Navigator.pop(context);
  }
}

 ''');

    await _createFile('$corePath/theme', 'app_colors', '''
import 'package:flutter/material.dart';

/// Application colors using enum
enum AppColors {
  scaffold(Color.fromARGB(255, 222, 242, 240)),
  // Primary colors
  primary(Color(0xFF26A69A)),
  primaryLight(Color(0xFF42A5F5)),
  primaryDark(Color(0xFF0D47A1)),

  // Secondary colors
  secondary(Color(0xFF26A69A)),
  secondaryLight(Color(0xFF4DB6AC)),
  secondaryDark(Color(0xFF00796B)),

  accent(Color(0xFF26A69A)),

  // Neutral colors
  black(Color(0xFF000000)),
  darkGrey(Color(0xFF4F4F4F)),
  grey(Color(0xFF9E9E9E)),
  lightGrey(Color(0xFFE0E0E0)),
  white(Color(0xFFFFFFFF)),

  greylish(Color(0xff303030)),
  transparent(Colors.transparent),
  yellow(Color(0xffF6D403)),
  // Status colors
  success(Color(0xFF4CAF50)),
  warning(Color(0xFFFFC107)),
  error(Color(0xFFF44336)),
  info(Color(0xFF2196F3)),
  red(Colors.red),
  green(Colors.green),
  orange(Colors.orange),

  // Background colors
  background(Color(0xFFF5F5F5)),
  cardBackground(Color.fromARGB(255, 216, 213, 213)),

  // Text colors
  textPrimary(Color(0xFF212121)),
  textSecondary(Color(0xFF757575)),
  textHint(Color(0xFFBDBDBD));

  final Color color;

  const AppColors(this.color);
}

''');

    await _createFile('$corePath/theme', 'theme_helper', '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      // Enhanced dropdown styling for light theme
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: AppColors.black.color),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.white.color),
          shadowColor: WidgetStatePropertyAll(
            AppColors.grey.color.withValues(alpha: 0.2),
          ),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8.h)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white.color,
          hintStyle: TextStyle(color: AppColors.grey.color),
          labelStyle: TextStyle(color: AppColors.black.color),
          errorStyle: TextStyle(color: AppColors.error.color),
          errorMaxLines: 3,
          iconColor: AppColors.black.color,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.grey.color),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.grey.color),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.primary.color),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.grey.color,
        refreshBackgroundColor: AppColors.primary.color,
      ),
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        fillColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.red.color,
        ),
        checkColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.white.color,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(color: AppColors.red.color, width: 2.w),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.r), // Rounded corners (4px)
        ),
      ),
      cardTheme: CardThemeData(color: AppColors.white.color),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.white.color),
      drawerTheme: DrawerThemeData(backgroundColor: AppColors.white.color),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.transparent.color,
        modalBackgroundColor: AppColors.white.color,
        modalElevation: 1,
        shape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide.none,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: WidgetStateProperty.resolveWith(
            (states) => AppColors.black.color,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.greylish.color,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintStyle: TextStyle(color: AppColors.white.color),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        horizontalTitleGap: 0,
        textColor: AppColors.white.color,
        contentPadding: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white.color,
        selectedItemColor: AppColors.red.color,
        unselectedItemColor: AppColors.grey.color,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.black.color,
        indicatorColor: AppColors.transparent.color,
        dividerColor: AppColors.transparent.color,
        unselectedLabelColor: AppColors.grey.color,
        overlayColor: WidgetStateColor.resolveWith(
          (states) => AppColors.transparent.color,
        ),
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(
          fontSize: 10.sp,
          color: AppColors.red.color,
          fontWeight: FontWeight.bold,
        ),
      ),
      radioTheme: RadioThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        fillColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.white.color,
        ),
      ),
      primaryColor: AppColors.white.color,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white.color,
        iconTheme: IconThemeData(color: AppColors.black.color),
        titleTextStyle: TextStyle(color: AppColors.black.color),
      ),
      scaffoldBackgroundColor: AppColors.white.color,
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColors.black.color),
        displayMedium: TextStyle(color: AppColors.black.color),
        displaySmall: TextStyle(color: AppColors.black.color),
        headlineLarge: TextStyle(color: AppColors.black.color),
        headlineMedium: TextStyle(color: AppColors.black.color),
        headlineSmall: TextStyle(color: AppColors.black.color),
        titleLarge: TextStyle(color: AppColors.black.color),
        titleMedium: TextStyle(color: AppColors.black.color),
        titleSmall: TextStyle(color: AppColors.black.color),
        bodyLarge: TextStyle(color: AppColors.black.color),
        bodyMedium: TextStyle(color: AppColors.black.color),
        bodySmall: TextStyle(color: AppColors.black.color),
        labelLarge: TextStyle(color: AppColors.black.color),
        labelMedium: TextStyle(color: AppColors.black.color),
        labelSmall: TextStyle(color: AppColors.black.color),
      ),
      iconTheme: IconThemeData(color: AppColors.black.color),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      // Enhanced dropdown styling for dark theme
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: AppColors.white.color),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.greylish.color),
          shadowColor: WidgetStatePropertyAll(
            AppColors.black.color.withValues(alpha: 0.3),
          ),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8.h)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.greylish.color,
          hintStyle: TextStyle(color: AppColors.lightGrey.color),
          labelStyle: TextStyle(color: AppColors.white.color),
          errorStyle: TextStyle(color: AppColors.error.color),
          errorMaxLines: 3,
          iconColor: AppColors.white.color,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.grey.color),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.grey.color),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.primary.color),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.grey.color,
        refreshBackgroundColor: AppColors.primary.color,
      ),
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        fillColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.red.color,
        ),
        checkColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.white.color,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(color: AppColors.red.color, width: 2.w),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.r), // Rounded corners (4px)
        ),
      ),
      cardTheme: CardThemeData(color: AppColors.greylish.color),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.greylish.color),
      drawerTheme: DrawerThemeData(backgroundColor: AppColors.black.color),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.transparent.color,
        modalBackgroundColor: AppColors.greylish.color,
        modalElevation: 1,
        shape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide.none,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: WidgetStateProperty.resolveWith(
            (states) => AppColors.white.color,
          ),
        ),
      ),
      primaryColor: AppColors.black.color,
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.greylish.color,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintStyle: TextStyle(color: AppColors.black.color),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        horizontalTitleGap: 0,
        textColor: AppColors.white.color,
        contentPadding: EdgeInsets.zero,
      ),
      radioTheme: RadioThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        fillColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.white.color,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.white.color,
        indicatorColor: AppColors.transparent.color,
        dividerColor: AppColors.transparent.color,
        unselectedLabelColor: AppColors.grey.color,
        overlayColor: WidgetStateColor.resolveWith(
          (states) => AppColors.transparent.color,
        ),
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(
          fontSize: 10.sp,
          color: AppColors.red.color,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.greylish.color,
        selectedItemColor: AppColors.red.color,
        unselectedItemColor: AppColors.grey.color,
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.black.color,
        iconTheme: IconThemeData(color: AppColors.white.color),
        titleTextStyle: TextStyle(color: AppColors.white.color),
      ),
      scaffoldBackgroundColor: AppColors.black.color,
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColors.white.color),
        displayMedium: TextStyle(color: AppColors.white.color),
        displaySmall: TextStyle(color: AppColors.white.color),
        headlineLarge: TextStyle(color: AppColors.white.color),
        headlineMedium: TextStyle(color: AppColors.white.color),
        headlineSmall: TextStyle(color: AppColors.white.color),
        titleLarge: TextStyle(color: AppColors.white.color),
        titleMedium: TextStyle(color: AppColors.white.color),
        titleSmall: TextStyle(color: AppColors.white.color),
        bodyLarge: TextStyle(color: AppColors.white.color),
        bodyMedium: TextStyle(color: AppColors.white.color),
        bodySmall: TextStyle(color: AppColors.white.color),
        labelLarge: TextStyle(color: AppColors.white.color),
        labelSmall: TextStyle(color: AppColors.white.color),
        labelMedium: TextStyle(color: AppColors.white.color),
      ),
      iconTheme: IconThemeData(color: AppColors.white.color),
    );
  }
}

''');

    await _createFile('$corePath/theme', 'theme_manager', '''
import 'package:flutter/material.dart';
import '/core/constants/app_constants.dart';
import '/core/theme/theme_helper.dart';

import '../utils/preferences_helper.dart';

class ThemeManager {
  final String _themeKey = AppConstants.isDarkMode.key;
  bool _isDarkMode = false;
  static final ThemeManager _instance = ThemeManager._internal();

  factory ThemeManager() => _instance;

  ThemeManager._internal() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData =>
      _isDarkMode ? AppTheme.darkTheme() : AppTheme.lightTheme();

  /// Load saved theme preference
  Future<void> _loadThemePreference() async {
    try {
      _isDarkMode = PrefHelper.instance.getBool(_themeKey);
      // notifyListeners();
    } catch (e) {
      // Default to light theme if there's an error
      _isDarkMode = false;
    }
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;

    try {
      await PrefHelper.instance.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // Revert if saving fails
      _isDarkMode = !_isDarkMode;
    }
    await WidgetsBinding.instance.performReassemble();
  }
}

''');

    // Network
    await _createFile(
      '$corePath/network',
      'network_info',
      '''import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_client.dart';

/// Interface for network information
abstract class NetworkInfo {
  /// Check if the device is connected to the internet
  Future<bool> get isConnected;

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged;

  /// Check internet availability
  Future<bool> internetAvailable();

  /// Get the current connectivity status
  Future<List<ConnectivityResult>> getConnectivityStatus();
}

/// Implementation of NetworkInfo
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  bool _isInternet = false;

  /// API requests that need to be retried when internet is available
  final List<ApiRequest> apiStack = [];

  NetworkInfoImpl({required Connectivity connectivity})
    : _connectivity = connectivity;

  /// Get whether internet is available
  bool get isInternet => _isInternet;

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty &&
        result.any((element) => element != ConnectivityResult.none);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  @override
  Future<bool> internetAvailable() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _isInternet =
        connectivityResult.isNotEmpty &&
        connectivityResult.any((element) => element != ConnectivityResult.none);
    return _isInternet;
  }

  @override
  Future<List<ConnectivityResult>> getConnectivityStatus() async {
    return await _connectivity.checkConnectivity();
  }
}

/// Class to store API request information for retry
class ApiRequest {
  final String url;
  final HttpMethod method;
  final Map<String, dynamic> variables;
  final dynamic Function(dynamic) onSuccessFunction;
  final Future<dynamic> Function() execute;

  ApiRequest({
    required this.url,
    required this.method,
    required this.variables,
    required this.onSuccessFunction,
    required this.execute,
  });
}

''',
    );

    await _createFile('$corePath/network', 'api_client', '''

import 'dart:io';
import 'package:dio/dio.dart';
import '/core/utils/extension.dart';
import '../../../../core/constants/app_constants.dart';
import '../utils/preferences_helper.dart';
import '/core/error/exceptions.dart';
import '/core/network/network_info.dart';
import '../../../../core/constants/api_urls.dart';

/// HTTP methods enum
enum HttpMethod { get, post, put, delete, patch, download }

/// Core API client for making HTTP requests
class ApiClient {
  final Dio _dio;
  final NetworkInfo _networkInfo;
  final PrefHelper _prefHelper;

  ApiClient({
    required Dio dio,
    required NetworkInfo networkInfo,
    required PrefHelper prefHelper,
  }) : _dio = dio,
       _networkInfo = networkInfo,
       _prefHelper = prefHelper {
    _initDio();
  }

  /// Initialize Dio with default options
  void _initDio() {
    _dio.options = BaseOptions(
      baseUrl: ApiUrl.base.url,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    );
    _initInterceptors();
  }

  /// Initialize interceptors for logging and auth
  void _initInterceptors() {
    _dio.interceptors.addAll([
      _createAuthInterceptor(),
      _createLoggingInterceptor(),
    ]);
  }

  /// Create auth interceptor
  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add common headers
        options.headers.addAll(_getHeaders());
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle token expiration (401 errors)
        if (error.response?.statusCode == 401) {
          // Clear token
          _prefHelper.setString(AppConstants.token.key, '');
        }
        return handler.next(error);
      },
    );
  }

  /// Create logging interceptor
  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        'REQUEST[\${options.method}] => PATH: \${ApiUrl.base.url}\${options.path} '
                '=> Request Values: param: \${options.queryParameters}, => Time : \${DateTime.now()}, DATA: \${options.data}, => _HEADERS: \${options.headers} '
            .log();
        return handler.next(options);
      },
      onResponse: (response, handler) {
        'RESPONSE[\${response.statusCode}] => Time : \${DateTime.now()} => DATA: \${response.data} URL: \${response.requestOptions.baseUrl}\${response.requestOptions.path} '
            .log();
        return handler.next(response);
      },
      onError: (error, handler) {
        'ERROR[\${error.response?.statusCode}] => DATA: \${error.response?.data} Message: \${error.message} URL: \${error.response?.requestOptions.baseUrl}\${error.response?.requestOptions.path}'
            .log();
        return handler.next(error);
      },
    );
  }

  /// Get headers including auth token
  Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': AppConstants.contentType.key,
      'Accept': AppConstants.accept.key,
      'app-version': _prefHelper.getString(AppConstants.appVersion.key),
      'build-number': _prefHelper.getString(AppConstants.buildNumber.key),
      'language':
          _prefHelper.getLanguage() == 1
              ? AppConstants.en.key
              : AppConstants.bn.key,
    };

    // Add bearer token if available
    String token = _prefHelper.getString(AppConstants.token.key);
    if (token.isNotEmpty) {
      headers['Authorization'] = '\${AppConstants.bearer.key} \$token';
    }

    return headers;
  }

  /// Unified request method for all HTTP methods
  Future<T> request<T>({
    required String endpoint,
    required HttpMethod method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? extraHeaders,
    List<File>? files,
    String? fileKeyName,
    String? savePath,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    ResponseConverter<T>? converter,
  }) async {
    // Check internet connectivity
    final isConnected = await _networkInfo.internetAvailable();
    if (!isConnected) {
      // Queue the request for later execution
      if (_networkInfo is NetworkInfoImpl) {
        (_networkInfo).apiStack.add(
          ApiRequest(
            url: endpoint,
            method: method,
            variables:
                data is Map<String, dynamic> ? data : <String, dynamic>{},
            onSuccessFunction: (response) {
              return converter != null ? converter(response) : response as T;
            },
            execute: () async {
              // Create a function that will retry this exact request
              try {
                return await request<T>(
                  endpoint: endpoint,
                  method: method,
                  data: data,
                  queryParameters: queryParameters,
                  extraHeaders: extraHeaders,
                  files: files,
                  fileKeyName: fileKeyName,
                  savePath: savePath,
                  onSendProgress: onSendProgress,
                  onReceiveProgress: onReceiveProgress,
                  converter: converter,
                );
              } catch (e) {
                'Error retrying request: \$e'.log();
                return null;
              }
            },
          ),
        );
      }
      throw NetworkException(message: 'No internet connection');
    }

    // Update headers if needed
    if (extraHeaders != null) {
      _dio.options.headers.addAll(extraHeaders);
    }

    // Handle file uploads
    FormData? formData;
    if (files != null && files.isNotEmpty && fileKeyName != null) {
      formData = FormData();

      // Add regular params to form data
      if (data is Map<String, dynamic>) {
        data.forEach((key, value) {
          formData?.fields.add(MapEntry(key, value.toString()));
        });
      }

      // Add files to form data
      for (var file in files) {
        formData.files.add(
          MapEntry(
            fileKeyName,
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }
    }

    try {
      Response response;

      // Execute request based on method
      switch (method) {
        case HttpMethod.get:
          response = await _dio.get(
            endpoint,
            queryParameters: queryParameters,
            options: Options(headers: extraHeaders),
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpMethod.post:
          response = await _dio.post(
            endpoint,
            data: formData ?? data,
            queryParameters: queryParameters,
            options: Options(headers: extraHeaders),
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpMethod.put:
          response = await _dio.put(
            endpoint,
            data: formData ?? data,
            queryParameters: queryParameters,
            options: Options(headers: extraHeaders),
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpMethod.delete:
          response = await _dio.delete(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: Options(headers: extraHeaders),
          );
          break;
        case HttpMethod.patch:
          response = await _dio.patch(
            endpoint,
            data: formData ?? data,
            queryParameters: queryParameters,
            options: Options(headers: extraHeaders),
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpMethod.download:
          if (savePath == null) {
            throw ArgumentError('savePath is required for download method');
          }
          response = await _dio.download(
            endpoint,
            savePath,
            queryParameters: queryParameters,
            options: Options(headers: extraHeaders),
            onReceiveProgress: onReceiveProgress,
          );
          break;
      }

      // Process response
      final result = _handleResponse(response);

      // Convert response if needed
      if (converter != null) {
        return converter(result);
      }

      return result as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Something went wrong: \$e');
    }
  }

  /// Handle response based on status code
  dynamic _handleResponse(Response response) {
    'RESPONSE: \${response.data}'.log();
    switch (response.statusCode) {
      case 200:
      case 201:
        return response.data;
      case 400:
        throw BadRequestException(message: 'Bad request');
      case 401:
      case 403:
        throw UnauthorizedException(message: 'Unauthorized');
      case 404:
        throw NotFoundException(message: 'Not found');
      case 500:
      default:
        throw ServerException(message: 'Server error: \${response.statusCode}');
    }
  }

  /// Handle Dio errors
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(message: 'Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        // Extract error message from response data if available
        String errorMessage = 'Server error occurred';
        if (e.response?.data != null) {
          if (e.response?.data is Map) {
            errorMessage = e.response?.data['message'] ?? errorMessage;
          } else if (e.response?.data is String) {
            errorMessage = e.response?.data;
          }
        }
        'RESPONSE ERROR: \$errorMessage \$statusCode'.log();
        // Handle specific status codes
        if (statusCode == 401) {
          _prefHelper.setString(AppConstants.token.key, '');
          return UnauthorizedException(message: errorMessage, statusCode: 401);
        } else if (statusCode == 404) {
          return NotFoundException(message: errorMessage, statusCode: 404);
        } else if (statusCode == 400) {
          return BadRequestException(message: errorMessage, statusCode: 400);
        } else if (statusCode == 500) {
          return ServerException(message: errorMessage, statusCode: 500);
        } else {
          return ServerException(message: errorMessage, statusCode: statusCode);
        }
      case DioExceptionType.cancel:
        return RequestCancelledException(message: 'Request cancelled');
      case DioExceptionType.connectionError:
        return NetworkException(message: 'Connection error');
      default:
        return ServerException(message: e.message ?? 'Unknown error occurred');
    }
  }
}

/// Type definition for response converters
typedef ResponseConverter<T> = T Function(dynamic data);

''');

    await _createFile('$corePath/utils', 'app_version', '''
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_constants.dart';
import 'extension.dart';
import 'preferences_helper.dart';

class AppVersion {
  static String currentVersion = '';
  static String versionCode = '';
  static Future<void> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    currentVersion = packageInfo.version;
    versionCode = packageInfo.buildNumber;
    PrefHelper.instance.setString(AppConstants.appVersion.key, currentVersion);
    PrefHelper.instance.setString(AppConstants.buildNumber.key, versionCode);
    'Current version is  :: \${currentVersion.toString()}'.log();
    'App version Code is :: \${versionCode.toString()}'.log();
  }
}
 
''');

    await _createFile('$corePath/utils', 'date_util', '''
import 'package:flutter/material.dart';

import '../routes/navigation.dart';

class DateUtil {
  static DateTime? fromDate;
  static bool isToShowPreviousDate = true;
  static Future<DateTime?> showDatePickerDialog() async {
    final picked = await showDatePicker(
      context: Navigation.key.currentContext!,
      initialDate: DateTime.now(),
      //use to show the previous month
      firstDate: isToShowPreviousDate == true
          ? DateTime(2020, DateTime.december)
          : DateTime.now(),
      lastDate: DateTime.now(),
    );

    fromDate = picked;
    return picked;
  }
}

''');

    await _createFile('$corePath/utils', 'validators', '''
  
// lib/core/utils/validators.dart

class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Required field
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return 'Please enter \${fieldName ?? 'this field'}';
    }
    return null;
  }

  // Phone number
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}\$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
  
''');

    // Utils
    await _createFile(
      '$corePath/utils',
      'preferences_helper',
      '''import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Singleton class for managing SharedPreferences
/// Located in core/utils as it's shared across all features
class PrefHelper {
  static PrefHelper? _instance;
  static SharedPreferences? _preferences;

  // Private constructor
  PrefHelper._();

  /// Get singleton instance
  static PrefHelper get instance {
    _instance ??= PrefHelper._();
    return _instance!;
  }

  /// Initialize SharedPreferences
  /// Call this in main() before runApp()
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // String operations
  Future<bool> setString(String key, String value) async {
    return await _preferences!.setString(key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    return _preferences!.getString(key) ?? defaultValue;
  }

  // Int operations
  Future<bool> setInt(String key, int value) async {
    return await _preferences!.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _preferences!.getInt(key) ?? defaultValue;
  }

  // Bool operations
  Future<bool> setBool(String key, bool value) async {
    return await _preferences!.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _preferences!.getBool(key) ?? defaultValue;
  }

  // Double operations
  Future<bool> setDouble(String key, double value) async {
    return await _preferences!.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _preferences!.getDouble(key) ?? defaultValue;
  }

  // List<String> operations
  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences!.setStringList(key, value);
  }

  List<String> getStringList(String key, {List<String>? defaultValue}) {
    return _preferences!.getStringList(key) ?? defaultValue ?? [];
  }

  // Remove a key
  Future<bool> remove(String key) async {
    return await _preferences!.remove(key);
  }

  // Clear all preferences
  Future<bool> clear() async {
    return await _preferences!.clear();
  }

  // Check if key exists
  bool containsKey(String key) {
    return _preferences!.containsKey(key);
  }

  // Get all keys
  Set<String> getKeys() {
    return _preferences!.getKeys();
  }

  // Custom method for language (example)
  int getLanguage() {
    return getInt(
      AppConstants.language.key,
      defaultValue: 1,
    ); // 1 for English, 2 for Bengali
  }

  Future<bool> setLanguage(int language) async {
    return await setInt(AppConstants.language.key, language);
  }
}

''',
    );

    await _createFile('$corePath/utils', 'extension', '''
import 'dart:developer' as darttools show log;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
// import '/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'preferences_helper.dart';

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
    '.',
  ];
  static const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', '.'];

  String changeNum() {
    String input = this;
    if (PrefHelper.instance.getLanguage() == 2) {
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
      if (prefix == '017' ||
          prefix == '016' ||
          prefix == '018' ||
          prefix == '015' ||
          prefix == '019' ||
          prefix == '013' ||
          prefix == '014') {
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
      input = input.replaceAll(args[i], values[i]);
    }
    return input;
  }
}

extension Context on BuildContext {
  //this extention is for localization
  //its a shorter version of AppLocalizations
  // AppLocalizations get loc => AppLocalizations.of(this)!;

  //get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  //get height
  double get height => MediaQuery.of(this).size.height;

  //get width
  double get width => MediaQuery.of(this).size.width;

  //Bottom Notch Check
  bool get bottomNotch =>
      MediaQuery.of(this).viewPadding.bottom > 0 ? true : false;
}

extension ValidationExtention on String {
  //Check email is valid or not
  bool get isValidEmail => RegExp(
    r"[a-z0-9!#\$%&'*+/=?^_`{|}~-]+(?:.[a-z0-9!#\$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?",
  ).hasMatch(this);

  //check mobile number contain special character or not
  bool get isMobileNumberValid =>
      RegExp(r'(^(?:[+0]9)?[0-9]{10,12}\$)').hasMatch(this);
}

extension NumGenericExtensions<T extends String> on T {
  double parseToDouble() {
    if (isEmpty) {
      return 0.0;
    }
    try {
      return double.parse(this);
    } catch (e) {
      e.log();
      return 0.0;
    }
  }

  String parseToString() {
    try {
      return toString();
    } catch (e) {
      e.log();

      return '';
    }
  }

  int parseToInt() {
    try {
      return int.parse(this);
    } catch (e) {
      e.log();
      return 0;
    }
  }
}

extension VersionCheck on String {
  bool isVersionGreaterThan(String currentVersion) {
    String serverVersion = this;
    String currentV = currentVersion.replaceAll('.', '');
    String serverV = serverVersion.replaceAll('.', '');
    'serverV \$serverV'.log();
    'currentV \$currentV'.log();
    return int.parse(serverV) > int.parse(currentV);
  }
}

extension Log on Object {
  void log() => darttools.log(toString());
}

// It will formate the date which will show in our application.
extension FormatedDateExtention on DateTime {
  String get formattedDate => DateFormat(AppConstants.mmm.key).format(this);
}

extension FormatedDateExtentionString on String {
  String formattedDate(String format) {
    DateTime parsedDate = DateTime.parse(this);
    return DateFormat(format).format(parsedDate);
  }
}

extension FormattedYearMonthDate on String? {
  DateTime fomateDateFromString({String? dateFormat}) {
    return DateFormat(dateFormat ?? AppConstants.yyyyMm.key).parse(this ?? '');
  }
}

//This extention sum the value from List<Map<String,dynamic>>
extension StringToDoubleFoldExtention<T extends List<Map<String, dynamic>>>
    on T {
  String? get listOfMapStringSum => map(
    (e) => double.tryParse(e.values.first?.toString() ?? ''),
  ).toList().fold('0', (previous, current) {
    var sum =
        double.parse(previous?.toString() ?? '0') +
        double.parse(current?.toString() ?? '0');
    return sum.toString().parseToDouble().toStringAsFixed(3);
  });
}

//It will capitalize the first letter of the String.
extension CapitalizeExtention on String {
  String toCapitalized() =>
      length > 0 ? '\${this[0].toUpperCase()}\${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => str.toCapitalized()).join(' ');
}

extension LastPathComponent on String {
  String get lastPathComponent => split('/').last.replaceAll('_', '');
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> distinctBy(Object Function(T e) getCompareValue) {
    var result = <T>[];
    forEach((element) {
      if (!result.any((x) => getCompareValue(x) == getCompareValue(element))) {
        result.add(element);
      }
    });

    return result;
  }
}

/// it will use for finding data  from list based on same date
extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
    <K, List<E>>{},
    (Map<K, List<E>> map, E element) =>
        map..putIfAbsent(keyFunction(element), () => <E>[]).add(element),
  );
}

extension DateTimeGreater on DateTime {
  bool get isDateGreater {
    DateTime currentDate = DateTime.now();

    // Create a date to compare with the current date
    DateTime compareDate = this;
    // Example date: May 30, 2023
    if (compareDate.isAfter(currentDate)) {
      return true;
    } else {
      return false;
    }
  }
}

''');

    await _createFile('$corePath/utils', 'enum', '''
enum LanguageOption { bangla, english }
''');

    await _createFile('$corePath/utils/styles', 'k_assets', '''
enum KAssetName { oil, closeBottom }

extension AssetsExtention on KAssetName {
  String get imagePath {
    String rootPath = 'assets';
    String svgDir = '\$rootPath/svg';
    String imageDir = '\$rootPath/images';

    switch (this) {
      case KAssetName.oil:
        return '\$imageDir/oil.png';
      case KAssetName.closeBottom:
        return '\$svgDir/close_bottom.svg';
    }
  }
}

''');

    await _createFile(
      '$corePath/utils/styles',
      'k_text_style',
      '''import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme/app_colors.dart';

class KTextStyle {
  static TextStyle customTextStyle({
    double fontSize = 12,
    fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return GoogleFonts.poppins(
      color: color ?? AppColors.lightGrey.color,
      fontSize: fontSize.sp,
      fontWeight: fontWeight,
    );
  }
}

''',
    );

    await _createFile('$corePath/utils/styles', 'styles', '''
export 'k_text_style.dart';
export 'k_assets.dart';
''');

    // Usecases
    await _createFile(
      '$corePath/usecases',
      'usecase',
      '''import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '/core/error/failures.dart';

/// Abstract class for defining use cases
// ignore: avoid_types_as_parameter_names
abstract class UseCase<Type, Params> {
  /// Call method to execute the use case
  Future<Either<Failure, Type>> call(Params params);
}

/// Class for use cases that don't require parameters
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}

''',
    );

    // DI
    await _createFile('$corePath/di', 'service_locator', '''
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '/core/network/api_client.dart';
import '/core/network/network_info.dart';
import '/core/utils/preferences_helper.dart';
import '/features/products/data/datasources/product_remote_datasource.dart';
import '/features/products/data/datasources/product_local_datasource.dart';
import '/features/products/data/repositories/product_repository_impl.dart';
import '/features/products/domain/repositories/product_repository.dart';
import '/features/products/domain/usecases/get_products.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(connectivity: sl()));
  sl.registerLazySingleton<PrefHelper>(() => PrefHelper.instance);
  sl.registerLazySingleton<ApiClient>(() => ApiClient(dio: sl(), networkInfo: sl(), prefHelper: sl()));

  // Products Feature
  sl.registerLazySingleton<ProductRemoteDataSource>(() => ProductRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<ProductLocalDataSource>(() => ProductLocalDataSourceImpl());
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));
  sl.registerLazySingleton(() => GetProducts(sl()));
}
''');

    // Presentation widgets
    await _createFile('$corePath/presentation/widgets', 'global_text', '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalText extends StatelessWidget {
  final String str;
  final FontWeight? fontWeight;
  final double? fontSize;
  final Color? color;
  final FontStyle? fontStyle;
  final double? letterSpacing;
  final TextDecoration? decoration;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softwrap;
  final double? height;
  final String? fontFamily;
  final TextStyle? style;

  const GlobalText({
    super.key,
    required this.str,
    this.fontWeight,
    this.fontSize,
    this.fontStyle,
    this.color,
    this.letterSpacing,
    this.decoration,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.softwrap,
    this.height,
    this.fontFamily,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Get the current text color from theme
    final defaultTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Text(
      str,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softwrap,
      textScaler: TextScaler.linear(1.0),
      style:
          style ??
          GoogleFonts.inter(
            // Use provided color or default from theme
            color: color ?? defaultTextColor,
            fontSize: fontSize?.sp,
            fontWeight: fontWeight ?? FontWeight.w500,
            letterSpacing: letterSpacing,
            decoration: decoration,
            height: height,
            fontStyle: fontStyle,
          ),
    );
  }
}

''');

    await _createFile('$corePath/presentation/widgets', 'global_button', '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '/core/presentation/widgets/global_text.dart';

class GlobalButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final bool isRounded;
  final double? btnHeight;
  final int roundedBorderRadius;
  final Color? btnBackgroundActiveColor;
  final double? textFontSize;

  const GlobalButton({
    super.key,
    required this.onPressed,
    required this.buttonText,
    this.isRounded = true,
    this.btnHeight,
    this.roundedBorderRadius = 17,
    this.btnBackgroundActiveColor,
    this.textFontSize,
  });

  @override
  Widget build(BuildContext context) {
    Color btnColor = btnBackgroundActiveColor ?? AppColors.primary.color;

    return ElevatedButton(
      style: ButtonStyle(
        shape: WidgetStateProperty.resolveWith<OutlinedBorder>((states) {
          return RoundedRectangleBorder(
            borderRadius:
                isRounded
                    ? BorderRadius.circular(roundedBorderRadius.r)
                    : BorderRadius.zero,
          );
        }),
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) =>
              onPressed != null ? btnColor : AppColors.grey.color,
        ),
        elevation: WidgetStateProperty.resolveWith((states) => 0.0),
      ),
      onPressed: onPressed,
      child: SizedBox(
        height: btnHeight ?? 76.h,
        child: Center(
          child: GlobalText(
            str: buttonText,
            fontWeight: FontWeight.w500,
            fontSize: textFontSize ?? 14,
          ),
        ),
      ),
    );
  }
}

''');

    await _createFile(
      '$corePath/presentation/widgets',
      'global_appbar',
      '''import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '/core/presentation/widgets/global_text.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool? centerTitle;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const GlobalAppBar({
    super.key,
    required this.title,
    this.centerTitle,
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color? themeBgColor = Theme.of(context).appBarTheme.backgroundColor;
    return AppBar(
      elevation: 0,
      centerTitle: centerTitle,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor ?? themeBgColor,
      title: GlobalText(
        str: title,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}

''',
    );

    await _createFile(
      '$corePath/presentation/widgets',
      'global_loader',
      '''import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '/core/presentation/widgets/global_text.dart';

class GlobalLoader extends StatelessWidget {
  const GlobalLoader({super.key, this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator.adaptive(),
        SizedBox(width: 10.w),
        GlobalText(str: text ?? ''),
      ],
    );
  }
}

''',
    );

    await _createFile('$corePath/presentation/widgets', 'app_starter_error', '''
 import 'package:flutter/material.dart';

import 'global_text.dart';

class AppStarterError extends StatelessWidget {
  const AppStarterError({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              GlobalText(
                str: 'Failed to initialize app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              GlobalText(
                str: error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
 ''');

    await _createFile('$corePath/presentation/widgets', 'global_dropdown', '''
 
 import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '/core/presentation/widgets/global_text.dart';
import '../../theme/app_colors.dart';

class GlobalDropdown<T> extends StatelessWidget {
  const GlobalDropdown({
    super.key,
    required this.validator,
    required this.hintText,
    required this.onChanged,
    required this.items,
    this.borderRadius = 10,
    this.value,
  });

  final String? Function(T?)? validator;
  final String? hintText;
  final void Function(T?)? onChanged;
  final List<DropdownMenuItem<T>>? items;
  final double? borderRadius;
  final T? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? AppColors.white.color : AppColors.black.color;
    final hintColor = isDark ? AppColors.lightGrey.color : AppColors.grey.color;

    return Theme(
      data: ThemeData(
        buttonTheme: ButtonTheme.of(context).copyWith(alignedDropdown: true),
      ),
      child: DropdownButtonFormField<T>(
        validator: validator,
        padding: EdgeInsets.zero,
        alignment: AlignmentDirectional.centerStart,
        icon: Icon(Icons.arrow_drop_down, color: AppColors.black.color),
        iconSize: 24.sp,
        value: value,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0.h),
          filled: true,
          fillColor: isDark ? AppColors.lightGrey.color : AppColors.white.color,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius!.r),
            borderSide: BorderSide(color: AppColors.primary.color, width: 1.w),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.error.color, width: 1.w),
            borderRadius: BorderRadius.circular(borderRadius!.r),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.error.color, width: 1.w),
            borderRadius: BorderRadius.circular(borderRadius!.r),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius!.r),
            borderSide: BorderSide(color: AppColors.grey.color, width: 1.w),
          ),
        ),
        isExpanded: true,
        // Improved hint with explicit color
        hint: GlobalText(
          str: hintText ?? '',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: hintColor,
        ),
        onChanged: onChanged,
        items:
            items?.map((item) {
              // Ensure each dropdown item has the correct text color
              if (item.child is Text) {
                final text = item.child as Text;
                return DropdownMenuItem<T>(
                  value: item.value,
                  child: Text(
                    text.data ?? '',
                    style: TextStyle(color: textColor, fontSize: 14.sp),
                  ),
                );
              } else if (item.child is GlobalText) {
                final globalText = item.child as GlobalText;
                return DropdownMenuItem<T>(
                  value: item.value,
                  child: GlobalText(
                    str: globalText.str,
                    fontSize: 14.sp,
                    color: textColor,
                  ),
                );
              }
              return item;
            }).toList() ??
            [],
        dropdownColor:
            isDark ? AppColors.greylish.color : AppColors.white.color,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),

        itemHeight: 48.h,
        menuMaxHeight: 300.h,
        isDense: false,
      ),
    );
  }
}
''');

    await _createFile(
      '$corePath/presentation/widgets',
      'global_image_loader',
      '''
 
 import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '/core/presentation/widgets/global_loader.dart';

enum ImageFor { asset, network }

/// A unified image loader that can handle both regular images and SVGs
/// based on the file extension. Default to asset loading.
class GlobalImageLoader extends StatelessWidget {
  const GlobalImageLoader({
    super.key,
    required this.imagePath,
    this.height,
    this.width,
    this.fit,
    this.color,
    this.imageFor = ImageFor.asset,
  });

  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final ImageFor? imageFor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Check if the image is an SVG based on file extension
    final bool isSvg = imagePath.toLowerCase().endsWith('.svg');

    // Handle network images
    if (imageFor == ImageFor.network) {
      if (isSvg) {
        return SvgPicture.network(
          imagePath,
          height: height,
          width: width,
          fit: fit ?? BoxFit.scaleDown,
          placeholderBuilder: (BuildContext context) => GlobalLoader(text: ''),
        );
      } else {
        return Image.network(
          imagePath,
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          errorBuilder: (context, exception, stackTrace) => const Text('😢'),
        );
      }
    }
    // Handle asset images (default)
    else {
      if (isSvg) {
        return SvgPicture.asset(
          imagePath,
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
        );
      } else {
        return Image.asset(
          imagePath,
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          errorBuilder: (context, exception, stackTrace) => const Text('😢'),
        );
      }
    }
  }
} 
 ''',
    );

    await _createFile(
      '$corePath/presentation/widgets',
      'global_network_dialog',
      '''
 
 import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '/core/presentation/widgets/global_button.dart';
import '/core/presentation/widgets/global_text.dart';

class GlobalNetworkDialog extends StatelessWidget {
  final VoidCallback onRetry;

  const GlobalNetworkDialog({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white.color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: AppColors.error.color),
            const SizedBox(height: 16),
            const GlobalText(
              str: 'No Internet Connection',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            const GlobalText(
              str: 'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GlobalButton(
              btnHeight: 52.h,
              onPressed: onRetry,
              buttonText: 'Try Again',
            ),
          ],
        ),
      ),
    );
  }
}
 ''',
    );

    await _createFile(
      '$corePath/presentation/widgets',
      'global_network_listener',
      '''
 
 import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '/core/di/service_locator.dart';
import '/core/network/network_info.dart';
import 'global_network_dialog.dart';
import '../../routes/navigation.dart';
import '../../utils/extension.dart';
import '../view_util.dart';

class GlobalNetworkListener extends StatefulWidget {
  final Widget child;

  const GlobalNetworkListener({super.key, required this.child});

  @override
  State<GlobalNetworkListener> createState() => _GlobalNetworkListenerState();
}

class _GlobalNetworkListenerState extends State<GlobalNetworkListener> {
  bool _wasConnected = true;
  bool _isShowingDialog = false;
  // Track all active dialog contexts to ensure proper dismissal
  final List<BuildContext> _activeDialogContexts = [];

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
  }

  @override
  void dispose() {
    // Ensure all dialogs are dismissed when widget is disposed
    _dismissAllNetworkDialogs();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final networkInfo = sl<NetworkInfo>();
    _wasConnected = await networkInfo.internetAvailable();

    // Show dialog immediately if no internet on app start
    if (!_wasConnected) {
      _showNetworkErrorDialog();
    }

    // Listen for connectivity changes
    networkInfo.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(List<ConnectivityResult> connectivityResult) {
    final isConnected =
        connectivityResult.isNotEmpty &&
        connectivityResult.any((element) => element != ConnectivityResult.none);

    'isNetworkAvailable :: \$isConnected'.log();

    // If network was connected but now disconnected
    if (_wasConnected && !isConnected) {
      _showNetworkErrorDialog();
    }
    // If network was disconnected but now connected
    else if (!_wasConnected && isConnected) {
      _dismissAllNetworkDialogs();
      _retryQueuedRequests();
    }

    _wasConnected = isConnected;
  }

  void _showNetworkErrorDialog() {
    if (_isShowingDialog || !mounted) return;

    _isShowingDialog = true;

    // Show dialog on next frame to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Create a dialog context
      final BuildContext dialogContext = Navigation.key.currentContext!;

      ViewUtil.alertDialog(
        barrierDismissible: false,
        content: PopScope(
          canPop: false,
          onPopInvokedWithResult:
              (didpop, result) {}, // Prevent back button from closing dialog
          child: GlobalNetworkDialog(
            onRetry: () async {
              final networkInfo = sl<NetworkInfo>();
              final isConnected = await networkInfo.internetAvailable();

              if (isConnected) {
                _dismissAllNetworkDialogs();
                _retryQueuedRequests();
              }
            },
          ),
        ),
      ).then((_) {
        // Remove this dialog context when it's closed
        _activeDialogContexts.remove(dialogContext);
        if (_activeDialogContexts.isEmpty) {
          _isShowingDialog = false;
        }
      });

      // Add this dialog context to our tracking list
      _activeDialogContexts.add(dialogContext);
    });
  }

  void _dismissAllNetworkDialogs() {
    if (!_isShowingDialog || !mounted) return;

    // Pop all dialogs by repeatedly calling Navigator.pop until no more dialogs
    final navigatorState = Navigation.key.currentState;
    if (navigatorState != null) {
      while (_isShowingDialog && navigatorState.canPop()) {
        navigatorState.pop();
      }
    }

    // Clear the tracking list
    _activeDialogContexts.clear();
    _isShowingDialog = false;
  }

  void _retryQueuedRequests() {
    final networkInfo = sl<NetworkInfo>();

    if (networkInfo is NetworkInfoImpl) {
      if (networkInfo.apiStack.isNotEmpty) {
        for (final request in networkInfo.apiStack) {
          request.execute();
        }
        networkInfo.apiStack.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

 ''',
    );

    await _createFile(
      '$corePath/presentation/widgets',
      'global_text_form_field',
      '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '/core/presentation/widgets/global_text.dart';

class GlobalTextFormField extends StatelessWidget {
  final bool? obscureText;
  final TextInputType? textInputType;
  final TextInputType? keyboardType; // Added for compatibility
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxlength;
  final AutovalidateMode? autovalidateMode;
  final bool? readOnly;
  final Color? fillColor;
  final String? hintText;
  final String? labelText;
  final String? errorText; // Added for real-time validation
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final bool? mandatoryLabel;
  final TextStyle? style;
  final int? line;
  final String? initialValue;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;
  final double borderRadius;

  const GlobalTextFormField({
    super.key,
    this.obscureText,
    this.textInputType,
    this.keyboardType, // Added
    this.controller,
    this.validator,
    this.fillColor,
    this.suffixIcon,
    this.prefixIcon,
    this.maxlength,
    this.initialValue,
    this.autovalidateMode,
    this.readOnly,
    this.hintText,
    this.labelText,
    this.errorText, // Added
    this.hintStyle,
    this.mandatoryLabel,
    this.labelStyle,
    this.line = 1,
    this.style,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define colors based on theme
    final textColor = isDark ? AppColors.white.color : AppColors.black.color;
    final cursorColor =
        isDark ? AppColors.primary.color : AppColors.black.color;
    final fieldFillColor =
        isDark
            ? AppColors.greylish.color.withValues(alpha: 0.5)
            : fillColor ?? const Color.fromARGB(255, 250, 246, 246);
    final borderColor =
        isDark
            ? AppColors.grey.color
            : AppColors.grey.color.withValues(alpha: 0.2);
    final errorColor = AppColors.error.color;
    final primaryColor = AppColors.primary.color;

    return TextFormField(
      initialValue: initialValue,
      maxLines: line,
      style:
          style ??
          TextStyle(
            color: textColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
      autovalidateMode: autovalidateMode,
      obscureText: obscureText ?? false,
      obscuringCharacter: '*',
      controller: controller,
      textInputAction: textInputAction,
      cursorColor: cursorColor,

      keyboardType: keyboardType ?? textInputType ?? TextInputType.text,
      onChanged: onChanged,
      maxLength: maxlength,
      onEditingComplete: () => FocusScope.of(context).nextFocus(),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
        prefixIcon: prefixIcon,
        hintText: hintText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        errorText: errorText, // Show error from provider
        label:
            mandatoryLabel == true
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GlobalText(
                      str: labelText ?? '',
                      color: isDark ? AppColors.lightGrey.color : null,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    GlobalText(str: '*', color: errorColor, fontSize: 14),
                  ],
                )
                : GlobalText(
                  str: labelText ?? '',
                  color: isDark ? AppColors.lightGrey.color : null,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
        labelStyle:
            labelStyle ??
            TextStyle(
              color: isDark ? AppColors.lightGrey.color : AppColors.grey.color,
              fontSize: 14.sp,
            ),
        filled: true,
        counterText: '',

        fillColor: fieldFillColor,
        suffixIcon: suffixIcon,
        hintStyle:
            hintStyle ??
            TextStyle(
              color: isDark ? AppColors.lightGrey.color : AppColors.grey.color,
              fontSize: 14.sp,
            ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(borderRadius.r)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
          borderSide: BorderSide(color: primaryColor, width: 1.w),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: errorColor, width: 1.w),
          borderRadius: BorderRadius.all(Radius.circular(borderRadius.r)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: errorColor, width: 1.w),
          borderRadius: BorderRadius.all(Radius.circular(borderRadius.r)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
          borderSide: BorderSide(color: borderColor, width: 1.w),
        ),
      ),
      validator: validator,
      readOnly: readOnly ?? false,
    );
  }
}
 ''',
    );

    await _createFile('$corePath/presentation/mixins', 'error_handler_mixin', '''
import '/core/error/exceptions.dart';
import '/core/error/failures.dart';
import '/core/presentation/view_util.dart';
import '/core/presentation/widgets/global_text.dart';

/// A mixin that provides error handling methods for presentation layer
mixin ErrorHandlerMixin {
  /// Show appropriate error UI based on failure type
  void handleError(dynamic error) {
    if (error is AuthenticationFailure || error is UnauthorizedException) {
      _showUnauthorizedDialog(error.toString());
    } else if (error is ServerFailure || error is ServerException) {
      _showServerErrorSnackBar(error.toString());
    } else if (error is NetworkFailure || error is NetworkException) {
      _showNetworkErrorSnackBar(error.toString());
    } else {
      ViewUtil.snackbar(error.toString());
    }
  }

  /// Show dialog for authentication errors
  void _showUnauthorizedDialog(String message) {
    ViewUtil.alertDialog(
      title: GlobalText(str: 'Authentication Error'),
      content: GlobalText(str: message),
    );
  }

  /// Show snackbar for server errors
  void _showServerErrorSnackBar(String message) {
    ViewUtil.snackbar('Server Error');
  }

  /// Show snackbar for network errors
  void _showNetworkErrorSnackBar(String message) {
    ViewUtil.snackbar('Network Error');
  }
}
''');

    await _createFile('$corePath/presentation', 'view_util', '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../routes/navigation.dart';
import '../theme/app_colors.dart';
import 'widgets/global_text.dart';

class ViewUtil {
  static snackbar(String msg, {String? btnName, void Function()? onPressed}) {
    return ScaffoldMessenger.of(Navigation.key.currentContext!).showSnackBar(
      SnackBar(
        content: GlobalText(
          str: msg,
          fontWeight: FontWeight.w500,
          color: AppColors.white.color,
        ),
        action: SnackBarAction(
          label: btnName ?? '',
          textColor:
              btnName == null ? Colors.transparent : AppColors.white.color,
          onPressed: onPressed ?? () {},
        ),
      ),
    );
  }

  // global alert dialog
  static Future alertDialog({
    Widget? title,
    required Widget content,
    List<Widget>? actions,
    Color? alertBackgroundColor,
    bool? barrierDismissible,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? contentPadding,
  }) async {
    // flutter defined function.
    await showDialog(
      context: Navigation.key.currentContext!,
      barrierDismissible: barrierDismissible ?? true,
      builder: (BuildContext context) {
        // return object of type Dialog.
        return AlertDialog(
          backgroundColor: alertBackgroundColor ?? Colors.transparent,
          contentPadding:
              contentPadding ?? EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          shape: RoundedRectangleBorder(
            borderRadius:
                borderRadius ?? BorderRadius.all(Radius.circular(8.w)),
          ),
          title: title,
          content: content,
        );
      },
    );
  }

  static bottomSheet({
    required BuildContext context,
    bool? isDismissable,
    required Widget content,
    BoxConstraints? boxConstraints,
  }) {
    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      constraints: boxConstraints,
      isScrollControlled: true,
      context: context,
      isDismissible: isDismissable ?? true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1a000000),
                  offset: const Offset(0, 1),
                  blurRadius: 3.r,
                  spreadRadius: 0,
                ),
              ],
              color: const Color(0xffffffff),
            ),
            child: content,
          ),
    );
  }
}

''');
  }

  Future<void> _createFeatureFiles(String featuresPath) async {
    final productsPath = '$featuresPath/products';

    // Domain - Entities
    await _createFile(
      '$productsPath/domain/entities',
      'product',
      '''import 'package:equatable/equatable.dart';
class Product extends Equatable {
  final int id;
  const Product({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}
''',
    );

    // Domain - Repositories
    await _createFile(
      '$productsPath/domain/repositories',
      'product_repository',
      '''
import 'package:dartz/dartz.dart';

import '/core/error/failures.dart';
import '/features/products/domain/entities/product.dart';

/// Repository interface for product functionality
abstract class ProductRepository {
  /// Get paginated list of products
  Future<Either<Failure, List<Product>>> getProducts();
}

''',
    );

    // Domain - Usecases
    await _createFile('$productsPath/domain/usecases', 'get_products', '''
import 'package:dartz/dartz.dart';
import '/core/error/failures.dart';
import '/core/usecases/usecase.dart';
import '/features/products/domain/entities/product.dart';
import '/features/products/domain/repositories/product_repository.dart';

/// Use case for getting paginated products
class GetProducts implements UseCase<List<Product>, NoParams> {
  final ProductRepository _repository;

  GetProducts(this._repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await _repository.getProducts();
  }
}

''');

    // Data - Models
    await _createFile(
      '$productsPath/data/models',
      'product_model',
      '''import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
''',
    );

    await _createFile(
      '$productsPath/data/models',
      'product_response',
      '''import 'product_model.dart';

class ProductResponse {
  final List<ProductModel> products;
  final int total;

  ProductResponse({required this.products, required this.total});

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      products: (json['products'] as List).map((item) => ProductModel.fromJson(item)).toList(),
      total: json['total'] ?? 0,
    );
  }
}
''',
    );

    // Data - Datasources
    await _createFile(
      '$productsPath/data/datasources',
      'product_remote_datasource',
      '''import '/core/network/api_client.dart';
import '/core/constants/api_urls.dart';
import '/core/error/exceptions.dart';
import '../models/product_model.dart';
import '../models/product_response.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _apiClient.request(
        endpoint: ApiUrl.products.url,
        method: HttpMethod.get,
      );
      final productResponse = ProductResponse.fromJson(response);
      return productResponse.products;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
''',
    );

    await _createFile(
      '$productsPath/data/datasources',
      'product_local_datasource',
      '''import '/core/error/exceptions.dart';
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts();
  Future<void> cacheProducts(List<ProductModel> products);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  List<ProductModel> _cachedProducts = [];

  @override
  Future<List<ProductModel>> getProducts() async {
    if (_cachedProducts.isEmpty) {
      throw CacheException(message: 'No cached data');
    }
    return _cachedProducts;
  }

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    _cachedProducts = products;
  }
}
''',
    );

    // Data - Repositories
    await _createFile(
      '$productsPath/data/repositories',
      'product_repository_impl',
      '''
import 'package:dartz/dartz.dart';

import '/core/error/exceptions.dart';
import '/core/error/failures.dart';
import '/core/network/network_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  ProductRepositoryImpl({
    required ProductRemoteDataSource remoteDataSource,
    required ProductLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    if (await _networkInfo.internetAvailable()) {
      try {
        final remoteProducts = await _remoteDataSource.getProducts();
        await _localDataSource.cacheProducts(remoteProducts);
        return Right(remoteProducts);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final localProducts = await _localDataSource.getProducts();
        return Right(localProducts);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }
}
''',
    );

    // Presentation - State Management Files
    if (stateManagement == "2") {
      // Bloc pattern
      await _createBlocPresentationFiles(productsPath);
    } else {
      // Riverpod pattern (default)
      await _createRiverpodPresentationFiles(productsPath);
    }

    // Presentation - Pages
    await _createFile('$productsPath/presentation/pages', 'product_page', '''
import 'package:flutter/material.dart';
import '/core/presentation/widgets/global_appbar.dart';
import '/core/presentation/widgets/global_text.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(title: 'Product List'),
      body: const Center(child: GlobalText(str: 'Product  List')),
    );
  }
}
''');

    // Presentation - Widgets
    await _createFile('$productsPath/presentation/widgets', 'widget', '''
import 'package:flutter/material.dart';
import '/core/presentation/widgets/global_text.dart';

class Widget extends StatelessWidget {
  const Widget({super.key});

  @override
  Center build(BuildContext context) {
    return const Center(child: GlobalText(str: 'Widget'));
  }
}
''');
  }

  Future<void> _createRiverpodPresentationFiles(String productsPath) async {
    // State
    await _createFile(
      '$productsPath/presentation/providers/state',
      'product_state',
      '''

import 'package:flutter/material.dart';

@immutable
class ProductState {
  final bool isLoading;
  final String? errorMessage;

  const ProductState({
    this.isLoading = false,
    this.errorMessage,
  });

  ProductState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

''',
    );

    // Provider/Notifier
    await _createFile(
      '$productsPath/presentation/providers',
      'product_provider',
      '''
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/features/products/presentation/providers/state/product_state.dart';

part 'product_provider.g.dart';

@riverpod
class ProductNotifier extends _\$ProductNotifier {
  @override
  FutureOr<ProductState> build(){
    return const ProductState();
  }
}

''',
    );
  }

  Future<void> _createBlocPresentationFiles(String productsPath) async {
    // State
    await _createFile(
      '$productsPath/presentation/bloc/state',
      'product_state',
      '''
import 'package:equatable/equatable.dart';

import '/features/products/domain/entities/product.dart';

/// State for Product
sealed class ProductState extends Equatable {
  const ProductState();
  
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductLoaded extends ProductState {
  final List<Product> products;
  
  const ProductLoaded(this.products);
  
  @override
  List<Object?> get props => [products];
}

class ProductError extends ProductState {
  final String message;
  
  const ProductError(this.message);
  
  @override
  List<Object?> get props => [message];
}
''',
    );

    // Event
    await _createFile(
      '$productsPath/presentation/bloc/event',
      'product_event',
      '''
import 'package:equatable/equatable.dart';

/// Events for Product
sealed class ProductEvent extends Equatable {
  const ProductEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  const LoadProducts();
}

class RefreshProducts extends ProductEvent {
  const RefreshProducts();
}
''',
    );

    // Bloc
    await _createFile('$productsPath/presentation/bloc', 'product_bloc', '''
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/products/presentation/bloc/event/product_event.dart';
import '/features/products/presentation/bloc/state/product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<RefreshProducts>(_onRefreshProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    
    try {
      // TODO: Implement use case call
      // final result = await _getProductsUseCase(NoParams());
      
      // result.fold(
      //   (failure) => emit(ProductError(failure.message)),
      //   (data) => emit(ProductLoaded(data)),
      // );
      
      // Placeholder
      emit(const ProductLoaded([]));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductState> emit,
  ) async {
    // Same as load but can be customized
    await _onLoadProducts(const LoadProducts(), emit);
  }
}
''');
  }

  Future<void> _createMainFile() async {
    // Generate imports based on state management
    String imports = '''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
''';

    if (stateManagement == "1") {
      // Add Riverpod import
      imports += '''import 'package:flutter_riverpod/flutter_riverpod.dart';
''';
    }

    imports += '''
import '/core/constants/api_urls.dart';
import '/core/di/service_locator.dart';
import '/core/presentation/widgets/global_network_listener.dart';
import '/core/routes/navigation.dart';
import '/core/theme/theme_manager.dart';
import '/core/utils/app_version.dart';
import '/core/utils/preferences_helper.dart';
import '/features/products/presentation/pages/product_page.dart';
// import '/l10n/app_localizations.dart';
import 'core/presentation/widgets/app_starter_error.dart';
''';

    // Generate runApp based on state management
    String runAppCode =
        stateManagement == "1"
            ? '''runApp(const ProviderScope(child: MyApp()));'''
            : '''runApp(const MyApp());''';
    String runErrorCode =
        stateManagement == "1"
            ? '''runApp(
         ProviderScope(child: AppStarterError(error: e.toString())),
      );'''
            : '''runApp(
        MaterialApp(home: AppStarterError(error: e.toString())),
      );''';

    await _createFile('lib', 'main', '''$imports
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize core services (preferences, API URLs, etc.)
    await initServices();

    // Initialize dependency injection (get_it service locator)
    // This must be called before runApp() to ensure all dependencies are ready
    await initDependencies();

    // Set Portrait Mode only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    $runAppCode
  } catch (e, stackTrace) {
    // Log initialization error
    debugPrint('❌ App initialization failed: \$e');
    debugPrint('Stack trace: \$stackTrace');

    $runErrorCode
  }
}

/// Initialize core services
Future<void> initServices() async {
  const flavorType = String.fromEnvironment('flavorType', defaultValue: 'DEV');
  ApiUrlExtention.setUrl(flavorType == 'DEV' ? UrlLink.isDev : UrlLink.isLive);
  await PrefHelper.init();
  await AppVersion.getVersion();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (ctx, child) {
        return MaterialApp(
          title: '${projectName.capitalize()}',
          navigatorKey: Navigation.key,
          debugShowCheckedModeBanner: false,

          // Localization
          // supportedLocales: AppLocalizations.supportedLocales,
          // localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: _getLocale(),

          // Theme
          theme: ThemeManager().themeData,

          // Network listener wrapper
          builder: (context, child) {
            return GlobalNetworkListener(child: child ?? const SizedBox());
          },

          // Initial route based on auth status
          home: _getInitialPage(),
        );
      },
    );
  }


  /// Get locale based on user preference
  Locale _getLocale() {
    final languageCode = PrefHelper.instance.getLanguage();
    return languageCode == 1
        ? const Locale('en', 'US')
        : const Locale('bn', 'BD');
  }

  /// Determine initial page based on authentication status
  Widget _getInitialPage() {
    // final isLoggedIn = sl<AuthLocalDataSource>().isLoggedIn();
    // if (isLoggedIn) {
    //   return const ProductPage();
    // }
    return const ProductPage();
  }
}

''');
  }

  Future<void> _createLocalizationFiles() async {
    //localization yaml file create in project folder
    await _createFile(Directory.current.path, 'l10n', """arb-dir: lib/l10n
template-arb-file: intl_en.arb
output-localization-file: app_localizations.dart
""", fileExtention: 'yaml');

    await _createFile(Directory.current.path, 'verify_obfuscation', '''
#!/bin/bash

echo "=== APK Obfuscation Verification ==="
echo ""

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "\$APK_PATH" ]; then
    echo "❌ APK not found at: \$APK_PATH"
    exit 1
fi

echo "✅ APK found: \$APK_PATH"
echo "📦 APK Size: \$(du -h \"\$APK_PATH\" | cut -f1)"
echo ""

# Extract APK to temporary directory
TEMP_DIR=\$(mktemp -d)
echo "📂 Extracting APK to: \$TEMP_DIR"
unzip -q "\$APK_PATH" -d "\$TEMP_DIR"

# Check for Flutter assets
if [ -d "\$TEMP_DIR/assets/flutter_assets" ]; then
    echo "✅ Flutter assets found"
fi

# Check for obfuscation indicators
echo ""
echo "=== Obfuscation Indicators ==="

# Check if app.so exists (native code)
if [ -f "\$TEMP_DIR/lib/arm64-v8a/libapp.so" ]; then
    SO_SIZE=\$(du -h "\$TEMP_DIR/lib/arm64-v8a/libapp.so" | cut -f1)
    echo "✅ Native library found: libapp.so (\$SO_SIZE)"
    echo "   This contains your obfuscated Dart code"
fi

# Check for Kotlin/Java classes (should be minimal in Flutter)
if [ -d "\$TEMP_DIR/classes.dex\" ] || [ -f "\$TEMP_DIR/classes.dex\" ]; then
    echo "✅ DEX files found (Android native code)"
fi

echo ""
echo "=== Debug Symbols Check ==="
if [ -d "build/app/outputs/symbols" ]; then
    SYMBOL_COUNT=\$(find build/app/outputs/symbols -type f | wc -l)
    echo "✅ Debug symbols found: \$SYMBOL_COUNT files"
    echo "⚠️  IMPORTANT: Keep these files SECRET!"
    echo "   Upload to Firebase Crashlytics for crash reporting"
else
    echo "❌ No debug symbols found"
fi

# Cleanup
rm -rf "\$TEMP_DIR"

echo ""
echo "=== Summary ==="
echo "✅ Your APK is obfuscated and ready for distribution"
echo "🔒 Code is protected from reverse engineering"
echo "📊 Use debug symbols for crash reporting only"

''', fileExtention: 'sh');

    await _createFile(Directory.current.path, 'config', '''
{
    "telegram_chat_id": "",
    "botToken": "",
    "geminiApiKey":"",
    "openAiApiKey": "",
    "deepSeekApiKey": "",
    "geminiModelName":""
}
''', fileExtention: 'json');
    await _createFile("lib/l10n", 'intl_en', '''
{

    "logout_button": "Log out",
    "note": "Note",
    "cancel": "Cancel",
    "yes": "Yes",
    "delete": "Delete",
    "item": "You have %d item",
    "add_address":"Add Adress"


}
''', fileExtention: 'arb');
    await _createFile("lib/l10n", 'intl_bn', '''
{
    "logout_button": "লগ আউট",
    "note": "বিঃদ্রঃ",
    "cancel": "বাতিল করুন",
    "yes": "হ্যাঁ",
    "delete": "মুছে ফেলা",
    "item": "আপনার কাছে %d টি আইটেম আছে",
     "add_address":"ঠিকানা যোগ করুন"

}
''', fileExtention: 'arb');
  }

  Future<void> _createGitignoreFile() async {
    try {
      final file = await File('${Directory.current.path}/.gitignore').create();
      final writer = file.openWrite();
      writer.write('''
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# The .vscode folder contains launch configuration and tasks you configure in
# VS Code which you may wish to be included in version control, so this line
# is commented out by default.
#.vscode/

# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release

# Debug symbols (obfuscation)
# IMPORTANT: Keep these files secret and never commit to Git
**/build/app/outputs/symbols/
**/symbols/
build/

# Config files with sensitive data
config.json
''');
      writer.close();
      '.gitignore created successfully'.printWithColor(
        status: PrintType.success,
      );
    } catch (e) {
      stderr.write('creating .gitignore failed: $e');
    }
  }

  Future<void> _createAnalysisOptionsFile() async {
    try {
      final file =
          await File(
            '${Directory.current.path}/analysis_options.yaml',
          ).create();
      final writer = file.openWrite();

      String content =
          '''# This file configures the analyzer, which statically analyzes Dart code to
# check for errors, warnings, and lints.
#
# The issues identified by the analyzer are surfaced in the UI of Dart-enabled
# IDEs (https://dart.dev/tools#ides-and-editors). The analyzer can also be
# invoked from the command line by running `flutter analyze`.

# Include both Flutter lints and Riverpod lints
include:
  - package:flutter_lints/flutter.yaml

linter:
  # The lint rules applied to this project can be customized in the
  # section below to disable rules from the `package:flutter_lints/flutter.yaml` 
  # included above or to enable additional rules. A list of all available lints
  # and their documentation is published at https://dart.dev/lints.
  rules:
    avoid_print: false
''';

      // Add custom_lint plugin for Riverpod
      if (stateManagement == "1") {
        content += '''
analyzer:
  plugins:
    - custom_lint

# Additional information about this file can be found at
# https://dart.dev/guides/language/analysis-options
''';
      }

      writer.write(content);
      writer.close();
      'analysis_options.yaml created successfully'.printWithColor(
        status: PrintType.success,
      );
    } catch (e) {
      stderr.write('creating analysis_options.yaml failed: $e');
    }
  }

  Future<void> _createFile(
    String basePath,
    String fileName,
    String content, {
    String? fileExtention = 'dart',
  }) async {
    String fileType;
    if (fileExtention == 'yaml') {
      fileType = 'yaml';
    } else if (fileExtention == 'arb') {
      fileType = 'arb';
    } else if (fileExtention == 'json') {
      fileType = 'json';
    } else if (fileExtention == 'sh') {
      fileType = 'sh';
    } else {
      fileType = 'dart';
    }

    try {
      final file = await File('$basePath/$fileName.$fileType').create();

      final writer = file.openWrite();
      writer.write(content);
      writer.close();
    } catch (_) {
      stderr.write('creating $fileName.$fileType failed!');
      exit(2);
    }
  }
}
