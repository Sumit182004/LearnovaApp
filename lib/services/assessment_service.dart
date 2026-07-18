import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AssessmentService {
  // Replace this after deploying the FastAPI backend.
  static const String baseUrl =
      'https://learnovaapp-lfgn.onrender.com';

  // GENERATE ASSESSMENT


  static Future<Map<String, dynamic>> generateAssessment({
    required String standard,
  }) async {
    final Uri url = Uri.parse(
      '$baseUrl/generate-assessment',
    );

    try {
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'standard': standard,
        }),
      )
          .timeout(
        const Duration(seconds: 120),
      );

      final Map<String, dynamic> data =
      jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }

      throw Exception(
        data['detail'] ??
            'Unable to generate assessment.',
      );
    } catch (e) {
      throw Exception(
        'Assessment generation failed: $e',
      );
    }
  }

  // =========================================================
  // SUBMIT ASSESSMENT
  // =========================================================

  static Future<Map<String, dynamic>> submitAssessment({
    required String assessmentId,
    required Map<int, int> selectedAnswers,
  }) async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    // Get Firebase authentication token.
    final String? token =
    await user.getIdToken();

    if (token == null) {
      throw Exception(
        'Unable to get authentication token.',
      );
    }

    final Uri url = Uri.parse(
      '$baseUrl/submit-assessment',
    );

    final List<Map<String, dynamic>> answers =
    selectedAnswers.entries.map((entry) {
      return {
        'questionId': entry.key,
        'selectedAnswer': entry.value,
      };
    }).toList();

    try {
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'assessmentId': assessmentId,
          'answers': answers,
        }),
      )
          .timeout(
        const Duration(seconds: 60),
      );

      final Map<String, dynamic> data =
      jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }

      throw Exception(
        data['detail'] ??
            'Unable to submit assessment.',
      );
    } catch (e) {
      throw Exception(
        'Assessment submission failed: $e',
      );
    }
  }
}