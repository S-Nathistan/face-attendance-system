import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'singleemplyee.dart';

void main() {
  runApp(search());
}

class search extends StatelessWidget {
  const search({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmployeeSearch(searchQuery: '');
  }
}

class EmployeeSearch extends StatefulWidget {
  final String searchQuery;

  const EmployeeSearch({super.key, required this.searchQuery});

  @override
  _EmployeeSearchState createState() => _EmployeeSearchState(searchQuery);
}

class _EmployeeSearchState extends State<EmployeeSearch> {
  String searchQuery;
  List<dynamic> searchResults = []; // Initialize searchResults list
  _EmployeeSearchState(this.searchQuery); // Constructor to receive searchQuery

  String? _selectedPosition;
  final List<String> positions = [
    'All',
    'Developer',
    'Support',
    'Testing',
    'Manager',
    'Technical support trainee',
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        // Uri.parse('http://192.168.1.33:5000/api/search?query=$searchQuery'),
        Uri.parse(
          'https://lasting-wallaby-healthy.ngrok-free.app/api/search?query=$searchQuery',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          final parsedData = jsonDecode(response.body);
          if (parsedData is List) {
            searchResults = parsedData.cast<Map<String, dynamic>>();

            // Apply position filter
            if (_selectedPosition != null && _selectedPosition != 'All') {
              searchResults = searchResults
                  .where((item) => item['position'] == _selectedPosition)
                  .toList();
            }

            // Apply search query filter
            searchResults = searchResults
                .where(
                  (item) => item['emp_name'].toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
                )
                .toList();

            // print(searchResults);
          }
        });
      }
    } catch (e) {
      print(e);
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
              const SizedBox(
                height: kToolbarHeight,
              ), // Adjust for app bar height
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildPositionDropdown(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                    fetchData();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search by name',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final id = searchResults[index]['emp_id'];
                    final user = searchResults[index]['emp_name'];
                    final attStatus = searchResults[index]['status'];
                    final position = searchResults[index]['position'];
                    final photo = searchResults[index]['emp_photo'];
                    //final base64String = searchResults[index]['emp_photo'];

                    // final decodedBytes = base64Decode(base64String);
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
                        title: RichText(
                          text: TextSpan(
                            text: user,
                            style: const TextStyle(
                              fontSize:
                                  18, // Increases font size for better readability
                              fontWeight: FontWeight
                                  .bold, // Makes the title bold for emphasis
                              color:
                                  Colors.black, // Sets the title color to black
                            ),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Aligns text to start
                          children: <Widget>[
                            Text('Id No: $id'),
                            Text('Position: $position'),
                            Text('Status: $attStatus'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SingleEmployeeDetail(
                                  name:
                                      searchResults[index], // This should be the map representing an employee
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPosition,
      items: positions.map((String position) {
        return DropdownMenuItem<String>(
          value: position,
          child: Text(position, style: const TextStyle(color: Colors.black)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedPosition = newValue;
          fetchData(); // Reload data when the dropdown selection changes
        });
      },
      decoration: const InputDecoration(
        border: InputBorder.none,
        labelText: 'Position',
        labelStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
