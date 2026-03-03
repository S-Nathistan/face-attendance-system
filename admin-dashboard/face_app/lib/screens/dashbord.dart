import 'package:flutter/material.dart';
import 'package:face_app/screens/addemp.dart';
import 'details.dart';
import 'loginold style.dart';
import 'search.dart';
import 'statusupdate.dart';
import 'adminuserlistscreen.dart';

void main() {
  runApp(const Dashboard());
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late Color myColor;
  late Size mediaSize;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberUser = false;

  @override
  Widget build(BuildContext context) {
    myColor = Theme.of(context).primaryColor;
    mediaSize = MediaQuery.of(context).size;

    return MaterialApp(
      home: WillPopScope(
        onWillPop: () async {
          // This ensures back button exits the app directly
          return true;
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: AppBar(
              title: const Text(
                "Home",
                style: TextStyle(
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  letterSpacing: 2,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminUserListScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.person,
                    color: Colors.blue.withOpacity(0.5),
                    size: 35,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage112(),
                      ),
                      (Route<dynamic> route) =>
                          false, // removes all previous routes
                    );
                  },
                  icon: Icon(
                    Icons.logout,
                    color: Colors.blue.withOpacity(0.5),
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              _buildBackgroundImage(),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 150),
                    GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(20),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      shrinkWrap: true,
                      children: [
                        DashboardButton(
                          icon: Icons.person_add,
                          label: "Add",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEmployeeAp(),
                              ),
                            );
                          },
                        ),
                        DashboardButton(
                          icon: Icons.insert_chart_outlined,
                          label: "Status",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Empstatus1(),
                              ),
                            );
                          },
                        ),
                        DashboardButton(
                          icon: Icons.search,
                          label: "Search",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => search()),
                            );
                          },
                        ),
                        DashboardButton(
                          icon: Icons.info,
                          label: "Details",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Details(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Image.asset(
      'assets/image/green blue.jpg',
      fit: BoxFit.cover,
      width: double.infinity, // Ensure the image covers the full width
      height: double.infinity, // Ensure the image covers the full height
    );
  }
}

class DashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DashboardButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.black),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
