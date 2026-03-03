import 'package:flutter/material.dart';
import 'package:attendance_app/src/UI/home/QRcamer.dart';
import 'package:attendance_app/src/UI/home/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Needed before async code in main
  runApp(MyAppLauncher());
}

class MyAppLauncher extends StatelessWidget {
  const MyAppLauncher({super.key});

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastVisitedScreen = prefs.getString('lastVisitedScreen');

    if (lastVisitedScreen == 'CameraScreen') {
      return const screencam();
    } else {
      return const screenqr(); // Default to QR if not set
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: 'Attendance App',
            theme: ThemeData(),
            home: snapshot.data!,
          );
        } else {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
      },
    );
  }
}
