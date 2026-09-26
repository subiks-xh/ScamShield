import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/analysis_result.dart';

class ApiService {
  static String get baseUrl {
    if (const bool.hasEnvironment('API_BASE_URL')) {
      return const String.fromEnvironment('API_BASE_URL');
    }
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  // ─── Analysis ───────────────────────────────────────────────────────────────

  static Future<AnalysisResult> analyzeAudio({
    List<int>? audioBytes,
    String? audioPath,
    String? callerNumber,
    String? contactName,
    bool isDemo = false,
    String languageHint = 'auto',
  }) async {
    final uri = Uri.parse('$baseUrl/analyze');
    final request = http.MultipartRequest('POST', uri);

    if (audioBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', audioBytes, filename: 'audio.wav'));
    } else if (audioPath != null) {
      request.files.add(await http.MultipartFile.fromPath('file', audioPath));
    } else {
      throw Exception('Either audioBytes or audioPath must be provided');
    }
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
    List<int>? audioBytes,
    String? audioPath,
    required String contactName,
    String? relationship,
  }) async {
    final uri = Uri.parse('$baseUrl/enroll-voice');
    final request = http.MultipartRequest('POST', uri);
    
    if (audioBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', audioBytes, filename: 'enroll.wav'));
    } else if (audioPath != null) {
      request.files.add(await http.MultipartFile.fromPath('file', audioPath));
    } else {
      throw Exception('Either audioBytes or audioPath must be provided');
    }
    request.fields['contact_name'] = contactName;
    if (relationship != null) request.fields['relationship'] = relationship;

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── SOS ────────────────────────────────────────────────────────────────────
  
  static Future<bool> triggerSOS() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/sos/trigger'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Coaching ───────────────────────────────────────────────────────────────
  
  static Future<String?> getCoachingAdvice(String transcript) async {
    if (transcript.trim().isEmpty) return null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/coach/advice'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transcript': transcript}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['advice'];
      }
    } catch (_) {
      // fail silently
    }
    return null;
  }
}
