import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class EmployeeEmbeddingDetailsScreen extends StatefulWidget {
  final String empId;
  const EmployeeEmbeddingDetailsScreen({super.key, required this.empId});

  @override
  State<EmployeeEmbeddingDetailsScreen> createState() =>
      _EmployeeEmbeddingDetailsScreenState();
}

class _EmployeeEmbeddingDetailsScreenState
    extends State<EmployeeEmbeddingDetailsScreen> {
  List<dynamic> embeddings = [];
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://lasting-wallaby-healthy.ngrok-free.app/api/getemployeetempdetails/${widget.empId}',
        ),
      );
      final decoded = json.decode(response.body);
      setState(() {
        embeddings = decoded['embeddings'] ?? [];
        isLoaded = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load embeddings: $e')));
    }
  }

  Future<Uint8List?> detectAndCropFace(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final FaceDetector faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
      ),
    );

    try {
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        print("No face detected.");
        return null;
      }

      final face = faces.first;
      final landmarks = face.landmarks;
      if (!landmarks.containsKey(FaceLandmarkType.leftEye) ||
          !landmarks.containsKey(FaceLandmarkType.rightEye)) {
        print("Eyes not detected.");
        return null;
      }

      final leftEye = landmarks[FaceLandmarkType.leftEye]!.position;
      final rightEye = landmarks[FaceLandmarkType.rightEye]!.position;

      final dx = rightEye.x - leftEye.x;
      final dy = rightEye.y - leftEye.y;
      final angle = -atan2(dy, dx) * (180 / pi);

      final img.Image originalImage = img.decodeImage(
        await File(imagePath).readAsBytes(),
      )!;
      final rotatedImage = img.copyRotate(originalImage, angle: angle);

      final faceRect = face.boundingBox;
      final paddingX = (faceRect.width * 0.2).toInt();
      final paddingY = (faceRect.height * 0.2).toInt();
      final x = (faceRect.left - paddingX).toInt().clamp(
        0,
        rotatedImage.width - 1,
      );
      final y = (faceRect.top - paddingY).toInt().clamp(
        0,
        rotatedImage.height - 1,
      );
      final width = (faceRect.width + 2 * paddingX).toInt().clamp(
        1,
        rotatedImage.width - x,
      );
      final height = (faceRect.height + 2 * paddingY).toInt().clamp(
        1,
        rotatedImage.height - y,
      );

      final cropped = img.copyCrop(
        rotatedImage,
        x: x,
        y: y,
        width: width,
        height: height,
      );
      final resized = img.copyResize(cropped, width: 112, height: 112);

      final compressedImage = await FlutterImageCompress.compressWithList(
        img.encodeJpg(resized),
        quality: 90,
      );

      return Uint8List.fromList(compressedImage);
    } catch (e) {
      print('Face detection error: $e');
      return null;
    } finally {
      faceDetector.close();
    }
  }

  void onAddImage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Upload'),
        content: const Text(
          'Select the image you want to upload for this employee.\n\n'
          '⚠️ Once you select an image, it will be uploaded immediately.\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      Uint8List? croppedImage = await detectAndCropFace(image.path);
      if (croppedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No face detected. Try another image.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String base64Image = base64Encode(croppedImage);

      final response = await http.post(
        Uri.parse(
          'https://lasting-wallaby-healthy.ngrok-free.app/api/AddEmployeeTempEmbedding',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"empid": widget.empId, "image": base64Image}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully.')),
        );
        fetchData(); // Refresh list after success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the employee has 3 embeddings
    bool hasThreeEmbeddings = embeddings.length >= 3;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(
          color: Colors.grey,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Employee Yearly Image Count"),
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Text(
                'Employee ID: ${widget.empId}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              // Display embeddings
              ...embeddings.map(
                (e) => ProfileMenuWidget(
                  title: "Embedding No:",
                  subtitle: e['emb_no'].toString(),
                  icon: Icons.numbers,
                  additionalText: e['created_date'],
                ),
              ),
              // Add Image Button
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: hasThreeEmbeddings
                    ? null
                    : onAddImage, // Disable button if 3 embeddings
                child: const Text("Add Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasThreeEmbeddings
                      ? Colors.grey
                      : Colors.blue, // Grey if disabled
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.additionalText = '',
  });

  final String subtitle;
  final String title;
  final IconData icon;
  final String additionalText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white,
      ),
      child: ListTile(
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.blueGrey.withOpacity(0.1),
          ),
          child: Icon(icon, color: Colors.blueGrey),
        ),
        title: Text(title, style: const TextStyle(fontSize: 10)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            if (additionalText.isNotEmpty)
              Text(
                'Created: $additionalText',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
