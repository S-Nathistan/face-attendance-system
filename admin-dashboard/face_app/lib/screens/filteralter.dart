import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:external_path/external_path.dart';
import 'package:file_selector/file_selector.dart';

class WorkLog extends StatelessWidget {
  const WorkLog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Work Log')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeAttendancePage(empId: 'OYS10'),
              ),
            );
          },
          child: Text('View Employee Attendance'),
        ),
      ),
    );
  }
}

//
class EmployeeAttendancePage extends StatefulWidget {
  const EmployeeAttendancePage({super.key, required this.empId, this.empName});
  final String? empId;
  final String? empName;

  @override
  _EmployeeAttendancePageState createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  List<Map<String, dynamic>> workEntries = [];
  String? year;
  String? month;
  int totalFullDays = 0;
  int totalHalfDays = 0;
  int _rowsPerPage = 10;
  final int _sortColumnIndex = 0;
  final bool _sortAscending = true;

  // Move the convertDecimalToHoursAndMinutes method here
  String convertDecimalToHoursAndMinutes(double decimalHours) {
    Duration d = Duration(seconds: (decimalHours * 3600).round());
    int hours = d.inHours;
    int minutes = d.inMinutes % 60;
    return '${hours} hr ${minutes} min';
  }

  @override
  void initState() {
    super.initState();
    year = DateTime.now().year.toString();
    month = DateTime.now().month.toString();
    updateList(year!, month!);
  }

  // Add the method here
  Future<String?> getExternalStoragePath() async {
    // Ensure that storage permissions are granted
    await Permission.storage.request();

    if (await Permission.storage.isGranted) {
      try {
        // Access the Downloads directory directly as a string
        String? path = await ExternalPath.getExternalStoragePublicDirectory(
          "Download",
        );

        // Check if the directory exists, and if not, create it
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
      print("Storage permission denied");
      return null;
    }
  }

  Future<void> updateList(String year, String month) async {
    final response = await http.get(
      // Uri.parse(
      //   'http://192.168.1.33:5000/api/EmployeeAttendance/${widget.empId}/$year/$month',
      // ),
      Uri.parse(
        'https://lasting-wallaby-healthy.ngrok-free.app/api/EmployeeAttendance/${widget.empId}/$year/$month',
      ),
    );
    if (response.statusCode == 200) {
      setState(() {
        final parsedData = jsonDecode(response.body);
        if (parsedData['results'] != null) {
          workEntries = List<Map<String, dynamic>>.from(parsedData['results']);
          totalFullDays = parsedData['full_day_count'];
          totalHalfDays = parsedData['half_day_count'];
        } else {
          print('Invalid JSON format');
          workEntries = [];
          totalFullDays = 0;
          totalHalfDays = 0;
        }
      });
    } else {
      print('Failed to fetch data: ${response.statusCode}');
      setState(() {
        workEntries = [];
        totalFullDays = 0;
        totalHalfDays = 0;
      });
    }
  }

  // export as excel
  Future<void> requestStoragePermission() async {
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      print("Permission granted!");
    } else {
      print("Permission denied!");
      // Optionally direct users to app settings to manually enable permission
      openAppSettings();
    }
  }

  Future<void> exportToExcel(
    BuildContext context,
    List<Map<String, dynamic>> workEntries,
    String empId,
    String month,
    String year,
    int totalFullDays,
    int totalHalfDays,
  ) async {
    // Request storage permission before attempting to save the file
    await requestStoragePermission();

    try {
      // Your existing Excel creation logic
      final excel = Excel.createExcel();
      final sheet = excel['Attendance'];

      // Header row for the Excel sheet
      sheet.appendRow([
        'Date',
        'Sign-in',
        'Lunch-out',
        'Lunch-in',
        'Sign-out',
        'Work Hours',
      ]);

      double totalWorkHours = 0;

      // Data rows
      for (var entry in workEntries) {
        // Parse work hours (handle both numeric and "X.XX hrs" format)
        double workHours = 0;
        final raw = entry['work_hours']?.toString();
        if (raw != null && raw != 'N/A' && raw.trim().isNotEmpty) {
          // Extract numeric part from strings like "8.00 hrs"
          final numericString = raw.replaceAll(RegExp(r'[^0-9.]'), '');
          workHours = double.tryParse(numericString) ?? 0;
        }

        totalWorkHours += workHours;

        sheet.appendRow([
          entry['date'] ?? '',
          entry['signed_in'] ?? '',
          entry['lunch_out'] ?? '',
          entry['lunch_in'] ?? '',
          entry['sign_out'] ?? '',
          convertDecimalToHoursAndMinutes(workHours),
        ]);
      }

      // Add blank rows before summary
      sheet.appendRow(['', '', '', '', '', '']);
      sheet.appendRow(['', '', '', '', '', '']);

      // Summary section
      sheet.appendRow(['Summary']);
      sheet.appendRow(['Total Full Days', totalFullDays.toString()]);
      sheet.appendRow(['Total Half Days', totalHalfDays.toString()]);
      sheet.appendRow([
        'Total Work Hours',
        convertDecimalToHoursAndMinutes(totalWorkHours),
      ]);

      final fileName = 'Attendance_${empId}_$month-$year.xlsx';
      final Uint8List bytes = Uint8List.fromList(excel.save()!);

      // Check Android SDK version to decide the method
      if (Platform.isAndroid) {
        // For Android SDK 21+ devices, use getDirectoryPath
        if (await Permission.storage.request().isGranted) {
          final directoryPath = await getDirectoryPath();

          if (directoryPath == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unable to access storage directory')),
            );
            return;
          }

          final filePath = '$directoryPath/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Excel file saved to: $filePath')),
          );
        } else {
          // For older Android versions (SDK < 21), use a hardcoded path
          final path = '/storage/emulated/0/Download/';
          final filePath = '$path/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Excel file saved to: $filePath')),
          );
        }
      } else {
        // Handle other platforms like iOS, Windows, etc. (using the usual getSaveLocation or file path)
        final String? path = await getExternalStoragePath();
        if (path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to access storage directory')),
          );
          return;
        }

        final filePath = '$path/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel file saved to: $filePath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving Excel: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.empName ?? 'Employee Attendance')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<String>(
                  value: year,
                  onChanged: (String? newValue) {
                    setState(() {
                      year = newValue!;
                      updateList(year!, month!);
                    });
                  },
                  items: List.generate(10, (index) {
                    int currentYear = DateTime.now().year;
                    return DropdownMenuItem<String>(
                      value: (currentYear - index).toString(),
                      child: Text((currentYear - index).toString()),
                    );
                  }),
                ),
                SizedBox(width: 20),
                DropdownButton<String>(
                  value: month,
                  onChanged: (String? newValue) {
                    setState(() {
                      month = newValue!;
                      updateList(year!, month!);
                    });
                  },
                  items: List.generate(12, (index) {
                    return DropdownMenuItem<String>(
                      value: (index + 1).toString(),
                      child: Text(_getMonthName(index + 1)),
                    );
                  }),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Total Full Days: $totalFullDays',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Half Days: $totalHalfDays',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            workEntries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No attendance records found.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : PaginatedDataTable(
                    header: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Text(
                            'Employee Attendance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                exportToExcel(
                                  context,
                                  workEntries,
                                  widget.empId ?? '',
                                  month ?? '',
                                  year ?? '',
                                  totalFullDays,
                                  totalHalfDays,
                                );
                              },
                              icon: Icon(
                                Icons.download,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: Text(
                                "Download",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    rowsPerPage: _rowsPerPage,
                    onRowsPerPageChanged: (int? value) {
                      setState(() {
                        _rowsPerPage = value!;
                      });
                    },
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Sign-in')),
                      DataColumn(label: Text('Lunch-out')),
                      DataColumn(label: Text('Lunch-in')),
                      DataColumn(label: Text('Sign-out')),
                      DataColumn(label: Text('Total Work Hours')),
                    ],
                    source: _EmployeeAttendanceDataSource(workEntries),
                  ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int monthNumber) {
    switch (monthNumber) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}

class _EmployeeAttendanceDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _workEntries;

  _EmployeeAttendanceDataSource(this._workEntries);

  // Add this method inside the class
  String convertDecimalToHoursAndMinutes(double decimalHours) {
    Duration d = Duration(seconds: (decimalHours * 3600).round());
    int hours = d.inHours;
    int minutes = d.inMinutes % 60;
    return '${hours} hr ${minutes} min';
  }

  // Helper function to calculate the total working hours
  double getTotalWorkHours() {
    double totalWorkHours = 0;
    for (var entry in _workEntries) {
      final raw = entry['work_hours']?.toString();
      if (raw != null && raw != 'N/A' && raw.trim().isNotEmpty) {
        // Extract numeric part from strings like "8.00 hrs"
        final numericString = raw.replaceAll(RegExp(r'[^0-9.]'), '');
        final parsed = double.tryParse(numericString);
        if (parsed != null) totalWorkHours += parsed;
      }
    }
    return totalWorkHours;
  }

  @override
  DataRow getRow(int index) {
    // Show attendance data rows
    if (index < _workEntries.length) {
      final entry = _workEntries[index];
      return DataRow(
        cells: [
          DataCell(Text(entry['date'])),
          DataCell(Text(entry['signed_in'] ?? 'N/A')),
          DataCell(Text(entry['lunch_out'] ?? 'N/A')),
          DataCell(Text(entry['lunch_in'] ?? 'N/A')),
          DataCell(Text(entry['sign_out'] ?? 'N/A')),
          DataCell(
            Text(
              convertDecimalToHoursAndMinutes(
                double.tryParse(entry['work_hours']?.toString() ?? '0') ?? 0,
              ),
            ),
          ),
        ],
      );
    }
    // Show summary row (this will be the last row)
    else if (index == _workEntries.length) {
      final TextStyle summaryStyle = TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      );

      double totalWorkHours = getTotalWorkHours(); // Get total work hours
      String formattedTotalWorkHours = convertDecimalToHoursAndMinutes(
        totalWorkHours,
      ); // Format total work hours

      return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) => Colors.grey[200],
        ),
        cells: [
          DataCell(Text('Total Of Month', style: summaryStyle)),
          DataCell(Text('', style: summaryStyle)),
          DataCell(Text('', style: summaryStyle)),
          DataCell(Text('', style: summaryStyle)),
          DataCell(Text('', style: summaryStyle)),
          DataCell(Text(formattedTotalWorkHours, style: summaryStyle)),
        ],
      );
    }

    // Fallback for any unexpected index
    return DataRow(cells: List.generate(6, (_) => DataCell(Text(''))));
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _workEntries.length + 1;

  @override
  int get selectedRowCount => 0;
}

String _findTime(List<dynamic> entries, String type) {
  for (var item in entries) {
    if (item['type'] == type) {
      return item['time'];
    }
  }
  return 'No $type';
}
