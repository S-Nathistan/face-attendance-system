import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickalert/quickalert.dart';
import 'dashbord.dart';
import 'details.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'dart:math';

void main() {
  runApp(const AddEmployeeAp());
}

class AddEmployeeAp extends StatelessWidget {
  const AddEmployeeAp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: AddEmployee());
  }
}

class AddEmployee extends StatefulWidget {
  const AddEmployee({super.key});

  @override
  _AddEmployeeState createState() => _AddEmployeeState();
}

class _AddEmployeeState extends State<AddEmployee> {
  FocusNode nameFocusNode = FocusNode();
  FocusNode phoneFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode addressFocusNode = FocusNode();
  final List<String> BloodGroups = [
    "O+",
    "O-",
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
  ];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gmailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  TextEditingController positionController = TextEditingController();
  TextEditingController BloodGroupController = TextEditingController();
  TextEditingController addpicController = TextEditingController();

  String? _selecteAddpicOption;
  final List<String> Addphotos = ['From Gallery', 'From Camera'];

  final List<String> positions = [
    'Developer',
    'Support',
    'Testing',
    'Manager',
    'Technical support trainee',
  ];
  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();

  Uint8List? _image;
  Uint8List? _originalImageBytes;
  Uint8List? _additionalImage1;
  Uint8List? _additionalImage2;
  Uint8List? _additionalImage3;
  Uint8List? _additionalImage4;

  bool isAddingEmployee = false;
  bool isProcessingMainFace = false;

  bool isUploadingFace1 = false;
  bool isUploadingFace2 = false;
  bool isUploadingFace3 = false;
  bool isUploadingFace4 = false;

  bool isFace1Uploaded = false;
  bool isFace2Uploaded = false;
  bool isFace3Uploaded = false;
  bool isFace4Uploaded = false;

  bool isProcessingFace1 = false;
  bool isProcessingFace2 = false;
  bool isProcessingFace3 = false;
  bool isProcessingFace4 = false;

  bool _isImagePickerActive = false;
  String? _selectedPosition;
  String? _selectedBloodGroup;

  bool _allImagesSelected() {
    return _image != null &&
        isFace1Uploaded &&
        isFace2Uploaded &&
        isFace3Uploaded &&
        isFace4Uploaded;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Dashboard()),
              );
            },
          ),
        ),
        body: Stack(
          children: [
            Stack(
              fit: StackFit.expand,
              children: [
                _buildBackgroundImage(),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          buildAvatarWithImagePicker(context),
                          const SizedBox(height: 1),
                          const Text(
                            "Add Employee",
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _nameController,
                            labelText: 'Name',
                            focusNode: nameFocusNode,
                            validator: _validatename,
                          ),
                          const SizedBox(height: 20),
                          _buildBloodGroupDropdown(),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _addressController,
                            labelText: 'Address',
                            focusNode: addressFocusNode,
                            validator: _validateAddress,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _phoneController,
                            labelText: 'Phone Number',
                            focusNode: phoneFocusNode,
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _gmailController,
                            labelText: 'Gmail',
                            focusNode: emailFocusNode,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 20),
                          _buildPositionDropdown(),
                          const SizedBox(height: 20),
                          _buildAdditionalImageButton1(),
                          const SizedBox(height: 15),
                          _buildAdditionalImageButton2(),
                          const SizedBox(height: 15),
                          _buildAdditionalImageButton3(),
                          const SizedBox(height: 15),
                          _buildAdditionalImageButton4(),
                          const SizedBox(height: 15),
                          _buildAddEmployeeButton(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (isAddingEmployee) _buildOverlayMessage("Adding employee..."),
            if (isProcessingMainFace)
              _buildOverlayMessage("Processing main face..."),
            if (isProcessingFace1) _buildOverlayMessage("Processing face 1..."),
            if (isProcessingFace2) _buildOverlayMessage("Processing face 2..."),
            if (isProcessingFace3) _buildOverlayMessage("Processing face 3..."),
            if (isProcessingFace4) _buildOverlayMessage("Processing face 4..."),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayMessage(String message) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to handle additional image uploads and silent processing
  Future<void> _pickAdditionalImage(int imageNumber) async {
    if (_isImagePickerActive) return;
    _isImagePickerActive = true;

    try {
      final ImagePicker picker = ImagePicker();

      setState(() {
        if (imageNumber == 1) isProcessingFace1 = true;
        if (imageNumber == 2) isProcessingFace2 = true;
        if (imageNumber == 3) isProcessingFace3 = true;
        if (imageNumber == 4) isProcessingFace4 = true;
      });

      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        // If the user cancels without selecting an image, reset the state
        setState(() {
          if (imageNumber == 1) isProcessingFace1 = false;
          if (imageNumber == 2) isProcessingFace2 = false;
          if (imageNumber == 3) isProcessingFace3 = false;
          if (imageNumber == 4) isProcessingFace4 = false;
        });
        return;
      }

      Uint8List? imageBytes = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: 100,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
      );

      final faceImage = await _detectFaceInImage(image.path);

      if (faceImage == null) {
        setState(() {
          if (imageNumber == 1) {
            _additionalImage1 = null;
            isFace1Uploaded = false;
            isProcessingFace1 = false;
          } else if (imageNumber == 2) {
            _additionalImage2 = null;
            isFace2Uploaded = false;
            isProcessingFace2 = false;
          } else if (imageNumber == 3) {
            _additionalImage3 = null;
            isFace3Uploaded = false;
            isProcessingFace3 = false;
          } else if (imageNumber == 4) {
            _additionalImage4 = null;
            isFace4Uploaded = false;
            isProcessingFace4 = false;
          }
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No face detected in the image. Please try another.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        if (imageNumber == 1) {
          _additionalImage1 = faceImage;
          isFace1Uploaded = true;
          isProcessingFace1 = false;
        } else if (imageNumber == 2) {
          _additionalImage2 = faceImage;
          isFace2Uploaded = true;
          isProcessingFace2 = false;
        } else if (imageNumber == 3) {
          _additionalImage3 = faceImage;
          isFace3Uploaded = true;
          isProcessingFace3 = false;
        } else if (imageNumber == 4) {
          _additionalImage4 = faceImage;
          isFace4Uploaded = true;
          isProcessingFace4 = false;
        }
      });
    } catch (e) {
      print('Failed to add additional image: $e');
      setState(() {
        if (imageNumber == 1) isProcessingFace1 = false;
        if (imageNumber == 2) isProcessingFace2 = false;
        if (imageNumber == 3) isProcessingFace3 = false;
        if (imageNumber == 4) isProcessingFace4 = false;
      });
    } finally {
      _isImagePickerActive = false;
    }
  }

  // Button to upload the first additional image
  Widget _buildAdditionalImageButton1() {
    return ElevatedButton(
      onPressed: isAddingEmployee || isProcessingFace1
          ? null
          : () async {
              await _pickAdditionalImage(1);
            },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: isFace1Uploaded
            ? Colors.green
            : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.face, size: 20),
          SizedBox(width: 8),
          Text('Additional Face 1', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Button to upload the second additional image
  Widget _buildAdditionalImageButton2() {
    return ElevatedButton(
      onPressed: isAddingEmployee || isProcessingFace2
          ? null
          : () async {
              await _pickAdditionalImage(2);
            },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: isFace2Uploaded
            ? Colors.green
            : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.face, size: 20),
          SizedBox(width: 8),
          Text('Additional Face 2', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAdditionalImageButton3() {
    return ElevatedButton(
      onPressed: isAddingEmployee || isProcessingFace3
          ? null
          : () async {
              await _pickAdditionalImage(3);
            },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: isFace3Uploaded
            ? Colors.green
            : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.face, size: 20),
          SizedBox(width: 8),
          Text('Additional Face 3', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAdditionalImageButton4() {
    return ElevatedButton(
      onPressed: isAddingEmployee || isProcessingFace4
          ? null
          : () async {
              await _pickAdditionalImage(4);
            },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: isFace4Uploaded
            ? Colors.green
            : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.face, size: 20),
          SizedBox(width: 8),
          Text('Additional Face 4', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        // labelText: 'Username',
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.black),
        fillColor: Colors.white.withOpacity(0.3),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
      onChanged: (value) {
        setState(() {}); // Trigger validation on change
      },
    );
  }

  Widget _buildPositionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPosition,
      items: positions.map((String position) {
        return DropdownMenuItem<String>(
          value: position,
          child: Text(position, style: const TextStyle(color: Colors.black)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedPosition = newValue;
        });
      },
      decoration: InputDecoration(
        labelText: 'Position',
        labelStyle: const TextStyle(color: Colors.black),
        fillColor: Colors.white.withOpacity(0.3),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBloodGroup,
      items: BloodGroups.map((String bloodGroup) {
        return DropdownMenuItem<String>(
          value: bloodGroup,
          child: Text(bloodGroup, style: const TextStyle(color: Colors.black)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedBloodGroup = newValue;
        });
      },
      decoration: InputDecoration(
        labelText: 'BloodGroup',
        labelStyle: const TextStyle(color: Colors.black),
        fillColor: Colors.white.withOpacity(0.3),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildAddEmployeeButton() {
    Color myColor = Theme.of(context).primaryColor;

    bool canAdd = _allImagesSelected();

    return ElevatedButton(
      onPressed: isAddingEmployee
          ? null
          : () async {
              if (!canAdd) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please upload main photo and all 4 additional photos.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (_formKey.currentState!.validate()) {
                setState(() {
                  isAddingEmployee = true;
                });
                await addEmployee(context);
                setState(() {
                  isAddingEmployee = false;
                });
              }
            },
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: canAdd
            ? const Color.fromARGB(255, 68, 104, 221)
            : Colors.grey, // visually looks disabled
        foregroundColor: Colors.white,
        elevation: 20,
        shadowColor: myColor,
        minimumSize: const Size.fromHeight(60),
      ),
      child: const Text(
        'Add',
        style: TextStyle(fontSize: 25, color: Color.fromRGBO(5, 5, 5, 1)),
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (!phoneFocusNode.hasFocus && value!.isEmpty) {
      return null; // Don't show error unless field is focused
    }
    if (value == null || value.trim().isEmpty) {
      return "Please enter a phone number";
    }

    String trimmed = value.trim();

    // Pattern:
    // Either +94 followed by 9 digits
    // Or 0 followed by 9 digits
    final regex = RegExp(r'^(?:\+94\d{9}|0\d{9})$');

    if (!regex.hasMatch(trimmed)) {
      return "Phone number must be +94XXXXXXXXX or 0XXXXXXXXX without spaces.";
    }

    return null;
  }

  String? _validatename(String? value) {
    if (!nameFocusNode.hasFocus && value!.isEmpty) {
      return null; // Don't show error unless field is focused
    }
    if (value!.isEmpty) {
      return "Please enter a name";
    }
    // Updated regex to allow spaces within the name
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return "Only letters and spaces are allowed";
    }
    if (value.length < 2) {
      return "Please enter at least 2 characters";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (!emailFocusNode.hasFocus && value!.isEmpty) {
      return null; // Don't show error unless field is focused
    }
    if (value == null || value.isEmpty) {
      return "Please enter an email address";
    }
    // Trim whitespace from both ends
    final trimmedValue = value.trim();

    // Email regex pattern
    RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmedValue)) {
      return "Please enter a valid email address";
    }
    return null;
  }

  String? _validateid(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter a Id";
    }
    RegExp alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumericRegex.hasMatch(value)) {
      return "Only letters and numbers are allowed";
    }
    if (value.length < 2) {
      return "Please enter at least 2 characters";
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (!addressFocusNode.hasFocus && value!.isEmpty) {
      return null; // Don't show error unless field is focused
    }
    if (value!.isEmpty) {
      return "Please enter an address";
    }
    if (!RegExp(r'^[a-zA-Z0-9 \,\.]+$').hasMatch(value)) {
      return "No special characters";
    }
    if (value.length < 3) {
      return "Please enter at least 3 characters";
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value!.isEmpty) {
      return "Please enter a username";
    }
    // Add more validation rules for username if needed
    return null;
  }

  Future<void> _requestPermissionsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'This app needs access to your gallery or Camera to add photos.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Allow'),
              onPressed: () async {
                await requestGalleryPermission();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> requestGalleryPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Widget buildAvatarWithImagePicker(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                _originalImageBytes != null
                    ? CircleAvatar(
                        radius: 70,
                        backgroundImage: MemoryImage(_originalImageBytes!),
                      )
                    : const CircleAvatar(
                        radius: 70,
                        backgroundImage: NetworkImage(
                          "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
                        ),
                      ),
                if (isProcessingMainFace)
                  const SizedBox(
                    height: 140,
                    width: 140,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
            IconButton(
              onPressed: isProcessingMainFace
                  ? null
                  : () {
                      _pickImageFromGallery();
                    },
              icon: const Icon(Icons.add_a_photo, size: 30.0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundImage() {
    return Image.asset('assets/image/green blue.jpg', fit: BoxFit.cover);
  }

  Future<Uint8List> fixImageRotation(String imagePath) async {
    final result = await FlutterImageCompress.compressWithFile(
      imagePath,
      quality: 100,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: true,
    );
    if (result == null) {
      throw Exception("Failed to fix image orientation");
    }
    return Uint8List.fromList(result);
  }

  Future<void> _pickAndSaveImage() async {
    if (_isImagePickerActive) return;
    _isImagePickerActive = true;
    try {
      await _requestPermissionsDialog();
      final String imageData = await addbygallery();
      final Uint8List decodedImage = base64Decode(imageData);
      setState(() {
        _image = decodedImage;
      });
    } catch (e) {
      print('Failed to add image: $e');
    } finally {
      _isImagePickerActive = false;
    }
  }

  Future<Uint8List?> _detectFaceInImage(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final FaceDetector faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableContours: false,
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

      // === Crop with 20% padding ===
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
        quality: 100,
      );

      return Uint8List.fromList(compressedImage);
    } catch (e) {
      print('Error detecting face: $e');
      return null;
    } finally {
      faceDetector.close();
    }
  }

  File? selectedIMage;
  Future<void> _pickImageFromGallery() async {
    if (_isImagePickerActive) return;
    _isImagePickerActive = true;
    setState(() {
      isProcessingMainFace = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      _originalImageBytes = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: 100,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
      );

      final faceImage = await _detectFaceInImage(image.path);
      if (faceImage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No face detected in the image. Please try another.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      setState(() {
        _image = faceImage;
      });
    } catch (e) {
      print('Failed to add image: $e');
    } finally {
      setState(() {
        isProcessingMainFace = false;
        _isImagePickerActive = false;
      });
    }
  }

  Future<void> _pickAndSaveImagecam() async {
    if (_isImagePickerActive) return;
    _isImagePickerActive = true;
    setState(() {
      isProcessingMainFace = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      _originalImageBytes = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: 100,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
      );

      final faceImage = await _detectFaceInImage(image.path);
      setState(() {
        _image = faceImage;
      });
    } catch (e) {
      print('Failed to add image: $e');
    } finally {
      setState(() {
        isProcessingMainFace = false;
        _isImagePickerActive = false;
      });
    }
  }

  Future<String> addbygallery() async {
    await _requestPermissionsDialog();
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final String galleryBase64Image = base64Encode(
        await File(image.path).readAsBytes(),
      );
      print('Selected image from gallery: $galleryBase64Image');
      return galleryBase64Image;
    } else {
      throw Exception('No image selected.');
    }
  }

  Future<String> addbycam() async {
    await _requestPermissionsDialog();
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final String camerabase64Image = base64Encode(
        await File(image.path).readAsBytes(),
      );
      print(camerabase64Image);
      return camerabase64Image;
    } else {
      throw Exception('No image selected.');
    }
  }

  void _clearTextFields() {
    _gmailController.text = '';
    _nameController.text = '';
    _addressController.text = '';
    _phoneController.text = '';
    _selectedBloodGroup = null;
    _selectedPosition = null;
  }

  void successAlert() {
    QuickAlert.show(
      context: context,
      text: "Employee Added Successfully",
      type: QuickAlertType.success,
    );
  }

  Future<void> addEmployee(BuildContext context) async {
    try {
      String imageData = '';
      if (_image != null) {
        imageData = base64Encode(_image!);
      }

      String originalImageData = '';
      if (_originalImageBytes != null) {
        originalImageData = base64Encode(
          _originalImageBytes!,
        ); // original uncropped image
      }

      // Convert additional images to base64 if they exist
      String additionalImage1Data = '';
      if (_additionalImage1 != null) {
        additionalImage1Data = base64Encode(_additionalImage1!);
      }

      String additionalImage2Data = '';
      if (_additionalImage2 != null) {
        additionalImage2Data = base64Encode(_additionalImage2!);
      }

      String additionalImage3Data = '';
      if (_additionalImage3 != null) {
        additionalImage3Data = base64Encode(_additionalImage3!);
      }

      String additionalImage4Data = '';
      if (_additionalImage4 != null) {
        additionalImage4Data = base64Encode(_additionalImage4!);
      }

      // Send to /api/add first
      final response = await http.post(
        // Uri.parse('http://192.168.1.33:5000/api/add'),
        Uri.parse('https://lasting-wallaby-healthy.ngrok-free.app/api/add'),

        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "mail": _gmailController.text,
          "name": _nameController.text,
          "bg": _selectedBloodGroup,
          "address": _addressController.text,
          "phone": _phoneController.text,
          "position": _selectedPosition,
          "emp_photo": originalImageData,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add employee: ${response.body}');
      }

      // Get actual empid from response
      final decoded = json.decode(response.body);
      final actualEmpId = decoded[0]["empid"];
      print("Real Emp ID from backend: $actualEmpId");

      // Now send to /api/process_face using actual empid
      final embeddingResponse = await http.post(
        // Uri.parse('http://192.168.1.33:5000/api/process_face'),
        Uri.parse(
          'https://lasting-wallaby-healthy.ngrok-free.app/api/process_face',
        ),

        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "empid": actualEmpId,
          "image": imageData,
          "additional_images": [
            additionalImage1Data,
            additionalImage2Data,
            additionalImage3Data,
            additionalImage4Data,
          ],
        }),
      );

      if (embeddingResponse.statusCode != 200) {
        throw Exception(
          'Failed to process face embedding: ${embeddingResponse.body}',
        );
      }

      // Success
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Details()),
      ).then((_) {
        // When Details screen is popped, go back to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      });
      successAlert();
      _clearTextFields();
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
