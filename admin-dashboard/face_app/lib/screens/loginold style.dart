import 'package:flutter/material.dart';
import 'package:face_app/screens/dashbord.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage112 extends StatefulWidget {
  const LoginPage112({super.key});

  @override
  State<LoginPage112> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage112> {
  final _formKey = GlobalKey<FormState>();
  late Color myColor;
  late Size mediaSize;

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberUser = false;
  bool passwordVisible = false;
  bool isLoggingIn = false; // Track login process

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
    //print("Login button pressed");
    //print("Username: ${usernameController.text}");
    //print("Password: ${passwordController.text}");

    if (isLoggingIn) return; // Prevent multiple login attempts

    setState(() {
      isLoggingIn = true;
    });

    print("Sending login request...");
    final response = await http.post(
      // Uri.parse('http://192.168.1.33:5000/api/login'),
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
      print("Response parsed: $jsonResponse");
      // Adjust according to the actual structure of your response

      if (jsonResponse['status'] == "success") {
        await _saveUserCredentials();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
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
    myColor = Theme.of(context).primaryColor;
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
        resizeToAvoidBottomInset: false, // Prevent UI shift
        body: Stack(
          children: [
            Positioned(
              bottom: 0,
              child: SingleChildScrollView(child: _buildBottom()),
            ),
          ],
        ),
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
          padding: const EdgeInsets.all(32.0),
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
            "Admin Login",
            style: TextStyle(
              color: myColor,
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
          ),
          _buildGreyText("login with your credentials"),
          const SizedBox(height: 60),

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
                  color: Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    passwordVisible = !passwordVisible;
                  });
                },
              ),
            ),
            obscureText: !passwordVisible,
            style: const TextStyle(color: Colors.black),
            validator: _validatePassword,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Checkbox(
                value: rememberUser,
                onChanged: (bool? value) {
                  setState(() {
                    rememberUser = value ?? false;
                  });
                },
              ),
              const Text("Remember me", style: TextStyle(color: Colors.black)),
            ],
          ),
          const SizedBox(height: 20),
          _buildLoginButton(),
          const SizedBox(height: 20),
          _buildOtherLogin(),
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
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          elevation: 20,
          shadowColor: myColor,
          minimumSize: const Size.fromHeight(60),
        ),
        child: const Text("LOGIN"),
      ),
    );
  }

  Widget _buildOtherLogin() {
    return Center(
      child: Column(
        children: [
          _buildGreyText("Powered by"),
          Center(
            child: Image.asset(
              'assets/image/logo.png',
              height: 100,
              width: 200,
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}
