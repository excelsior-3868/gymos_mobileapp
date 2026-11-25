import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'config.dart';

class ApiException implements Exception {
  final String message;
  final int status;

  ApiException(this.message, {this.status = 0});

  @override
  String toString() => message;
}

class ApiService {
  static String? _token;
  static VoidCallback? onUnauthorized;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
  }

  static Future<dynamic> request(
    String method,
    String path, {
    dynamic body,
  }) async {
    final url = Uri.parse('${AppConfig.apiUrl}$path');
    http.Response response;

    try {
      final reqBody = body != null ? jsonEncode(body) : null;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await http.post(url, headers: _headers, body: reqBody).timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http.put(url, headers: _headers, body: reqBody).timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: _headers).timeout(const Duration(seconds: 15));
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      dynamic data;
      try {
        data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        data = null;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      if (response.statusCode == 401) {
        if (_token != null) {
          onUnauthorized?.call();
        }
      }

      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Request failed with status code ${response.statusCode}';
      throw ApiException(msg, status: response.statusCode);
    } on SocketException {
      throw ApiException("Can't reach the server. Please check your network connection.");
    } on TimeoutException {
      throw ApiException("The server took too long to respond.");
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException("An unexpected error occurred: ${e.toString()}");
    }
  }

  /// Uploads one file as multipart/form-data and returns the decoded JSON response.
  static Future<dynamic> uploadFile(String path, String field, String filePath, {String mime = 'image/jpeg'}) async {
    final url = Uri.parse('${AppConfig.apiUrl}$path');
    try {
      final req = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Accept': 'application/json',
          if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
        })
        ..files.add(await http.MultipartFile.fromPath(field, filePath, contentType: MediaType.parse(mime)));
      final response = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 60)));
      dynamic data;
      try {
        data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        data = null;
      }
      if (response.statusCode >= 200 && response.statusCode < 300) return data;
      if (response.statusCode == 401 && _token != null) onUnauthorized?.call();
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Upload failed with status code ${response.statusCode}';
      throw ApiException(msg, status: response.statusCode);
    } on SocketException {
      throw ApiException("Can't reach the server. Please check your network connection.");
    } on TimeoutException {
      throw ApiException('The upload took too long. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Could not upload the photo: $e');
    }
  }

  static Future<dynamic> get(String path) => request('GET', path);
  static Future<dynamic> post(String path, {dynamic body}) => request('POST', path, body: body);
  static Future<dynamic> put(String path, {dynamic body}) => request('PUT', path, body: body);
  static Future<dynamic> delete(String path) => request('DELETE', path);
}

typedef VoidCallback = void Function();
