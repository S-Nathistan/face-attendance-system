import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'loginpopup.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math';
import 'dart:typed_data';

enum DetectionStatus { noFace, fail, success, scan, scanCaptured, noRecog }

class screencam extends StatefulWidget {
  const screencam({super.key});

  @override
  State<screencam> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<screencam> {
  CameraController? _controller;
  DetectionStatus? _status;

  Timer? _timeoutTimer;

  bool _isDetected = false;
  bool _isScanButtonClicked = false;
  bool _isScanButtonVisible = true;
  bool _isAllButtonsVisible = false;
  String _name = "";
  String _empId = "";
  final _throttleDelay = const Duration(milliseconds: 2000);
  DateTime? _lastScanTime;
  bool _isBackendReady = false;
  bool _isInitializing = true;
  bool isSignInShow = false;
  bool isSignOutShow = false;
  bool isLunchInShow = false;
  bool isLunchOutShow = false;
  bool _isRefreshing = false;
  bool _showLoadingGif = false;

  bool _hasTimedOut = false;

  Uint8List? _newEmbeddingBytes;
  int _requestToken = 0;

  // static const String _baseUrl = 'http://192.168.1.33:5000/api';
  static const String _baseUrl =
      'https://lasting-wallaby-healthy.ngrok-free.app/api';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkBackendStatus();
  }

  Future<void> _checkBackendStatus() async {
    int attempts = 0;
    const maxAttempts = 5;
    const retryDelay = Duration(seconds: 2);

    while (attempts < maxAttempts && !_isBackendReady) {
      attempts++;
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/health'))
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'ready') {
            setState(() {
              _isBackendReady = true;
              _isInitializing = false;
            });
            return;
          }
        } else if (response.statusCode == 500) {
          final errorData = jsonDecode(response.body);
          setState(() {
            _isInitializing = false;
          });
          _showErrorDialog('Initialization Error', errorData['error']);
          return;
        }
      } catch (e) {
        debugPrint('Health check error: $e');
      }

      if (attempts < maxAttempts) {
        await Future.delayed(retryDelay);
      }
    }

    if (!_isBackendReady) {
      setState(() {
        _isInitializing = false;
      });
      _showErrorDialog(
        'Connection Error',
        'Failed to connect to face recognition service',
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkBackendStatus(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      } else {
        await controller.dispose(); // If widget disposed during init
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _sendFaceImage(XFile image) async {
    if (_isRefreshing) return; // Prevent sending when refreshing
    final currentToken = _requestToken; // 🔴 Add here
    if (_lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) < _throttleDelay) {
      return;
    }
    _lastScanTime = DateTime.now();

    try {
      final originalBytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(originalBytes);
      if (decodedImage == null) throw Exception('Failed to decode image');

      // Adjust brightness
      final adjustedImage = _adjustBrightnessAutomatically(decodedImage);

      final inputImage = InputImage.fromFilePath(image.path);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableLandmarks: true, // Enable landmarks
          enableContours: false,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        setState(() => _status = DetectionStatus.noFace);
        return;
      }

      final face = faces.first;
      final landmarks = face.landmarks;

      if (!landmarks.containsKey(FaceLandmarkType.leftEye) ||
          !landmarks.containsKey(FaceLandmarkType.rightEye)) {
        setState(() => _status = DetectionStatus.noFace);
        return;
      }

      // Get eye positions
      final leftEye = landmarks[FaceLandmarkType.leftEye]!.position;
      final rightEye = landmarks[FaceLandmarkType.rightEye]!.position;

      // Calculate the angle between eyes
      final dx = rightEye.x - leftEye.x;
      final dy = rightEye.y - leftEye.y;
      final angle =
          -atan2(dy, dx) * (180 / pi); // in degrees, negative for correction

      // Rotate the image to align the eyes horizontally
      final rotatedImage = img.copyRotate(decodedImage, angle: angle);

      // Crop the face bounding box with 20% padding
      final faceRect = face.boundingBox;
      final paddingX = (faceRect.width * 0.2).toInt();
      final paddingY = (faceRect.height * 0.2).toInt();

      final x = (faceRect.left - paddingX).toInt().clamp(
        0,
        rotatedImage.width - 1,
      );
      final y = (faceRect.top - paddingY).toInt().clamp(
        0,
        rotatedImage.height - 1,
      );
      final width = (faceRect.width + 2 * paddingX).toInt().clamp(
        1,
        rotatedImage.width - x,
      );
      final height = (faceRect.height + 2 * paddingY).toInt().clamp(
        1,
        rotatedImage.height - y,
      );

      final cropped = img.copyCrop(
        rotatedImage,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      // Resize to 112x112
      final resized = img.copyResize(cropped, width: 112, height: 112);
      final compressedImage = img.encodeJpg(resized, quality: 100);

      debugPrint(
        'Sending cropped and aligned face image (${compressedImage.length} bytes)',
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/processfaceattendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Encode(compressedImage)}),
      );

      if (currentToken != _requestToken) {
        return;
      }

      if (response.statusCode == 200) {
        _timeoutTimer?.cancel();
        final data = jsonDecode(response.body);
        debugPrint('Face API response: $data');
        _handleResponse(data);
      } else {
        _timeoutTimer?.cancel();
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _timeoutTimer?.cancel();
      debugPrint('Error in _sendFaceImage: $e');
      if (mounted) {
        setState(() => _status = DetectionStatus.fail);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Function to calculate average brightness of an image
  double _calculateAverageBrightness(img.Image image) {
    int totalBrightness = 0;
    int pixelCount = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        int brightness = (r + g + b) ~/ 3;
        totalBrightness += brightness;
      }
    }

    return totalBrightness / pixelCount;
  }

  // Function to adjust brightness automatically
  img.Image _adjustBrightnessAutomatically(img.Image image) {
    double avgBrightness = _calculateAverageBrightness(image);

    const targetBrightness = 128.0;
    const maxAdjustment = 50;

    int brightnessAdjustment = (targetBrightness - avgBrightness).toInt();
    brightnessAdjustment = brightnessAdjustment.clamp(
      -maxAdjustment,
      maxAdjustment,
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        int r = (pixel.r.toInt() + brightnessAdjustment).clamp(0, 255);
        int g = (pixel.g.toInt() + brightnessAdjustment).clamp(0, 255);
        int b = (pixel.b.toInt() + brightnessAdjustment).clamp(0, 255);

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return image;
  }

  void _handleResponse(dynamic data) {
    if (!mounted) return;

    if (_hasTimedOut) {
      return;
    }

    setState(() {
      if (data['status'] == 'success') {
        _name = data['emp_name'];
        _empId = data['emp_id'];
        _status = DetectionStatus.success;

        final lastAtt = data['last_att']; // already there

        final similarity = data['similarity'];
        final embeddingBase64 = data['embedding'];
        _newEmbeddingBytes = base64Decode(embeddingBase64);

        isSignInShow = false;
        isSignOutShow = false;
        isLunchInShow = false;
        isLunchOutShow = false;

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

        _isAllButtonsVisible = true; // now conditionally rendered
      } else if (data['error'] == 'No face detected') {
        _status = DetectionStatus.noFace;
      } else if (data['error'] == 'No match found') {
        _status = DetectionStatus.noRecog;
      } else {
        _status = DetectionStatus.fail;
      }

      _isDetected = _status == DetectionStatus.success;
      _isScanButtonClicked = false;
      _isScanButtonVisible = !_isDetected;

      _showLoadingGif = false;
    });
  }

  Future<void> _sendAttendance(String label) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/posttoattendance'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'qr': _empId, // Employee ID from the recognition response
              'status': label, // Attendance status (e.g., Sign-in, Sign-out)
              'embedding': base64Encode(
                _newEmbeddingBytes!,
              ), // Newly calculated embedding from /processfaceattendance
            }),
            // body: jsonEncode({'qr': _empId, 'status': label}),
          )
          .timeout(const Duration(seconds: 5));

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
      } else if (response.statusCode == 409) {
        // Handle conflict gracefully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance already marked for today')),
        );
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in _sendAttendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _refreshScreen() async {
    _hasTimedOut = false;
    _timeoutTimer?.cancel();
    _isRefreshing = true;
    _requestToken++;
    if (!mounted) return;

    setState(() {
      _isDetected = false;
      _isScanButtonClicked = false;
      _isScanButtonVisible = true;
      _isAllButtonsVisible = false;
      _status = null;
      _name = "";
      _empId = "";
      isSignInShow = false;
      isSignOutShow = false;
      isLunchInShow = false;
      isLunchOutShow = false;
      _showLoadingGif = false;
    });

    try {
      final oldController = _controller;
      _controller = null;
      await oldController?.dispose();
      await _initializeCamera(); // Wait for reinitialization to complete
    } catch (e) {
      debugPrint("Camera reinitialization failed: $e");
    }
    _isRefreshing = false;
    if (mounted) setState(() {});
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const LoginPage112(),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (_isInitializing || !_isBackendReady) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Initializing Face Recognition System...',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (!mounted || _controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            child: CameraPreview(_controller!),
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
                      _status == DetectionStatus.success
                          ? _name
                          : _getCurrentStatus(),
                      style: TextStyle(
                        fontSize: 24,
                        color: _getCurrentStatusColor(),
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isScanButtonVisible) _buildScanButton(),
                    if (_isAllButtonsVisible) _buildAttendanceButtons(),
                  ],
                ),
              ),
            ),
          ),
          if (_showLoadingGif)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/facescan2.gif', // Put your GIF in assets
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 150,
                    ), // leave space for attendance response
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getCurrentStatus() {
    switch (_status) {
      case DetectionStatus.noFace:
        return "No face detected";
      case DetectionStatus.fail:
        return "No face detected";
      case DetectionStatus.scan:
        return "Scanning...";
      case DetectionStatus.scanCaptured:
        return "Hold...";
      case DetectionStatus.noRecog:
        return "Not recognized";
      default:
        return "Tap 'Scan Now' to start";
    }
  }

  Color _getCurrentStatusColor() {
    switch (_status) {
      case DetectionStatus.noFace:
      case DetectionStatus.noRecog:
        return Colors.orangeAccent;
      case DetectionStatus.fail:
        return Colors.red;
      case DetectionStatus.success:
        return Colors.green;
      case DetectionStatus.scan:
        return Colors.yellow;
      default:
        return Colors.white70;
    }
  }

  void _startTimeout() {
    _hasTimedOut = false;
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && _showLoadingGif) {
        setState(() {
          _hasTimedOut = true;
          _showLoadingGif = false;
          _status = DetectionStatus.fail;
          _isScanButtonVisible = true;
        });
      }
    });
  }

  Widget _buildScanButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0175C2),
        minimumSize: const Size(200, 50),
      ),
      onPressed: () async {
        if (_isScanButtonClicked) return;
        setState(() {
          _status = DetectionStatus.scan;
          _isScanButtonVisible = false;
          _isScanButtonClicked = true;
        });
        final image = await _controller!.takePicture();
        await _controller?.pausePreview();
        setState(() {
          _showLoadingGif = true;
          _status = DetectionStatus.scanCaptured;
        });
        _startTimeout();
        await _sendFaceImage(image);
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

  Widget _buildAttendanceButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (isSignInShow) _buildAttendanceButton("Sign-in", Colors.blue),
        if (isSignOutShow) _buildAttendanceButton("Sign-out", Colors.red),
        if (isLunchInShow) _buildAttendanceButton("Lunch-in", Colors.green),
        if (isLunchOutShow) _buildAttendanceButton("Lunch-out", Colors.orange),
      ],
    );
  }

  Widget _buildAttendanceButton(String label, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(150, 50),
      ),
      onPressed: () => _sendAttendance(label),
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
