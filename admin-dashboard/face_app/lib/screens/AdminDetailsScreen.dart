import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'EditAdminScreen.dart';

class AdminDetailsScreen extends StatelessWidget {
  const AdminDetailsScreen({super.key, required this.adminData});
  final Map<String, dynamic> adminData;

  @override
  Widget build(BuildContext context) {
    final isProtected =
        adminData['protected'].toString() == 'true' ||
        adminData['protected'] == 1;
    print('Is Protected Admin: $isProtected');

    // Function to show success alert after deletion
    void successAlert(BuildContext context) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin Deleted Successfully")),
      );
    }

    // Function to delete the admin
    void deleteAdmin() async {
      try {
        final response = await http.delete(
          Uri.parse(
            'https://lasting-wallaby-healthy.ngrok-free.app/api/deleteadmin/${adminData['admin_id']}',
          ),
        );
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success') {
          successAlert(context);
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context, true); // Go back to the list screen
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete admin")),
          );
        }
      } catch (e) {
        print('Error deleting admin: $e');
      }
    }

    // Function to show delete confirmation dialog
    void deleteConfirmationDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Admin'),
            content: const Text('Are you sure you want to delete this admin?'),
            actions: <Widget>[
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () {
                  deleteAdmin();
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
              ),
            ],
          );
        },
      );
    }

    // Function to navigate to edit admin screen
    Future<void> navigateToEditScreen(BuildContext context) async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditAdminScreen(adminData: adminData),
        ),
      );

      if (result == true) {
        Navigator.pop(context, true);
      }
    }

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
        title: const Text("Admin Details"),
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adminData['name'] ?? 'N/A',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Admin ID details
              ProfileMenuWidget(
                title: "Admin ID:",
                subtitle: adminData['admin_id']?.toString() ?? 'N/A',
                icon: Icons.person,
              ),
              const SizedBox(height: 10),
              // Username details
              ProfileMenuWidget(
                title: "Username:",
                subtitle: adminData['username'] ?? 'N/A',
                icon: Icons.account_circle,
              ),
              const SizedBox(height: 10),
              // Position details (newly added)
              ProfileMenuWidget(
                title: "Position:",
                subtitle: adminData['position'] ?? 'N/A',
                icon: Icons.work,
              ),
              // Delete and Edit Buttons
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isProtected
                    ? null
                    : () => deleteConfirmationDialog(context),
                child: const Text("Delete Admin"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isProtected ? Colors.grey : Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isProtected
                    ? null
                    : () => navigateToEditScreen(context),
                child: const Text("Edit Admin"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isProtected ? Colors.grey : Colors.green,
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
  });

  final String subtitle;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        trailing: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
