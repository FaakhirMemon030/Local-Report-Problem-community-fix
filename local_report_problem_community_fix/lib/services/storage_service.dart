import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StorageService {
  static const String cloudName = "ddjrzpj4r"; 
  static const String uploadPreset = "lrpcfa";

  /// Generic image uploader — use folder like 'workers/cnic', 'workers/bills'
  Future<String?> uploadImage(XFile file, String folder) async {
    try {
      final bytes = await file.readAsBytes();
      final uniqueName = '${folder}_${DateTime.now().millisecondsSinceEpoch}';
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$uniqueName.jpg',
        ));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(respStr)['secure_url'] as String?;
      } else {
        print('Cloudinary Error: ${response.statusCode} | $respStr');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  /// Uploads image to Cloudinary using REST API (No CORS issues on Web)
  Future<String?> uploadProblemImageXFile(XFile file, String problemId) async {
    return uploadImage(file, 'problems/$problemId');
  }
}
