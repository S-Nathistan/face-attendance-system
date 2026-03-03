import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'AdminDetailsScreen.dart';
import 'CreateAdminScreen.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  bool isLoaded = false;
  List<dynamic> adminList = [];

  @override
  void initState() {
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://lasting-wallaby-healthy.ngrok-free.app/api/getadmins',
        ), // Replace with your API endpoint
      );
      final decoded = json.decode(response.body);
      setState(() {
        adminList = decoded;

        isLoaded = true;
      });
      for (var admin in adminList) {
        // print('Admin ${admin['name']} - Protected: ${admin['protected']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load admins: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Navigate to Create Admin Screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateAdminScreen(), // Create Admin screen
                ),
              );
              if (result == true) {
                fetchData();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/image/green blue.jpg',
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                "Admin Users",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: isLoaded
                    ? ListView.builder(
                        itemCount: adminList.length,
                        itemBuilder: (context, index) {
                          final adminName = adminList[index]['name'] ?? '';
                          final username = adminList[index]['username'] ?? '';
                          final position = adminList[index]['position'] ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(adminName),
                              subtitle: Text(position),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminDetailsScreen(
                                      adminData: adminList[index],
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  fetchData(); // Refresh the list after deletion
                                }
                              },
                            ),
                          );
                        },
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
