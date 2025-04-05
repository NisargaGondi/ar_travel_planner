import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ARScreen(),
    );
  }
}

class ARScreen extends StatefulWidget {
  @override
  _ARScreenState createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool isCameraOpen = false;
  late ObjectDetector objectDetector;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeObjectDetector();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    _initializeControllerFuture = _cameraController.initialize();
  }

  void _initializeObjectDetector() {
    objectDetector = GoogleMlKit.vision.objectDetector(
      options: ObjectDetectorOptions(classifyObjects: true),
    );
  }

  void _toggleCamera() {
    setState(() {
      isCameraOpen = !isCameraOpen;
    });

    if (isCameraOpen) {
      _detectObject();
    }
  }

  Future<void> _detectObject() async {
    try {
      await _initializeControllerFuture;
      final picture = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);

      final detectedObjects = await objectDetector.processImage(inputImage);
      for (var obj in detectedObjects) {
        if (obj.labels.isNotEmpty) {
          String detectedLabel = obj.labels.first.text;
          print("Detected: $detectedLabel");

          if (detectedLabel.toLowerCase() == "cup") {
            _showHotelInfo();
          }
        }
      }
    } catch (e) {
      print("Error detecting object: $e");
    }
  }

  void _showHotelInfo() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Grand Palace Hotel",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return const Icon(Icons.star, color: Colors.amber, size: 20);
                }),
              ),
              const SizedBox(height: 10),
              const Text(
                "⭐ 4.7 (2,315 reviews)",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 10),
              const Text(
                "💰 Avg. Cost: \$120 per night",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                "🏨 Luxurious rooms with a city view, spa, and fine dining.",
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AR Travel Guide")),
      body: Stack(
        children: [
          isCameraOpen
              ? FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_cameraController);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          )
              : const Center(child: Text("Click the button to open the camera")),
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              onPressed: _toggleCamera,
              child: Icon(isCameraOpen ? Icons.close : Icons.camera),
            ),
          ),
        ],
      ),
    );
  }
}
