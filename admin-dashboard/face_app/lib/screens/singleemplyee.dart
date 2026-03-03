import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:face_app/screens/filteralter.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'search.dart';

class SingleEmployeeDetail extends StatefulWidget {
  const SingleEmployeeDetail({super.key, required this.name});
  final Map<String, dynamic> name;

  @override
  _SingleEmployeeDetailState createState() => _SingleEmployeeDetailState();
}

class _SingleEmployeeDetailState extends State<SingleEmployeeDetail> {
  Uint8List? _image;
  bool isLoaded = false;
  Map<String, dynamic>? empList;

  @override
  void initState() {
    super.initState();

    fetchData();
  }

  Future<void> fetchData() async {
    String eid =
        widget.name['emp_id'] ??
        'N/A'; // Get the emp_id for the specific employee
    try {
      final response = await http.get(
        Uri.parse(
          'https://lasting-wallaby-healthy.ngrok-free.app/api/employee-detail/$eid',
        ), // Updated API endpoint
      );
      if (response.statusCode == 200) {
        final employeeDetails = json.decode(response.body);
        if (employeeDetails != null) {
          String empPhoto = employeeDetails['emp_photo'];
          try {
            Uint8List bytes = base64Decode(empPhoto);
            setState(() {
              empList = employeeDetails;
              _image = bytes;
              isLoaded = true;
            });
          } catch (e) {
            print('Error decoding emp_photo: $e');
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load employee details')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Employee Details",
          style: TextStyle(color: Colors.black87),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Row(
                children: [
                  buildAvatarWithImagePicker(context),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name['emp_name'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "ID : ${widget.name['emp_id'] ?? 'N/A'}",
                          style: TextStyle(fontSize: 14),
                        ),
                        Row(
                          children: [
                            SizedBox(width: 10),
                            // IconButton(
                            //   icon: Icon(Icons.delete_rounded, color: Colors.red),
                            //   onPressed: () => deleteConfirmationDialog(context),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeAttendancePage(
                        empId: widget.name['emp_id'] ?? 'N/A',
                      ),
                    ),
                  );
                },
                child: Text('View Employee Attendance'),
              ),
              //               ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //                 builder: (context) => EmployeeAttendancePage(empId: 'OYS10'),
              //               ),
              //     );
              //   },
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.blue[900],
              //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              //   ),
              //   child: Text("View Attendance", style: TextStyle(color: Colors.white)),
              // ),

              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeAttendancePage(empId: widget.name['emp_id']?? 'N/A',)));//(widget.name['emp_name']?? 'N/A'
              //   },
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.blue[900],
              //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              //   ),
              //   child: Text("View Attendance", style: TextStyle(color: Colors.white)),
              // ),
              const SizedBox(height: 30),
              ProfileMenuWidget(
                title: "Current Status: ",
                subtitle: widget.name['status'] ?? 'N/A',
                icon: Icons.online_prediction,
              ),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Last attendance:",
                subtitle:
                    "${widget.name['date']} ${widget.name['time'] ?? 'N/A'}",
                icon: Icons.access_time_rounded,
              ),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Position:",
                subtitle: widget.name['position'] ?? 'N/A',
                icon: Icons.workspace_premium,
              ),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Blood Group: ",
                subtitle: widget.name['blood-group'] ?? 'N/A',
                icon: Icons.bloodtype,
              ),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Address: ",
                subtitle: widget.name['address'] ?? 'N/A',
                icon: Icons.location_on_sharp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAvatarWithImagePicker(BuildContext context) {
    // print("Building avatar with image picker");

    return _image != null
        ? CircleAvatar(radius: 55, backgroundImage: MemoryImage(_image!))
        : const CircleAvatar(
            radius: 55,
            backgroundImage: NetworkImage(
              "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
            ),
          );
  }

  bool isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  void deleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Employee'),
          content: Text('Are you sure you want to delete this employee?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                deleteEmployee();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void deleteEmployee() async {
    try {
      String id = widget.name['emp_id'] ?? 'N/A';
      var conn;
      final response = await http.delete(
        Uri.parse('${conn.connectionString}/api/delete/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('status') &&
          decoded['status'] == 'success') {
        successAlert(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => search()),
        ); // Assuming Search is the next page
      } else {
        // print('Unexpected response format: $decoded');
      }
    } catch (e) {
      // print('Error deleting employee: $e');
    }
  }

  void successAlert(BuildContext context) {
    QuickAlert.show(
      context: context,
      text: "Employee Updated",
      type: QuickAlertType.success,
    ).then((_) {
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => search()),
        ); // Assuming Search is the next page
      });
    });
  }
}

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.endIcon = true,
    this.textColor,
  });

  final String subtitle;
  final String title;
  final IconData icon;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    var iconColor = Colors.blueGrey;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            spreadRadius: 1,
            blurStyle: BlurStyle.outer,
            blurRadius: 11,
          ),
        ],
        color: Colors.white,
      ),
      child: ListTile(
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: iconColor.withOpacity(0.1),
          ),
          child: Icon(icon, color: iconColor),
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
