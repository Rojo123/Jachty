import "package:flutter/material.dart";
import "package:qr_code_scanner/qr_code_scanner.dart";
import "package:yacht_rental/constants.dart";
import "package:yacht_rental/rental_page.dart";
import "package:yacht_rental/issue_page.dart";

class ScanPage extends StatefulWidget {
  final String mode;

  const ScanPage({super.key, required this.mode});

  @override
  State<ScanPage> createState() => ScanPageState();
}

class ScanPageState extends State<ScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: "QR");
  QRViewController? controller;
  String result = "";
  bool routed = false;

  @override
  void dispose(){
  controller?.dispose();
  super.dispose();
  }

  void onQRViewCreated(QRViewController controller){
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData.code!;
      });

      if(!routed){
        if(result.isNotEmpty){
          if(widget.mode == "rent"){
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RentalPage(qrCode: result))
            );
          } else if(widget.mode == "issue"){
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => IssuePage(qrCode: result))
            );
          }
        }
        routed = true;
      } else {
        if(Navigator.canPop(context)){
          routed = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context){
    var scanArea = (MediaQuery.of(context).size.width < 400) || (MediaQuery.of(context).size.height < 400) ? 150.0 : 300.0;
    return Scaffold(
      appBar: AppBar(title: const Text("Skanowanie"),),
      body:
        QRView(
          key: qrKey,
          onQRViewCreated: onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: secondaryColor,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: scanArea)
        )
    );
  }
}