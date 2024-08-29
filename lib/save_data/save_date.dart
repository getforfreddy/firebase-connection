// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// class HomeScreen extends StatelessWidget {
//   final TextEditingController nameController = TextEditingController();
//
//   Future<void> saveNameToFirestore(String name) async {
//     try {
//       await FirebaseFirestore.instance.collection('users').add({
//         'name': name,
//         'createdAt': Timestamp.now(),
//       });
//       print("Name saved successfully!");
//     } catch (e) {
//       print("Failed to save name: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Save Name to Firestore')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: nameController,
//               decoration: InputDecoration(labelText: 'Enter your name'),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 String name = nameController.text;
//                 if (name.isNotEmpty) {
//                   await saveNameToFirestore(name);
//                 } else {
//                   print("Name field is empty");
//                 }
//               },
//               child: Text('Save Name'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  File? _pdfFile;

  String _generateFileName(String originalFileName) {
    String timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.-]'), '_');
    String sanitizedOriginalName = originalFileName.replaceAll(RegExp(r'\s+'), '_');
    // Remove file extension
    String fileNameWithoutExtension = sanitizedOriginalName.split('.').first;
    return '${fileNameWithoutExtension}_$timestamp';
  }

  Future<String?> uploadFileToStorage(File file, String filePath) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(filePath);
      await storageRef.putFile(file);
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Failed to upload file: $e");
      return null;
    }
  }

  Future<void> pickAndSetImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    } else {
      print("No image selected");
    }
  }

  Future<void> pickAndSetPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
      });
    } else {
      print("No file selected");
    }
  }

  Future<void> saveFormData() async {
    String name = nameController.text;
    if (name.isEmpty) {
      print("Name field is empty");
      return;
    }

    try {
      // Generate filenames without extension and with timestamp
      String imageFileName = _imageFile != null
          ? '${_generateFileName(_imageFile!.path.split('/').last)}.jpg'
          : '';
      String pdfFileName = _pdfFile != null
          ? '${_generateFileName(_pdfFile!.path.split('/').last)}.pdf'
          : '';

      // Upload files
      String? imageUrl = _imageFile != null
          ? await uploadFileToStorage(_imageFile!, 'user_images/$imageFileName')
          : null;
      String? pdfUrl = _pdfFile != null
          ? await uploadFileToStorage(_pdfFile!, 'user_pdfs/$pdfFileName')
          : null;

      // Save data to Firestore
      await FirebaseFirestore.instance.collection('user_data').add({
        'name': name,
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl,
        'pdfUrl': pdfUrl,
      });

      print("Data saved successfully!");
    } catch (e) {
      print("Failed to save data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Save Data with Attachments')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Enter your name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickAndSetImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 10),
            if (_imageFile != null) ...[
              Image.file(
                _imageFile!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 10),
            ],
            ElevatedButton(
              onPressed: pickAndSetPDF,
              child: Text('Pick PDF'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveFormData,
              child: Text('Save Data'),
            ),
          ],
        ),
      ),
    );
  }
}
