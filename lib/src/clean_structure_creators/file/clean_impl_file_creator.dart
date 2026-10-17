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

    // Create .env and .env.example
    await _createEnvFiles();

    // Create lib/core/config/env.dart for envied
    await _createEnvConfigFile();

    'All Clean Architecture files created successfully!'.printWithColor(
      status: PrintType.success,
    );

    // Generate lib/l10n/app_localizations*.dart from the .arb files. The
    // earlier `flutter pub get` ran before the .arb files existed.
    'Running flutter gen-l10n...'.printWithColor(status: PrintType.warning);
    final l10nResult = Process.runSync('flutter', ['gen-l10n']);
    if (l10nResult.exitCode == 0) {
      'app_localizations.dart generated successfully'.printWithColor(
        status: PrintType.success,
      );
    } else {
      'gen-l10n warning: ${l10nResult.stderr}'.printWithColor(
        status: PrintType.warning,
      );
    }

    // Generate env.g.dart so envied is ready before first run
    'Running build_runner to generate env.g.dart...'.printWithColor(
      status: PrintType.warning,
    );
    final buildResult = Process.runSync('dart', [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ]);
    if (buildResult.exitCode == 0) {
      'env.g.dart generated successfully'.printWithColor(
        status: PrintType.success,
      );
    } else {
      'build_runner warning: ${buildResult.stderr}'.printWithColor(
        status: PrintType.warning,
      );
    }
  }

  Future<void> _createCoreFiles(String corePath) async {
    // Constants
    await _createFile('$corePath/constants', 'api_urls', '''
import '/core/config/env.dart';

enum UrlLink { isLive, isDev, isLocalServer }

enum ApiUrl { base, baseImage, homes }

extension ApiUrlExtention on ApiUrl {
  static String _baseUrl = '';
  static String _baseImageUrl = '';

  static void setUrl(UrlLink urlLink) {
    switch (urlLink) {
      case UrlLink.isLive:
        _baseUrl = Env.baseUrlLive;
        _baseImageUrl = Env.baseImageUrlLive;
        break;
      case UrlLink.isDev:
        _baseUrl = Env.baseUrlDev;
        _baseImageUrl = Env.baseImageUrlDev;
        break;
      case UrlLink.isLocalServer:
        _baseUrl = Env.baseUrlLocal;
        break;
    }
  }

  String get url {
    switch (this) {
      case ApiUrl.base:
        return _baseUrl;
      case ApiUrl.baseImage:
        return _baseImageUrl;
      case ApiUrl.homes:
        return "/homes";
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
  userId('user-id'),
  token('token'),
  language('language'),
  yyyyMmDd('yyyy-MM-dd'),
  ddMmYyyy('dd/MM/yyyy'),
  ddMmYyyySlash('dd/MM/yyyy'),
  dMmmYHm('d MMMM y hh:mm a'),
  dMmmY('d MMM y'),
  dMmY('d MMM y'),
  yyyyMm('yyyy-MM'),
  mmm('mmm'),
  mmmm('mmmm'),
  mmmmY('mmmmY'),
  isSwitched('is-switched'),
  deviceId('device-id'),
  deviceOs('device-os'),
  userAgent('user-agent'),
  appVersion('app-version'),
  buildNumber('build-number'),
  ipnUrl('ipn-url'),
  storeId('store-id'),
  storePassword('store-password'),
  mobile('mobile'),
  email('email'),
  pushId('push-id'),
  refreshToken('refresh-token'),
  accessToken('access-token'),
  fontFamily('font-family'),
  loginResponse('login-response'),
  cashCartItems('cash-cart-items'),
  isDarkMode('is-dark-mode'),
  user('user'),
  deviceName('device-name'),
  deviceModel('device-model'),
  deviceOsVersion('device-os-version'),
  forceUpdate('force-update'),

  username('username');

  final String key;
  const AppConstants(this.key);
}
''',
    );
    await _createFile('$corePath/error', 'exception_handler', '''
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '/core/utils/extension.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Converts exceptions to failures - use this in all repository methods
///
/// Usage:
/// ```dart
/// @override
/// Future<Either<Failure, LoginResponse>> login(LoginEntity entity) async {
///   return handleException(() async {
///     final response = await remoteDataSource.login(model);
///     await localDataSource.saveLoginData(response);
///     return response;  // Just return the data, not Right()
///   });
/// }
/// ```
///
/// Failure messages are either a usable server message or `''`. The UI
/// resolves `''` to a localized fallback (see `failure_message.dart`), so
/// raw exception text never reaches the screen.
Future<Either<Failure, T>> handleException<T>(
  Future<T> Function() operation,
) async {
  try {
    final result = await operation();
    return Right(result);
  } on AppException catch (e) {
    return Left(_mapAppException(e));
  } on FormatException catch (e) {
    // Log the type only — the text may contain response data.
    handleExceptionLog('handleException: \${e.runtimeType}');
    return const Left(DataParsingFailure(message: ''));
  } on TypeError catch (e) {
    handleExceptionLog('handleException: \${e.runtimeType}');
    return const Left(DataParsingFailure(message: ''));
  } catch (e) {
    handleExceptionLog('handleException: \${e.runtimeType}');
    return const Left(UnexpectedFailure(message: ''));
  }
}

/// Where [handleException] writes its debug log line. Only the exception's
/// runtime type is ever passed here, never its text.
@visibleForTesting
void Function(String line) handleExceptionLog = (line) => line.log();

Failure _mapAppException(AppException e) {
  final message = e.message;
  final statusCode = e.statusCode;
  return switch (e) {
    ValidationException() => ValidationFailure(
        message: message,
        statusCode: statusCode,
        errors: e.errors,
      ),
    UnauthorizedException() || AuthenticationException() =>
      AuthenticationFailure(message: message, statusCode: statusCode),
    ForbiddenException() =>
      ForbiddenFailure(message: message, statusCode: statusCode),
    TooManyRequestsException() =>
      TooManyRequestsFailure(message: message, statusCode: statusCode),
    BadRequestException() =>
      BadRequestFailure(message: message, statusCode: statusCode),
    NotFoundException() =>
      NotFoundFailure(message: message, statusCode: statusCode),
    MethodNotAllowedException() =>
      MethodNotAllowedFailure(message: message, statusCode: statusCode),
    TimeoutException() =>
      TimeoutFailure(message: message, statusCode: statusCode),
    RequestCancelledException() =>
      RequestCancelledFailure(message: message, statusCode: statusCode),
    NetworkException() =>
      NetworkFailure(message: message, statusCode: statusCode),
    CacheException() => CacheFailure(message: message, statusCode: statusCode),
    ServerException() =>
      ServerFailure(message: message, statusCode: statusCode),
    _ => UnexpectedFailure(message: message, statusCode: statusCode),
  };
}
''');
    // Error
    await _createFile('$corePath/error', 'failures', '''
import 'package:equatable/equatable.dart';

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

/// Method not allowed failures for 405 errors
class MethodNotAllowedFailure extends Failure {
  const MethodNotAllowedFailure({required super.message, super.statusCode = 405});
}

/// Validation failures for input validation errors
class ValidationFailure extends Failure {
  final Map<String, dynamic>? errors;

  const ValidationFailure(
      {required super.message, super.statusCode, this.errors});

  @override
  List<Object?> get props => [message, statusCode, errors];

  /// Get all error messages as a flat list
  List<String> get errorMessages {
    if (errors == null || errors!.isEmpty) return [message];

    final List<String> messages = [];
    errors!.forEach((key, value) {
      if (value is List) {
        messages.addAll(value.map((e) => e.toString()));
      } else {
        messages.add(value.toString());
      }
    });
    return messages;
  }

  /// Get first error message
  String get firstError {
    if (errors == null || errors!.isEmpty) return message;

    final firstKey = errors!.keys.first;
    final firstValue = errors![firstKey];

    if (firstValue is List && firstValue.isNotEmpty) {
      return firstValue.first.toString();
    }
    return firstValue.toString();
  }
}

/// Too many requests failures for 429 errors
class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure({required super.message, super.statusCode = 429});
}

/// Bad request failures for 400 errors
class BadRequestFailure extends Failure {
  const BadRequestFailure({required super.message, super.statusCode = 400});
}

/// Forbidden failures for 403 errors (authenticated but not allowed)
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({required super.message, super.statusCode = 403});
}

/// Not found failures for 404 errors
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.statusCode = 404});
}

/// Timeout failures for connect / send / receive timeouts
class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message, super.statusCode});
}

/// Request cancelled failures
class RequestCancelledFailure extends Failure {
  const RequestCancelledFailure({required super.message, super.statusCode});
}

/// Data parsing failures when the response is not in the expected shape
class DataParsingFailure extends Failure {
  const DataParsingFailure({required super.message, super.statusCode});
}

/// Unexpected failures for anything not covered above
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.statusCode});
}


''');

    await _createFile('$corePath/error', 'exceptions', '''
/// Base exception class for the application
class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException({required this.message, this.statusCode});

  @override
  String toString() => '\$runtimeType(statusCode: \$statusCode)';
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
  final Map<String, dynamic>? errors;

  ValidationException({required super.message, super.statusCode, this.errors});
}

/// Too many requests exception for 429 errors
class TooManyRequestsException extends AppException {
  TooManyRequestsException({required super.message, super.statusCode = 429});
}

/// Bad request exception for 400 errors
class BadRequestException extends AppException {
  BadRequestException({required super.message, super.statusCode = 400});
}

/// Unauthorized exception for 401 errors
class UnauthorizedException extends AppException {
  UnauthorizedException({required super.message, super.statusCode = 401});
}

/// Forbidden exception for 403 errors (authenticated but not allowed)
class ForbiddenException extends AppException {
  ForbiddenException({required super.message, super.statusCode = 403});
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

/// Method not allowed exception for 405 errors
class MethodNotAllowedException extends AppException {
  MethodNotAllowedException({required super.message, super.statusCode = 405});
}


''');

    await _createFile('$corePath/error', 'server_message', '''
/// Longest server message we are willing to show to the user.
const int kMaxServerMessageLength = 200;

/// Returns the server's `message` when it is safe to show, otherwise `''`.
///
/// Usable means: the body is a Map and its `message` is a String that is
/// non-empty after trimming and at most [kMaxServerMessageLength] characters.
/// String / HTML bodies, lists and numbers are never used.
String extractServerMessage(dynamic data) {
  if (data is! Map) return '';
  final message = data['message'];
  if (message is! String) return '';
  final trimmed = message.trim();
  if (trimmed.isEmpty || trimmed.length > kMaxServerMessageLength) return '';
  return trimmed;
}

/// Returns `data['errors']` when it is a Map (keys stringified), else `null`.
Map<String, dynamic>? extractValidationErrors(dynamic data) {
  if (data is! Map) return null;
  final errors = data['errors'];
  if (errors is! Map) return null;
  return errors.map((key, value) => MapEntry(key.toString(), value));
}
''');

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
  GlobalResponse({
    this.message,
    this.errors,
    this.code,
  });

  String? message;
  Map<String, dynamic>? errors;
  int? code;

  factory GlobalResponse.fromJson(Map<String, dynamic> json) => GlobalResponse(
        message: json["message"].toString(),
        errors: json["errors"] == null
            ? null
            : Map<String, dynamic>.from(json["errors"]),
        code: json["code"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "errors": errors,
        "code": code,
      };
}
''');

    // Bloc: feature blocs are provided at the route level (created on
    // navigation, disposed on pop) via BlocProvider + sl.
    final routesBlocImports =
        stateManagement == "2"
            ? "import 'package:flutter_bloc/flutter_bloc.dart';\nimport '/core/di/service_locator.dart';\nimport '../../features/homes/presentation/bloc/home_bloc.dart';\n"
            : "";
    final homeRouteWidget =
        stateManagement == "2"
            ? "return BlocProvider(\n          create: (_) => sl<HomeBloc>(),\n          child: const HomePage(),\n        );"
            : "return const HomePage();";
    await _createFile('$corePath/routes', 'app_routes', '''
import 'package:flutter/material.dart';
import '../../features/homes/presentation/pages/home_page.dart';
$routesBlocImports
enum AppRoutes { home }

extension AppRoutesExtention on AppRoutes {
  Widget buildWidget<T extends Object>({T? arguments}) {
    switch (this) {
      case AppRoutes.home:
        $homeRouteWidget
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
        builder: (BuildContext context) =>
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
  static void pop(context, {bool result = false}) {
    return Navigator.pop(context, result);
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
  btnText(Color(0xFF878DB5)),
  textBlue(Color(0xFF28294D)),
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
    await _createFile('$corePath/network', 'network_info', '''
import 'package:connectivity_plus/connectivity_plus.dart';

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
    _isInternet = connectivityResult.isNotEmpty &&
        connectivityResult.any((element) => element != ConnectivityResult.none);
    return _isInternet;
  }

  @override
  Future<List<ConnectivityResult>> getConnectivityStatus() async {
    return await _connectivity.checkConnectivity();
  }
}
''');

    await _createFile('$corePath/network', 'api_client', '''
import 'dart:io';

import 'package:dio/dio.dart';

import '/core/error/exceptions.dart';
import '/core/error/server_message.dart';
import '/core/utils/extension.dart';
import '../../../../core/constants/api_urls.dart';
import '../../../../core/constants/app_constants.dart';
import '../utils/preferences_helper.dart';

/// HTTP methods enum
enum HttpMethod { get, post, put, delete, patch, download }

/// Core API client for making HTTP requests
class ApiClient {
  final Dio _dio;
  final PrefHelper _prefHelper;

  ApiClient({
    required Dio dio,
    required PrefHelper prefHelper,
  })  : _dio = dio,
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
    final deviceOs =
        Platform.isAndroid ? AppConstants.android.key : AppConstants.ios.key;
    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: AppConstants.applicationJson.key,
      AppConstants.appVersion.key:
          _prefHelper.getString(AppConstants.appVersion.key),
      AppConstants.buildNumber.key:
          _prefHelper.getString(AppConstants.buildNumber.key),
      AppConstants.deviceOs.key: deviceOs,
      AppConstants.language.key: _prefHelper.getLanguage() == 1
          ? AppConstants.en.key
          : AppConstants.bn.key,
      AppConstants.deviceId.key:
          _prefHelper.getString(AppConstants.deviceId.key),
      AppConstants.deviceName.key:
          _prefHelper.getString(AppConstants.deviceName.key),
      AppConstants.deviceModel.key:
          _prefHelper.getString(AppConstants.deviceModel.key),
      AppConstants.deviceOsVersion.key:
          _prefHelper.getString(AppConstants.deviceOsVersion.key),
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
    Map<String, List<File>>? files,
    String? fileKeyName,
    String? savePath,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    ResponseConverter<T>? converter,
  }) async {
    // Update headers if needed
    if (extraHeaders != null) {
      _dio.options.headers.addAll(extraHeaders);
    }

    // Create form data
    final formData = FormData.fromMap(queryParameters ?? {});

    // Add files to form data if any
    if (files != null && files.isNotEmpty) {
      for (var entry in files.entries) {
        final key = entry.key;
        final fileList = entry.value;

        if (fileList.isNotEmpty) {
          // If there's only one file for this key, add it directly
          if (fileList.length == 1) {
            formData.files.add(MapEntry(
              key,
              await MultipartFile.fromFile(
                fileList.first.path,
                filename: fileList.first.path.split('/').last,
              ),
            ));
          }
          // If there are multiple files for this key, add them as a list
          else {
            formData.files.addAll(
              await Future.wait(
                fileList.map((file) async {
                  return MapEntry(
                    key,
                    await MultipartFile.fromFile(
                      file.path,
                      filename: file.path.split('/').last,
                    ),
                  );
                }),
              ),
            );
          }
        }
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
            data: formData,
            queryParameters: queryParameters,
            options: Options(headers: extraHeaders),
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpMethod.put:
          response = await _dio.put(
            endpoint,
            data: formData,
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
            data: formData,
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
    }
    // Anything else (FormatException / TypeError from a converter, ...) is
    // propagated as is; handleException maps it without exposing its text.
  }

  /// Error codes our backend may send inside a 2xx body.
  static const _bodyErrorCodes = {401, 405, 422, 429};

  /// Handle response based on status code
  dynamic _handleResponse(Response response) {
    final data = response.data;
    final statusCode = response.statusCode;
    if (statusCode != null && statusCode >= 200 && statusCode < 300) {
      // Our backend can also report an error inside a 2xx body via `code`.
      if (data is Map) {
        final code = int.tryParse(data['code'].toString()) ?? 0;
        if (_bodyErrorCodes.contains(code) || (code >= 500 && code < 600)) {
          throw _exceptionForStatus(code, data);
        }
      }
      return data;
    }
    throw _exceptionForStatus(statusCode, data);
  }

  /// Handle Dio errors
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutException(message: '');
      case DioExceptionType.badResponse:
        final response = e.response;
        if (response == null) return ServerException(message: '');
        'RESPONSE ERROR: \${response.statusCode}'.log();
        return _exceptionForStatus(response.statusCode, response.data);
      case DioExceptionType.cancel:
        return RequestCancelledException(message: '');
      case DioExceptionType.connectionError:
        return NetworkException(message: '');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ServerException(message: '');
    }
  }

  /// Build the exception for an error status. The message is the server's
  /// message when usable (see [extractServerMessage]), otherwise `''` so the
  /// UI shows a localized fallback. 5xx bodies are never shown.
  AppException _exceptionForStatus(int? statusCode, dynamic data) {
    final message = extractServerMessage(data);
    switch (statusCode) {
      case 400:
        return BadRequestException(message: message);
      case 401:
        _prefHelper.setString(AppConstants.token.key, '');
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
      case 405:
        return MethodNotAllowedException(message: message);
      case 422:
        return ValidationException(
          message: message,
          statusCode: 422,
          errors: extractValidationErrors(data),
        );
      case 429:
        return TooManyRequestsException(message: message);
    }
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return ServerException(message: '', statusCode: statusCode);
    }
    return ServerException(message: message, statusCode: statusCode);
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
import '../theme/app_colors.dart';

import '../routes/navigation.dart';

class DateUtil {
  static DateTime? fromDate;
  static bool isToShowPreviousDate = true;
  static bool isToShowFutureDate = false;
  static Future<DateTime?> showDatePickerDialog() async {
    final picked = await showDatePicker(
        builder: (context, child) {
          return Theme(
            data: ThemeData(
              colorScheme: ColorScheme.light(
                primary: AppColors.accent.color,
                onPrimary: AppColors.white.color,
                onSurface: AppColors.black.color,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: AppColors.white.color,
              ),
            ),
            child: child!,
          );
        },
        context: Navigation.key.currentContext!,
        initialDate: DateTime.now(),
        //use to show the previous month
        firstDate: isToShowPreviousDate == true
            ? DateTime(1950, DateTime.december)
            : DateTime.now(),
        lastDate: isToShowFutureDate == true
            ? DateTime(2080, DateTime.december)
            : DateTime.now());

    fromDate = picked;
    return picked;
  }
}


''');

    await _createFile('$corePath/utils', 'validators', '''
  
/// lib/core/utils/validators.dart

class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    final emailRegex = RegExp(r'[a-zA-Z0-9@._\-+]');
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
    final phoneRegex = RegExp(r'^+?[ds-]{10,}\$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter pin';
    }
    return null;
  }

  static String? otp(String? value) {
    if (value!.isEmpty) {
      return "Please enter OTP";
    }
    if (value.length < 6) {
      return "OTP must be at least 6 characters long";
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

  static String? dropdown(dynamic value) {
    if (value == null) {
      return 'Please select a value';
    }
    // If value is a String, check if it's empty
    if (value is String && value.isEmpty) {
      return 'Please select a value';
    }
    return null;
  }
} 
''');

    // Utils
    await _createFile('$corePath/utils', 'preferences_helper', '''

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Singleton class for managing secure storage
/// Uses FlutterSecureStorage under the hood but maintains the same
/// synchronous read API by pre-loading all values into an in-memory cache.
/// Located in core/utils as it's shared across all features
class PrefHelper {
  static PrefHelper? _instance;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// In-memory cache so that getters remain synchronous.
  /// All writes go through to secure storage AND update this cache.
  static Map<String, String> _cache = {};

  // Private constructor
  PrefHelper._();

  /// Get singleton instance
  static PrefHelper get instance {
    _instance ??= PrefHelper._();
    return _instance!;
  }

  /// Initialize secure storage cache
  /// Call this in main() before runApp()
  static Future<void> init() async {
    _cache = await _secureStorage.readAll();
  }

  // String operations
  Future<bool> setString(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      _cache[key] = value;
      return true;
    } catch (_) {
      return false;
    }
  }

  String getString(String key, {String defaultValue = ''}) {
    return _cache[key] ?? defaultValue;
  }

  // Int operations
  Future<bool> setInt(String key, int value) async {
    return setString(key, value.toString());
  }

  int getInt(String key, {int defaultValue = 0}) {
    final value = _cache[key];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  // Bool operations
  Future<bool> setBool(String key, bool value) async {
    return setString(key, value.toString());
  }

  bool getBool(String key, {bool defaultValue = false}) {
    final value = _cache[key];
    if (value == null) return defaultValue;
    return value == 'true';
  }

  // Double operations
  Future<bool> setDouble(String key, double value) async {
    return setString(key, value.toString());
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = _cache[key];
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  // List<String> operations
  Future<bool> setStringList(String key, List<String> value) async {
    // Store as a joined string with a delimiter unlikely to appear in data
    return setString(key, value.join('┃'));
  }

  List<String> getStringList(String key, {List<String>? defaultValue}) {
    final value = _cache[key];
    if (value == null || value.isEmpty) return defaultValue ?? [];
    return value.split('┃');
  }

  // Remove a key
  Future<bool> remove(String key) async {
    try {
      await _secureStorage.delete(key: key);
      _cache.remove(key);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Clear all preferences
  Future<bool> clear() async {
    try {
      await _secureStorage.deleteAll();
      _cache.clear();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Check if key exists
  bool containsKey(String key) {
    return _cache.containsKey(key);
  }

  // Get all keys
  Set<String> getKeys() {
    return _cache.keys.toSet();
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

''');

    await _createFile('$corePath/utils', 'extension', '''
import 'dart:developer' as darttools show log;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '/l10n/app_localizations.dart';
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
  AppLocalizations get loc => AppLocalizations.of(this)!;

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

extension NumGenericExtensions<T extends String> on T? {
  double parseToDouble() {
    if (this?.isEmpty ?? true) {
      return 0.0;
    }
    try {
      return double.parse(this!);
    } catch (e) {
      e.log();
      return 0.0;
    }
  }

  String parseToString() {
    try {
      if (this == null) {
        return '';
      }
      return toString();
    } catch (e) {
      e.log();

      return '';
    }
  }

  int parseToInt() {
    try {
      if (this == null) {
        return 0;
      }
      return int.parse(this!);
    } catch (e) {
      e.log();
      return 0;
    }
  }

  bool parseToBool() {
    if (this?.isEmpty ?? true) {
      return false;
    }
    try {
      return bool.parse(this!);
    } catch (e) {
      e.log();
      return false;
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
  void log() {
    if (kDebugMode) {
      darttools.log(toString());
    }
  }
}

// It will formate the date which will show in our application.
extension FormatedDateExtention on DateTime {
  String get formattedDate =>
      DateFormat(AppConstants.yyyyMmDd.key).format(this);
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
        var sum = double.parse(previous?.toString() ?? '0') +
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

extension FormatDuration on int {
  String formatDuration() {
    int minutes = this ~/ 60;
    int remainingSeconds = this % 60;
    return '0\$minutes:\${remainingSeconds.toString().padLeft(2, '0')}s';
    // if (minutes != 0) {
    //   return '\$minutesm:\${remainingSeconds.toString().padLeft(2, '0')}s';
    // } else {
    //   return '\${remainingSeconds.toString().padLeft(2, '0')}s';
    // }
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
    fontStyle = FontStyle.normal,
    Color? color,
  }) =>
      GoogleFonts.poppins(
        color: color ?? AppColors.textBlue.color,
        fontSize: fontSize.sp,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
      );
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
    // Bloc: register HomeBloc as a factory (new instance per screen/route).
    final blocDiImport =
        stateManagement == "2"
            ? "import '/features/homes/presentation/bloc/home_bloc.dart';\n"
            : "";
    final blocDiRegistration =
        stateManagement == "2"
            ? "\n  // Blocs (factory — one fresh instance per screen/route)\n  sl.registerFactory(() => HomeBloc());\n"
            : "";
    await _createFile('$corePath/di', 'service_locator', '''
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../features/homes/domain/usecases/get_home.dart';
import '/core/network/api_client.dart';
import '/core/network/network_info.dart';
import '/core/utils/preferences_helper.dart';
import '/features/homes/data/datasources/home_remote_datasource.dart';
import '/features/homes/data/datasources/home_local_datasource.dart';
import '/features/homes/data/repositories/home_repository_impl.dart';
import '/features/homes/domain/repositories/home_repository.dart';
$blocDiImport
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );
  sl.registerLazySingleton<PrefHelper>(() => PrefHelper.instance);
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(dio: sl(), prefHelper: sl()),
  );

  // Homes Feature
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetHomes(sl()));
$blocDiRegistration}

''');

    // Bloc: single place to register app-wide (global) blocs.
    if (stateManagement == "2") {
      await _createFile('$corePath/bloc', 'global_bloc_providers', '''
import 'package:flutter_bloc/flutter_bloc.dart';

/// App-wide blocs that must live for the whole app lifecycle
/// (e.g. Auth, Theme, Connectivity). Provided once at the root via
/// MultiBlocProvider in main.dart.
///
/// Feature/screen-scoped blocs must NOT go here — provide those at the route
/// level with `BlocProvider(create: (_) => sl<XBloc>())` in app_routes.dart so
/// they are created on navigation and disposed when the screen is popped.
List<BlocProvider> globalBlocProviders() => [
      // Example:
      // BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
      // BlocProvider<ThemeBloc>(create: (_) => sl<ThemeBloc>()),
    ];
''');
    }

    await _createFile('$corePath/presentation/widgets', 'error_dialog', '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/core/theme/app_colors.dart';
import '/core/presentation/mixins/failure_message.dart';

import 'global_text.dart';

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    super.key,
    required this.erroMsg,
  });

  final List<dynamic> erroMsg;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlobalText(
                str: errorLocalizations(context).error_title,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.btnText.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16.w),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10.h,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(
                erroMsg.length,
                (index) => Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.only(right: 20.w),
                        child: GlobalText(
                          str: erroMsg[index]
                              .toString()
                              .replaceAll("[", "")
                              .replaceAll("]", ""),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.btnText.color,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
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
    return PopScope(
      canPop: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator.adaptive(),
          SizedBox(width: 10.w),
          GlobalText(str: text ?? ''),
        ],
      ),
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
          errorBuilder: (context, exception, stackTrace) =>
              const Icon(Icons.error),
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
          errorBuilder: (context, exception, stackTrace) =>
              const Icon(Icons.error),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.black.color),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
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
 import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '/core/di/service_locator.dart';
import '/core/network/network_info.dart';
import '../../routes/navigation.dart';
import '../../utils/extension.dart';
import '../view_util.dart';
import 'global_network_dialog.dart';

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

    if (Platform.isAndroid) {
      // Listen for connectivity changes
      networkInfo.onConnectivityChanged.listen(_handleConnectivityChange);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> connectivityResult) {
    final isConnected = connectivityResult.isNotEmpty &&
        connectivityResult.any((element) => element != ConnectivityResult.none);

    'isNetworkAvailable ::\$isConnected'.log();

    // If network was connected but now disconnected
    if (_wasConnected && !isConnected) {
      _showNetworkErrorDialog();
    }
    // If network was disconnected but now connected
    else if (!_wasConnected && isConnected) {
      _dismissAllNetworkDialogs();
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

    await _createFile(
      '$corePath/presentation/mixins',
      'error_handler_mixin',
      '''
import 'package:flutter/material.dart';
import '../../routes/navigation.dart';
import '/core/error/failures.dart';
import '/core/presentation/view_util.dart';
import '/core/presentation/widgets/error_dialog.dart';
import '/core/theme/app_colors.dart';
import 'failure_message.dart';

/// A mixin that provides error handling methods for presentation layer
mixin ErrorHandlerMixin {
  /// Show appropriate error UI based on failure type.
  ///
  /// The shown text is the server message when usable, otherwise a
  /// localized fallback (see [FailureMessage.localizedMessage]).
  void handleError(Failure error, {BuildContext? context}) {
    final ctx = context ?? Navigation.key.currentContext;
    if (ctx == null) return;
    final loc = errorLocalizations(ctx);

    if (error is ValidationFailure) {
      _showErrorDialog(resolvedValidationMessages(error, loc), context: ctx);
    } else if (error is TooManyRequestsFailure) {
      _showErrorDialog([error.localizedMessage(loc)], context: ctx);
    } else if (error is AuthenticationFailure) {
      _makeUnauthorizedDecision(error.localizedMessage(loc), context: ctx);
    } else {
      ViewUtil.snackbar(error.localizedMessage(loc), context: ctx);
    }
  }

  /// Make decision for authentication errors
  void _makeUnauthorizedDecision(String message, {BuildContext? context}) {
    // Navigation.pushAndRemoveUntil(
    //   context ?? Navigation.key.currentContext,
    //   appRoutes: AppRoutes.login,
    // );
  }

  /// Show dialog listing the given error messages
  void _showErrorDialog(List<String> messages, {required BuildContext context}) {
    ViewUtil.alertDialog(
      context: context,
      alertBackgroundColor: AppColors.white.color,
      content: ErrorDialog(erroMsg: messages),
    );
  }
}
''',
    );

    await _createFile('$corePath/presentation/mixins', 'failure_message', '''
import 'package:flutter/widgets.dart';

import '/core/error/failures.dart';
import '/core/error/server_message.dart';
import '/l10n/app_localizations.dart';

/// Localizations for error text. Falls back to English when the app has not
/// registered `AppLocalizations.localizationsDelegates`, so error UI never
/// crashes.
AppLocalizations errorLocalizations(BuildContext context) =>
    AppLocalizations.of(context) ?? lookupAppLocalizations(const Locale('en'));

/// Resolves the text to show for a [Failure].
///
/// A non-blank [Failure.message] is a usable server message and is shown as
/// is; otherwise the localized fallback for the failure type is used.
extension FailureMessage on Failure {
  String localizedMessage(AppLocalizations loc) {
    final trimmed = message.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return switch (this) {
      ServerFailure() => loc.error_server,
      NetworkFailure() => loc.error_network,
      TimeoutFailure() => loc.error_timeout,
      TooManyRequestsFailure() => loc.error_too_many_requests,
      DataParsingFailure() => loc.error_data_parsing,
      BadRequestFailure() || MethodNotAllowedFailure() => loc.error_bad_request,
      NotFoundFailure() => loc.error_not_found,
      AuthenticationFailure() => loc.error_session_expired,
      ForbiddenFailure() => loc.error_forbidden,
      ValidationFailure() => loc.error_validation,
      CacheFailure() => loc.error_cache,
      _ => loc.error_unexpected,
    };
  }
}

/// Usable field errors of [failure], or its resolved message when none.
///
/// Only String values (or Strings inside Lists) that are non-blank and at
/// most [kMaxServerMessageLength] characters are kept; nested maps, numbers
/// and over-long text are dropped.
List<String> resolvedValidationMessages(
  ValidationFailure failure,
  AppLocalizations loc,
) {
  final messages = <String>[];
  void addIfUsable(Object? value) {
    if (value is! String) return;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > kMaxServerMessageLength) return;
    messages.add(trimmed);
  }

  for (final value in (failure.errors ?? const {}).values) {
    if (value is List) {
      value.forEach(addIfUsable);
    } else {
      addIfUsable(value);
    }
  }
  return messages.isEmpty ? [failure.localizedMessage(loc)] : messages;
}
''');

    await _createFile('$corePath/presentation', 'view_util', '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/core/presentation/widgets/global_loader.dart';
import '../routes/navigation.dart';
import '../theme/app_colors.dart';
import 'widgets/global_text.dart';

class ViewUtil {
  static snackbar(
    String msg, {
    String? btnName,
    void Function()? onPressed,
    BuildContext? context,
  }) {
    return ScaffoldMessenger.of(context ?? Navigation.key.currentContext!)
        .showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
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
    BuildContext? context,
  }) async {
    // flutter defined function.
    await showDialog(
      context: context ?? Navigation.key.currentContext!,
      barrierDismissible: barrierDismissible ?? true,
      builder: (context) {
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
      builder: (context) => Container(
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

  static showLoader(BuildContext context) {
    return alertDialog(
      context: context,
      alertBackgroundColor: AppColors.white.color,
      content: GlobalLoader(text: 'Loading...'),
    );
  }

  static hideLoader(BuildContext context) {
    Navigation.pop(context);
  }
}

''');
  }

  Future<void> _createFeatureFiles(String featuresPath) async {
    final homesPath = '$featuresPath/homes';

    // Clean data→domain pattern for BOTH Riverpod and Bloc (state-management
    // agnostic, per clean_architecture_pattern.md): entity with defaults, a
    // response DTO that does NOT extend the entity, and DTO→entity mapping in
    // the repository.
    await _createFeatureDomainDataFiles(homesPath);

    // Presentation - State Management Files
    if (stateManagement == "2") {
      // Bloc pattern
      await _createBlocPresentationFiles(homesPath);
    } else {
      // Riverpod pattern (default)
      await _createRiverpodPresentationFiles(homesPath);
    }

    // Presentation - Pages
    if (stateManagement == "2") {
      // Bloc page: dispatches LoadHomes in initState, rebuilds via BlocBuilder.
      await _createFile('$homesPath/presentation/pages', 'home_page', '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/core/presentation/widgets/global_appbar.dart';
import '/core/presentation/widgets/global_text.dart';
import '/core/presentation/widgets/global_loader.dart';
import '../bloc/home_bloc.dart';
import '../bloc/event/home_event.dart';
import '../bloc/state/home_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const LoadHomes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(title: 'Home List'),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return switch (state) {
            HomeLoading() ||
            HomeInitial() => const Center(child: GlobalLoader()),
            HomeError(:final message) => Center(child: GlobalText(str: message)),
            HomeLoaded(:final homes) => Center(
              child: GlobalText(str: 'Loaded \${homes.length} items'),
            ),
          };
        },
      ),
    );
  }
}
''');
    } else {
      await _createFile('$homesPath/presentation/pages', 'home_page', '''
import 'package:flutter/material.dart';
import '/core/presentation/widgets/global_appbar.dart';
import '/core/presentation/widgets/global_text.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(title: 'Home List'),
      body: const Center(child: GlobalText(str: 'Home  List')),
    );
  }
}
''');
    }

    // Presentation - Widgets
    await _createFile('$homesPath/presentation/widgets', 'widget', '''
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

  Future<void> _createRiverpodPresentationFiles(String homesPath) async {
    // State
    await _createFile(
      '$homesPath/presentation/providers/state',
      'home_state',
      '''

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '/core/error/failures.dart';

@immutable
class HomeState extends Equatable{
  final bool isLoading;
  final Failure? failure;

  const HomeState({
    this.isLoading = false,
    this.failure,
  });

  HomeState copyWith({
    bool? isLoading,
    Failure? failure,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [isLoading, failure];
}

''',
    );

    // Provider/Notifier
    await _createFile('$homesPath/presentation/providers', 'home_provider', '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/features/Homes/presentation/providers/state/home_state.dart';

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    return const HomeState();
  }
}

''');
  }

  Future<void> _createBlocPresentationFiles(String homesPath) async {
    // State — sealed, carries the entity in the loaded state
    await _createFile('$homesPath/presentation/bloc/state', 'home_state', '''
import 'package:equatable/equatable.dart';

import '/features/homes/domain/entities/home_entity.dart';

/// State for Home
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<HomeEntity> homes;

  const HomeLoaded(this.homes);

  @override
  List<Object?> get props => [homes];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
''');

    // Event
    await _createFile('$homesPath/presentation/bloc/event', 'home_event', '''
import 'package:equatable/equatable.dart';

/// Events for Home
sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomes extends HomeEvent {
  const LoadHomes();
}

class RefreshHomes extends HomeEvent {
  const RefreshHomes();
}
''');

    // Bloc — resolves the use case via sl and folds the Either into state
    await _createFile('$homesPath/presentation/bloc', 'home_bloc', '''
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/di/service_locator.dart';
import '/core/usecases/usecase.dart';
import '/features/homes/domain/usecases/get_home.dart';
import '/features/homes/presentation/bloc/event/home_event.dart';
import '/features/homes/presentation/bloc/state/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<LoadHomes>(_onLoadHomes);
    on<RefreshHomes>(_onRefreshHomes);
  }

  Future<void> _onLoadHomes(
    LoadHomes event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      final result = await sl<GetHomes>()(NoParams());
      result.fold(
        (failure) => emit(HomeError(failure.message)),
        (data) => emit(HomeLoaded(data)),
      );
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onRefreshHomes(
    RefreshHomes event,
    Emitter<HomeState> emit,
  ) async {
    // Same as load but can be customized
    await _onLoadHomes(const LoadHomes(), emit);
  }
}
''');
  }

  /// Clean data→domain generation shared by Riverpod and Bloc (the pattern is
  /// state-management agnostic). Entity uses non-nullable defaults; the wire
  /// DTO does NOT extend the entity; the repository maps DTO→entity.
  Future<void> _createFeatureDomainDataFiles(String homesPath) async {
    // Domain - Entity (non-nullable defaults, Equatable, no fromJson)
    await _createFile('$homesPath/domain/entities', 'home_entity', '''
import 'package:equatable/equatable.dart';

/// Domain entity — non-nullable with defaults. The repository maps the
/// HomeResponse/HomeData wire DTO into this. Entities never extend models.
class HomeEntity extends Equatable {
  final int id;

  const HomeEntity({this.id = 0});

  @override
  List<Object?> get props => [id];
}
''');

    // Domain - Repository contract
    await _createFile('$homesPath/domain/repositories', 'home_repository', '''
import 'package:dartz/dartz.dart';

import '/core/error/failures.dart';
import '/features/homes/domain/entities/home_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<HomeEntity>>> getHomes();
}
''');

    // Domain - UseCase
    await _createFile('$homesPath/domain/usecases', 'get_home', '''
import 'package:dartz/dartz.dart';
import '/core/error/failures.dart';
import '/core/usecases/usecase.dart';
import '/features/homes/domain/entities/home_entity.dart';
import '/features/homes/domain/repositories/home_repository.dart';

class GetHomes implements UseCase<List<HomeEntity>, NoParams> {
  final HomeRepository _repository;

  GetHomes(this._repository);

  @override
  Future<Either<Failure, List<HomeEntity>>> call(NoParams params) async {
    return await _repository.getHomes();
  }
}
''');

    // Data - Response DTO (nullable, SafeJson, autoSafe.raw top-level only;
    // does NOT extend the entity)
    await _createFile('$homesPath/data/models', 'home_response', '''
import 'package:autosafe_json/autosafe_json.dart';

/// Wire DTO. All fields nullable, decoded with SafeJson. Mapped to HomeEntity
/// inside the repository. Models never extend entities.
class HomeResponse {
  final List<HomeData>? results;

  HomeResponse({this.results});

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    json = json.autoSafe.raw; // top-level sanitise only
    return HomeResponse(
      results: json['results'] == null || json['results'] == ''
          ? []
          : List<HomeData>.from(
              SafeJson.asList(json['results'])
                  .map((x) => HomeData.fromJson(SafeJson.asMap(x))),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'results': results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
      };
}

class HomeData {
  final int? id;

  HomeData({this.id});

  factory HomeData.fromJson(Map<String, dynamic> json) =>
      HomeData(id: SafeJson.asInt(json['id']));

  Map<String, dynamic> toJson() => {'id': id};
}
''');

    // Data - Remote datasource (returns the DTO)
    await _createFile(
      '$homesPath/data/datasources',
      'home_remote_datasource',
      '''
import '/core/network/api_client.dart';
import '/core/constants/api_urls.dart';
import '../models/home_response.dart';

abstract class HomeRemoteDataSource {
  Future<HomeResponse> getHomes();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _apiClient;

  HomeRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<HomeResponse> getHomes() async {
    try {
      final response = await _apiClient.request(
        endpoint: ApiUrl.homes.url,
        method: HttpMethod.get,
      );
      return HomeResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
''',
    );

    // Data - Local datasource (caches the DTO items)
    await _createFile(
      '$homesPath/data/datasources',
      'home_local_datasource',
      '''
import '/core/error/exceptions.dart';
import '../models/home_response.dart';

abstract class HomeLocalDataSource {
  Future<List<HomeData>> getHomes();
  Future<void> cacheHomes(List<HomeData> homes);
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  List<HomeData> _cachedHomes = [];

  @override
  Future<List<HomeData>> getHomes() async {
    if (_cachedHomes.isEmpty) {
      throw CacheException(message: 'No cached data');
    }
    return _cachedHomes;
  }

  @override
  Future<void> cacheHomes(List<HomeData> homes) async {
    _cachedHomes = homes;
  }
}
''',
    );

    // Data - Repository impl (maps DTO -> entity, wrapped in handleException)
    await _createFile(
      '$homesPath/data/repositories',
      'home_repository_impl',
      '''
import 'package:dartz/dartz.dart';

import '/core/error/failures.dart';
import '../../../../core/error/exception_handler.dart';
import '../../domain/entities/home_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  final HomeLocalDataSource _localDataSource;

  HomeRepositoryImpl({
    required HomeRemoteDataSource remoteDataSource,
    required HomeLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<HomeEntity>>> getHomes() async {
    return handleException(() async {
      final response = await _remoteDataSource.getHomes();
      final items = response.results ?? [];
      await _localDataSource.cacheHomes(items);
      // Explicit DTO -> entity mapping with ?? fallbacks.
      return items.map((e) => HomeEntity(id: e.id ?? 0)).toList();
    });
  }
}
''',
    );
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
    } else if (stateManagement == "2") {
      // Add Bloc imports (root MultiBlocProvider + the initial page's feature bloc)
      imports += '''import 'package:flutter_bloc/flutter_bloc.dart';
import '/core/bloc/global_bloc_providers.dart';
import '/features/homes/presentation/bloc/home_bloc.dart';
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
import '/features/homes/presentation/pages/home_page.dart';
import '/l10n/app_localizations.dart';
import 'core/presentation/widgets/app_starter_error.dart';
''';

    // Generate runApp based on state management
    String runAppCode;
    if (stateManagement == "1") {
      runAppCode = '''runApp(const ProviderScope(child: MyApp()));''';
    } else if (stateManagement == "2") {
      runAppCode = '''runApp(
      MultiBlocProvider(providers: globalBlocProviders(), child: const MyApp()),
    );''';
    } else {
      runAppCode = '''runApp(const MyApp());''';
    }

    // The initial page also needs its feature bloc provided. For bloc we wrap
    // the first screen with BlocProvider (same as the route builder does).
    final initialPageReturn =
        stateManagement == "2"
            ? "return BlocProvider(create: (_) => sl<HomeBloc>(), child: const HomePage());"
            : "return const HomePage();";
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
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
    //   return const HomePage();
    // }
    $initialPageReturn
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
    "add_address":"Add Adress",
    "error_title": "Error",
    "error_server": "Something went wrong on our side. Please try again later.",
    "error_network": "No internet connection. Please check your connection and try again.",
    "error_timeout": "The request timed out. Please try again.",
    "error_too_many_requests": "Too many requests. Please wait a moment and try again.",
    "error_data_parsing": "We couldn't read the server's response. Please try again later.",
    "error_bad_request": "The request could not be processed. Please try again.",
    "error_not_found": "The requested information was not found.",
    "error_session_expired": "Your session has expired. Please log in again.",
    "error_validation": "Please check the information you entered.",
    "error_cache": "Couldn't load saved data. Please try again.",
    "error_unexpected": "Something went wrong. Please try again.",
    "error_forbidden": "You don't have permission to do this."


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
     "add_address":"ঠিকানা যোগ করুন",
    "error_title": "ত্রুটি",
    "error_server": "আমাদের দিকে একটি সমস্যা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।",
    "error_network": "ইন্টারনেট সংযোগ নেই। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।",
    "error_timeout": "অনুরোধের সময় শেষ হয়ে গেছে। আবার চেষ্টা করুন।",
    "error_too_many_requests": "অনেক বেশি অনুরোধ করা হয়েছে। কিছুক্ষণ অপেক্ষা করে আবার চেষ্টা করুন।",
    "error_data_parsing": "সার্ভারের উত্তর পড়া যায়নি। কিছুক্ষণ পরে আবার চেষ্টা করুন।",
    "error_bad_request": "অনুরোধটি প্রক্রিয়া করা যায়নি। আবার চেষ্টা করুন।",
    "error_not_found": "অনুরোধ করা তথ্য পাওয়া যায়নি।",
    "error_session_expired": "আপনার সেশনের মেয়াদ শেষ হয়েছে। আবার লগ ইন করুন।",
    "error_validation": "আপনার দেওয়া তথ্য যাচাই করুন।",
    "error_cache": "সংরক্ষিত তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।",
    "error_unexpected": "কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।",
    "error_forbidden": "এই কাজটি করার অনুমতি আপনার নেই।"

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

# Secrets — NEVER commit
.env
.env.*
android/key.properties
android/app/release.jks
android/app/*.jks
ios/Flutter/Secret.xcconfig
lib/core/config/env.g.dart
*.keystore
google-services.json
GoogleService-Info.plist
local.properties
serviceAccountKey.json
*.p12
*.pem
*.cer
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

# Flutter recommended lints
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

      // Add riverpod_lint plugin (riverpod_lint 3.x uses analysis_server_plugin directly)
      if (stateManagement == "1") {
        content += '''
analyzer:
  plugins:
    - riverpod_lint

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
      // create(recursive: true) also creates any missing parent directories
      // (e.g. core/bloc) so new subfolders don't need a matching entry in the
      // directory creator.
      final file = await File(
        '$basePath/$fileName.$fileType',
      ).create(recursive: true);

      final writer = file.openWrite();
      writer.write(content);
      writer.close();
    } catch (e) {
      stderr.write('creating $fileName.$fileType failed! ($e)');
      exit(2);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Security & AI setup files
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _createEnvFiles() async {
    final basePath = Directory.current.path;
    const content =
        r'''# ── API & URLs — read by envied → Dart code via Env.* ────────────────────
BASE_URL_LIVE=https://api.yourapp.com
BASE_URL_DEV=https://dev-api.yourapp.com
BASE_URL_LOCAL=http://192.168.1.100:8000
BASE_IMAGE_URL_LIVE=https://images.yourapp.com
BASE_IMAGE_URL_DEV=https://dev-images.yourapp.com
GOOGLE_MAPS_API_KEY=AIzaSyDUMMY_replace_with_your_real_key
PAYMENT_API_KEY=pk_test_DUMMY_replace_with_your_real_key
SMS_API_KEY=sms_DUMMY_replace_with_your_real_key

# ── Android Keystore ───────────────────────────────────────────────────────
# JKS file must be at: android/app/release.jks
KEYSTORE_PATH=android/app/release.jks
KEYSTORE_PASSWORD=your_keystore_password
KEY_ALIAS=your_key_alias
KEY_PASSWORD=your_key_password

# ── Release Keystore (base64) ──────────────────────────────────────────────
# How to encode: base64 -i android/app/release.jks | tr -d '\n'
# The setup script decodes this → android/app/release.jks (gitignored)
RELEASE_JKS_BASE64=<paste_base64_encoded_jks_here>

# ── Firebase Android ───────────────────────────────────────────────────────
# How to encode: base64 -i android/app/google-services.json | tr -d '\n'
# The setup script decodes this → android/app/google-services.json (gitignored)
GOOGLE_SERVICES_JSON_BASE64=<paste_base64_encoded_google_services_json_here>

# ── Firebase iOS ───────────────────────────────────────────────────────────
# How to encode: base64 -i ios/Runner/GoogleService-Info.plist | tr -d '\n'
# The setup script decodes this → ios/Runner/GoogleService-Info.plist (gitignored)
GOOGLE_SERVICE_INFO_BASE64=<paste_base64_encoded_google_service_info_plist_here>
''';
    try {
      await File('$basePath/.env.example').writeAsString(content);
      await File('$basePath/.env').writeAsString(content);
      '.env and .env.example created successfully'.printWithColor(
        status: PrintType.success,
      );
    } catch (e) {
      stderr.write('creating .env files failed: $e');
    }
  }

  Future<void> _createEnvConfigFile() async {
    final configDir = '${Directory.current.path}/lib/core/config';
    await Directory(configDir).create(recursive: true);
    const content = r'''import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'BASE_URL_LIVE')
  static final String baseUrlLive = _Env.baseUrlLive;

  @EnviedField(varName: 'BASE_URL_DEV')
  static final String baseUrlDev = _Env.baseUrlDev;

  @EnviedField(varName: 'BASE_URL_LOCAL')
  static final String baseUrlLocal = _Env.baseUrlLocal;

  @EnviedField(varName: 'BASE_IMAGE_URL_LIVE')
  static final String baseImageUrlLive = _Env.baseImageUrlLive;

  @EnviedField(varName: 'BASE_IMAGE_URL_DEV')
  static final String baseImageUrlDev = _Env.baseImageUrlDev;

  @EnviedField(varName: 'GOOGLE_MAPS_API_KEY')
  static final String googleMapsApiKey = _Env.googleMapsApiKey;

  @EnviedField(varName: 'PAYMENT_API_KEY')
  static final String paymentApiKey = _Env.paymentApiKey;

  @EnviedField(varName: 'SMS_API_KEY')
  static final String smsApiKey = _Env.smsApiKey;
}
''';
    try {
      await File('$configDir/env.dart').writeAsString(content);
      'lib/core/config/env.dart created successfully'.printWithColor(
        status: PrintType.success,
      );
    } catch (e) {
      stderr.write('creating env.dart failed: $e');
    }
  }
}
