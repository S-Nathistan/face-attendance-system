// ignore_for_file: unused_element, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:face_app/screens/details.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickalert/quickalert.dart';
import 'package:image_picker/image_picker.dart';

class NewUpdateEmployeeApp extends StatelessWidget {
  const NewUpdateEmployeeApp({super.key, required this.emp});
  final Map<String, dynamic> emp;

  @override
  Widget build(BuildContext context) {
    return UpdateEmployee(emp: emp);
  }
}

class UpdateEmployee extends StatefulWidget {
  final Map<String, dynamic> emp;
  const UpdateEmployee({super.key, required this.emp});

  @override
  UpdateEmployeeState createState() => UpdateEmployeeState();
}

class UpdateEmployeeState extends State<UpdateEmployee> {
  List<String> BloodGroups = ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"];
  final TextEditingController _nameController = TextEditingController();

  TextEditingController _mailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  TextEditingController positionController = TextEditingController();
  TextEditingController BloodGroupController = TextEditingController();

  TextEditingController addpicController = TextEditingController();
  String? _selecteAddpicOption;

  @override
  void initState() {
    super.initState();

    if (widget.emp['emp_photo'] != null &&
        widget.emp['emp_photo'].toString().isNotEmpty) {
      try {
        _image = base64Decode(widget.emp['emp_photo']);
      } catch (e) {
        print('Failed to decode image: $e');
      }
    }
    // Assigning values from employeeData to the controllers
    _nameController.text = widget.emp['emp_name'] ?? '';
    _addressController.text =
        widget.emp['address'] ??
        ''; // Assuming 'emp_address' is the correct key
    _phoneController.text = widget.emp['phone-number']
        .toString(); // Corrected typo here
    positionController.text =
        widget.emp['position'] ??
        ''; // Assuming 'emp_position' is the correct key for position
    BloodGroupController.text = widget.emp['blood-group'] ?? '';

    //var BloodGroup = [widget.emp['blood-group']];
    //print(BloodGroup);
    _selectedPosition = widget.emp['position'];
    _selectedBloodGroup = widget.emp['blood-group'];

    _mailController = TextEditingController(
      text: widget.emp['emp_email'] ?? '',
    );
  }

  // ignore: non_constant_identifier_names
  final List<String> Addphotos = ['From Gallery', 'From Camera'];

  String? _selectedPosition;
  String? _selectedBloodGroup;

  final List<String> positions = [
    'Developer',
    'Support',
    'Testing',
    'Manager',
    'Technical support trainee',
  ];
  bool isAddingEmployee = false;

  // Initialize the _formKey
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackgroundImage(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    buildAvatarWithImagePicker(context),
                    const SizedBox(height: 1),
                    const Text(
                      "Update Employee",
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildTextField(
                      controller: _nameController,
                      labelText: ' Name',
                      validator: _validatename,
                    ),
                    const SizedBox(height: 20),
                    _buildBloodGroupDropdown(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _mailController,
                      labelText: 'e-mail',
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _addressController,
                      labelText: 'Address',
                      validator: _validateAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 20),
                    _buildPositionDropdown(),
                    const SizedBox(height: 20),
                    _buildAddEmployeeButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
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
    );
  }

  Uint8List? _image;
  late String simage;
  Future<void> estate() async {
    simage = '';
    if (_selecteAddpicOption == 'From Gallery') {
      simage = await addbygallery();
    } else if (_selecteAddpicOption == 'From Camera') {
      simage = await addbycam();
    }
  }

  Widget buildAvatarWithImagePicker(BuildContext context) {
    Uint8List? image;
    try {
      if (widget.emp['emp_photo'] != null &&
          widget.emp['emp_photo'].toString().isNotEmpty) {
        image = base64Decode(widget.emp['emp_photo']);
      }
    } catch (e) {
      print('Invalid image data caught in buildAvatarWithImagePicker: $e');
    }
    return Stack(
      children: [
        Column(
          children: [
            _image != null
                ? CircleAvatar(
                    radius: 70,
                    backgroundImage: MemoryImage(_image!),
                  )
                : (image != null
                      ? CircleAvatar(
                          radius: 70,
                          backgroundImage: MemoryImage(image),
                        )
                      : const CircleAvatar(
                          radius: 70,
                          child: Icon(Icons.person),
                        )),
          ],
        ),
      ],
    );
  }

  late String imageData;
  Future<void> _pickImage() async {
    setState(() {
      _isImagePickerActive = true;
    });

    try {
      imageData = await addbygallery(); // or addbycam() for camera
      final Uint8List decodedImage = base64Decode(imageData);
      setState(() {
        _image = decodedImage;
      });
    } catch (e) {
      print('Failed to add image: $e');
    } finally {
      setState(() {
        _isImagePickerActive = false;
      });
    }
  }

  Widget _buildBackgroundImage() {
    return Image.asset('assets/image/green blue.jpg', fit: BoxFit.cover);
  }

  Widget _buildBloodGroupDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBloodGroup,
      items: BloodGroups.map((String position) {
        return DropdownMenuItem<String>(
          value: position,
          child: Text(position, style: const TextStyle(color: Colors.black)),
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

  Widget _buildAddEmployeeButton() {
    Color myColor;
    myColor = Theme.of(context).primaryColor;
    return ElevatedButton(
      onPressed: isAddingEmployee
          ? null
          : () async {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  isAddingEmployee = true; // Disable button during operation
                });
                await addEmployee();
                setState(() {
                  isAddingEmployee = false; // Re-enable button after operation
                });
              }
            },
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: Color.fromARGB(255, 68, 104, 221),
        foregroundColor: Colors.white,
        elevation: 20,
        shadowColor: myColor,
        minimumSize: const Size.fromHeight(60),
      ),
      child: Text(
        'Update',
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value!.isEmpty) {
      return "Please enter a phone number";
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return "Only numbers";
    }
    if (value.length != 10) {
      return "Please enter 10 digits";
    }
    return null;
  }

  String? _validatename(String? value) {
    if (value!.isEmpty) {
      return "Please enter a name";
    }
    if (!RegExp(r'^[a-z A-Z]+$').hasMatch(value)) {
      return "Only letters";
    }
    if (value.length < 2) {
      return "Please enter atleast 2 characters";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter an email address";
    }
    // Email regex pattern
    RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return "Please enter a valid email address";
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value!.isEmpty) {
      return "Please enter an address";
    }
    if (!RegExp(r'^[a-z A-Z 0-9 \,\.]+$').hasMatch(value)) {
      return "No special characters";
    }
    if (value.length < 3) {
      return "Please enter atleast 3 characters";
    }
    return null;
  }

  Future<void> _requestPermissionsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
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
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Close the dialog
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

  bool _isImagePickerActive = false;
  File? selectedIMage;
  Future<void> _pickImageFromGallery() async {
    if (_isImagePickerActive) return;
    _isImagePickerActive = true;
    try {
      final String base64Image = await addbygallery();
      if (base64Image != null) {
        setState(() {
          _image = base64Decode(base64Image);
          simage = base64Image; // Update simage here
        });
      }
    } catch (e) {
      print('Failed to add image: $e');
    } finally {
      _isImagePickerActive = false;
    }
  }

  Future<void> _pickAndSaveImagecam() async {
    if (_isImagePickerActive) return;
    _isImagePickerActive = true;
    try {
      final String imageData = await addbycam();
      if (imageData != null) {
        setState(() {
          _image = base64Decode(imageData);
          simage = imageData; // Update simage here
        });
      }
    } catch (e) {
      print('Failed to add image: $e');
    } finally {
      _isImagePickerActive = false;
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
      return camerabase64Image;
    } else {
      throw Exception('No image selected.');
    }
  }

  void successAlert(BuildContext context) {
    QuickAlert.show(
      context: context,
      text: "Employee Updated Successfully",
      type: QuickAlertType.success,
    );

    //Simulate onConfirm action with a delay
    Future.delayed(const Duration(seconds: 1), () {
      // Your navigation logic here
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => Details(
            // Pass the required parameters to Details screen
          ),
        ),
        (Route<dynamic> route) => false, // This removes all routes in the stack
      );
    });
  }

  Future<void> addEmployee() async {
    try {
      String imageData = '';
      if (_image != null) {
        imageData = base64Encode(_image!);
      } else {
        imageData = widget.emp['emp_photo']; // fallback to existing image
      }

      String ID = widget.emp['emp_id'];
      final response = await http.post(
        // Uri.parse('http://192.168.1.33:5000/api/update/$ID'),
        Uri.parse(
          'https://lasting-wallaby-healthy.ngrok-free.app/api/update/$ID',
        ),

        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          "emp_email": _mailController.text,
          "name": _nameController.text,
          "bg": _selectedBloodGroup,
          "address": _addressController.text,
          "phone": _phoneController.text,
          "position": _selectedPosition,
          "emp_photo": imageData,
        }),
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = await json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('status')) {
          // Handle success case here
          print('Success: ${decoded['status']}');
          successAlert(context);
          _clearTextFields();
          print('expected response format: $decoded');
          // Optionally, show a success alert or perform other actions
        } else {}
      } else {
        print('Failed to upload employee: ${response.statusCode}');
        // Optionally, show an error message to the user
      }
    } catch (e) {
      print('Error uploading employee: $e');
      // Consider adding more comprehensive error handling here
    }
  }

  Future<void> setpic() async {
    // Load the image from assets
    final imageBytes = await rootBundle.load(
      'assets/image/Kristen Stewart.jpg',
    );
    // Convert the image bytes to a Uint8List
    final imageBytesList = imageBytes.buffer.asUint8List();

    // Decode the image bytes to a Uint8List
    final decodedImage = base64Decode(base64Encode(imageBytesList));

    // Set the decoded image as the background image of a CircleAvatar
    setState(() {
      _image = decodedImage;
    });
  }

  void _clearTextFields() {
    _nameController.text = '';
    _addressController.text = '';
    _phoneController.text = '';
    _selectedBloodGroup = null;
    _selectedPosition = null;
  }
}
