import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'loginpopup.dart';

enum DetectionStatus { noQR, fail, success, scan, noRecog }

class screenqr extends StatefulWidget {
  const screenqr({super.key});

  @override
  State<screenqr> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<screenqr> with WidgetsBindingObserver {
  late MobileScannerController scannerController;
  DetectionStatus? status;
  bool isDetected = false;
  bool isScanButtonClicked = false;
  bool isScanButtonVisible = true;
  bool isAllButtonsVisible = false;
  bool isSignInShow = false;
  bool isSignOutShow = false;
  bool isLunchInShow = false;
  bool isLunchOutShow = false;
  String name = "";
  String QR = "";
  bool shouldProcessQR = false;
  bool isSending = false;
  bool _isCameraInitialized = false;
  int _requestToken = 0;
  bool _isRefreshing = false;

  final String baseUrl = 'https://lasting-wallaby-healthy.ngrok-free.app/api';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isCameraInitialized) {
      _initializeCamera(); // Only initialize camera when needed
    } else if (state == AppLifecycleState.paused) {
      if (_isCameraInitialized) {
        scannerController
            .stop(); // Stop the camera when the app goes to background
      }
      _isCameraInitialized = false; // Mark as not initialized
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitialized) return;

    try {
      scannerController.dispose(); // Dispose of the old controller
      scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        returnImage: false,
      );
      await Future.delayed(const Duration(milliseconds: 300));
      await scannerController.start();
      setState(() {
        _isCameraInitialized = true; // Mark as initialized
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> _barcodeDetected(BarcodeCapture capture) async {
    if (!shouldProcessQR || isSending) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      try {
        final String? code = barcode.rawValue;
        if (code != null && code.isNotEmpty) {
          QR = code;
          setState(() {
            isSending = true;
            shouldProcessQR = false;
          });
          await sendQRCode();
          setState(() {
            isSending = false;
          });
        } else {
          setState(() => status = DetectionStatus.noQR);
        }
      } catch (e) {
        debugPrint('QR parsing error: $e');
        setState(() {
          status = DetectionStatus.noQR;
          isSending = false;
          shouldProcessQR = false;
        });
      }
    }
  }

  Future<void> sendQRCode() async {
    debugPrint('Sending QR: $QR');
    if (_isRefreshing) return;
    final currentToken = _requestToken;
    final url = Uri.parse('$baseUrl/getforattendance');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'qr': QR}),
    );

    if (currentToken != _requestToken) {
      return;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      handleResponse(data, currentToken);
    } else {
      debugPrint('QR send failed');
      setState(() => status = DetectionStatus.noQR);
    }
  }

  Future<void> sendAttendance(String label) async {
    final url = Uri.parse('$baseUrl/posttoattendance');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'qr': QR,
        'status': label,
        'embedding': '', // Send empty string for QR code
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✅ Attendance has been marked successfully!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
      _refreshScreen();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance already marked today')),
      );
    }
  }

  void handleResponse(dynamic data, int responseToken) {
    if (responseToken != _requestToken) {
      debugPrint('Ignoring response in handleResponse due to refresh.');
      return;
    }
    setState(() {
      name = data["name"];
      int code = data["data"];

      switch (code) {
        case 0:
          status = DetectionStatus.noQR;
          break;
        case 1:
          status = DetectionStatus.fail;
          break;
        case 2:
          status = DetectionStatus.success;
          isAllButtonsVisible = true;
          break;
        case 3:
          status = DetectionStatus.scan;
          break;
        case 4:
          status = DetectionStatus.noRecog;
          break;
        default:
          status = DetectionStatus.noQR;
      }

      isSignInShow = false;
      isSignOutShow = false;
      isLunchInShow = false;
      isLunchOutShow = false;

      String? lastAtt = data['lastatt'];

      if (lastAtt == null || lastAtt == "" || lastAtt == "Sign-out") {
        isSignInShow = true;
      } else if (lastAtt == "Sign-in") {
        isLunchOutShow = true;
        isSignOutShow = true;
      } else if (lastAtt == "Lunch-out") {
        isLunchInShow = true;
        isSignOutShow = false;
      } else if (lastAtt == "Lunch-in") {
        isSignOutShow = true;
      }

      isDetected = code == 2 || code == 4;
      isScanButtonClicked = false;
    });
  }

  void _refreshScreen() async {
    _isRefreshing = true;
    _requestToken++;

    await scannerController.stop();
    scannerController.dispose(); // Mark controller as disposed

    setState(() {
      isDetected = false;
      isScanButtonClicked = false;
      isScanButtonVisible = true;
      isAllButtonsVisible = false;
      status = null;
      name = "";
      QR = "";
      shouldProcessQR = false;
      _isCameraInitialized = false;
    });

    // Create a new controller instance
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );

    // Start new camera
    _initializeCamera();
    _isRefreshing = false;
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const LoginPage112();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scannerController.stop();
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: 100,
              height: 36,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _refreshScreen,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text(
                  'Refresh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Color(0xFF424242),
              size: 30,
            ),
            onPressed: () => _showLoginDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            height: screenSize.height,
            width: screenSize.width,
            child: _isCameraInitialized
                ? MobileScanner(
                    controller: scannerController,
                    onDetect: _barcodeDetected,
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getCurrentStatus(),
                      style: TextStyle(
                        fontSize: 24,
                        color: getCurrentStatusColor(),
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isScanButtonVisible) _scanNowStyled(),
                    if (isAllButtonsVisible) _markAttendanceStyled(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getCurrentStatus() {
    switch (status) {
      case DetectionStatus.noQR:
        return "No QR";
      case DetectionStatus.fail:
        return "Already marked";
      case DetectionStatus.success:
        return name;
      case DetectionStatus.scan:
        return "Scanning ..";
      case DetectionStatus.noRecog:
        return "No face recognized";
      default:
        return "Tap 'Scan Now' to start";
    }
  }

  Color getCurrentStatusColor() {
    switch (status) {
      case DetectionStatus.noQR:
      case DetectionStatus.fail:
      case DetectionStatus.noRecog:
        return Colors.orangeAccent;
      case DetectionStatus.success:
        return Colors.green;
      case DetectionStatus.scan:
        return Colors.yellow;
      default:
        return Colors.white70;
    }
  }

  Widget _scanNowStyled() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0175C2),
        minimumSize: const Size(200, 50),
      ),
      onPressed: () {
        setState(() {
          status = DetectionStatus.scan;
          isScanButtonVisible = false;
          shouldProcessQR = true;
        });
        // Add timeout to revert if no QR found
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && shouldProcessQR) {
            setState(() {
              status = DetectionStatus.noQR;
              shouldProcessQR = false;
              isScanButtonVisible = true;
            });
          }
        });
      },
      child: const Text(
        "Scan now",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _markAttendanceStyled() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (isSignInShow) _attendanceButton("Sign-in", Colors.blue),
        if (isSignOutShow) _attendanceButton("Sign-out", Colors.red),
        if (isLunchInShow) _attendanceButton("Lunch-in", Colors.green),
        if (isLunchOutShow) _attendanceButton("Lunch-out", Colors.orange),
      ],
    );
  }

  Widget _attendanceButton(String label, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(150, 50),
      ),
      onPressed: () {
        sendAttendance(label);
      },
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
