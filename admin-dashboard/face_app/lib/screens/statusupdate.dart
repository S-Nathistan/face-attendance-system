import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(Empstatus1());
}

class Empstatus1 extends StatelessWidget {
  const Empstatus1({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmployeeSearch();
  }
}

class EmployeeSearch extends StatefulWidget {
  const EmployeeSearch({super.key});

  @override
  _EmployeeSearchState createState() => _EmployeeSearchState();
}

class _EmployeeSearchState extends State<EmployeeSearch> {
  bool isLoaded = false;
  late List<dynamic> empList;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        // Uri.parse('http://192.168.1.33:5000/api/getall'),
        Uri.parse('https://lasting-wallaby-healthy.ngrok-free.app/api/getall'),
      );
      final decoded = json.decode(response.body);
      // print(decoded);
      setState(() {
        empList = decoded;
        isLoaded = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load employees: $e')));
    }
  }

  Color _getColorForStatus(String? status) {
    // Define your color logic based on different status values
    if (status == 'Sign-in') {
      return Colors.green; // Green color for 'Sign-in'
    } else if (status == 'Sign-out') {
      return Colors.red; // Red color for 'Sign-out'
    } else if (status == 'Lunch-in') {
      return Colors.blue; // Blue color for 'Lunch-in'
    } else if (status == '') {
      return Colors.yellow.shade100; // Default color for empty status
    } else {
      return Colors.yellow.shade100; // Default color for other statuses
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
              const SizedBox(height: kToolbarHeight),
              const Text(
                "Current Status",
                style: TextStyle(
                  fontSize: 35,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1), // Adjust for app bar height
              Expanded(
                child: isLoaded
                    ? ListView.builder(
                        itemCount: empList.length,
                        itemBuilder: (context, index) {
                          final user = empList[index]['emp_name'];
                          final attStatus = empList[index]['status'] ?? 'None';
                          final time = empList[index]['time'];
                          final date = empList[index]['date'];

                          //--this me
                          final empPhoto = empList[index]['emp_photo'];
                          Uint8List? bytes;

                          if (empPhoto == null ||
                              empPhoto == 'null' ||
                              empPhoto == '') {
                            print(
                              "Missing or empty photo for: ${empList[index]['emp_name']}",
                            );
                            bytes = null; // No decoding if photo is not valid
                          } else {
                            try {
                              bytes = base64Decode(empPhoto);
                            } catch (e) {
                              print(
                                "Failed to decode photo for ${empList[index]['emp_name']}: $e",
                              );
                              bytes = null;
                            }
                          }

                          final imageProvider = bytes != null
                              ? MemoryImage(bytes)
                              : const AssetImage(
                                      'assets/image/default_profile.png',
                                    )
                                    as ImageProvider;
                          //--me
                          return Card(
                            margin: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$user',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundImage: imageProvider,
                                        backgroundColor: Colors.grey[200],
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 4,
                                                    horizontal: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                    color: _getColorForStatus(
                                                      attStatus,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    attStatus == 'None'
                                                        ? 'Newly Added'
                                                        : attStatus,

                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  '$time',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            attStatus == 'None'
                                                ? 'No attendance yet'
                                                : 'Date: $date',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontStyle: attStatus == 'None'
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Additional content if needed
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
