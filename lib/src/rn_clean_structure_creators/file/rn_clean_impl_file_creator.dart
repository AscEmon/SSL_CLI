import 'dart:io';
import 'package:ssl_cli/utils/enum.dart';
import 'package:ssl_cli/utils/extension.dart';
import '../rn_clean_i_creators.dart';

class RNCleanImplFileCreator implements RNIFileCreator {
  final RNIDirectoryCreator directoryCreator;
  final String projectName;

  RNCleanImplFileCreator(this.directoryCreator, this.projectName);

  @override
  Future<void> createNecessaryFiles() async {
    'Creating React Native Clean Architecture files...'.printWithColor(
      status: PrintType.success,
    );

    final corePath = directoryCreator.coreDir.path;
    final featuresPath = directoryCreator.featuresDir.path;
    final srcPath = directoryCreator.srcDir.path;
    final basePath = Directory.current.path;

    await _createCoreFiles(corePath);
    await _createFeatureFiles(featuresPath);
    await _createRootFiles(srcPath, basePath);

    'All React Native Clean Architecture files created successfully!'
        .printWithColor(status: PrintType.success);
  }

  // ─── Core Layer ───────────────────────────────────────────────────────────

  Future<void> _createCoreFiles(String corePath) async {
    await _createFile('$corePath/constants', 'api_urls.ts', '''
enum UrlLink { Live = 'live', Dev = 'dev', Local = 'local' }

export enum ApiUrl {
  Base = 'base',
  BaseImage = 'baseImage',
  Homes = 'homes',
}

let _baseUrl = '';
let _baseImageUrl = '';

export function setUrl(urlLink: UrlLink): void {
  switch (urlLink) {
    case UrlLink.Live:
      _baseUrl = '';
      _baseImageUrl = '';
      break;
    case UrlLink.Dev:
      _baseUrl = '';
      _baseImageUrl = '';
      break;
    case UrlLink.Local:
      _baseUrl = '';
      break;
  }
}

export function getUrl(apiUrl: ApiUrl): string {
  switch (apiUrl) {
    case ApiUrl.Base:
      return _baseUrl;
    case ApiUrl.BaseImage:
      return _baseImageUrl;
    case ApiUrl.Homes:
      return '/homes';
  }
}
''');

    await _createFile('$corePath/constants', 'app_constants.ts', '''
export enum AppConstants {
  Bearer = 'Bearer',
  ApplicationJson = 'application/json',
  MultipartFormData = 'multipart/form-data',
  Android = 'android',
  Ios = 'ios',
  En = 'en',
  Bn = 'bn',
  UserId = 'user-id',
  Token = 'token',
  Language = 'language',
  IsSwitched = 'is-switched',
  DeviceId = 'device-id',
  DeviceOs = 'device-os',
  UserAgent = 'user-agent',
  AppVersion = 'app-version',
  BuildNumber = 'build-number',
  Mobile = 'mobile',
  Email = 'email',
  PushId = 'push-id',
  RefreshToken = 'refresh-token',
  AccessToken = 'access-token',
  LoginResponse = 'login-response',
  IsDarkMode = 'is-dark-mode',
  User = 'user',
  DeviceName = 'device-name',
  DeviceModel = 'device-model',
  DeviceOsVersion = 'device-os-version',
  Username = 'username',
  DateFormatYMD = 'yyyy-MM-dd',
  DateFormatDMY = 'dd/MM/yyyy',
}
''');

    await _createFile('$corePath/error', 'exceptions.ts', '''
export class AppException extends Error {
  statusCode?: number;
  constructor(message: string, statusCode?: number) {
    super(message);
    this.name = 'AppException';
    this.statusCode = statusCode;
  }
}

export class ServerException extends AppException {
  constructor(message: string, statusCode?: number) {
    super(message, statusCode);
    this.name = 'ServerException';
  }
}

export class NetworkException extends AppException {
  constructor(message: string, statusCode?: number) {
    super(message, statusCode);
    this.name = 'NetworkException';
  }
}

export class UnauthorizedException extends AppException {
  constructor(message: string, statusCode = 401) {
    super(message, statusCode);
    this.name = 'UnauthorizedException';
  }
}

export class ValidationException extends AppException {
  errors?: Record<string, unknown>;
  constructor(message: string, statusCode = 422, errors?: Record<string, unknown>) {
    super(message, statusCode);
    this.name = 'ValidationException';
    this.errors = errors;
  }
}

export class TooManyRequestsException extends AppException {
  constructor(message: string, statusCode = 429) {
    super(message, statusCode);
    this.name = 'TooManyRequestsException';
  }
}

export class BadRequestException extends AppException {
  constructor(message: string, statusCode = 400) {
    super(message, statusCode);
    this.name = 'BadRequestException';
  }
}

export class NotFoundException extends AppException {
  constructor(message: string, statusCode = 404) {
    super(message, statusCode);
    this.name = 'NotFoundException';
  }
}

export class TimeoutException extends AppException {
  constructor(message: string, statusCode?: number) {
    super(message, statusCode);
    this.name = 'TimeoutException';
  }
}

export class RequestCancelledException extends AppException {
  constructor(message: string) {
    super(message);
    this.name = 'RequestCancelledException';
  }
}
''');

    await _createFile('$corePath/error', 'failures.ts', '''
export abstract class Failure {
  message: string;
  statusCode?: number;
  constructor(message: string, statusCode?: number) {
    this.message = message;
    this.statusCode = statusCode;
  }
}

export class ServerFailure extends Failure {
  constructor(message: string, statusCode?: number) {
    super(message, statusCode);
  }
}

export class NetworkFailure extends Failure {
  constructor(message: string, statusCode?: number) {
    super(message, statusCode);
  }
}

export class AuthenticationFailure extends Failure {
  constructor(message: string, statusCode?: number) {
    super(message, statusCode);
  }
}

export class ValidationFailure extends Failure {
  errors?: Record<string, unknown>;
  constructor(message: string, statusCode?: number, errors?: Record<string, unknown>) {
    super(message, statusCode);
    this.errors = errors;
  }

  get errorMessages(): string[] {
    if (!this.errors) return [this.message];
    return Object.values(this.errors).flatMap((v) =>
      Array.isArray(v) ? v.map(String) : [String(v)]
    );
  }

  get firstError(): string {
    if (!this.errors) return this.message;
    const first = Object.values(this.errors)[0];
    return Array.isArray(first) ? String(first[0]) : String(first);
  }
}

export class TooManyRequestsFailure extends Failure {
  constructor(message: string, statusCode = 429) {
    super(message, statusCode);
  }
}

export class CacheFailure extends Failure {
  constructor(message: string, statusCode?: number) {
    super(message, statusCode);
  }
}
''');

    await _createFile('$corePath/error', 'exception_handler.ts', '''
import {
  AppException,
  NetworkException,
  ServerException,
  TooManyRequestsException,
  UnauthorizedException,
  ValidationException,
} from './exceptions';
import {
  AuthenticationFailure,
  Failure,
  NetworkFailure,
  ServerFailure,
  TooManyRequestsFailure,
  ValidationFailure,
} from './failures';

export type Either<L, R> = { tag: 'left'; value: L } | { tag: 'right'; value: R };

export function Left<L>(value: L): Either<L, never> {
  return { tag: 'left', value };
}

export function Right<R>(value: R): Either<never, R> {
  return { tag: 'right', value };
}

export function isLeft<L, R>(e: Either<L, R>): e is { tag: 'left'; value: L } {
  return e.tag === 'left';
}

export function isRight<L, R>(e: Either<L, R>): e is { tag: 'right'; value: R } {
  return e.tag === 'right';
}

/**
 * Wraps an async operation and converts thrown exceptions into Either<Failure, T>.
 *
 * Usage:
 * ```ts
 * const result = await handleException(() => remoteDataSource.getHomes());
 * ```
 */
export async function handleException<T>(
  operation: () => Promise<T>
): Promise<Either<Failure, T>> {
  try {
    const result = await operation();
    return Right(result);
  } catch (e) {
    if (e instanceof ValidationException) {
      return Left(new ValidationFailure(e.message, e.statusCode, e.errors));
    }
    if (e instanceof UnauthorizedException) {
      return Left(new AuthenticationFailure(e.message, e.statusCode));
    }
    if (e instanceof NetworkException) {
      return Left(new NetworkFailure(e.message, e.statusCode));
    }
    if (e instanceof TooManyRequestsException) {
      return Left(new TooManyRequestsFailure(e.message, e.statusCode));
    }
    if (e instanceof AppException) {
      return Left(new ServerFailure(e.message, e.statusCode));
    }
    return Left(new ServerFailure(e instanceof Error ? e.message : String(e)));
  }
}
''');

    await _createFile('$corePath/models', 'global_paginator.ts', '''
export interface GlobalPaginator {
  currentPage?: number;
  totalPages?: number;
  recordPerPage?: number;
}

export function paginatorFromJson(json: Record<string, unknown>): GlobalPaginator {
  return {
    currentPage: json['current_page'] as number | undefined,
    totalPages: json['total_pages'] as number | undefined,
    recordPerPage: json['record_per_page'] as number | undefined,
  };
}

export function paginatorToJson(p: GlobalPaginator): Record<string, unknown> {
  return {
    current_page: p.currentPage,
    total_pages: p.totalPages,
    record_per_page: p.recordPerPage,
  };
}
''');

    await _createFile('$corePath/models', 'global_response.ts', '''
export interface GlobalResponse {
  message?: string;
  errors?: Record<string, unknown>;
  code?: number;
}

export function globalResponseFromJson(json: Record<string, unknown>): GlobalResponse {
  return {
    message: json['message'] != null ? String(json['message']) : undefined,
    errors: json['errors'] as Record<string, unknown> | undefined,
    code: json['code'] as number | undefined,
  };
}
''');

    await _createFile('$corePath/network', 'network_info.ts', '''
import NetInfo, { NetInfoState } from '@react-native-community/netinfo';

export interface NetworkInfo {
  isConnected(): Promise<boolean>;
  addListener(callback: (state: NetInfoState) => void): () => void;
}

export class NetworkInfoImpl implements NetworkInfo {
  async isConnected(): Promise<boolean> {
    const state = await NetInfo.fetch();
    return state.isConnected === true && state.isInternetReachable !== false;
  }

  addListener(callback: (state: NetInfoState) => void): () => void {
    return NetInfo.addEventListener(callback);
  }
}
''');

    await _createFile('$corePath/network', 'api_client.ts', '''
import axios, {
  AxiosInstance,
  AxiosRequestConfig,
  AxiosResponse,
  InternalAxiosRequestConfig,
} from 'axios';
import { getUrl, ApiUrl } from '../constants/api_urls';
import { AppConstants } from '../constants/app_constants';
import {
  BadRequestException,
  NetworkException,
  NotFoundException,
  RequestCancelledException,
  ServerException,
  TimeoutException,
  TooManyRequestsException,
  UnauthorizedException,
  ValidationException,
} from '../error/exceptions';
import { PreferencesHelper } from '../utils/preferences_helper';

export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE',
  PATCH = 'PATCH',
}

export interface RequestOptions<T> {
  endpoint: string;
  method: HttpMethod;
  data?: unknown;
  params?: Record<string, unknown>;
  extraHeaders?: Record<string, string>;
  converter?: (data: unknown) => T;
}

export class ApiClient {
  private readonly client: AxiosInstance;
  private readonly prefs: PreferencesHelper;

  constructor(prefs: PreferencesHelper) {
    this.prefs = prefs;
    this.client = axios.create({
      baseURL: getUrl(ApiUrl.Base),
      timeout: 30000,
    });
    this._initInterceptors();
  }

  private _initInterceptors(): void {
    this.client.interceptors.request.use(
      async (config: InternalAxiosRequestConfig) => {
        const headers = await this._buildHeaders();
        Object.assign(config.headers, headers);
        console.log(
          \`[API] REQUEST [\${config.method?.toUpperCase()}] \${config.baseURL}\${config.url}\`
        );
        return config;
      },
      (error) => Promise.reject(error)
    );

    this.client.interceptors.response.use(
      (response: AxiosResponse) => {
        console.log(
          \`[API] RESPONSE [\${response.status}] \${response.config.url}\`
        );
        return response;
      },
      (error) => {
        console.log(\`[API] ERROR \${error.message}\`);
        return Promise.reject(error);
      }
    );
  }

  private async _buildHeaders(): Promise<Record<string, string>> {
    const token = await this.prefs.getString(AppConstants.Token);
    const headers: Record<string, string> = {
      'Content-Type': AppConstants.ApplicationJson,
      [AppConstants.AppVersion]: await this.prefs.getString(AppConstants.AppVersion) ?? '',
      [AppConstants.Language]: (await this.prefs.getLanguage()) === 1 ? AppConstants.En : AppConstants.Bn,
    };
    if (token) {
      headers['Authorization'] = \`\${AppConstants.Bearer} \${token}\`;
    }
    return headers;
  }

  async request<T>(options: RequestOptions<T>): Promise<T> {
    try {
      const config: AxiosRequestConfig = {
        url: options.endpoint,
        method: options.method,
        data: options.data,
        params: options.params,
        headers: options.extraHeaders,
      };

      const response = await this.client.request<unknown>(config);
      const result = this._handleResponse(response);
      return options.converter ? options.converter(result) : (result as T);
    } catch (e: unknown) {
      if (axios.isAxiosError(e)) {
        throw this._handleAxiosError(e);
      }
      if (e instanceof Error && e.name !== 'AppException') {
        throw new ServerException(\`Something went wrong: \${e.message}\`);
      }
      throw e;
    }
  }

  private _handleResponse(response: AxiosResponse): unknown {
    const { status, data } = response;

    if (status === 200 || status === 201) {
      if (data && typeof data === 'object') {
        const code = Number(data.code);
        if (code === 401) throw new UnauthorizedException('Unauthorized');
        if (code === 422) throw new ValidationException('Validation error', 422, data.errors);
        if (code === 429) throw new TooManyRequestsException(data.message ?? 'Too many requests');
        if (code === 500) throw new ServerException('Server error');
      }
      return data;
    }

    switch (status) {
      case 400: throw new BadRequestException('Bad request');
      case 401: throw new UnauthorizedException('Unauthorized');
      case 403: throw new UnauthorizedException('Forbidden', 403);
      case 404: throw new NotFoundException('Not found', 404);
      case 422: throw new ValidationException('Validation error', 422, (data as Record<string, unknown>)?.errors as Record<string, unknown>);
      case 429: throw new TooManyRequestsException('Too many requests');
      case 500: throw new ServerException('Server error');
      default: throw new ServerException(\`Server error: \${status}\`);
    }
  }

  private _handleAxiosError(error: ReturnType<typeof axios.isAxiosError extends (e: unknown) => e is infer R ? (e: unknown) => e is R : never>): Error {
    if (axios.isCancel(error)) return new RequestCancelledException('Request cancelled');

    const axiosErr = error as import('axios').AxiosError;
    if (!axiosErr.response) {
      if (axiosErr.code === 'ECONNABORTED') return new TimeoutException('Connection timeout');
      return new NetworkException('Connection error');
    }

    const status = axiosErr.response.status;
    const data = axiosErr.response.data as Record<string, unknown> | undefined;
    const msg = (data?.message as string) ?? 'Server error occurred';

    switch (status) {
      case 400: return new BadRequestException(msg, 400);
      case 401: return new UnauthorizedException(msg, 401);
      case 404: return new NotFoundException(msg, 404);
      case 422: return new ValidationException(msg, 422, data?.errors as Record<string, unknown>);
      case 429: return new TooManyRequestsException(msg, 429);
      case 500: return new ServerException(msg, 500);
      default: return new ServerException(msg, status);
    }
  }
}
''');

    await _createFile('$corePath/usecases', 'usecase.ts', '''
import { Either, Failure } from '../error/exception_handler';

export abstract class UseCase<T, Params> {
  abstract call(params: Params): Promise<Either<Failure, T>>;
}

export class NoParams {}
''');

    await _createFile('$corePath/utils', 'preferences_helper.ts', '''
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AppConstants } from '../constants/app_constants';

export class PreferencesHelper {
  private static _instance: PreferencesHelper;

  private constructor() {}

  static get instance(): PreferencesHelper {
    if (!PreferencesHelper._instance) {
      PreferencesHelper._instance = new PreferencesHelper();
    }
    return PreferencesHelper._instance;
  }

  async setString(key: string, value: string): Promise<void> {
    await AsyncStorage.setItem(key, value);
  }

  async getString(key: string, defaultValue = ''): Promise<string> {
    const val = await AsyncStorage.getItem(key);
    return val ?? defaultValue;
  }

  async setNumber(key: string, value: number): Promise<void> {
    await AsyncStorage.setItem(key, String(value));
  }

  async getNumber(key: string, defaultValue = 0): Promise<number> {
    const val = await AsyncStorage.getItem(key);
    return val != null ? Number(val) : defaultValue;
  }

  async setBool(key: string, value: boolean): Promise<void> {
    await AsyncStorage.setItem(key, value ? 'true' : 'false');
  }

  async getBool(key: string, defaultValue = false): Promise<boolean> {
    const val = await AsyncStorage.getItem(key);
    if (val == null) return defaultValue;
    return val === 'true';
  }

  async remove(key: string): Promise<void> {
    await AsyncStorage.removeItem(key);
  }

  async clear(): Promise<void> {
    await AsyncStorage.clear();
  }

  async getLanguage(): Promise<number> {
    return this.getNumber(AppConstants.Language, 1);
  }

  async setLanguage(lang: number): Promise<void> {
    await this.setNumber(AppConstants.Language, lang);
  }
}
''');

    await _createFile('$corePath/utils', 'validators.ts', '''
export class Validators {
  static email(value?: string): string | null {
    if (!value) return 'Please enter email';
    const re = /^[a-zA-Z0-9@._+\-]+\$/;
    if (!re.test(value)) return 'Please enter a valid email';
    return null;
  }

  static password(value?: string): string | null {
    if (!value) return 'Please enter password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static required(value?: string, fieldName?: string): string | null {
    if (!value || value.trim().length === 0)
      return \`Please enter \${fieldName ?? 'this field'}\`;
    return null;
  }

  static phone(value?: string): string | null {
    if (!value) return 'Please enter phone number';
    const re = /^\\+?[\\d\\s\\-]{10,}\$/;
    if (!re.test(value)) return 'Please enter a valid phone number';
    return null;
  }

  static otp(value?: string): string | null {
    if (!value) return 'Please enter OTP';
    if (value.length < 6) return 'OTP must be at least 6 characters long';
    return null;
  }

  static combine(
    validators: Array<(v?: string) => string | null>
  ): (v?: string) => string | null {
    return (value) => {
      for (const v of validators) {
        const err = v(value);
        if (err) return err;
      }
      return null;
    };
  }
}
''');

    await _createFile('$corePath/utils', 'extension.ts', '''
export function capitalize(str: string): string {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}

export function toTitleCase(str: string): string {
  return str.replace(/\\w\\S*/g, (txt) => capitalize(txt));
}

export function isValidEmail(str: string): boolean {
  return /^[a-z0-9!#\$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#\$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/.test(
    str
  );
}

export function isValidPhone(number: string): boolean {
  return number.length === 11 && /^01[3-9]/.test(number);
}

export function parseToDouble(str?: string): number {
  if (!str) return 0.0;
  const n = parseFloat(str);
  return isNaN(n) ? 0.0 : n;
}

export function parseToInt(str?: string): number {
  if (!str) return 0;
  const n = parseInt(str, 10);
  return isNaN(n) ? 0 : n;
}

export function groupBy<T, K extends string | number>(
  list: T[],
  key: (item: T) => K
): Record<K, T[]> {
  return list.reduce((acc, item) => {
    const k = key(item);
    if (!acc[k]) acc[k] = [];
    acc[k].push(item);
    return acc;
  }, {} as Record<K, T[]>);
}
''');

    await _createFile('$corePath/theme', 'app_colors.ts', '''
export const AppColors = {
  primary: '#26A69A',
  primaryLight: '#42A5F5',
  primaryDark: '#0D47A1',

  secondary: '#26A69A',
  secondaryLight: '#4DB6AC',
  secondaryDark: '#00796B',

  accent: '#26A69A',

  black: '#000000',
  darkGrey: '#4F4F4F',
  grey: '#9E9E9E',
  lightGrey: '#E0E0E0',
  white: '#FFFFFF',
  btnText: '#878DB5',
  textBlue: '#28294D',
  greylish: '#303030',
  transparent: 'transparent',
  yellow: '#F6D403',

  success: '#4CAF50',
  warning: '#FFC107',
  error: '#F44336',
  info: '#2196F3',
  red: '#F44336',
  green: '#4CAF50',
  orange: '#FF9800',

  background: '#F5F5F5',
  cardBackground: '#D8D5D5',

  textPrimary: '#212121',
  textSecondary: '#757575',
  textHint: '#BDBDBD',
} as const;

export type AppColorsType = typeof AppColors;
''');

    await _createFile('$corePath/theme', 'theme_helper.ts', '''
import { StyleSheet } from 'react-native';
import { AppColors } from './app_colors';

export const lightTheme = {
  dark: false,
  colors: {
    background: AppColors.white,
    card: AppColors.white,
    text: AppColors.black,
    border: AppColors.lightGrey,
    notification: AppColors.primary,
    primary: AppColors.primary,
  },
};

export const darkTheme = {
  dark: true,
  colors: {
    background: AppColors.black,
    card: AppColors.greylish,
    text: AppColors.white,
    border: AppColors.darkGrey,
    notification: AppColors.primary,
    primary: AppColors.primary,
  },
};

export const globalStyles = StyleSheet.create({
  flex1: { flex: 1 },
  center: { justifyContent: 'center', alignItems: 'center' },
  row: { flexDirection: 'row', alignItems: 'center' },
  padding16: { padding: 16 },
  paddingH16: { paddingHorizontal: 16 },
  paddingV8: { paddingVertical: 8 },
});
''');

    await _createFile('$corePath/routes', 'app_routes.ts', '''
export enum AppRoutes {
  Home = 'Home',
}
''');

    await _createFile('$corePath/routes', 'navigation_ref.ts', '''
import { createNavigationContainerRef, NavigationContainerRef, ParamListBase } from '@react-navigation/native';

export const navigationRef = createNavigationContainerRef<ParamListBase>();

export function navigate(name: string, params?: object): void {
  if (navigationRef.isReady()) {
    navigationRef.navigate(name as never, params as never);
  }
}

export function goBack(): void {
  if (navigationRef.isReady() && navigationRef.canGoBack()) {
    navigationRef.goBack();
  }
}

export function reset(routeName: string): void {
  if (navigationRef.isReady()) {
    navigationRef.reset({ index: 0, routes: [{ name: routeName }] });
  }
}
''');

    await _createFile('$corePath/di', 'service_locator.ts', '''
import { ApiClient } from '../network/api_client';
import { NetworkInfoImpl } from '../network/network_info';
import { PreferencesHelper } from '../utils/preferences_helper';
import { HomeRemoteDataSourceImpl } from '../../features/homes/data/datasources/home_remote_datasource';
import { HomeLocalDataSourceImpl } from '../../features/homes/data/datasources/home_local_datasource';
import { HomeRepositoryImpl } from '../../features/homes/data/repositories/home_repository_impl';
import { GetHomes } from '../../features/homes/domain/usecases/get_home';

export class ServiceLocator {
  private static _instance: ServiceLocator;
  private readonly _registry = new Map<string, unknown>();

  private constructor() {}

  static get instance(): ServiceLocator {
    if (!ServiceLocator._instance) {
      ServiceLocator._instance = new ServiceLocator();
    }
    return ServiceLocator._instance;
  }

  register<T>(key: string, factory: () => T): void {
    this._registry.set(key, factory());
  }

  get<T>(key: string): T {
    const dep = this._registry.get(key);
    if (!dep) throw new Error(\`Dependency not found: \${key}\`);
    return dep as T;
  }
}

export const sl = ServiceLocator.instance;

export async function initDependencies(): Promise<void> {
  const prefs = PreferencesHelper.instance;
  const apiClient = new ApiClient(prefs);
  const networkInfo = new NetworkInfoImpl();

  sl.register('prefs', () => prefs);
  sl.register('apiClient', () => apiClient);
  sl.register('networkInfo', () => networkInfo);

  // Homes feature
  const remoteDS = new HomeRemoteDataSourceImpl(apiClient);
  const localDS = new HomeLocalDataSourceImpl();
  const homeRepo = new HomeRepositoryImpl(remoteDS, localDS);

  sl.register('homeRemoteDataSource', () => remoteDS);
  sl.register('homeLocalDataSource', () => localDS);
  sl.register('homeRepository', () => homeRepo);
  sl.register('getHomes', () => new GetHomes(homeRepo));
}
''');

    await _createFile('$corePath/presentation/components', 'GlobalText.tsx', '''
import React from 'react';
import { Text, TextProps, StyleSheet } from 'react-native';
import { AppColors } from '../../theme/app_colors';

interface GlobalTextProps extends TextProps {
  str: string;
  fontSize?: number;
  fontWeight?: 'normal' | 'bold' | '100' | '200' | '300' | '400' | '500' | '600' | '700' | '800' | '900';
  color?: string;
  textAlign?: 'auto' | 'left' | 'right' | 'center' | 'justify';
}

const GlobalText: React.FC<GlobalTextProps> = ({
  str,
  fontSize = 14,
  fontWeight = '500',
  color = AppColors.textPrimary,
  textAlign = 'left',
  style,
  ...rest
}) => {
  return (
    <Text
      style={[styles.text, { fontSize, fontWeight, color, textAlign }, style]}
      {...rest}
    >
      {str}
    </Text>
  );
};

const styles = StyleSheet.create({
  text: {
    fontFamily: 'System',
  },
});

export default GlobalText;
''');

    await _createFile('$corePath/presentation/components', 'GlobalButton.tsx', '''
import React from 'react';
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  ActivityIndicator,
  ViewStyle,
} from 'react-native';
import { AppColors } from '../../theme/app_colors';

interface GlobalButtonProps {
  onPress?: () => void;
  title: string;
  isLoading?: boolean;
  disabled?: boolean;
  backgroundColor?: string;
  textColor?: string;
  style?: ViewStyle;
  borderRadius?: number;
}

const GlobalButton: React.FC<GlobalButtonProps> = ({
  onPress,
  title,
  isLoading = false,
  disabled = false,
  backgroundColor = AppColors.primary,
  textColor = AppColors.white,
  style,
  borderRadius = 10,
}) => {
  const isDisabled = disabled || isLoading;

  return (
    <TouchableOpacity
      onPress={onPress}
      disabled={isDisabled}
      style={[
        styles.btn,
        {
          backgroundColor: isDisabled ? AppColors.grey : backgroundColor,
          borderRadius,
        },
        style,
      ]}
      activeOpacity={0.8}
    >
      {isLoading ? (
        <ActivityIndicator color={textColor} />
      ) : (
        <Text style={[styles.text, { color: textColor }]}>{title}</Text>
      )}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  btn: {
    height: 50,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 16,
  },
  text: {
    fontSize: 16,
    fontWeight: '600',
  },
});

export default GlobalButton;
''');

    await _createFile('$corePath/presentation/components', 'GlobalLoader.tsx', '''
import React from 'react';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { AppColors } from '../../theme/app_colors';
import GlobalText from './GlobalText';

interface GlobalLoaderProps {
  text?: string;
  color?: string;
}

const GlobalLoader: React.FC<GlobalLoaderProps> = ({
  text,
  color = AppColors.primary,
}) => {
  return (
    <View style={styles.container}>
      <ActivityIndicator size="large" color={color} />
      {text ? <GlobalText str={text} style={styles.text} /> : null}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  text: { marginLeft: 10 },
});

export default GlobalLoader;
''');

    await _createFile('$corePath/presentation/components', 'GlobalInput.tsx', '''
import React, { useState } from 'react';
import {
  TextInput,
  View,
  Text,
  StyleSheet,
  TextInputProps,
  ViewStyle,
} from 'react-native';
import { AppColors } from '../../theme/app_colors';

interface GlobalInputProps extends TextInputProps {
  label?: string;
  error?: string;
  containerStyle?: ViewStyle;
  borderRadius?: number;
}

const GlobalInput: React.FC<GlobalInputProps> = ({
  label,
  error,
  containerStyle,
  borderRadius = 10,
  style,
  ...rest
}) => {
  const [focused, setFocused] = useState(false);

  return (
    <View style={[styles.container, containerStyle]}>
      {label ? <Text style={styles.label}>{label}</Text> : null}
      <TextInput
        style={[
          styles.input,
          { borderRadius, borderColor: error ? AppColors.error : focused ? AppColors.primary : AppColors.lightGrey },
          style,
        ]}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        placeholderTextColor={AppColors.textHint}
        {...rest}
      />
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { marginBottom: 12 },
  label: { fontSize: 14, fontWeight: '500', marginBottom: 6, color: AppColors.textPrimary },
  input: {
    height: 50,
    borderWidth: 1,
    paddingHorizontal: 14,
    fontSize: 14,
    backgroundColor: AppColors.white,
    color: AppColors.textPrimary,
  },
  error: { fontSize: 12, color: AppColors.error, marginTop: 4 },
});

export default GlobalInput;
''');

    await _createFile('$corePath/presentation/hooks', 'useErrorHandler.ts', '''
import { useCallback } from 'react';
import { Alert } from 'react-native';
import { Failure, ValidationFailure } from '../../error/failures';

export function useErrorHandler() {
  const handleFailure = useCallback((failure: Failure) => {
    if (failure instanceof ValidationFailure) {
      Alert.alert('Validation Error', failure.firstError);
    } else {
      Alert.alert('Error', failure.message);
    }
  }, []);

  return { handleFailure };
}
''');
  }

  // ─── Feature Layer ────────────────────────────────────────────────────────

  Future<void> _createFeatureFiles(String featuresPath) async {
    final homesPath = '$featuresPath/homes';

    // Domain
    await _createFile('$homesPath/domain/entities', 'home.ts', '''
export interface HomeEntity {
  id: number;
  // Add your entity properties here
}
''');

    await _createFile('$homesPath/domain/repositories', 'home_repository.ts', '''
import { Either } from '../../../core/error/exception_handler';
import { Failure } from '../../../core/error/failures';
import { HomeEntity } from '../entities/home';

export interface HomeRepository {
  getHomes(): Promise<Either<Failure, HomeEntity[]>>;
}
''');

    await _createFile('$homesPath/domain/usecases', 'get_home.ts', '''
import { Either } from '../../../core/error/exception_handler';
import { Failure } from '../../../core/error/failures';
import { UseCase, NoParams } from '../../../core/usecases/usecase';
import { HomeEntity } from '../entities/home';
import { HomeRepository } from '../repositories/home_repository';

export class GetHomes implements UseCase<HomeEntity[], NoParams> {
  private readonly repository: HomeRepository;

  constructor(repository: HomeRepository) {
    this.repository = repository;
  }

  async call(_params: NoParams): Promise<Either<Failure, HomeEntity[]>> {
    return this.repository.getHomes();
  }
}
''');

    // Data
    await _createFile('$homesPath/data/models', 'home_model.ts', '''
import { HomeEntity } from '../../domain/entities/home';

export interface HomeModel extends HomeEntity {
  // Add additional model properties here
}

export function homeModelFromJson(json: Record<string, unknown>): HomeModel {
  return {
    id: json['id'] as number,
  };
}

export function homeModelToJson(model: HomeModel): Record<string, unknown> {
  return {
    id: model.id,
  };
}
''');

    await _createFile(
        '$homesPath/data/datasources', 'home_remote_datasource.ts', '''
import { ApiClient, HttpMethod } from '../../../core/network/api_client';
import { getUrl, ApiUrl } from '../../../core/constants/api_urls';
import { HomeModel, homeModelFromJson } from '../models/home_model';

export interface HomeRemoteDataSource {
  getHomes(): Promise<HomeModel[]>;
}

export class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  private readonly apiClient: ApiClient;

  constructor(apiClient: ApiClient) {
    this.apiClient = apiClient;
  }

  async getHomes(): Promise<HomeModel[]> {
    return this.apiClient.request<HomeModel[]>({
      endpoint: getUrl(ApiUrl.Homes),
      method: HttpMethod.GET,
      converter: (data) => {
        const list = data as Record<string, unknown>[];
        return list.map(homeModelFromJson);
      },
    });
  }
}
''');

    await _createFile(
        '$homesPath/data/datasources', 'home_local_datasource.ts', '''
import { HomeModel } from '../models/home_model';

export interface HomeLocalDataSource {
  getCachedHomes(): Promise<HomeModel[]>;
  cacheHomes(homes: HomeModel[]): Promise<void>;
}

export class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  async getCachedHomes(): Promise<HomeModel[]> {
    return [];
  }

  async cacheHomes(_homes: HomeModel[]): Promise<void> {
    // Implement caching with AsyncStorage if needed
  }
}
''');

    await _createFile(
        '$homesPath/data/repositories', 'home_repository_impl.ts', '''
import { handleException, Either } from '../../../core/error/exception_handler';
import { Failure } from '../../../core/error/failures';
import { HomeEntity } from '../../domain/entities/home';
import { HomeRepository } from '../../domain/repositories/home_repository';
import { HomeRemoteDataSource } from '../datasources/home_remote_datasource';
import { HomeLocalDataSource } from '../datasources/home_local_datasource';

export class HomeRepositoryImpl implements HomeRepository {
  private readonly remoteDataSource: HomeRemoteDataSource;
  private readonly localDataSource: HomeLocalDataSource;

  constructor(remote: HomeRemoteDataSource, local: HomeLocalDataSource) {
    this.remoteDataSource = remote;
    this.localDataSource = local;
  }

  async getHomes(): Promise<Either<Failure, HomeEntity[]>> {
    return handleException(() => this.remoteDataSource.getHomes());
  }
}
''');

    // Presentation
    await _createFile('$homesPath/presentation/store', 'home_state.ts', '''
import { HomeEntity } from '../../domain/entities/home';
import { Failure } from '../../../../core/error/failures';

export type HomeStatus = 'idle' | 'loading' | 'success' | 'error';

export interface HomeState {
  status: HomeStatus;
  homes: HomeEntity[];
  failure?: Failure;
}

export const initialHomeState: HomeState = {
  status: 'idle',
  homes: [],
  failure: undefined,
};
''');

    await _createFile('$homesPath/presentation/store', 'home_store.ts', '''
import { create } from 'zustand';
import { HomeState, initialHomeState } from './home_state';
import { GetHomes } from '../../domain/usecases/get_home';
import { NoParams } from '../../../../core/usecases/usecase';
import { isRight, isLeft } from '../../../../core/error/exception_handler';
import { sl } from '../../../../core/di/service_locator';

interface HomeStore extends HomeState {
  fetchHomes(): Promise<void>;
  reset(): void;
}

export const useHomeStore = create<HomeStore>((set) => ({
  ...initialHomeState,

  fetchHomes: async () => {
    set({ status: 'loading', failure: undefined });
    const getHomes = sl.get<GetHomes>('getHomes');
    const result = await getHomes.call(new NoParams());
    if (isRight(result)) {
      set({ status: 'success', homes: result.value });
    } else if (isLeft(result)) {
      set({ status: 'error', failure: result.value });
    }
  },

  reset: () => set(initialHomeState),
}));
''');

    await _createFile('$homesPath/presentation/screens', 'HomeScreen.tsx', '''
import React, { useEffect } from 'react';
import { View, FlatList, StyleSheet, SafeAreaView } from 'react-native';
import { useHomeStore } from '../store/home_store';
import { useErrorHandler } from '../../../../core/presentation/hooks/useErrorHandler';
import GlobalLoader from '../../../../core/presentation/components/GlobalLoader';
import GlobalText from '../../../../core/presentation/components/GlobalText';
import HomeWidget from '../components/HomeWidget';

const HomeScreen: React.FC = () => {
  const { status, homes, failure, fetchHomes } = useHomeStore();
  const { handleFailure } = useErrorHandler();

  useEffect(() => {
    fetchHomes();
  }, []);

  useEffect(() => {
    if (status === 'error' && failure) {
      handleFailure(failure);
    }
  }, [status, failure]);

  if (status === 'loading') {
    return (
      <SafeAreaView style={styles.center}>
        <GlobalLoader text="Loading..." />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <FlatList
        data={homes}
        keyExtractor={(item) => String(item.id)}
        renderItem={({ item }) => <HomeWidget home={item} />}
        ListEmptyComponent={<GlobalText str="No data found" textAlign="center" />}
        contentContainerStyle={styles.list}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  list: { padding: 16, gap: 8 },
});

export default HomeScreen;
''');

    await _createFile(
        '$homesPath/presentation/components', 'HomeWidget.tsx', '''
import React from 'react';
import { View, StyleSheet } from 'react-native';
import { HomeEntity } from '../../domain/entities/home';
import GlobalText from '../../../../core/presentation/components/GlobalText';
import { AppColors } from '../../../../core/theme/app_colors';

interface HomeWidgetProps {
  home: HomeEntity;
}

const HomeWidget: React.FC<HomeWidgetProps> = ({ home }) => {
  return (
    <View style={styles.card}>
      <GlobalText str={String(home.id)} fontSize={14} color={AppColors.textPrimary} />
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: AppColors.white,
    borderRadius: 10,
    padding: 16,
    shadowColor: AppColors.black,
    shadowOpacity: 0.08,
    shadowOffset: { width: 0, height: 2 },
    shadowRadius: 4,
    elevation: 2,
  },
});

export default HomeWidget;
''');
  }

  // ─── Root Files ───────────────────────────────────────────────────────────

  Future<void> _createRootFiles(String srcPath, String basePath) async {
    await _createFile(srcPath, 'App.tsx', '''
import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { View, ActivityIndicator } from 'react-native';
import { initDependencies } from './core/di/service_locator';
import { navigationRef } from './core/routes/navigation_ref';
import { AppRoutes } from './core/routes/app_routes';
import { AppColors } from './core/theme/app_colors';
import HomeScreen from './features/homes/presentation/screens/HomeScreen';

const Stack = createStackNavigator();

const App: React.FC = () => {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    initDependencies().then(() => setReady(true));
  }, []);

  if (!ready) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" color={AppColors.primary} />
      </View>
    );
  }

  return (
    <NavigationContainer ref={navigationRef}>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name={AppRoutes.Home} component={HomeScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default App;
''');

    await _createFile(basePath, 'index.js', '''
import { AppRegistry } from 'react-native';
import App from './src/App';
import { name as appName } from './app.json';

AppRegistry.registerComponent(appName, () => App);
''');

    await _createFile(basePath, 'tsconfig.json', '''{
  "extends": "@react-native/typescript-config/tsconfig.json",
  "compilerOptions": {
    "strict": true,
    "baseUrl": ".",
    "paths": {
      "@core/*": ["src/core/*"],
      "@features/*": ["src/features/*"]
    }
  }
}
''');

    await _createFile(basePath, 'package.json', '''{
  "name": "$projectName",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "android": "react-native run-android",
    "ios": "react-native run-ios",
    "start": "react-native start",
    "test": "jest",
    "lint": "eslint . --ext .js,.jsx,.ts,.tsx",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "react": "18.3.1",
    "react-native": "0.75.0",
    "@react-navigation/native": "^6.1.18",
    "@react-navigation/stack": "^6.4.1",
    "@react-native-async-storage/async-storage": "^2.0.0",
    "@react-native-community/netinfo": "^11.4.1",
    "axios": "^1.7.7",
    "react-native-safe-area-context": "^4.11.0",
    "react-native-screens": "^3.34.0",
    "zustand": "^5.0.0"
  },
  "devDependencies": {
    "@react-native/typescript-config": "0.75.0",
    "@react-native/eslint-config": "0.75.0",
    "@types/react": "^18.3.11",
    "@types/react-native": "^0.73.0",
    "typescript": "5.0.4",
    "eslint": "^8.57.1",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.13"
  }
}
''');

    await _createFile(basePath, '.eslintrc.js', '''module.exports = {
  root: true,
  extends: ['@react-native'],
  rules: {
    'react-native/no-inline-styles': 'warn',
  },
};
''');

    await _createFile(basePath, '.gitignore', '''# OSX
.DS_Store

# Xcode
build/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata
*.xccheckout
*.moved-aside
DerivedData
*.hmap
*.ipa
*.xcuserstate

# Android/IntelliJ
build/
.idea
.gradle
local.properties
*.iml
*.hprof

# node.js
node_modules/
npm-debug.log
yarn-error.log

# BUCK
buck-out/
\\.buckd/
*.keystore
!debug.keystore

# FastLane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/test_output
fastlane/readme.md

# Bundle artifact
*.jsbundle

# CocoaPods
/ios/Pods/
''');
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _createFile(
      String dirPath, String fileName, String content) async {
    final file = File('$dirPath/$fileName');
    await file.writeAsString(content);
    print('  Created: $dirPath/$fileName');
  }
}
