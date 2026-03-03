import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditAdminScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const EditAdminScreen({super.key, required this.adminData});

  @override
  _EditAdminScreenState createState() => _EditAdminScreenState();
}

class _EditAdminScreenState extends State<EditAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _username;
  late String _position;
  late String _oldPassword;
  late String _newPassword;
  late String _confirmPassword;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = widget.adminData['name'] ?? '';
    _username = widget.adminData['username'] ?? '';
    _position = widget.adminData['position'] ?? '';
    _oldPassword = ''; // Initialize old password as empty
    _newPassword = ''; // Initialize new password as empty
    _confirmPassword = ''; // Initialize confirm password as empty
  }

  void saveAdmin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      // Step 1: Check if the old password matches the one in adminData
      if (_oldPassword != widget.adminData['password']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Old password is incorrect')),
        );
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
        return;
      }

      // Step 2: Check if new password and confirm password match
      if (_newPassword != _confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match')),
        );
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
        return;
      }

      try {
        final response = await http.put(
          Uri.parse(
            'https://lasting-wallaby-healthy.ngrok-free.app/api/updateadmin/${widget.adminData['admin_id']}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': _name,
            'username': _username,
            'position': _position,
            'password': _newPassword, // Send new password if valid
          }),
        );

        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin updated successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update admin')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Edit Admin"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name Field
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onChanged: (value) => _name = value,
              ),
              const SizedBox(height: 10),
              // Username Field
              TextFormField(
                initialValue: _username,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a username';
                  }
                  return null;
                },
                onChanged: (value) => _username = value,
              ),
              const SizedBox(height: 10),
              // Position Field
              TextFormField(
                initialValue: _position,
                decoration: const InputDecoration(labelText: "Position"),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a position';
                  }
                  return null;
                },
                onChanged: (value) => _position = value,
              ),
              const SizedBox(height: 20),
              // Old Password Field
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: "Old Password"),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your old password';
                  }
                  return null;
                },
                onChanged: (value) => _oldPassword = value,
              ),
              const SizedBox(height: 10),
              // New Password Field
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a new password';
                  }
                  return null;
                },
                onChanged: (value) => _newPassword = value,
              ),
              const SizedBox(height: 10),
              // Confirm New Password Field
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm New Password",
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please confirm your new password';
                  }
                  return null;
                },
                onChanged: (value) => _confirmPassword = value,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: saveAdmin,
                      child: const Text("Save Changes"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
