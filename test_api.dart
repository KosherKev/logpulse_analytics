import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:convert';

void main() async {
  final dio = Dio();
  final baseUrl = 'https://email-service-463804703329.us-central1.run.app';
  final apiKey = 'd83dcd990886bdaf11dbba347ce84726dfa6fc953162794558591306cc3bd69d148a4d69a0a9b932a0167661b92b97abe2c8bd621bf526eac4567a1693f6162e';
  
  dio.options.headers['X-API-Key'] = apiKey;

  print('=== LOGS SEARCH EVIDENCE ===');
  
  final testCases = ['payment', 'pay', 'PaYmEnT']; 
  
  for (var term in testCases) {
    try {
      final url = '$baseUrl/logs?search=${Uri.encodeComponent(term)}&limit=1';
      print('Outgoing URL: $url');
      final response = await dio.get(url);
      print('Response Status: ${response.statusCode}');
      print('Raw Response: ${jsonEncode(response.data)}');
      print('---------------------------');
    } on DioException catch (e) {
      print('Error on search for $term: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
    } catch (e) {
      print('Error on search for $term: $e');
    }
  }

  print('\n=== ERROR JSON EVIDENCE ===');
  try {
    final url = '$baseUrl/logs?level=error&limit=1';
    final response = await dio.get(url);
    
    dynamic data = response.data;
    List items = [];
    if (data is List) items = data;
    else if (data is Map && data['data'] is List) items = data['data'];
    
    if (items.isNotEmpty) {
      print('Raw Error Log Entry: ${jsonEncode(items.first)}');
    } else {
      print('No error logs found.');
    }
  } on DioException catch (e) {
    print('Error fetching error logs: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
  } catch (e) {
    print('Error fetching error logs: $e');
  }
}
