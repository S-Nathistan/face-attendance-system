import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:attendance_app/src/UI/home/QRcamer.dart';
import 'package:attendance_app/src/UI/home/camera.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Connect {
  String? readmeContent;
  bool isLoading = true;

  String? get connectionString => readmeContent;
}

class LoginPage112 extends StatefulWidget {
  const LoginPage112({super.key});

  @override
  State<LoginPage112> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage112> {
  late Connect conn;
  final _formKey = GlobalKey<FormState>();
  late Color myColor;
  late Size mediaSize;
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberUser = false;
  bool passwordVisible = false;
  bool isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserCredentials();
  }

  Future<void> _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberUser = prefs.getBool('rememberUser') ?? false;
      if (rememberUser) {
        usernameController.text = prefs.getString('username') ?? '';
        passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  Future<void> _saveUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberUser) {
      await prefs.setString('username', usernameController.text);
      await prefs.setString('password', passwordController.text);
    }
    await prefs.setBool('rememberUser', rememberUser);
  }

  Future<void> login() async {
    if (isLoggingIn) return;
    setState(() {
      isLoggingIn = true;
    });

    // final response = await http.post(
    //   Uri.parse('http://192.168.1.33:5000/api/login'),

    final response = await http.post(
      Uri.parse('https://lasting-wallaby-healthy.ngrok-free.app/api/login'),

      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'username': usernameController.text,
        'password': passwordController.text,
      }),
    );

    setState(() {
      isLoggingIn = false;
    });

    if (response.statusCode == 200) {
      // Assuming a 200 status code indicates success
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      // Adjust according to the actual structure of your response

      if (jsonResponse['status'] == "success") {
        TextInput.finishAutofillContext();
        //await _saveCredentials();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authorized successfully")),
        );

        Navigator.of(context).pop();

        await Future.microtask(() {
          _showPopup();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incorrect username or password")),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to log in")));
    }
  }

  void _showPopup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? lastVisitedScreen = prefs.getString('lastVisitedScreen');
    String selectedOption = lastVisitedScreen == 'CameraScreen'
        ? 'Camera'
        : 'QR';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Container(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    title: const Text('Camera'),
                    value: 'Camera',
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value.toString();
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('QR'),
                    value: 'QR',
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value.toString();
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedOption.isNotEmpty) {
                        String selectedScreen = selectedOption == 'Camera'
                            ? 'CameraScreen'
                            : 'QRScreen';

                        if (selectedScreen == lastVisitedScreen) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Already on $selectedOption screen",
                              ),
                            ),
                          );
                        } else {
                          await prefs.setString(
                            'lastVisitedScreen',
                            selectedScreen,
                          );
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => selectedOption == 'Camera'
                                  ? const screencam()
                                  : const screenqr(),
                            ),
                          );
                          successAlert(context, selectedOption);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select an option"),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(300, 40),
                    ),
                    child: const Text("Choose"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void successAlert(BuildContext context, String selectedOption) {
    String message;
    if (selectedOption == 'Camera') {
      message = "Camera option selected!";
    } else if (selectedOption == 'QR') {
      message = "QR option selected!";
    } else {
      message = "Option selected: $selectedOption";
    }

    QuickAlert.show(
      context: context,
      text: message,
      type: QuickAlertType.success,
    );
  }

  String? _validateUsername(value) {
    if (value!.isEmpty) {
      return "Enter your username";
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return "No special characters";
    }
    if (value.length < 3) {
      return "enter at least 3 characters";
    }
    return null;
  }

  String? _validatePassword(value) {
    if (value!.isEmpty) {
      return "Enter your password";
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return "No special characters";
    }
    if (value.length < 5) {
      return "Must be at least 5 characters";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    myColor = Colors.grey; // Set myColor to gray

    mediaSize = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        color: myColor,
        image: DecorationImage(
          image: const AssetImage("assets/image/green blue.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            myColor.withOpacity(0.2),
            BlendMode.dstATop,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [Positioned(bottom: 0, child: _buildBottom())]),
      ),
    );
  }

  Widget _buildBottom() {
    return SizedBox(
      width: mediaSize.width,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(60.0),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "User Authentication",
            style: TextStyle(
              color: myColor,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 80),

          /// USERNAME
          TextFormField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.person, color: Colors.black),
              labelStyle: const TextStyle(color: Colors.black),
              fillColor: Colors.white.withOpacity(0.3),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.black),
            validator: _validateUsername,
          ),
          const SizedBox(height: 15),

          /// PASSWORD
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock, color: Colors.black),
              labelStyle: const TextStyle(color: Colors.black),
              hintText: 'Enter your password',
              fillColor: Colors.white.withOpacity(0.3),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    passwordVisible = !passwordVisible;
                  });
                },
              ),
            ),
            obscureText: !passwordVisible,
            validator: _validatePassword,
          ),
          const SizedBox(height: 15),

          const SizedBox(height: 20),
          _buildLoginButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGreyText(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey));
  }

  Widget _buildLoginButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: isLoggingIn ? null : () => login(),
        // Disable button when logging in
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          backgroundColor: myColor,
          foregroundColor: Colors.white,
          elevation: 20,
          shadowColor: myColor,
          minimumSize: const Size.fromHeight(60),
        ),
        child: const Text("Authorise"),
      ),
    );
  }
}
