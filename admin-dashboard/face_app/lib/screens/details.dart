import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:face_app/screens/singleetts.dart';
import 'package:http/http.dart' as http;
import 'package:face_app/screens/EmployeeTempCountScreen.dart';

void main() {
  runApp(const Details());
}

class Details extends StatelessWidget {
  const Details({super.key});

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
  List<dynamic> empList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoaded = false; // show loading while fetching
    });

    try {
      final response = await http.get(
        // Uri.parse('http://192.168.1.33:5000/api/getall'),
        Uri.parse('https://lasting-wallaby-healthy.ngrok-free.app/api/getall'),
      );
      final decoded = json.decode(response.body);
      setState(() {
        empList = decoded;
        isLoaded = true;
      });
    } catch (e) {
      setState(() {
        isLoaded = true; // still stop loading even on error
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load employees: $e')));
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
          Container(
            margin: const EdgeInsets.only(right: 10, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            child: SizedBox(
              width: 60, // Control the button width here
              height: 32,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmployeeTempCountScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Manual',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
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
                "Employee Details",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5), // Adjust for app bar height
              Expanded(
                child: isLoaded
                    ? ListView.builder(
                        itemCount: empList.length,
                        itemBuilder: (context, index) {
                          final user = empList[index]['emp_name'];
                          final time = empList[index]['time'];
                          final date = empList[index]['date'];
                          final empPhoto = empList[index]['emp_photo'] ?? '';
                          final address = empList[index]['address'];
                          final phone = empList[index]['phone-nubmer'];
                          final position = empList[index]['position'];
                          final e_mail = empList[index]['emp_email'];

                          Uint8List bytes = base64Decode(empPhoto);
                          final imageProvider = MemoryImage(bytes);

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
                              leading: CircleAvatar(
                                //backgroundImage: AssetImage('assets/image/profile.gif'),
                                backgroundImage: imageProvider,
                                radius: 30,
                              ),
                              title: Text(user),
                              subtitle: Text(''),
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                onPressed: () async {
                                  // Push the SingleEmployeeDetails screen and wait for the result
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SingleEmployeeDetails(
                                            name: empList[index],
                                          ),
                                    ),
                                  );

                                  // If the result is true (i.e., the employee was deleted), refresh the data
                                  if (result == true) {
                                    fetchData(); // Refresh employee list after coming back
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ), // Added loading indicator
              ),
            ],
          ),
        ],
      ),
    );
  }
}
