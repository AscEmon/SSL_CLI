import 'dart:io';
import '../i_creators.dart';

class ImplFileCreator implements IFileCreator {
  final IDirectoryCreator directoryCreator;
  final String projectName;
  ImplFileCreator(this.directoryCreator, this.projectName);

  @override
  Future<void> createNecessaryFiles() async {
    print('creating necessary files...');

    //constant folder file
    await _createFile(
      directoryCreator.constantDir.path,
      'app_url',
      content: """import 'package:$projectName/utils/enum.dart';

enum AppUrl {
  Base,
}

extension AppUrlExtention on AppUrl {
  static String _baseUrl = "";

  static void setUrl(UrlLink urlLink) {
    switch (urlLink) {
      case UrlLink.isLive:
        _baseUrl = "";

        break;

      case UrlLink.isDev:
        _baseUrl = "";

        break;

      case UrlLink.isLocalServer:
        // set up your local server ip address.
        _baseUrl = "";
        break;
    }
  }

  String get url {
    switch (this) {
      case AppUrl.Base:
        return "\$_baseUrl";

      default:
        return "";
    }
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
  D_MMM_Y,
  APPLICATION_JSON,
  BEARER,
  MULTIPART_FORM_DATA,
}

extension AppConstantExtention on AppConstant {
  String get key {
    switch (this) {
      case AppConstant.USER_ID:
        return "USER_ID";
      case AppConstant.TOKEN:
        return "TOKEN";
      case AppConstant.LANGUAGE:
        return "LANGUAGE";
      case AppConstant.DD_MM_YYYY:
        return "DD_MM_YYYY";
      case AppConstant.D_MMM_Y:
        return "D_MMM_Y";
      case AppConstant.YYYY_MM_DD:
        return "YYYY_MM_DD";
      case AppConstant.APPLICATION_JSON:
        return "application/json";
      case AppConstant.BEARER:
        return "Bearer";
      case AppConstant.MULTIPART_FORM_DATA:
        return "multipart/form-data";
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
import 'package:$projectName/utils/enum.dart';
import 'package:$projectName/utils/extention.dart';
import 'package:$projectName/utils/navigation_service.dart';
import 'package:$projectName/utils/network_connection.dart';
import 'package:$projectName/utils/view_util.dart';

class ApiClient {
  late Dio _dio;

  Map<String, dynamic> _header = {};

  _initDio() {
    _header = {
      HttpHeaders.contentTypeHeader: AppConstant.APPLICATION_JSON.key,
      HttpHeaders.authorizationHeader:
          "\${AppConstant.BEARER.key} \${PrefHelper.getString(
        AppConstant.TOKEN.key,
      )}"
    };

    _dio = Dio(BaseOptions(
      baseUrl: AppUrl.Base.url,
      headers: _header,
      connectTimeout: 1000 * 30,
      sendTimeout: 1000 * 10,
    ));
    _initInterceptors();
  }

  void _initInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint(
              'REQUEST[\${options.method}] => PATH: \${AppUrl.Base.url}\${options.path} '
              '=> Request Values: param: \${options.queryParameters}, DATA: \${options.data}, => HEADERS: \${options.headers}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
         debugPrint(
              'RESPONSE[\${response.statusCode}] => DATA: \${response.data} URL: \${response.requestOptions.baseUrl}\${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (err, handler) {
          debugPrint(
              'ERROR[\${err.response?.statusCode}] => DATA: \${err.response?.data} Message: \${err.message} URL: \${err.response?.requestOptions.baseUrl}\${err.response?.requestOptions.path}');
          return handler.next(err);
        },
      ),
    );
  }

  // Image or file upload using Rest handle.
  Future requestFormData(
    String url,
    Method method,
    Map<String, dynamic>? params,
    Map<String, File>? files,
  ) async {
    _header[Headers.contentTypeHeader] = AppConstant.MULTIPART_FORM_DATA.key;
    _initDio();

    Map<String, MultipartFile> fileMap = {};
    if (files != null) {
      for (MapEntry fileEntry in files.entries) {
        File file = fileEntry.value;
        fileMap[fileEntry.key] = await MultipartFile.fromFile(file.path);
      }
    }
    params?.addAll(fileMap);
    final data = FormData.fromMap(params!);

    debugPrint(data.fields.toString());
    // Handle and check all the status.
    return clientHandle(
      url,
      method,
      params,
      data: data,
    );
  }

  // Normal Rest API  handle.
  Future request({
    required String url,
    required Method method,
    Map<String, dynamic>? params,
    Function? onSuccessFunction(Response response)?,
  }) async {
    if (NetworkConnection.instance.isInternet) {
      _initDio();
      // Handle and check all the status.
      return clientHandle(
        url,
        method,
        params,
        onSuccessFunction: onSuccessFunction,
      );
    } else {
      NetworkConnection.instance.apiStack.add(
        APIParams(
            url: url,
            method: method,
            variables: params ?? {},
            onSuccessFunction: onSuccessFunction),
      );
      if (ViewUtil.isPresentedDialog == false) {
        ViewUtil.isPresentedDialog = true;
        WidgetsBinding.instance!.addPostFrameCallback(
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
                          onSuccessFunction: element.onSuccessFunction);
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
    Function? onSuccessFunction(Response response)?,
  }) async {
    Response response;
    try {
      // Handle response code from api.
      if (method == Method.POST) {
        response = await _dio.post(url, queryParameters: params, data: data);
      } else if (method == Method.DELETE) {
        response = await _dio.delete(url);
      } else if (method == Method.PATCH) {
        response = await _dio.patch(url);
      } else {
        response = await _dio.get(
          url,
          queryParameters: params,
        );
      }
      /**
       * Handle Rest based on response json
       * So please check in json body there is any status_code or code
       */
      if (response.statusCode == 200) {
        final Map data = json.decode(response.toString());

        final code = data['code'];
        if (code == 200) {
          return onSuccessFunction!(response);
        } else {
          if (code < 500) {
            List<String> messages = data['message'].cast<String>();

            switch (code) {
              case 401:
                // PrefHelper.setString(TOKEN, "").then((value) => LoginScreen()
                //     .pushAndRemoveUntil(Navigation.key.currentContext));

                break;
              default:
                ViewUtil.SSLSnackbar(_extractMessages(messages));

                throw Exception(_extractMessages(messages));
            }
          } else {
            ViewUtil.SSLSnackbar("Server Error");
            throw Exception();
          }
        }
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized");
      } else if (response.statusCode == 500) {
        throw Exception("Server Error");
      } else {
        throw Exception("Something went wrongs");
      }

      // Handle Error type if dio catches anything.
    } on DioError catch (e) {
      e.log();
      switch (e.type) {
        case DioErrorType.connectTimeout:
          ViewUtil.SSLSnackbar("Time out delay ");
          break;
        case DioErrorType.receiveTimeout:
          ViewUtil.SSLSnackbar("Server is not responded properly");
          break;
        case DioErrorType.other:
          if (e.error is SocketException) {
            ViewUtil.SSLSnackbar("Check your Internet Connection");
            throw SocketException("Not in Online");
          }
          break;
        case DioErrorType.response:
          try {
            ViewUtil.SSLSnackbar("Internal Responses error");
          } catch (e) {
          } finally {
            throw Exception(e.toString());
          }

        default:
      }
    } catch (e) {
      "ex".log();
      e.log();
      throw Exception("Something went wrong" + e.toString());
    }
  }

  /**
   * error message will give us as a list of string thats why extract it
   * so check it in your response
   */
  _extractMessages(List<String> messages) {
    var str = "";

    messages.forEach((element) {
      str += element;
    });

    return str;
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
    this.status,
    this.code,
    this.message,
  });

  String? status;
  int? code;
  List<String>? message;

  factory GlobalResponse.fromJson(Map<String, dynamic> json) => GlobalResponse(
        status: json["status"] == null ? null : json["status"],
        code: json["code"] == null ? null : json["code"],
        message: json["message"] == null
            ? null
            : List<String>.from(json["message"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "status": status == null ? null : status,
        "code": code == null ? null : code,
        "message":
            message == null ? null : List<dynamic>.from(message!.map((x) => x)),
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
      directoryCreator.globalDir.path + '/widget',
      'global_appbar',
      content: '''
  import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/styles/styles.dart';

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


 '''
    );

   await _createFile(
      directoryCreator.globalDir.path + '/widget',
      'global_button',
      content: '''
import 'package:flutter/material.dart';
import 'package:$projectName/utils/styles/styles.dart';

class GlobalButton extends StatelessWidget {
  const GlobalButton({
    Key? key,
    required this.onPressed,
    required this.btnName,
  }) : super(key: key);
  final void Function() onPressed;
  final String btnName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 65.h,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: KColor.secondary.color),
      child: TextButton(
        style: TextButton.styleFrom(
          primary: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(
          btnName,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


 '''
    );
     await _createFile(
      directoryCreator.globalDir.path + '/widget',
      'global_textformfield',
      content: '''
import 'package:flutter/material.dart';
import 'package:$projectName/utils/styles/k_text_style.dart';
import 'package:$projectName/utils/styles/styles.dart';

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


 '''
    );
  

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
      directoryCreator.mvcDir.path + '/module_name' + '/controller',
      'controller_name',
    );
    await _createFile(
      directoryCreator.mvcDir.path + '/module_name' + '/model',
      'model_class_name',
    );
    await _createFile(
        directoryCreator.mvcDir.path + '/module_name' + '/views', 'views_name',
        content: """
import 'package:flutter/material.dart';

class ViewsName extends StatelessWidget {
  const ViewsName({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Container(child: Text("Project Setup"),),),);
  }
}

""");
    await _createFile(
      directoryCreator.mvcDir.path + '/module_name' + '/views' + '/components',
      'widget_name',
    );

//Utils file
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
    await _createFile(directoryCreator.utilsDir.path + '/styles', 'k_size',
        content: """import 'package:flutter/material.dart';
import 'package:$projectName/utils/navigation_service.dart';

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
""");
    await _createFile(
        directoryCreator.utilsDir.path + '/styles', 'k_text_style',
        content: """import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
export 'k_size.dart';
export 'k_text_style.dart';
export 'k_assets.dart';
""");

    await _createFile(directoryCreator.utilsDir.path, 'enum',
        content: """enum LanguageOption {
  Bangla,
  English,
}

enum CART_STATUS {
  INCREMENT,
  REMOVE,
  DECREMENT,
}

enum Method { POST, GET, PUT, DELETE, PATCH, }
enum UrlLink {
  isLive,
  isDev,
  isLocalServer,
}


""");

    await _createFile(directoryCreator.utilsDir.path, 'extention', content: """

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as darttools show log;
import 'package:$projectName/constant/constant_key.dart';
import 'package:$projectName/data_provider/pref_helper.dart';

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
    int _lanIndex = PrefHelper.getInt(AppConstant.IS_SWITCHED.key);
    if (_lanIndex == 1) {
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



extension VersionCheck on String {
  bool isVersionGreaterThan(String currentVersion) {
    String newVersion = this;
    List<String> currentV = currentVersion.split(".");
    List<String> newV = newVersion.split(".");
    bool a = false;
    for (var i = 0; i <= 2; i++) {
      a = int.parse(newV[i]) > int.parse(currentV[i]);
      if (int.parse(newV[i]) != int.parse(currentV[i])) break;
    }
    return a;
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
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#\$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+.[a-zA-Z]+")
      .hasMatch(this);

  //check mobile number contain special character or not
  bool get isMobileNumberValid =>
      RegExp(r'(^(?:[+0]9)?[0-9]{10,12}\$)').hasMatch(this);
}

extension WidgetExtention on Object {
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

// TextEditing controller empty check and set the value in hint text.
extension EditingEmptyCheck on String {
  String validateEmptyCheck(TextEditingController tempTextControleller) =>
      tempTextControleller.text.isEmpty ? this : tempTextControleller.text;
}

// TextEditing controller mandatory check and set the value mandatory or not.
extension EditingMadatoryCheck on bool {
  bool mandatoryCheck(TextEditingController tempTextControleller) =>
      tempTextControleller.text.isEmpty ? this : false;
}

// This extention is convert the number to k.
// such as 1000 to show 1k.
extension NumberFormatExtention on num {
  String get formattedNumber => NumberFormat.compactCurrency(
        decimalDigits: 0,
      ).format(this).substring(3);
}

// It will formate the date which will show in our application.
extension FormatedDateExtention on DateTime {
  String get formattedDate => DateFormat(AppConstant.D_MMM_Y.key).format(this);
}

extension FormatedDateExtentionString on String {
  String formattedDate() {
    DateTime parsedDate = DateTime.parse(this);
    return DateFormat(AppConstant.D_MMM_Y.key).format(parsedDate);
  }
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

extension GetValueFromString on String {
  /**
   * "You will get 60 tk discount"
   * example : here replace all find the 60 value
   * then split get the list of this string such as ["You will get","tk discount"]
   * After that we return full value using map
   * */
  Map get splitTextMap {
    //Get integer value form the list
    String value = replaceAll(new RegExp(r'[^0-9]'), '');
    //After get the value we split the String and return this list of String.
    Map<String, dynamic> splittedText = {
      "value": value,
      "splittedList": this.split(value.toString())
    };
    return splittedText;
  }
}


""");
    await _createFile(directoryCreator.utilsDir.path, 'navigation_service',
        content: """import 'package:flutter/material.dart';

extension Navigation on Widget {
  static GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// Holds the information about parent context
  /// For example when navigation from Screen A to Screen B
  /// we can access context of Screen A from Screen B to check if it
  /// came from Screen A. So we can trigger different logic depending on
  /// which screen we navigated from.
    

  //it will navigate you to one screen to another
  Future push(context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => this),
    );
  }
   

  //it will pop all the screen  and take you to the new screen
  //E:g : when you will goto the login to home page then you will use this 
  Future pushAndRemoveUntil(context) {
    return Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => this),
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

  Future pushReplacement(context, {String? routeName}) {
    return Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          settings: RouteSettings(name: routeName),
          builder: (BuildContext context) => this),
    );
  }

  //it will pop all the screen and take you to the first screen of the stack
  //that means you will go to the Home page
  Future pushAndRemoveSpecificScreen(context) {
    return Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => this),
        (route) => route.isFirst);
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
import 'package:$projectName/utils/view_util.dart';


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
        ViewUtil.SSLSnackbar("Internet is not Available");
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
  Function? Function(Response<dynamic>)? onSuccessFunction;

  APIParams(
      {required this.url,
      required this.method,
      required this.variables,
      required this.onSuccessFunction,});
}

""");
    await _createFile(directoryCreator.utilsDir.path, 'view_util',
        content: """
import 'package:flutter/material.dart';
import 'package:$projectName/utils/navigation_service.dart';
import 'package:$projectName/utils/styles/styles.dart';

class ViewUtil {
  static SSLSnackbar(String msg) {
    /**
     * Using ScaffoldMessenger we can easily access
     * this snackbar from anywhere
     */

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

  static SSLRemoveSnackBar() {
    /**
     * Using ScaffoldMessenger we can easily remove
     * this snackbar from anywhere
     */
    return ScaffoldMessenger.of(Navigation.key.currentContext!)
        .removeCurrentSnackBar();
  }

  // this varialble is for internet connection check.
  static bool isPresentedDialog = false;
  static showInternetDialog({
    required VoidCallback onPressed,
  }) async {
    // flutter defined function.
    await showDialog(
      context: Navigation.key.currentContext!,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // return object of type Dialog.
        return AlertDialog(
          title: Text("Connection Error"),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Internet is not available"),
              TextButton(child: Text("Try Again"), onPressed: onPressed),
            ],
          ),
          actions: [
            // usually buttons at the bottom of the dialog.
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// global alert dialog
  static showAlertDialog(
      {String? title,
      required Widget content,
      List<Widget>? actions,
      Color? alertBackgroundColor,
      bool? barrierDismissible,
      BorderRadius? borderRadius}) async {
    // flutter defined function.
    await showDialog(
      context: Navigation.key.currentContext!,
      barrierDismissible: barrierDismissible ?? true,
      builder: (BuildContext context) {
        // return object of type Dialog.
        return AlertDialog(
            backgroundColor: alertBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ??
                  BorderRadius.all(
                    Radius.circular(8.w),
                  ),
            ),
            title: title == null ? null : Text(title),
            content: content,
            actions: actions,);
      },
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
import 'package:google_fonts/google_fonts.dart';
import 'package:$projectName/data_provider/pref_helper.dart';
import 'package:$projectName/mvc/module_name/views/views_name.dart';
import 'package:$projectName/utils/navigation_service.dart';
import 'package:$projectName/utils/styles/styles.dart';
import 'package:$projectName/constant/app_url.dart';
import 'package:$projectName/utils/enum.dart';
//localization
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

//iOS localization is required to add this below
//code in dict tag in info.plist

// <key>CFBundleLocalizations</key>
// 	<array>
// 		<string>en</string>
// 		<string>sv</string>
// 	</array>

//Add this line in pubspec.yaml

//This line is added for localization 
 // flutter_localizations:
  //  sdk: flutter
   
//pls check pubspec.yaml
// generate: true

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServices();
  //Set Potraite Mode only
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(MyApp());
}

/// Make sure you always init shared pref first. It has token and token is need
/// to make API call
initServices() async {
   AppUrlExtention.setUrl(
    UrlLink.isDev,
  );

  await PrefHelper.init();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChannels.textInput.invokeMethod('TextInput.hide');

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
        //globally handle progress color using themeData class
        progressIndicatorTheme: ProgressIndicatorThemeData(color: Colors.green),
        textTheme: GoogleFonts.robotoMonoTextTheme(),
        primaryColor:KColor.primary.color,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ThemeData().colorScheme.copyWith(
              secondary:KColor.secondary.color,
            ),
        primarySwatch: KColor.primary.color as MaterialColor,
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(size: 16),
          actionsIconTheme: IconThemeData(size: 16),
          backgroundColor: KColor.white.color,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: KColor.divider.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      home:ViewsName(),
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
