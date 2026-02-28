import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StorageService {
  // TODO: Replace with your actual Cloudinary details
  static const String cloudName = "YOUR_CLOUD_NAME"; 
  static const String uploadPreset = "YOUR_UPLOAD_PRESET";

  /// Uploads image to Cloudinary using REST API (No CORS issues on Web)
  Future<String?> uploadProblemImageXFile(XFile file, String problemId) async {
    try {
      final bytes = await file.readAsBytes();
      
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$problemId.jpg',
        ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final json = jsonDecode(respStr);
        return json['secure_url']; // This is the direct image link
      } else {
        final error = await response.stream.bytesToString();
        print('Cloudinary upload failed: $error');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
