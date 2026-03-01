import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StorageService {
  static const String cloudName = "faakhirmemon"; 
  static const String uploadPreset = "lrpcfa";
  static const String apiKey = "STAGu0W7v0DPq8GMRnUZUUEFlJs";

  /// Uploads image to Cloudinary using REST API (No CORS issues on Web)
  Future<String?> uploadProblemImageXFile(XFile file, String problemId) async {
    try {
      final bytes = await file.readAsBytes();
      
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['api_key'] = apiKey
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$problemId.jpg',
        ));

      final response = await request.send();
      final respStr = await response.stream.bytesToString(); // Pehle response read karlein
      
      if (response.statusCode == 200) {
        final json = jsonDecode(respStr);
        return json['secure_url']; 
      } else {
        print('Cloudinary Error ($uploadPreset): $respStr'); // Is se exact error pata chalega
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
