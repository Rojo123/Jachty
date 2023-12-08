import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:yacht_rental/constants.dart';
import 'package:yacht_rental/send_picture.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late XFile? _imageFile;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      const CameraDescription(
        name: '0',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
      
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void goToSend(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SendPicturePage(picture: File(_imageFile!.path)))
    );
  }

  void _takePicture() async {
    try {
      await _initializeControllerFuture;

      final XFile file = await _controller.takePicture();

      setState(() {
        _imageFile = file;
      });

      goToSend();

    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: CameraPreview(_controller),
                ),
                ElevatedButton(
                  onPressed: _takePicture,
                  child: const Text('Zrób zdjęcie'),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator(color: secondaryColor));
          }
        },
      ),
    );
  }
}