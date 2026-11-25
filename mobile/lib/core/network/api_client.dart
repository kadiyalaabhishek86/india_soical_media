import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? token;

  void setToken(String? newToken) {
    token = newToken;
  }

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _resolveUri(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Uri.parse(url);
    }
    final base = ApiEndpoints.baseUrl;
    String cleanPath = url.startsWith('/') ? url : '/$url';
    if (cleanPath.startsWith('/api/v1/')) {
      cleanPath = cleanPath.substring('/api/v1'.length);
    }
    return Uri.parse('$base$cleanPath');
  }

  static const Duration timeoutDuration = Duration(seconds: 30);

  Future<dynamic> get(String url) async {
    try {
      final response = await http
          .get(_resolveUri(url), headers: _headers())
          .timeout(timeoutDuration);
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Server took too long to respond. The cloud service may be waking up, please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error: $e');
    }
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .post(
            _resolveUri(url),
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Server took too long to respond. The cloud service may be waking up, please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error: $e');
    }
  }

  Future<dynamic> put(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .put(
            _resolveUri(url),
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Server took too long to respond. The cloud service may be waking up, please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error: $e');
    }
  }

  Future<dynamic> delete(String url) async {
    try {
      final response = await http
          .delete(_resolveUri(url), headers: _headers())
          .timeout(timeoutDuration);
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Server took too long to respond. The cloud service may be waking up, please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error: $e');
    }
  }

  Future<dynamic> uploadMultipart(
    String url, {
    required String fieldName,
    required String filename,
    required List<int> bytes,
    Map<String, String>? fields,
  }) async {
    try {
      final uri = _resolveUri(url);
      final request = http.MultipartRequest('POST', uri);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
        ),
      );
      if (fields != null) {
        request.fields.addAll(fields);
      }
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Media upload timed out. Please check your internet connection and try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Upload failed: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      throw Exception('Server error (${response.statusCode}): ${response.reasonPhrase ?? "Service unavailable"}');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    } else {
      final detail = json is Map ? (json['detail'] ?? json['message'] ?? 'Request failed (${response.statusCode})') : 'Request failed (${response.statusCode})';
      throw Exception(detail.toString());
    }
  }
}
