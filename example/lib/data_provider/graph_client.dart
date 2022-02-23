import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as d;
import 'package:flutter/material.dart';
import 'package:riverpod_test/constant/app_url.dart';
import 'package:riverpod_test/constant/constant_key.dart';
import 'package:riverpod_test/data_provider/pref_helper.dart';
import 'package:riverpod_test/global/model/graph_ql_error_response.dart';
import 'package:riverpod_test/utils/navigation_service.dart';
import 'package:riverpod_test/utils/view_util.dart';

class ApiClient {
  late d.Dio _dio;

  Map<String, dynamic> _header = {};

  _initDio({String baseUrl = AppUrl.BASE_URL}) {
    _header = {
      HttpHeaders.contentTypeHeader: "application/json",
      HttpHeaders.authorizationHeader: "Bearer ${PrefHelper.getString(TOKEN)}"
    };

    _dio = d.Dio(
      d.BaseOptions(
        baseUrl: baseUrl,
        headers: _header,
        connectTimeout: 1000 * 30,
        sendTimeout: 1000 * 10,
      ),
    );
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

//This requestFormData is actually for REST API
//Usign this we sent multipart file thats why its argument
//is different in request method
  Future requestFormData(String url, Map<String, File>? files,
      {bool isLoaderShowing = false}) async {
    try {
      if (isLoaderShowing) CircularProgressIndicator();

      d.Response response;
      _header[d.Headers.contentTypeHeader] = 'multipart/form-data';
      _initDio(baseUrl: AppUrl.FILE_UPLOAD_BASE_URL);

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
    if (isLoaderShowing) CircularProgressIndicator();

    d.Response response;
    _initDio(baseUrl: AppUrl.BASE_URL);

    try {
      String paramJson = ''' 
      {
      "query" : "$body",
      "variables" : ${jsonEncode(variables)}
      }
      '''
          .replaceAll("
", "");

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
          } else
            _showExceptionSnackBar(result.errors[0].message);
        }
      }
    } catch (e) {}
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
        // return request(body: body, variables: variables);
        break;
      case d.DioErrorType.sendTimeout:
        // return request(body: body, variables: variables);
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
 