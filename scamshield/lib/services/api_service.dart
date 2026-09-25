import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/analysis_result.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Android emulator fallback
  );

  // ─── Analysis ───────────────────────────────────────────────────────────────

  static Future<AnalysisResult> analyzeAudio({
    required File audioFile,
    String? callerNumber,
    String? contactName,
    bool isDemo = false,
    String languageHint = 'auto',
  }) async {
    final uri = Uri.parse('$baseUrl/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));
    if (callerNumber != null) request.fields['caller_number'] = callerNumber;
    if (contactName != null) request.fields['contact_name'] = contactName;
    if (isDemo) request.fields['is_demo'] = 'true';
    if (languageHint != 'auto') request.fields['language_hint'] = languageHint;

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Analysis timed out after 30 seconds'),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Server error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AnalysisResult.fromJson(data);
  }

  // ─── Health check ───────────────────────────────────────────────────────────

  static Future<bool> isHealthy() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Community number reporting ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> reportNumber(
      String phoneNumber, {String? notes}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/report-number'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone_number': phoneNumber, 'notes': notes}),
        )
        .timeout(const Duration(seconds: 10));

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> checkNumber(String phoneNumber) async {
    final encoded = Uri.encodeComponent(phoneNumber);
    final response = await http
        .get(Uri.parse('$baseUrl/check-number/$encoded'))
        .timeout(const Duration(seconds: 5));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Voice enrollment ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> enrollVoice({
    required File audioFile,
    required String contactName,
    String? relationship,
  }) async {
    final uri = Uri.parse('$baseUrl/enroll-voice');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));
    request.fields['contact_name'] = contactName;
    if (relationship != null) request.fields['relationship'] = relationship;

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
