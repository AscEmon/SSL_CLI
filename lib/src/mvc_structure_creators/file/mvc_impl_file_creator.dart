import 'dart:io';
import '../mvc_i_creators.dart';

class MvcImplFileCreator implements IFileCreator {
  final IDirectoryCreator directoryCreator;
  final String projectName;
  MvcImplFileCreator(this.directoryCreator, this.projectName);

  @override
  Future<void> createNecessaryFiles() async {
    print('creating necessary files...');

    //constant folder file
    await _createFile(
      directoryCreator.constantDir.path,
      'app_url',
      content: """import 'package:$projectName/utils/enum.dart';

enum AppUrl {
  base,
  baseImage,

}

extension AppUrlExtention on AppUrl {
  static String _baseUrl = "";
  static String _baseImageUrl = "";

  static void setUrl(UrlLink urlLink) {
    switch (urlLink) {
      case UrlLink.isLive:
        _baseUrl = "";
        _baseImageUrl = "";

        break;

      case UrlLink.isDev:
        _baseUrl = "";
        _baseImageUrl = "";

        break;
      case UrlLink.isLocalServer:
        // set up your local server ip address.
        _baseUrl = "";
        break;
    }
  }

  String get url {
    switch (this) {
      case AppUrl.base:
        return "\$_baseUrl";
      case AppUrl.baseImage:
        return "\$_baseImageUrl";
     
      default:
    }
    return "";
  }
}

""",
    );
    await _createFile(
      directoryCreator.constantDir.path,
      'constant_key',
      content: """enum AppConstant {
  USER_ID,
  TOKEN,
  LANGUAGE,
  YYYY_MM_DD,
  DD_MM_YYYY,
  DD_MM_YYYY_SLASH,
  D_MMM_Y_HM,
  D_MMM_Y,
  D_MM_Y,
  YYYY_MM,
  MMM,
  MMMM,
  MMMM_Y,
  APPLICATION_JSON,
  BEARER,
  MULTIPART_FORM_DATA,
  IS_SWITCHED,
  DEVICE_ID,
  DEVICE_OS,
  USER_AGENT,
  APP_VERSION,
  BUILD_NUMBER,
  ANDROID,
  IOS,
  IPN_URL,
  STORE_ID,
  STORE_PASSWORD,
  MOBILE,
  EMAIL,
  PUSH_ID,
  EN,
  BN,
  FONTFAMILY,
  
}

extension AppConstantExtention on AppConstant {
  String get key {
    switch (this) {
      case AppConstant.USER_ID:
        return "USER_ID";
      case AppConstant.TOKEN:
        return "TOKEN";
      case AppConstant.LANGUAGE:
        return "language";
      case AppConstant.DD_MM_YYYY:
        return "dd-MM-yyyy";
      case AppConstant.DD_MM_YYYY_SLASH:
        return "dd/MM/yyyy hh:mm a";
      case AppConstant.D_MMM_Y_HM:
        return "d MMMM y hh:mm a";
      case AppConstant.D_MM_Y:
        return "d MMM y";
      case AppConstant.D_MMM_Y:
        return "d MMMM y";
      case AppConstant.MMMM_Y:
        return "MMMM y";
      case AppConstant.MMM:
        return "MMM";
      case AppConstant.MMM:
        return "MMMM";
      case AppConstant.YYYY_MM:
        return 'yyyy-MM';
      case AppConstant.YYYY_MM_DD:
        return "yyyy-MM-dd";
      case AppConstant.APPLICATION_JSON:
        return "application/json";
      case AppConstant.BEARER:
        return "Bearer";
      case AppConstant.MULTIPART_FORM_DATA:
        return "multipart/form-data";
      case AppConstant.IS_SWITCHED:
        return "IS_SWITCHED";
      case AppConstant.USER_AGENT:
        return "user-agent";
      case AppConstant.BUILD_NUMBER:
        return "build";
      case AppConstant.DEVICE_ID:
        return "device-id";
      case AppConstant.APP_VERSION:
        return "app-version";
      case AppConstant.DEVICE_OS:
        return "device-os";
      case AppConstant.PUSH_ID:
        return "push-id";
      case AppConstant.ANDROID:
        return "android";
      case AppConstant.IOS:
        return "ios";
      case AppConstant.IPN_URL:
        return "ipn_url";
      case AppConstant.STORE_ID:
        return "store_id";
      case AppConstant.STORE_PASSWORD:
        return "store_password";
      case AppConstant.MOBILE:
        return "mobile";
      case AppConstant.EMAIL:
        return "email";
      case AppConstant.EN:
        return 'en';
      case AppConstant.BN:
        return 'bn';
      case AppConstant.FONTFAMILY:
        return 'Arboria';
    

      default:
        return "";
    }
  }
}



""",
    );

    //dataProvider folder file
    await _createFile(directoryCreator.dataProviderDir.path, 'api_client',
        content: """import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:$projectName/constant/app_url.dart';
import 'package:$projectName/constant/constant_key.dart';
import 'package:$projectName/data_provider/pref_helper.dart';
import 'package:$projectName/global/widget/error_dialog.dart';
import 'package:$projectName/utils/app_routes.dart';
import 'package:$projectName/utils/enum.dart';
import 'package:$projectName/utils/extension.dart';
import 'package:$projectName/utils/navigation.dart';
import 'package:$projectName/utils/network_connection.dart';
import 'package:$projectName/utils/view_util.dart';

class ApiClient {
  Dio _dio = Dio();

  Map<String, dynamic> _header = {};

  bool? isPopDialog;

  _initDio({Map<String, String>? extraHeader}) async {
    final DEVISE_OS =
        Platform.isAndroid ? AppConstant.ANDROID.key : AppConstant.IOS.key;

    _header = {
      HttpHeaders.contentTypeHeader: AppConstant.APPLICATION_JSON.key,
      HttpHeaders.authorizationHeader:
          "\${AppConstant.BEARER.key} \${PrefHelper.getString(AppConstant.TOKEN.key)}",
      AppConstant.APP_VERSION.key:
          PrefHelper.getString(AppConstant.APP_VERSION.key),
      AppConstant.BUILD_NUMBER.key:
          PrefHelper.getString(AppConstant.BUILD_NUMBER.key),
      AppConstant.USER_AGENT.key: DEVISE_OS,
      AppConstant.DEVICE_OS.key: DEVISE_OS,
      AppConstant.LANGUAGE.key: PrefHelper.getLanguage() == 1
          ? AppConstant.EN.key
          : AppConstant.BN.key,
      extraHeader?.keys.first ?? "": extraHeader?.values.first ?? ""
    };

    _dio.options = BaseOptions(
      baseUrl: AppUrl.base.url,
      headers: _header,
      connectTimeout: 60 * 1000 * 3 * 3, //miliseconds
      sendTimeout: 60 * 1000 * 2 * 3,
      receiveTimeout: 60 * 1000 * 2 * 3,
    );
    _initInterceptors();
  }

  void _initInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      print(
          'REQUEST[\${options.method}] => PATH: \${AppUrl.base.url}\${options.path} '
          '=> Request Values: param: \${options.queryParameters}, DATA: \${options.data}, => _HEADERS: \${options.headers}');
      return handler.next(options);
    }, onResponse: (response, handler) {
      print(
          'RESPONSE[\${response.statusCode}] => DATA: \${response.data} URL: \${response.requestOptions.baseUrl}\${response.requestOptions.path}');
      return handler.next(response);
    }, onError: (err, handler) {
      print(
          'ERROR[\${err.response?.statusCode}] => DATA: \${err.response?.data} Message: \${err.message} URL: \${err.response?.requestOptions.baseUrl}\${err.response?.requestOptions.path}');
      return handler.next(err);
    }));
  }

  // Image or file upload using Rest handle.
  Future requestFormData(
      {required String url,
      required Method method,
      Map<String, dynamic>? params,
      bool? isPopGlobalDialog,
      String? token,
      Options? options,
      void Function(int, int)? onReceiveProgress,
      String? savePath,
      List<File>? files,
      String? fileKeyName,
      required onSuccessFunction(
        Response response,
      )}) async {
    final tokenHeader = <String, String>{
      HttpHeaders.contentTypeHeader: AppConstant.MULTIPART_FORM_DATA.key
    };
    _initDio(extraHeader: tokenHeader);

    if (files != null) {
      params?.addAll({
        "\${fileKeyName}": files
            .map((item) => MultipartFile.fromFileSync(item.path,
                filename: item.path.split('/').last))
            .toList()
      });
    }

    final data = FormData.fromMap(params!);
    data.log();
    // Handle and check all the status.
    return clientHandle(
      url,
      method,
      params,
      data: data,
      onSuccessFunction: onSuccessFunction,
    );
  }

  // Normal Rest API  handle.
  Future request(
      {required String url,
      required Method method,
      Map<String, dynamic>? params,
      bool? isPopGlobalDialog,
      String? token,
      Options? options,
      void Function(int, int)? onReceiveProgress,
      String? savePath,
      required onSuccessFunction(
        Response response,
      )}) async {
    final tokenHeader = <String, String>{AppConstant.PUSH_ID.key: token ?? ""};

    if (NetworkConnection.instance.isInternet) {
      // Handle and check all the status.
      isPopDialog = isPopGlobalDialog;
      _initDio(extraHeader: tokenHeader);
      return clientHandle(
        url,
        method,
        params,
        options: options,
        savePath: savePath,
        onReceiveProgress: onReceiveProgress,
        onSuccessFunction: onSuccessFunction,
      );
    } else {
      NetworkConnection.instance.apiStack.add(
        APIParams(
          url: url,
          method: method,
          variables: params ?? {},
          onSuccessFunction: onSuccessFunction,
        ),
      );
      if (ViewUtil.isPresentedDialog == false) {
        ViewUtil.isPresentedDialog = true;
        WidgetsBinding.instance?.addPostFrameCallback(
          (_) {
            ViewUtil.showInternetDialog(
              onPressed: () {
                if (NetworkConnection.instance.isInternet == true) {
                  Navigator.of(Navigation.key.currentState!.overlay!.context,
                          rootNavigator: true)
                      .pop();
                  ViewUtil.isPresentedDialog = false;
                  NetworkConnection.instance.apiStack.forEach(
                    (element) {
                      request(
                        url: element.url,
                        method: element.method,
                        params: element.variables,
                        onSuccessFunction: element.onSuccessFunction,
                      );
                    },
                  );
                  NetworkConnection.instance.apiStack = [];
                }
              },
            );
          },
        );
      }
    }
  }

// Handle all the method and error.
  Future clientHandle(
    String url,
    Method method,
    Map<String, dynamic>? params, {
    dynamic data,
    Options? options,
    String? savePath,
    void Function(int, int)? onReceiveProgress,
    required onSuccessFunction(Response response)?,
  }) async {
    Response response;
    try {
      // Handle response code from api.
      if (method == Method.POST) {
        response = await _dio.post(
          url,
          queryParameters: params,
          data: data,
        );
      } else if (method == Method.DELETE) {
        response = await _dio.delete(url);
      } else if (method == Method.PATCH) {
        response = await _dio.patch(url);
      } else if (method == Method.DOWNLOAD) {
        response = await _dio.download(
          url,
          savePath,
          queryParameters: params,
          options: options,
          onReceiveProgress: onReceiveProgress,
        );
      } else {
        response = await _dio.get(
          url,
          queryParameters: params,
          options: options,
          onReceiveProgress: onReceiveProgress,
        );
      }
      /**
       * Handle Rest based on response json
       * So please check in json body there is any status_code or code
       */
      if (response.statusCode == 200) {
        final Map data = json.decode(response.toString());
        final verifycode = data['code'];
        int code = int.tryParse(verifycode.toString()) ?? 0;
        if (code == 200) {
          if (response.data != null) {
            return onSuccessFunction!(response);
          } else {
            "response data is \${response.data}".log();
          }
        } else if (code == 401) {
          // PrefHelper.setString(AppConstant.TOKEN.key, "").then(
          //   (value) => Navigation.pushAndRemoveUntil(
          //     Navigation.key.currentContext,
          //     appRoutes: AppRoutes.login,
          //   ),
          // );
        } else {
          //Where error occured then pop the global dialog
          response.statusCode?.log();
          code.log();
          isPopDialog?.log();

          List<String>? erroMsg;
          erroMsg = List<String>.from(data["errors"]?.map((x) => x));
          ViewUtil.showAlertDialog(
            barrierDismissible: false,
            content: ErrorDialog(
              erroMsg: erroMsg,
            ),
          ).then((value) {
            if (isPopDialog == true || isPopDialog == null) {
              Navigator.pop(Navigation.key.currentContext!);
            }
          });
          if (isPopDialog == false) {
            throw Exception();
          }
        }
      }

      // Handle Error type if dio catches anything.
    } on DioError catch (e) {
      e.log();

      switch (e.type) {
        case DioErrorType.connectTimeout:
          ViewUtil.SSLSnackbar("Time out delay ");
          throw Exception();
        case DioErrorType.receiveTimeout:
          ViewUtil.SSLSnackbar("Server is not responded properly");
          throw Exception();
        case DioErrorType.other:
          if (e.error is SocketException) {
            throw SocketException("No Internat Available");
          } else {
            ViewUtil.SSLSnackbar("Server is not responded properly");
            throw Exception();
          }
        case DioErrorType.response:
          ViewUtil.SSLSnackbar("Internal Responses error");
          throw Exception(e.toString());
        default:
          ViewUtil.SSLSnackbar("Something went wrong");
          throw Exception("Something went wrong" + e.toString());
      }
    } catch (e) {
      "dioErrorCatch \$e".log();
      throw Exception("Something went wrong" + e.toString());
    }
  }
}


""");
    await _createFile(
      directoryCreator.dataProviderDir.path,
      'graph_client',
      content: """import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as d;
import 'package:flutter/material.dart';
import 'package:$projectName/constant/app_url.dart';
import 'package:$projectName/constant/constant_key.dart';
import 'package:$projectName/data_provider/pref_helper.dart';
import 'package:$projectName/global/model/graph_ql_error_response.dart';
import 'package:$projectName/utils/navigation_service.dart';
import 'package:$projectName/utils/view_util.dart';

class ApiClient {
  late d.Dio _dio;

  Map<String, dynamic> _header = {};

  _initDio() {
    _header = {
      HttpHeaders.contentTypeHeader: AppConstant.APPLICATION_JSON.key,
      HttpHeaders.authorizationHeader: "\${AppConstant.BEARER.key} \${PrefHelper.getString(AppConstant.TOKEN.key)}"
    };

    _dio = d.Dio(
      d.BaseOptions(
        baseUrl: AppUrl.Base.url,
        headers: _header,
        connectTimeout: 1000 * 30,
        sendTimeout: 1000 * 10,
      ),
    );
    _initInterceptors();
  }

  void _initInterceptors() {
    _dio.interceptors.add(d.InterceptorsWrapper(onRequest: (options, handler) {
     debugPrint(
          'REQUEST[\${options.method}] => PATH: \${AppUrl.Base.url}\${options.path} '
          '=> Request Values: param: \${options.queryParameters}, DATA: \${options.data}, => HEADERS: \${options.headers}');
      return handler.next(options);
    }, onResponse: (response, handler) {
      debugPrint(
          'RESPONSE[\${response.statusCode}] => DATA: \${response.data} URL: \${response.requestOptions.baseUrl}\${response.requestOptions.path}');
      return handler.next(response);
    }, onError: (err, handler) {
      debugPrint(
          'ERROR[\${err.response?.statusCode}] => DATA: \${err.response?.data} Message: \${err.message} URL: \${err.response?.requestOptions.baseUrl}\${err.response?.requestOptions.path}');
      return handler.next(err);
    }));
  }

//This requestFormData is actually for REST API
//Usign this we sent multipart file thats why its argument
//is different in request method
  Future requestFormData(String url, Map<String, File>? files,
      {bool isLoaderShowing = false}) async {
    try {
      if (isLoaderShowing) CircularProgressIndicator();

      d.Response response;
      _header[d.Headers.contentTypeHeader] = 'multipart/form-data';
      _initDio();

      Map<String, d.MultipartFile> fileMap = {};
      if (files != null) {
        for (MapEntry fileEntry in files.entries) {
          File file = fileEntry.value;
          fileMap[fileEntry.key] = await d.MultipartFile.fromFile(file.path);
        }
      }

      Map<String, dynamic> params = Map<String, dynamic>();
      params.addAll(fileMap);
      final data = d.FormData.fromMap(params);

      // Handle response code from api
      response = await _dio.post(url, data: data);

      if (isLoaderShowing) Navigation.pop(Navigation.key.currentContext);

      if (response.statusCode == 200) {
        return response;
      } else {
        _showExceptionSnackBar("Something went wrong");
        throw Exception();
      }

      // Handle Error type if dio catches anything
    } on d.DioError catch (e) {
      _dioErrorHandler(isLoaderShowing, e);
    } catch (e) {
      throw Exception();
    }
  }

  //GraphQL client using dio for Mutation and query
  Future request(
      {String body = "",
      String url = '',
      Map<String, dynamic> variables = const {},
      bool isLoaderShowing = false}) async {
    if (isLoaderShowing) const CircularProgressIndicator();

    d.Response response;
    _initDio();

    try {
      String paramJson =
          ''' 
      {
      "query" : "\$body",
      "variables" : \${jsonEncode(variables)}
      }
      '''.replaceAll("", "");

      response = await _dio.post(url, data: paramJson);

      if (isLoaderShowing) Navigation.pop(Navigation.key.currentContext);

      if (response.statusCode == 200) {
        if (response.data['errors'] != null) {
          handleGraphQlError(response);
        } else {
          return response;
        }
      } else {
        _showExceptionSnackBar("Something went wrong");
        throw Exception();
      }

      // Handle Error type if dio catches anything
    } on d.DioError catch (e) {
      _dioErrorHandler(isLoaderShowing, e);
    } catch (e) {
      throw Exception();
    }
  }

  void handleGraphQlError(d.Response response) {
    try {
      final result = GraphQLErrorResponse.fromJson(response.data);

      if (result != null) {
        if (result.errors.isNotEmpty) {
          if (result.errors[0].message == "Invalid User" ||
              result.errors[0].message == "User does not exist") {
            PrefHelper.logout();
            // GetScreen().pushAndRemoveUntil(Navigation.key.currentContext);
          } else {
            _showExceptionSnackBar(result.errors[0].message);
          }
        }
      }
    } catch(e){}
  }

// Handle Error type if dio catches anything
  void _dioErrorHandler(bool isLoaderShowing, d.DioError dioError) {
    if (isLoaderShowing) Navigation.pop(Navigation.key.currentContext);

    switch (dioError.type) {
      case d.DioErrorType.response:
        if (dioError.response != null) {
          if (dioError.response!.statusCode != null) {
            if (dioError.response!.statusCode! == 500) {
              _showExceptionSnackBar("Server Error");
            }
          }
        }

        break;
      case d.DioErrorType.connectTimeout:
        _showExceptionSnackBar("Connection failed!. Please refresh");

        break;
      case d.DioErrorType.sendTimeout:
        break;
      case d.DioErrorType.receiveTimeout:
        break;
      case d.DioErrorType.other:
        if (dioError.error is SocketException) {
          _showExceptionSnackBar("Check your internet connection");
        }
        break;
      default:
        _showExceptionSnackBar("Something went wrong!");
    }
  }

  static _showExceptionSnackBar(String? msg) async {
    ViewUtil.SSLSnackbar(msg ?? "");
  }
}

 
 """,
    );

    await _createFile(directoryCreator.dataProviderDir.path, 'pref_helper',
        content: """import 'package:$projectName/constant/constant_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefHelper {

  static Future<SharedPreferences> get _instance async =>
      _prefsInstance ??= await SharedPreferences.getInstance();
  static SharedPreferences? _prefsInstance;

  static Future<SharedPreferences> init() async {
    _prefsInstance = await _instance;
    return _prefsInstance!;
  }

  static Future setString(String key, String value) async {
    var _pref = await _instance;
    await _pref.setString(key, value);
  }

  static Future setInt(String key, int value) async {
    var _pref = await _instance;
    await _pref.setInt(key, value);
  }

  static Future setBool(String key, bool value) async {
    var _pref = await _instance;
    await _pref.setBool(key, value);
  }

  static Future setDouble(String key, double value) async {
    var _pref = await _instance;
    await _pref.setDouble(key, value);
  }

  static Future setStringList(String key, List<String> value) async {
    var _pref = await _instance;
    await _pref.setStringList(key, value);
  }

  static getString(String key, [String defaultValue = ""]) {
    return _prefsInstance?.getString(key) ?? defaultValue;
  }

  static getInt(String key) {
    return _prefsInstance?.getInt(key) ?? 0;
  }

  static getBool(String key) {
    return _prefsInstance?.getBool(key) ?? false;
  }

  static getDouble(String key) {
    return _prefsInstance?.getDouble(key) ?? 0.0;
  }

  static getStringList(String key) {
    return _prefsInstance?.getStringList(key) ?? <String>[];
  }

  static getLanguage() {
    return _prefsInstance?.getInt(AppConstant.LANGUAGE.key) ?? 1;
  }

  static void logout() {
    final languageValue = getLanguage();
    _prefsInstance?.clear();
    _prefsInstance?.setInt(AppConstant.LANGUAGE.key, languageValue);
  }

  static bool isLoggedIn() {
    return (_prefsInstance?.getInt(AppConstant.USER_ID.key) ?? -1) > 0;
  }
}

""");

//global model folder
    await _createFile(
      directoryCreator.globalDir.path + '/model',
      'graph_ql_error_response',
      content: """class GraphQLErrorResponse {
  GraphQLErrorResponse({
    required this.errors,
  });

  late final List<Errors> errors;

  GraphQLErrorResponse.fromJson(Map<String, dynamic> json) {
    errors = List.from(json['errors']).map((e) => Errors.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['errors'] = errors.map((e) => e.toJson()).toList();
    return _data;
  }
}

class Errors {
  Errors({
    required this.message,
  });

  late final String message;

  Errors.fromJson(Map<String, dynamic> json) {
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['message'] = message;
    return _data;
  }
}
""",
    );
    //global model folder
    await _createFile(
      directoryCreator.globalDir.path + '/model',
      'global_response',
      content: """class GlobalResponse {
  GlobalResponse({
    this.message,
    this.errors,
    this.code,
  });

  String? message;
  List<String>? errors;
  int? code;

  factory GlobalResponse.fromJson(Map<String, dynamic> json) => GlobalResponse(
        message: json["message"],
        errors: json["errors"] == null
            ? null
            : List<String>.from(json["errors"].map((x) => x)),
        code: json["code"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "errors":
            errors == null ? null : List<dynamic>.from(errors!.map((x) => x)),
        "code": code,
      };
}

""",
    );

    //global model folder
    await _createFile(
      directoryCreator.globalDir.path + '/model',
      'global_paginator',
      content: """class GlobalPaginator {
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
        currentPage: json["current_page"] == null ? null : json["current_page"],
        totalPages: json["total_pages"] == null ? null : json["total_pages"],
        recordPerPage:
            json["record_per_page"] == null ? null : json["record_per_page"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage == null ? null : currentPage,
        "total_pages": totalPages == null ? null : totalPages,
        "record_per_page": recordPerPage == null ? null : recordPerPage,
      };
}

""",
    );

    await _createFile(
        directoryCreator.globalDir.path + '/widget', 'global_appbar',
        content: '''
  import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/styles/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color backgroundColor = KColor.secondary.color;
  final String title;
  final bool? centerTitle;
  final List<Widget>? actions;

  GlobalAppBar({
    Key? key,
    required this.title,
    this.centerTitle,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: KColor.white.color,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => new Size.fromHeight(56.h);
}


 ''');
    await _createFile(
        directoryCreator.globalDir.path + '/widget', 'error_dialog',
        content: '''
  import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:$projectName/constant/constant_key.dart';
import 'package:$projectName/global/widget/global_text.dart';
import 'package:$projectName/utils/navigation.dart';

import '../../utils/styles/styles.dart';

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    Key? key,
    required this.erroMsg,
  }) : super(key: key);

  final List<String> erroMsg;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
              InkWell(
              onTap: () {
                Navigation.pop(Navigation.key.currentContext);
              },
              child: const Icon(Icons.close),
            ),
          ],
        ),
        SizedBox(
          height: 10.h,
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(left: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              erroMsg.length,
              (index) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.only(right: 30..w),
                      child: GlobalText(
                        str: "\${erroMsg[index].toString()}",
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff999999),
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
    );
  }
}

 ''');

    await _createFile(
        directoryCreator.globalDir.path + '/widget', 'global_button',
        content: '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:$projectName/global/widget/global_text.dart';

import '../../utils/styles/styles.dart';

class GlobalButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final bool isRounded;
  final double? btnHeight;
  final int roundedBorderRadius;
  final Color? btnBackgroundActiveColor;
  final double? textFontSize;

  GlobalButton({
    Key? key,
    required this.onPressed,
    required this.buttonText,
    this.isRounded = true,
    this.btnHeight,
    this.roundedBorderRadius = 17,
    this.btnBackgroundActiveColor,
    this.textFontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color btnColor = btnBackgroundActiveColor ?? KColor.accent.color;

    return ElevatedButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.resolveWith<OutlinedBorder>(
          (states) {
            return RoundedRectangleBorder(
              borderRadius: isRounded
                  ? BorderRadius.circular(
                      roundedBorderRadius.r,
                    )
                  : BorderRadius.zero,
            );
          },
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) =>
              onPressed != null ? btnColor : KColor.divider.color,
        ),
        elevation: MaterialStateProperty.resolveWith(
          (states) => 0.0,
        ),
      ),
      onPressed: onPressed,
      child: Container(
        height: btnHeight ?? 76.h,
        child: Center(
          child: GlobalText(
            str: buttonText,
            fontWeight: FontWeight.w500,
            fontSize: textFontSize ?? 14,
            color: KColor.white.color,
          ),
        ),
      ),
    );
  }
}



 ''');
    await _createFile(
        directoryCreator.globalDir.path + '/widget', 'global_textformfield',
        content: '''
import 'package:flutter/material.dart';
import 'package:$projectName/utils/styles/k_text_style.dart';
import 'package:$projectName/utils/styles/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GlobalTextFormField extends StatelessWidget {
  final bool? obscureText;
  final TextInputType? textInputType;
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
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final bool? mandatoryLabel;
  final TextStyle? style;
  final int? line;
  final String? initialValue;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;

  const GlobalTextFormField({
    Key? key,
    this.obscureText,
    this.textInputType,
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
    this.hintStyle,
    this.mandatoryLabel,
    this.labelStyle,
    this.line = 1,
    this.style,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: line,
      style: style == null ? KTextStyle.customTextStyle() : style,
      autovalidateMode: autovalidateMode,
      obscureText: obscureText ?? false,
      obscuringCharacter: '*',
      controller: controller,
      textInputAction: textInputAction,
      cursorColor: KColor.black.color,
      keyboardType: textInputType ?? TextInputType.text,
      onChanged: onChanged,
      maxLength: maxlength,
      onEditingComplete: () => FocusScope.of(context).nextFocus(),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(
          top: 24.h,
          bottom: 24.h,
          left: 14.w,
        ),
        prefixIcon: prefixIcon,

        hintText: hintText,
        label: mandatoryLabel == true
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(labelText ?? "", style: KTextStyle.customTextStyle()),
                  const Text('*', style: TextStyle(color: Colors.red)),
                ],
              )
            : Text(labelText ?? "", style: KTextStyle.customTextStyle()),
        // labelText: labelText,
        labelStyle: labelStyle,
        filled: true,
        counterText: "",

        fillColor: KColor.formtextFill.color,
        suffixIcon: suffixIcon,
        hintStyle: hintStyle == null
            ? KTextStyle.customTextStyle(fontSize: 13.sp)
            : hintStyle,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(
            Radius.circular(8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: KColor.primary.color, width: 1.w),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: KColor.red.color, width: 1.w),
          borderRadius: BorderRadius.all(
            Radius.circular(
              8,
            ),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: KColor.red.color, width: 1.w),
          borderRadius: BorderRadius.all(
            Radius.circular(
              8,
            ),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xffE0E0E0), width: 1.w),
        ),
      ),
      validator: validator,
      readOnly: readOnly ?? false,
    );
  }
}


 ''');

    await _createFile(
        directoryCreator.globalDir.path + '/widget', 'global_text',
        content: '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:$projectName/constant/constant_key.dart';

class GlobalText extends StatelessWidget {
  final String str;
  final FontWeight fontWeight;
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

  const GlobalText({
    Key? key,
    required this.str,
    required this.fontWeight,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      str,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softwrap,
      style: TextStyle(
        color: color ?? Colors.black,
        fontSize: fontSize?.sp,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        decoration: decoration,
        height: height,
        fontStyle: fontStyle,
        fontFamily: fontFamily ?? AppConstant.FONTFAMILY.key,
      ),
    );
  }
}

 ''');

    await _createFile(
        directoryCreator.globalDir.path + '/widget', 'global_dropdown',
        content: '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/styles/styles.dart';

class GlobalDropdown extends StatelessWidget {
  const GlobalDropdown({
    Key? key,
    required this.validator,
    required this.hintText,
    required this.onChanged,
    required this.items,
  }) : super(key: key);

  final String? Function(Object?)? validator;
  final String? hintText;
  final void Function(Object?)? onChanged;
  final List<DropdownMenuItem<Object>>? items;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      menuMaxHeight: 200,
      validator: validator,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xff9ea1a6),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: KColor.fill.color,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: KColor.enableBorder.color, width: 1.w),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: KColor.red.color, width: 1.w),
          borderRadius: BorderRadius.circular(12.r),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: KColor.red.color, width: 1.w),
          borderRadius: BorderRadius.circular(12.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: KColor.divider.color, width: 1.w),
        ),
      ),
      isExpanded: true,
      hint: Text(
        "\$hintText",
        style: TextStyle(
          color: KColor.grey.color,
          fontSize: 18.sp,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
      ),
      onChanged: onChanged,
      items: items,
    );
  }
}


 ''');

    await _createFile(
        directoryCreator.globalDir.path + '/widget', 'global_loader',
        content: '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GlobalLoader extends StatelessWidget {
  const GlobalLoader({Key? key, this.text = "Loading..."}) : super(key: key);
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
      const  CircularProgressIndicator.adaptive(),
        SizedBox(width: 10.w),
        Text(text ?? "")
      ],
    );
  }
}

 ''');

    await _createFile(
        directoryCreator.globalDir.path + '/widget', 'global_svg_loader',
        content: '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:$projectName/utils/enum.dart';
import 'package:$projectName/utils/extension.dart';

class GlobalSvgLoader extends StatelessWidget {
  const GlobalSvgLoader({
    Key? key,
    required this.imagePath,
    this.height,
    this.width,
    this.fit,
    this.color,
    required this.svgFor,
  }) : super(key: key);
  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final SvgFor svgFor;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    if (svgFor == SvgFor.network) {
      return SvgPicture.network(
        imagePath,
        height: height,
        width: width,
        fit: fit ?? BoxFit.scaleDown,
        color: color,
        placeholderBuilder: (BuildContext context) => centerCircularProgress(),
      );
    } else {
      return SvgPicture.asset(
        imagePath,
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
        color: color,
      );
    }
  }
}

 ''');

    await _createFile(
        directoryCreator.globalDir.path + '/widget', 'global_image_loader',
        content: '''
import 'package:flutter/material.dart';
import 'package:$projectName/utils/enum.dart';

class GlobalImageLoader extends StatelessWidget {
  const GlobalImageLoader({
    Key? key,
    required this.imagePath,
    required this.imageFor,
    this.height,
    this.width,
    this.fit,
  }) : super(key: key);
  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final ImageFor imageFor;
  @override
  Widget build(BuildContext context) {
    if (imageFor == ImageFor.network) {
      return Image.network(
        imagePath,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, exception, stackTrace) => const Text('😢'),
      );
    } else {
      return Image.asset(
        imagePath,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, exception, stackTrace) => const Text('😢'),
      );
    }
  }
}

 ''');

    //localization file
    await _createFile(
      directoryCreator.l10nDir.path,
      'intl_bn',
      fileExtention: 'arb',
      content: """{
    "logout_button": "লগ আউট",
    "note": "বিঃদ্রঃ",
    "cancel": "বাতিল করুন",
    "yes": "হ্যাঁ",
    "delete": "মুছে ফেলা",
    "item": "আপনার কাছে %d টি আইটেম আছে",
     "add_address":"ঠিকানা যোগ করুন"

}""",
    );

    await _createFile(
      directoryCreator.l10nDir.path,
      'intl_en',
      fileExtention: 'arb',
      content: """{

    "logout_button": "Log out",
    "note": "Note",
    "cancel": "Cancel",
    "yes": "Yes",
    "delete": "Delete",
    "item": "You have %d item",
    "add_address":"Add Adress"


}""",
    );

    //MVC  module file
    await _createFile(
      directoryCreator.moduleDir.path + '/module_name' + '/controller',
      'controller_name',
    );
    await _createFile(
      directoryCreator.moduleDir.path + '/module_name' + '/model',
      'model_class_name',
    );
    await _createFile(
        directoryCreator.moduleDir.path + '/module_name' + '/views',
        'screen_name',
        content: """
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Container(child: Text("Project Setup"),),),);
  }
}

""");
    await _createFile(
      directoryCreator.moduleDir.path +
          '/module_name' +
          '/views' +
          '/components',
      'widget_name',
    );

//Utils file

    await _createFile(directoryCreator.utilsDir.path, 'extension',
        content: """import 'dart:developer' as darttools show log;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'
    show AppLocalizations;
//import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:$projectName/constant/constant_key.dart';
import 'package:$projectName/data_provider/pref_helper.dart';
import 'package:intl/intl.dart';

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
      input = input.replaceAll(args[i], "\${values[i]}");
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

//Customly call a provider for read method only
//It will be helpful for us for calling the read function
//without Consumer,ConsumerWidget or ConsumerStatefulWidget
//Incase if you face any issue using this then please wrap your widget
//with consumer and then call your provider

  // T read<T>(ProviderBase<T> provider) {
  //   return ProviderScope.containerOf(this, listen: false).read(provider);
  // }
}

extension validationExtention on String {
  //Check email is valid or not
  bool get isValidEmail => RegExp(
          r"[a-z0-9!#\$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#\$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
      .hasMatch(this);

  //check mobile number contain special character or not
  bool get isMobileNumberValid =>
      RegExp(r'(^(?:[+0]9)?[0-9]{10,12}\$)').hasMatch(this);
}

extension NumGenericExtensions<T extends String> on T {
  double parseToDouble() {
    try {
      return double.parse(this);
    } catch (e) {
      e.log;

      return 0.0;
    }
  }

  String parseToString() {
    try {
      return this.toString();
    } catch (e) {
      e.log();

      return "";
    }
  }
}

extension VersionCheck on String {
  bool isVersionGreaterThan(String currentVersion) {
    String serverVersion = this;
    String currentV = "\${currentVersion}".replaceAll(".", "");
    String serverV = "\${serverVersion}".replaceAll(".", "");
    debugPrint("serverV \${serverV}");
    debugPrint("currentV \${currentV}");
    return int.parse(serverV) > int.parse(currentV);
  }
}

extension WidgetExtention on Widget {
  Widget centerCircularProgress({Color? progressColor}) => Center(
        child: Container(
          //using adaptive we can easily show platfrom base indicator
          child: CircularProgressIndicator.adaptive(
            backgroundColor: progressColor,
          ),
        ),
      );
}

extension Log on Object {
  void log() => darttools.log(toString());
}

// It will formate the date which will show in our application.
extension FormatedDateExtention on DateTime {
  String get formattedDate => DateFormat(AppConstant.MMM.key).format(this);
}

extension FormatedDateExtentionString on String {
  String formattedDate(String format) {
    DateTime parsedDate = DateTime.parse(this);
    return DateFormat(format).format(parsedDate);
  }
}

extension FormattedYearMonthDate on String? {
  DateTime fomateDateFromString({String? dateFormat}) {
    return DateFormat(dateFormat ?? AppConstant.YYYY_MM.key).parse(this ?? "");
  }
}

//This extention sum the value from List<Map<String,dynamic>>
extension StringToDoubleFoldExtention<T extends List<Map<String, dynamic>>>
    on T {
  String? get listOfMapStringSum => this
          .map((e) => double.tryParse(e.values.first?.toString() ?? ""))
          .toList()
          .fold("0", (previous, current) {
        var sum = double.parse(previous?.toString() ?? "0") +
            double.parse(current?.toString() ?? "0");
        return sum.toString().parseToDouble().toStringAsFixed(3);
      });
}

//It will capitalize the first letter of the String.
extension CapitalizeExtention on String {
  String toCapitalized() =>
      length > 0 ? '\${this[0].toUpperCase()}\${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}

extension LastPathComponent on String {
  String get lastPathComponent => this.split('/').last.replaceAll("_", "");
}

""");
    await _createFile(directoryCreator.utilsDir.path + '/styles', 'k_assets',
        content: """enum KAssetName {
  oil,
  close_bottom,
}

extension AssetsExtention on KAssetName {
  String get imagePath {
    String _rootPath = 'assets';
    String _svgDir = '\$_rootPath/svg';
    String _imageDir = '\$_rootPath/images';

    switch (this) {
      case KAssetName.oil:
        return "\$_imageDir/oil.png";
      case KAssetName.close_bottom:
        return "\$_svgDir/close_bottom.svg";

      default:
        return "";
    }
  }
}

""");
    await _createFile(directoryCreator.utilsDir.path + '/styles', 'k_colors',
        content: """import 'package:flutter/material.dart';


enum KColor {
  primary,
  secondary,
  accent,
  red,
  white,
  black,
  grey,
  divider,
  fill,
  transparent,
  enableBorder,
  fromText,
  statusBar,
  addbtn,
  formtextFill,
  dashBack,
  drawerHeader,
  dropDownfill,
  bookingText,
}

extension KColorExtention on KColor {
  Color get color {
    switch (this) {
      case KColor.primary:
        return Colors.blue;
      case KColor.secondary:
        return Color(0xff5EA7FF);
      case KColor.accent:
        return Colors.blue;
      case KColor.red:
        return Color(0xffE42B2B);
      case KColor.grey:
        return Color.fromARGB(255, 157, 157, 157);
      case KColor.addbtn:
        return Color(0xFFA8CFFF);
      case KColor.black:
        return Colors.black;
      case KColor.divider:
        return Color(0xffE6E6E6);
      case KColor.enableBorder:
        return Color(0xffE0E0E0);
      case KColor.fill:
        return Color.fromARGB(255, 247, 246, 246);
      case KColor.fromText:
        return Color(0xff7B7A7A);
      case KColor.white:
        return Colors.white;
      case KColor.statusBar:
        return Color(0xff3E95FF);
      case KColor.transparent:
        return Colors.transparent;
      case KColor.formtextFill:
        return Color(0xffFCFCFC);
      case KColor.drawerHeader:
        return Color(0xFF5EA7FF);
      case KColor.dropDownfill:
        return Color(0xFFFCFCFC);
      case KColor.dashBack:
        return Color(0xffF8F8F8);
      case KColor.bookingText:
        return Color(0xff808080);
      default:
        return Colors.blue;
    }
  }
}
""");

    await _createFile(
        directoryCreator.utilsDir.path + '/styles', 'k_text_style',
        content: """import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'styles.dart';

class KTextStyle {
  static TextStyle customTextStyle(
          {double fontSize = 12, fontWeight = FontWeight.normal}) =>
      GoogleFonts.poppins(
        color: KColor.fromText.color,
        fontSize: fontSize.sp,
        fontWeight: fontWeight,
      );
}
""");

    await _createFile(directoryCreator.utilsDir.path + '/styles', 'styles',
        content: """export 'k_colors.dart';
export 'k_text_style.dart';
export 'k_assets.dart';
""");
    await _createFile(directoryCreator.utilsDir.path, 'app_routes',
        content: """import 'package:flutter/material.dart';
        import 'package:$projectName/module/module_name/views/screen_name.dart';

enum AppRoutes {
  dashboard,
  
}

extension AppRoutesExtention on AppRoutes {
  Widget buildWidget<T extends Object>({T? arguments}) {
    switch (this) {
      case AppRoutes.dashboard:
        return DashboardScreen();
    
    }
  }
}

""");

    await _createFile(directoryCreator.utilsDir.path, 'app_version',
        content: """import 'package:$projectName/constant/constant_key.dart';
import 'package:$projectName/data_provider/pref_helper.dart';
import 'package:$projectName/utils/extension.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  static String currentVersion = "";
  static String versionCode = "";
  static Future<void> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    currentVersion = packageInfo.version;
    versionCode = packageInfo.buildNumber;
    await PrefHelper.setString(AppConstant.APP_VERSION.key, currentVersion);
    await PrefHelper.setString(AppConstant.BUILD_NUMBER.key, versionCode);
    "Current version is  \${currentVersion.toString()}".log();
    "App version Code is  \${versionCode.toString()}".log();
  }
}


""");

    await _createFile(directoryCreator.utilsDir.path, 'date_util',
        content: """import 'package:flutter/material.dart';
import 'package:$projectName/utils/navigation.dart';

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


""");

    await _createFile(directoryCreator.utilsDir.path, 'enum',
        content: """enum LanguageOption {
  Bangla,
  English,
}



enum Method {
  POST,
  GET,
  PUT,
  DELETE,
  PATCH,
  DOWNLOAD,
}

enum UrlLink {
  isLive,
  isDev,
  isLocalServer,
}

enum ImageFor {
  asset,
  network,
}
enum SvgFor {
  asset,
  network,
}


""");

    await _createFile(directoryCreator.utilsDir.path, 'navigation',
        content: """import 'package:flutter/material.dart';
import 'package:$projectName/utils/app_routes.dart';

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
        builder: (context) => appRoutes.buildWidget(
          arguments: arguments,
        ),
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
        builder: (context) => appRoutes.buildWidget(
          arguments: arguments,
        ),
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
        builder: (BuildContext context) => appRoutes.buildWidget(
          arguments: arguments,
        ),
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
        builder: (context) => appRoutes.buildWidget(
          arguments: arguments,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  // when you remove previous x count of  route
  //from stack then please use this way
  //E.g : if you remove 3 route from stack then pass the argument to 3
  static popUntil(context, int removeProviousPage) {
    int screenPop = 0;
    return Navigator.of(context)
        .popUntil((_) => screenPop++ >= removeProviousPage);
  }

  //Remove single page from stack
  static void pop(context) {
    return Navigator.pop(context);
  }
}

""");
    await _createFile(directoryCreator.utilsDir.path, 'network_connection',
        content: """import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:$projectName/utils/enum.dart';

class NetworkConnection {
  static NetworkConnection? _instance;

  NetworkConnection._();

  static NetworkConnection get instance => _instance ??= NetworkConnection._();
  bool isInternet = true;

  InternetAvailable() async {
    StreamSubscription<ConnectivityResult> subscription;

    subscription = await Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      // Got a new connectivity status!
      if (result == ConnectivityResult.none) {
        isInternet = false;
      } else {
        isInternet = true;
      }
    });
  }

  List<APIParams> apiStack = [];
}

//check api params for calling the api while internet will be available
class APIParams {
  String url;
  Method method;
  Map<String, dynamic> variables;
  Function(Response<dynamic>) onSuccessFunction;

  APIParams({
    required this.url,
    required this.method,
    required this.variables,
    required this.onSuccessFunction,
  });
}


""");
    await _createFile(directoryCreator.utilsDir.path, 'view_util', content: """
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:$projectName/global/widget/global_button.dart';
import 'package:$projectName/global/widget/global_text.dart';
import 'package:$projectName/utils/navigation.dart';
import 'package:$projectName/utils/styles/styles.dart';

class ViewUtil {
  static SSLSnackbar(
    String msg, {
    String? btnName,
    void Function()? onPressed,
  }) {
    /**
     * Using ScaffoldMessenger we can easily access
     * this snackbar from anywhere
     */

    return ScaffoldMessenger.of(Navigation.key.currentContext!).showSnackBar(
      SnackBar(
        content: GlobalText(
          str: msg,
          fontWeight: FontWeight.w500,
          color: KColor.white.color,
        ),
        action: SnackBarAction(
          label: btnName ?? "",
          textColor: btnName == null ? Colors.transparent : KColor.white.color,
          onPressed: onPressed ?? () {},
        ),
      ),
    );
  }

  // this varialble is for internet connection check.
  static bool isPresentedDialog = false;
  static showInternetDialog({
    required VoidCallback onPressed,
  }) async {
    // flutter defined function.
    await showDialog(
      context: Navigation.key.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // return object of type Dialog.
        return AlertDialog(
          title: GlobalText(
            str: "Connection Error",
            fontWeight: FontWeight.w500,
          ),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              GlobalText(
                str: "Your internet connection appears to be offline",
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w500,
              ),
              SizedBox(
                height: 25.h,
              ),
              GlobalButton(
                btnHeight: 25.h,
                onPressed: onPressed,
                buttonText: "Try Again",
                textFontSize: 12,
              )
            ],
          ),
        );
      },
    );
  }

// global alert dialog
  static Future showAlertDialog({
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
          backgroundColor: alertBackgroundColor,
          contentPadding: contentPadding ??
              EdgeInsets.fromLTRB(
                24.0,
                20.0,
                24.0,
                24.0,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ??
                BorderRadius.all(
                  Radius.circular(8.w),
                ),
          ),
          title: title,
          content: content,
          actions: actions,
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
              offset: Offset(0, 1),
              blurRadius: 3.r,
              spreadRadius: 0,
            )
          ],
          color: const Color(0xffffffff),
        ),
        child: content,
      ),
    );
  }
}


""");
    await _createFile(
      'lib',
      'main',
      content: """
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//localization
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:$projectName/constant/app_url.dart';
import 'package:$projectName/constant/constant_key.dart';
import 'package:$projectName/data_provider/pref_helper.dart';
import 'package:$projectName/module/module_name/views/screen_name.dart';
import 'package:$projectName/utils/app_version.dart';
import 'package:$projectName/utils/enum.dart';
import 'package:$projectName/utils/navigation.dart';
import 'package:$projectName/utils/network_connection.dart';
import 'package:$projectName/utils/styles/k_colors.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServices();                                                                                                                                                                                                                                                           
  //Set Potraite Mode only
  await SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );
  runApp(MyApp());
}

/// Make sure you always init shared pref first. It has token and token is need
/// to make API call
initServices() async {
  AppUrlExtention.setUrl(
    UrlLink.isDev,
  );
  await PrefHelper.init();
  await AppVersion.getVersion();
  await NetworkConnection.instance.InternetAvailable();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    return ScreenUtilInit(
      //Change the height and Width based on design 
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (ctx, child) {
        return MaterialApp(
          title: '$projectName',
          navigatorKey: Navigation.key,
          debugShowCheckedModeBanner: false,
          //localization
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: (PrefHelper.getLanguage() == 1)
              ? const Locale('en', 'US')
              : const Locale('bn', 'BD'),
          theme: ThemeData(
            progressIndicatorTheme: ProgressIndicatorThemeData(
              color: KColor.secondary.color,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
            primaryColor: KColor.primary.color,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            colorScheme: ThemeData().colorScheme.copyWith(
                  secondary: KColor.secondary.color,
                ),
            primarySwatch: KColor.primary.color as MaterialColor,
          ),
          home: child,
        );
      },
      child: DashboardScreen()
    );
  }
}

""",
    );

    //localization yaml file create in project folder
    await _createFile(Directory.current.path, 'l10n',
        fileExtention: 'yaml', content: """arb-dir: lib/l10n
template-arb-file: intl_en.arb
output-localization-file: app_localizations.dart
""");

    // Create .gitignore
    await _createGitignoreFile();
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

# Config files with sensitive data
config.json
''');
      writer.close();
      print('.gitignore created successfully');
    } catch (e) {
      stderr.write('creating .gitignore failed: $e');
    }
  }

  Future<void> _createFile(
    String basePath,
    String fileName, {
    String? content,
    String? fileExtention = 'dart',
  }) async {
    String fileType;
    if (fileExtention == 'yaml') {
      fileType = 'yaml';
    } else if (fileExtention == 'arb') {
      fileType = 'arb';
    } else {
      fileType = 'dart';
    }

    try {
      final file = await File('$basePath/$fileName.$fileType').create();

      if (content != null) {
        final writer = file.openWrite();
        writer.write(content);
        writer.close();
      }
    } catch (_) {
      stderr.write('creating $fileName.$fileType failed!');
      exit(2);
    }
  }
}
