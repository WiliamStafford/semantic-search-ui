import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ProductImagePicker extends StatefulWidget {
  final Function(String) onUploadSuccess;

  const ProductImagePicker({super.key, required this.onUploadSuccess});

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  bool _isUploading = false;
  Uint8List? _webImage;
  PlatformFile? _pickedFile;

  // Điền chính xác Cloud Name và Preset của bạn
  final String cloudName = 'dxz9mhmjz';
  final String uploadPreset = 'nongsan_unsigned';

  Future<void> _pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);

    if (result != null) {
      setState(() => _isUploading = true);
      try {
        final file = result.files.single;

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
        );

        request.fields['upload_preset'] = uploadPreset;

        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
          );
          setState(() => _webImage = file.bytes);
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('file', file.path!),
          );
          setState(() => _pickedFile = file);
        }

        // Gửi Request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          // Thành công
          var responseData = json.decode(response.body);
          String secureUrl = responseData['secure_url'];
          widget.onUploadSuccess(secureUrl);
        } else {
          debugPrint(" LỖI TỪ CLOUDINARY: ${response.body}");
        }

      } catch (e) {
        debugPrint(" LỖI HỆ THỐNG FLUTTER: $e");
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUpload,
      child: Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: _isUploading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : (_webImage != null || _pickedFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.memory(_webImage!, fit: BoxFit.cover, width: 150, height: 150)
              : Image.file(
            File(_pickedFile!.path!),
            fit: BoxFit.cover,
            width: 150,
            height: 150,
          ),
        )
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text("Chọn ảnh", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ],
        )),
      ),
    );
  }
}