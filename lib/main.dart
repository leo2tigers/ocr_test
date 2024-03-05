import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Text Recognition',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(title: 'Flutter Demo Home Page'),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});
  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool isFilePermissionGranted = false;

  late final Future<void> _future;

  CameraController? cameraController;
  File? file;
  String? filename;
  String extractedText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _future = requestFilePermission();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: _future, builder: (context, snapshot) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Text recognition example'),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0),
            child: isFilePermissionGranted ?
            Column(
              children: [ 
                Column(
                  children: [
                    ElevatedButton(onPressed: () async {await pickFile();}, child: const Text('Select file')),
                    Text(filename ?? 'No file selected yet'),
                    ElevatedButton(onPressed: () async {await extractTextFromFile();}, child: const Text('Extract Text'))
                  ],
                ),
                Column(
                  children: [
                    Text(extractedText)
                  ],
                )
              ],
            )
            :
            const Text('Permission to files denied'),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Control camera selection flow
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      //type: FileType.image
    );
    if (result != null) {
      setState(() {
        file = File(result.files.single.path!);
        filename = result.files.single.name;
      });
    }
  }

  Future<void> extractTextFromFile() async {
    if (file == null) {
      showDialog(context: context, builder: (context) {
        return const AlertDialog(title: Text('No file selected'),);
      });
      return;
    }
    String extractedTextTmp = await FlutterTesseractOcr.extractText(file!.path, language: 'tha+eng',
      args: {
        "psm": "1",
      });
    setState(() {extractedText = extractedTextTmp;});
  }

  Future<void> requestFilePermission() async {
    PermissionStatus status = await Permission.photos.request();
    if (status != PermissionStatus.granted) {
      status = await Permission.storage.request();
    }
    isFilePermissionGranted = status == PermissionStatus.granted;
  }

  void initCameraController(List<CameraDescription> cameras) {
    if (cameraController != null) {
      return;
    }

    CameraDescription? camera;
    for (var i = 0; i < cameras.length; i++) {
      final CameraDescription current = cameras[i];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }

    if (camera != null) {
      cameraSelected(camera);
    }
  }

  Future<void> cameraSelected(CameraDescription camera) async {
    cameraController = CameraController(camera, ResolutionPreset.max, enableAudio: false);

    await cameraController?.initialize();

    if(!mounted) {
      return;
    }

    setState(() {
      
    });
  }

  void startCamera() {
    if (cameraController != null) {
      cameraSelected(cameraController!.description);
    }
  }

  void stopCamera() {
    if (cameraController != null) {
      cameraController?.dispose();
    }
  }
}
