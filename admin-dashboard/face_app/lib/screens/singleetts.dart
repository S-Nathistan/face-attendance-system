import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:face_app/screens/filteralter.dart';
import 'package:face_app/screens/newupdate.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:external_path/external_path.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

final GlobalKey qrKey = GlobalKey();

class SingleEmployeeDetails extends StatelessWidget {
  const SingleEmployeeDetails({super.key, required this.name});
  final Map<String, dynamic> name;

  @override
  Widget build(BuildContext context) {
    void successAlert(BuildContext context) {
      QuickAlert.show(
        context: context,
        text: "Employee Deleted",
        type: QuickAlertType.success,
      );
    }

    Future<void> deleteEmployee(BuildContext context) async {
      try {
        String ID = name['emp_id'] ?? 'N/A';
        print("Deleting employee with ID: $ID");

        final response = await http.delete(
          Uri.parse(
            'https://lasting-wallaby-healthy.ngrok-free.app/api/delete/$ID',
          ),
          headers: {'Content-Type': 'application/json'},
        );

        // print('Response status: ${response.statusCode}');
        // print('Response body: ${response.body}');

        final decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic> && decoded.containsKey('status')) {
          // Show success dialog and wait until dismissed
          await QuickAlert.show(
            context: context,
            text: "Employee Deleted",
            type: QuickAlertType.success,
          );

          // Pop back after user taps OK
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        } else {
          print('Unexpected response format: $decoded');
        }
      } catch (e) {
        print('Error deleting employee: $e');
      }
    }

    void deleteConfirmationDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext alertContext) {
          return AlertDialog(
            title: const Text('Delete Employee'),
            content: const Text(
              'Are you sure you want to delete this employee?',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(alertContext).pop(); // Close dialog
                },
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () async {
                  Navigator.of(alertContext).pop(); // Close dialog
                  await deleteEmployee(context); // Use main context here
                },
              ),
            ],
          );
        },
      );
    }

    Future<String?> getExternalStoragePath() async {
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.request().isGranted) {
          try {
            String? path = await ExternalPath.getExternalStoragePublicDirectory(
              "Download",
            );
            final directory = Directory(path!);
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
            return path;
          } catch (e) {
            print("Error accessing external storage: $e");
            return null;
          }
        } else {
          await openAppSettings();
          return null;
        }
      }
      return null;
    }

    Future<void> saveQrToDownloads(BuildContext context, String empId) async {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Storage permission denied. Enable 'All Files Access'",
            ),
          ),
        );
        await openAppSettings();
        return;
      }

      try {
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 200));

        RenderRepaintBoundary boundary =
            qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        String fileName = '${empId}_QRCode.png';

        String? directoryPath = await getExternalStoragePath();
        if (directoryPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to access storage directory')),
          );
          return;
        }

        final filePath = '$directoryPath/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QR saved to: $filePath')));
      } catch (e) {
        print("Error saving QR: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving QR: $e')));
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Employee Details"),
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Row(
                children: [
                  buildAvatarWithImagePicker(
                    context,
                  ), // This will be on the left
                  SizedBox(
                    width: 12,
                  ), // Optional: Adds some space between the avatar and the text
                  Expanded(
                    // Wrap the icons in an Expanded widget
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Aligns the text to the start of the column
                      children: [
                        Text(
                          name['emp_name'] ?? 'N/A',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          "ID : ${name['emp_id'] ?? 'N/A'}",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                // Navigate to the desired screen when the edit button is tapped
                                deleteConfirmationDialog(context);
                              },
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(
                                    255,
                                    238,
                                    75,
                                    69,
                                  ), // Adjust color as needed
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            TextButton(
                              onPressed: () {
                                // Navigate to the desired screen when the edit button is tapped
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NewUpdateEmployeeApp(emp: name),
                                  ),
                                );
                              },
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(
                                    255,
                                    35,
                                    230,
                                    83,
                                  ), // Adjust color as needed
                                ),
                              ),
                            ), // Add some space between the icons
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              //deleteConfirmationDialog(context);
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeAttendancePage(
                          empId: name['emp_id'] ?? 'N/A',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "View Attendance",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ProfileMenuWidget(
                title: "Current Status: ",
                subtitle: "${name['status'] ?? 'N/A'}",
                icon: Icons.online_prediction,
              ),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Last attendance:",
                subtitle: "${name['date']} ${name['time'] ?? 'N/A'}",
                icon: Icons.access_time_rounded,
              ),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Position:",
                subtitle: "${name['position'] ?? 'N/A'}",
                icon: Icons.workspace_premium,
              ),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Blood Group: ",
                subtitle: "${name['blood-group'] ?? 'N/A'}",
                icon: Icons.bloodtype,
              ),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Address: ",
                subtitle: "${name['address'] ?? 'N/A'}",
                icon: Icons.location_on_sharp,
              ),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Download QR Code",
                subtitle: "",
                icon: Icons.download,
                endIcon: false,
                textColor: Colors.blue,
                onTap: () {
                  saveQrToDownloads(context, name['emp_id'] ?? 'N/A');
                },
              ),
              const SizedBox(height: 30),
              // QR Code and Download Button inside ProfileMenuWidget
              RepaintBoundary(
                key: qrKey,
                child: Padding(
                  // Wrap QR code with Padding widget
                  padding: const EdgeInsets.only(
                    bottom: 20.0,
                  ), // Adjust bottom padding as needed
                  child: Container(
                    color: Colors.white, // Add white background
                    padding: EdgeInsets.all(20),
                    child: QrImageView(
                      data: name['emp_id'] ?? 'N/A',
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor:
                          Colors.white, // Ensure QR has white background
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAvatarWithImagePicker(BuildContext context) {
    try {
      Uint8List image = base64Decode(name['emp_photo'] ?? '');
      return ClipOval(
        child: Image.memory(
          image,
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const CircleAvatar(
              radius: 55,
              backgroundImage: NetworkImage(
                "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
              ),
            );
          },
        ),
      );
    } catch (e) {
      // fallback on decoding errors
      return const CircleAvatar(
        radius: 55,
        backgroundImage: NetworkImage(
          "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
        ),
      );
    }
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
    this.onTap,
  });

  final String subtitle;
  final String title;
  final IconData icon;
  final bool endIcon;
  final Color? textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    var iconColor = Colors.blueGrey;

    return GestureDetector(
      // Wrap with GestureDetector to handle taps
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
