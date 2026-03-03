import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'EmployeeEmbeddingDetailsScreen.dart'; // Import the new screen

class EmployeeTempCountScreen extends StatefulWidget {
  const EmployeeTempCountScreen({super.key});

  @override
  State<EmployeeTempCountScreen> createState() =>
      _EmployeeTempCountScreenState();
}

class _EmployeeTempCountScreenState extends State<EmployeeTempCountScreen> {
  bool isLoaded = false;
  List<dynamic> empTempList = [];
  String noticeMessage = '';
  Color noticeColor = Colors.red;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://lasting-wallaby-healthy.ngrok-free.app/api/getemployeetempcounts',
        ),
      );

      final decoded = json.decode(response.body);

      // Check if the response is a List or an error Map
      if (decoded is List) {
        setState(() {
          empTempList = decoded;
          isLoaded = true;

          bool allHaveThree = true;
          for (var item in decoded) {
            if ((item['temp_count'] ?? 0) < 3) {
              allHaveThree = false;
              break;
            }
          }

          noticeMessage = allHaveThree
              ? "Base images and new images used to identify the face"
              : "Only base images are used to identify the face, some employee does not have the all 3 temp image";

          noticeColor = allHaveThree ? Colors.green : Colors.red;
        });
      } else if (decoded is Map && decoded.containsKey('error')) {
        // Handle error response from backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error from backend: ${decoded['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load temp counts: $e')));
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
                "Employee Temp Counts",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                noticeMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: noticeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: isLoaded
                    ? ListView.builder(
                        itemCount: empTempList.length,
                        itemBuilder: (context, index) {
                          final empId = empTempList[index]['emp_id'] ?? '';
                          final tempCount =
                              empTempList[index]['temp_count'] ?? 0;

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
                              title: Text('Employee ID: $empId'),
                              subtitle: Text('Temp Count: $tempCount'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EmployeeEmbeddingDetailsScreen(
                                          empId: empId,
                                        ), // Pass empId
                                  ),
                                );
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
