import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:yacht_rental/confirmation_page.dart';
import 'package:yacht_rental/config.dart';


class SendPicturePage extends StatefulWidget {
  final File picture;

  const SendPicturePage({super.key, required this.picture});

  @override
  State<SendPicturePage> createState() => SendPicturePageState();
}

class SendPicturePageState extends State<SendPicturePage> {
    void routeToResult(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfirmationPage())
    );
  }

  Future<void> _uploadImage() async {
    try {
      final ftp = FTPConnect(ftpHost, user: ftpUser, pass: ftpPass);

      await ftp.connect();

      final fileName = widget.picture.path.split('/').last;
      await ftp.uploadFile(
        widget.picture,
        sRemoteName: fileName,
      );

      await ftp.disconnect();

      routeToResult();
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text("Przesyłanie"),),
      body: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Image.file(widget.picture),

        ElevatedButton(onPressed: () {_uploadImage();}, child: const Text("Prześlij")),
      ],)
    );
  }
}