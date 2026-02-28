import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Cross-platform upload using XFile (works on web AND mobile)
  Future<String?> uploadProblemImageXFile(XFile file, String problemId) async {
    try {
      final bytes = await file.readAsBytes();
      final ref = _storage.ref().child('problems/$problemId.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}
