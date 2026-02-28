import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;

  Future<String?> uploadProblemImage(File image, String problemId) async {
    try {
      Reference ref = _storage.ref().child('problems/$problemId.jpg');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print(e);
      return null;
    }
  }
}
