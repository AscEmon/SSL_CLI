import 'dart:io';
import '../i_creators.dart';

class ImplFileCreator implements IFileCreator {
  final IDirectoryCreator directoryCreator;

  ImplFileCreator(this.directoryCreator);

  @override
  Future<void> createNecessaryFiles() async {
    print('creating necessary files...');

    //constant folder file
    await _createFile(
      directoryCreator.constantDir.path,
      'app_url',
      content: 'class AppUrl{ static const BASE_URL = "";}',
    );
    await _createFile(
      directoryCreator.constantDir.path,
      'constant_key',
      content: 'const String USER_UID = /n' 'USER_UID' ';',
    );

    //dataProvider folder file
    await _createFile(directoryCreator.dataProviderDir.path, 'api_client',
        content:
            "import 'dart:convert'; import 'dart:io'; import 'package:dio/dio.dart' as d; import 'package:riverpod_test/constant/app_url.dart'; import 'package:riverpod_test/constant/constant_key.dart'; import 'package:riverpod_test/data_provider/pref_helper.dart'; import 'package:riverpod_test/mvc/get_module/views/get_screen.dart'; import 'package:riverpod_test/utils/enum.dart'; import 'package:riverpod_test/utils/navigation_service.dart'; import 'package:riverpod_test/utils/view_util.dart'; class ApiClient { late d.Dio _dio; Map<String, dynamic> _header = {}; _initDio() { _header = { // 'language': PrefHelper.getString(PrefConstant.LANGUAGE, 'en'), HttpHeaders.authorizationHeader: 'Bearer \${PrefHelper.getString(TOKEN)}' }; _dio = d.Dio(d.BaseOptions(baseUrl: AppUrl.BASE_URL, headers: _header)); _initInterceptors(); } void _initInterceptors() { _dio.interceptors.add(d.InterceptorsWrapper(onRequest: (options, handler) { print( 'REQUEST[\${options.method}] => PATH: \${AppUrl.BASE_URL}\${options.path} ' '=> Request Values: param: \${options.queryParameters}, DATA: \${options.data}, => HEADERS:\${options.headers}'); return handler.next(options); }, onResponse: (response, handler) { print( 'RESPONSE[\${response.statusCode}] => DATA: \${response.data} URL: \${response.requestOptions.baseUrl}\${response.requestOptions.path}'); return handler.next(response); }, onError: (err, handler) { print( 'ERROR[\${err.response?.statusCode}] => DATA: \${err.response?.data} Message: \${err.message} URL: \${err.response?.requestOptions.baseUrl}\${err.response?.requestOptions.path}'); return handler.next(err); })); } //Image or file upload using Rest handle Future requestFormData(String url, Method method, Map<String, dynamic>? params, Map<String, File>? files) async { _header[d.Headers.contentTypeHeader] = 'multipart/form-data'; _initDio(); Map<String, d.MultipartFile> fileMap = {}; if (files != null) { for (MapEntry fileEntry in files.entries) { File file = fileEntry.value; fileMap[fileEntry.key] = await d.MultipartFile.fromFile(file.path); } } params?.addAll(fileMap); final data = d.FormData.fromMap(params!); print(data.fields.toString()); //Handle and check all the status return clientHandle(url, method, params, data: data); } //Normal Rest handle Future request( String url, Method method, Map<String, dynamic>? params) async { _initDio(); //Handle and check all the status return clientHandle(url, method, params); } //Handle all the method and error Future clientHandle(String url, Method method, Map<String, dynamic>? params, {dynamic data}) async { d.Response response; try { // Handle response code from api if (method == Method.POST) { response = await _dio.post(url, queryParameters: params, data: data); } else if (method == Method.DELETE) { response = await _dio.delete(url); } else if (method == Method.PATCH) { response = await _dio.patch(url); } else { response = await _dio.get( url, queryParameters: params, ); } //Handle Rest based on response json //So please check in json body there is any status_code or code if (response.statusCode == 200) { final Map data = json.decode(response.toString()); final code = data['status_code']; if (code == 200) { return response; } else { if (code < 500) { List<String> messages = data['error_message'].cast<String>(); switch (code) { case 401: PrefHelper.setString(TOKEN, "
            ").then((value) => GetScreen() .pushAndRemoveUntil(Navigation.key.currentContext)); break; default: ViewUtil.SSLSnackbar(_extractMessages(messages)); throw Exception(_extractMessages(messages)); } } else { ViewUtil.SSLSnackbar('Server Error'); throw Exception(); } } } else if (response.statusCode == 401) { throw Exception('Unauthorized'); } else if (response.statusCode == 500) { throw Exception('Server Error'); } else { throw Exception('Something went wrong'); } // Handle Error type if dio catches anything } on d.DioError catch (e) { switch (e.type) { case d.DioErrorType.connectTimeout: ViewUtil.SSLSnackbar('Time out delay '); break; case d.DioErrorType.receiveTimeout: ViewUtil.SSLSnackbar('Server is not responded properly'); break; case d.DioErrorType.other: if (e.error is SocketException) { ViewUtil.SSLSnackbar('Check your Internet Connection'); } break; case d.DioErrorType.response: try { ViewUtil.SSLSnackbar('Internal Response error'); } catch (e) {} break; default: } } catch (e) { throw Exception('Something went wrong'); } } // error message will give us as a list of string thats why extract it //so check it in your response _extractMessages(List<String> messages) { var str = "
            "; messages.forEach((element) { str += element; }); return str; } }");

    await _createFile(directoryCreator.dataProviderDir.path, 'pref_helper.dart',
        content:
            "import 'package:riverpod_test/constant/constant_key.dart'; import 'package:shared_preferences/shared_preferences.dart'; class PrefHelper { static Future<SharedPreferences> get _instance async => _prefsInstance ??= await SharedPreferences.getInstance(); static SharedPreferences? _prefsInstance; static Future<SharedPreferences> init() async { _prefsInstance = await _instance; return _prefsInstance!; } static Future setString(String key, String value) async { var _pref = await _instance; await _pref.setString(key, value); } static Future setInt(String key, int value) async { var _pref = await _instance; await _pref.setInt(key, value); } static Future setBool(String key, bool value) async { var _pref = await _instance; await _pref.setBool(key, value); } static Future setDouble(String key, double value) async { var _pref = await _instance; await _pref.setDouble(key, value); } static Future setStringList(String key, List<String> value) async { var _pref = await _instance; await _pref.setStringList(key, value); } static getString(String key, [String defaultValue = "
            "]) { return _prefsInstance?.getString(key) ?? defaultValue; } static getInt(String key) { return _prefsInstance?.getInt(key) ?? 0; } static getBool(String key) { return _prefsInstance?.getBool(key) ?? false; } static getDouble(String key) { return _prefsInstance?.getDouble(key) ?? 0.0; } static getStringList(String key) { return _prefsInstance?.getStringList(key) ?? <String>[]; } static getLanguage() { return _prefsInstance?.getInt(LANGUAGE) ?? 1; } static void logout() { final languageValue = getLanguage(); _prefsInstance?.clear(); _prefsInstance?.setInt(LANGUAGE, languageValue); } static bool isLoggedIn() { return (_prefsInstance?.getInt(USER_ID) ?? -1) > 0; } }");

    //localization file
    await _createFile(
      directoryCreator.l10nDir.path,
      'intl_bn',
      fileExtention: 'arb',
      content: '{"logout_button":"","item":"","add_address":""}',
    );

    await _createFile(
      directoryCreator.l10nDir.path,
      'intl_en',
      fileExtention: 'arb',
      content:
          '{"logout_button":"Log out","item":"You have %d item","add_address":"Add Adress"}',
    );

    //MVC  module file
    await _createFile(
      directoryCreator.mvcDir.path + '/model',
      'model_class_name',
    );
    await _createFile(
      directoryCreator.mvcDir.path + '/views',
      'views_name',
    );
    await _createFile(
      directoryCreator.mvcDir.path + '/controller',
      'controller_name',
    );
//Utils file
    await _createFile(directoryCreator.utilsDir.path + '/styles', 'k_assets',
        content:
            "class KAssets { static const _rootPath = 'assets'; static const _svgDir = '\$_rootPath/svg'; static const _imageDir = '\$_rootPath/images'; }");
    await _createFile(directoryCreator.utilsDir.path + '/styles', 'k_colors',
        content:
            "import 'package:flutter/material.dart'; class KColors { static const primary = Color(0xFF299E8D); static const accent = Color(0x1F299E8D); static const darkAccent = Color(0xFF2C4251); static const white = Colors.white; static const black = Colors.black; static final charcoal = Color(0xFF264654); static final lightCharcoal = charcoal.withOpacity(.12); static const spaceCadet = Color(0xFF2C3549); static final lightRed = Colors.red[100]; static final red = Colors.red; static final transparent = Colors.transparent; }");
    await _createFile(directoryCreator.utilsDir.path + '/styles', 'k_size',
        content:
            "import 'package:flutter/material.dart'; import 'package:riverpod_test/utils/navigation_service.dart'; //zeplin size // width 414 // height 896 extension KSizes on num { static Size get screenSize => MediaQuery.of(Navigation.key.currentContext!).size; //height double get h => (this / 896) * (screenSize.height > 896 ? 896 : screenSize.height); //Width double get w => (this / 414) * (screenSize.width > 414 ? 414 : screenSize.width); //fontSize double get sp { // For small devices. if (screenSize.height < 600) { return 0.7 * this; } // For normal device return 1.0 * this; } }");
    await _createFile(
        directoryCreator.utilsDir.path + '/styles', 'k_text_style',
        content:
            "import 'package:flutter/material.dart'; import 'package:google_fonts/google_fonts.dart'; import 'package:riverpod_test/utils/styles/styles.dart'; class KTextStyle { static TextStyle headLine3 = GoogleFonts.quicksand( fontSize: 42.sp, fontWeight: FontWeight.w500, ); static TextStyle headLine4 = GoogleFonts.quicksand( fontSize: 32.sp, fontWeight: FontWeight.w500, ); static TextStyle buttonText({fontWeight = FontWeight.normal}) => GoogleFonts.quicksand( fontSize:27.sp, fontWeight: fontWeight, ); /// Normal Texts static TextStyle bodyText1() => GoogleFonts.quicksand( fontSize: 27.sp, fontWeight: FontWeight.normal, ); static TextStyle bodyText2() => GoogleFonts.quicksand( fontSize: 24.sp, fontWeight: FontWeight.w500, ); static TextStyle bodyText3() => GoogleFonts.quicksand( fontSize: 22.sp, fontWeight: FontWeight.normal, ); /// Subtitles static TextStyle subtitle1 =const TextStyle( fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15, ); static TextStyle subtitle2 =const TextStyle( fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, ); }");

    await _createFile(directoryCreator.utilsDir.path + '/styles', 'k_assets',
        content:
            "    export 'k_colors.dart'; export 'k_size.dart'; export 'k_text_style.dart'; export 'k_assets.dart'");

    await _createFile(directoryCreator.utilsDir.path, 'enum',
        content:
            "enum LanguageOption { Bangla, English, } enum CART_STATUS { INCREMENT, REMOVE, DECREMENT, } enum Method { POST, GET, PUT, DELETE, PATCH }");
    await _createFile(directoryCreator.utilsDir.path, 'extention', content: "");
    await _createFile(directoryCreator.utilsDir.path, 'navigation_service',
        content: "");
    await _createFile(directoryCreator.utilsDir.path, 'view_util', content: "");
    await _createFile(
      'lib',
      'main',
      content: '',
    );
  }

  Future<void> _createFile(
    String basePath,
    String fileName, {
    String? content,
    String fileExtention = 'dart',
  }) async {
    String fileType = fileExtention == 'dart' ? 'dart' : 'arb';
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
