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
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return Uri.parse('$base$cleanPath');
  }

  Future<dynamic> get(String url) async {
    final response = await http
        .get(_resolveUri(url), headers: _headers())
        .timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    final response = await http
        .post(
          _resolveUri(url),
          headers: _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  Future<dynamic> put(String url, {Map<String, dynamic>? body}) async {
    final response = await http
        .put(
          _resolveUri(url),
          headers: _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  Future<dynamic> delete(String url) async {
    final response = await http
        .delete(_resolveUri(url), headers: _headers())
        .timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  Future<dynamic> uploadMultipart(
    String url, {
    required String fieldName,
    required String filename,
    required List<int> bytes,
    Map<String, String>? fields,
  }) async {
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
    final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    final json = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    } else {
      final detail = json is Map ? (json['detail'] ?? json['message'] ?? 'Request failed') : 'Request failed';
      throw Exception(detail.toString());
    }
  }
}
