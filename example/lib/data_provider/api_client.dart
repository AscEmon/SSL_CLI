import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as d;
import 'package:riverpod_test/constant/app_url.dart';
import 'package:riverpod_test/constant/constant_key.dart';
import 'package:riverpod_test/data_provider/pref_helper.dart';
import 'package:riverpod_test/utils/enum.dart';
import 'package:riverpod_test/utils/navigation_service.dart';
import 'package:riverpod_test/utils/view_util.dart';

class ApiClient {
  late d.Dio _dio;

  Map<String, dynamic> _header = {};

  _initDio() {
    _header = {
      // 'language': PrefHelper.getString(PrefConstant.LANGUAGE, "en"),
      HttpHeaders.authorizationHeader: "Bearer ${PrefHelper.getString(TOKEN)}"
    };

    _dio = d.Dio(d.BaseOptions(baseUrl: AppUrl.BASE_URL, headers: _header));
    _initInterceptors();
  }

  void _initInterceptors() {
    _dio.interceptors.add(d.InterceptorsWrapper(onRequest: (options, handler) {
      print(
          'REQUEST[${options.method}] => PATH: ${AppUrl.BASE_URL}${options.path} '
          '=> Request Values: param: ${options.queryParameters}, DATA: ${options.data}, => HEADERS: ${options.headers}');
      return handler.next(options);
    }, onResponse: (response, handler) {
      print(
          'RESPONSE[${response.statusCode}] => DATA: ${response.data} URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
      return handler.next(response);
    }, onError: (err, handler) {
      print(
          'ERROR[${err.response?.statusCode}] => DATA: ${err.response?.data} Message: ${err.message} URL: ${err.response?.requestOptions.baseUrl}${err.response?.requestOptions.path}');
      return handler.next(err);
    }));
  }

  //Image or file upload using Rest handle
  Future requestFormData(String url, Method method,
      Map<String, dynamic>? params, Map<String, File>? files) async {
    _header[d.Headers.contentTypeHeader] = 'multipart/form-data';
    _initDio();

    Map<String, d.MultipartFile> fileMap = {};
    if (files != null) {
      for (MapEntry fileEntry in files.entries) {
        File file = fileEntry.value;
        fileMap[fileEntry.key] = await d.MultipartFile.fromFile(file.path);
      }
    }
    params?.addAll(fileMap);
    final data = d.FormData.fromMap(params!);

    print(data.fields.toString());
    //Handle and check all the status
    return clientHandle(url, method, params, data: data);
  }

  //Normal Rest handle
  Future request(
      String url, Method method, Map<String, dynamic>? params) async {
    _initDio();
    //Handle and check all the status
    return clientHandle(url, method, params);
  }

//Handle all the method and error
  Future clientHandle(String url, Method method, Map<String, dynamic>? params,
      {dynamic data}) async {
    d.Response response;
    try {
      // Handle response code from api
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
      //Handle Rest based on response json
      //So please check in json body there is any status_code or code
      if (response.statusCode == 200) {
        final Map data = json.decode(response.toString());

        final code = data['status_code'];
        if (code == 200) {
          return response;
        } else {
          if (code < 500) {
            List<String> messages = data['error_message'].cast<String>();

            switch (code) {
              case 401:
                // PrefHelper.setString(TOKEN, "").then((value) => GetScreen()
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
        throw Exception("Something went wrong");
      }

      // Handle Error type if dio catches anything
    } on d.DioError catch (e) {
      switch (e.type) {
        case d.DioErrorType.connectTimeout:
          ViewUtil.SSLSnackbar("Time out delay ");
          break;
        case d.DioErrorType.receiveTimeout:
          ViewUtil.SSLSnackbar("Server is not responded properly");
          break;
        case d.DioErrorType.other:
          if (e.error is SocketException) {
            ViewUtil.SSLSnackbar("Check your Internet Connection");
          }
          break;
        case d.DioErrorType.response:
          try {
            ViewUtil.SSLSnackbar("Internal Response error");
          } catch (e) {}
          break;

        default:
      }
    } catch (e) {
      throw Exception("Something went wrong");
    }
  }

  // error message will give us as a list of string thats why extract it
  //so check it in your response
  _extractMessages(List<String> messages) {
    var str = "";

    messages.forEach((element) {
      str += element;
    });

    return str;
  }
}
