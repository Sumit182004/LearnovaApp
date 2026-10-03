import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class TestSeriesService {
  static const String baseUrl =
      'https://learnovaapp-lfgn.onrender.com';

  // --------------------------------------------------
  // Firebase ID Token
  // --------------------------------------------------

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Unable to get Firebase ID token.');
    }

    return token;
  }

  // --------------------------------------------------
  // Generate Test
  // --------------------------------------------------

  Future<Map<String, dynamic>> generateTest({
    required String standard,
    required String subject,
    required String chapter,
    String? source,
  }) async {
    final token = await _getIdToken();

    final response = await http.post(
      Uri.parse('$baseUrl/generate-test'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'standard': standard,
        'subject': subject,
        'chapter': chapter,
        'source': source,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Failed to generate test.',
      );
    }

    return data;
  }

  // --------------------------------------------------
  // Submit Test
  // --------------------------------------------------

  Future<Map<String, dynamic>> submitTest({
    required String testId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final token = await _getIdToken();

    final response = await http.post(
      Uri.parse('$baseUrl/submit-test'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'testId': testId,
        'answers': answers,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Failed to submit test.',
      );
    }

    return data;
  }

  // --------------------------------------------------
// Test History
// --------------------------------------------------

  Future<List<dynamic>> getTestHistory({
    String? subject,
    String? chapter,
  }) async {
    final token = await _getIdToken();

    final queryParameters = <String, String>{};

    if (subject != null && subject.isNotEmpty) {
      queryParameters['subject'] = subject;
    }

    if (chapter != null && chapter.isNotEmpty) {
      queryParameters['chapter'] = chapter;
    }

    final uri = Uri.parse(
      '$baseUrl/test-history',
    ).replace(
      queryParameters: queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Failed to load test history.',
      );
    }

    return data['attempts'] ?? [];
  }

// --------------------------------------------------
// Test Result
// --------------------------------------------------

  Future<Map<String, dynamic>> getTestResult(
      String attemptId,
      ) async {
    final token = await _getIdToken();

    final response = await http.get(
      Uri.parse(
        '$baseUrl/test-result/$attemptId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Failed to load test result.',
      );
    }

    return data;
  }

// --------------------------------------------------
// Test Progress
// --------------------------------------------------

  Future<Map<String, dynamic>> getTestProgress({
    required String subject,
    required String chapter,
  }) async {
    final token = await _getIdToken();

    final uri = Uri.parse(
      '$baseUrl/test-progress',
    ).replace(
      queryParameters: {
        'subject': subject,
        'chapter': chapter,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Failed to load test progress.',
      );
    }

    return data;
  }

// --------------------------------------------------
// Personalized Recommendation
// --------------------------------------------------

  Future<Map<String, dynamic>> getTestRecommendation({
    required String subject,
    required String chapter,
  }) async {
    final token = await _getIdToken();

    final uri = Uri.parse(
      '$baseUrl/test-recommendation',
    ).replace(
      queryParameters: {
        'subject': subject,
        'chapter': chapter,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Failed to load recommendation.',
      );
    }

    return data;
  }
}
