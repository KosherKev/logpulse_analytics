import 'package:dio/dio.dart';
import 'dart:convert';

void main() async {
  final dio = Dio();
  final baseUrl = 'https://central-logging-service-858865328729.europe-west1.run.app/api/v1';
  final apiKey = 'cls_RBA8xoVM16L7CNi8kubgQ5rgplv4gYVCNV_vNtoxW_k';
  
  dio.options.headers['X-API-Key'] = apiKey;

  print('=== BACKEND EVIDENCE REDO ===');
  
  final testCases = ['', 'zzznonexistentterm999']; 
  
  for (var term in testCases) {
    try {
      final searchStr = term.isEmpty ? '' : '&search=${Uri.encodeComponent(term)}';
      final url = '$baseUrl/logs?limit=1$searchStr';
      print('Outgoing URL: $url');
      final response = await dio.get(url);
      print('Response Status: ${response.statusCode}');
      final data = response.data as Map<String, dynamic>?;
      print('Total results: ${data?['total']}');
      final logs = data?['data'] as List?;
      if (logs != null && logs.isNotEmpty) {
        print('First log traceId: ${logs[0]['traceId']}');
      } else {
        print('No logs returned.');
      }
      print('---------------------------');
    } catch (e) {
      print('Error on search for $term: $e');
    }
  }
}
