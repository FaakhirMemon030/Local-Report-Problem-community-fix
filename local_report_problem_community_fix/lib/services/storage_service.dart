import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StorageService {
  static const String cloudName = "FaakhirMemon"; 
  static const String uploadPreset = "lrpcfa";

  /// Uploads image to Cloudinary using REST API (No CORS issues on Web)
  Future<String?> uploadProblemImageXFile(XFile file, String problemId) async {
    try {
      final bytes = await file.readAsBytes();
      
      // Multi-part request for Unsigned Upload
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['cloud_name'] = cloudName
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$problemId.jpg',
        ));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final json = jsonDecode(respStr);
        return json['secure_url']; 
      } else {
        // Detailed error for the user to see exactly what's wrong
        print('Cloudinary Error Details:');
        print('Status Code: ${response.statusCode}');
        print('URL: $url');
        print('Cloud Name: $cloudName');
        print('Preset: $uploadPreset');
        print('Response Body: $respStr');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
