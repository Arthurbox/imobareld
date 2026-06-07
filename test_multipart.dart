
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

void main() async {
  final url = 'http://192.168.11.171:8000/api/v1/upload/';
  final filePath1 = 'test_dart_image1.txt';
  final filePath2 = 'test_dart_image2.txt';
  File(filePath1).writeAsStringSync('test content 1');
  File(filePath2).writeAsStringSync('test content 2');

  try {
    print('🚀 Testing MULTIPLE multipart upload with Dart http package...');
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('images', filePath1));
    request.files.add(await http.MultipartFile.fromPath('images', filePath2));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('📡 Status: ${response.statusCode}');
    print('📡 Body: ${response.body}');
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅ Success!');
    } else {
      print('❌ Failed!');
    }
  } catch (e) {
    print('🚨 Error: $e');
  } finally {
    if (File(filePath1).existsSync()) File(filePath1).deleteSync();
    if (File(filePath2).existsSync()) File(filePath2).deleteSync();
  }
}
