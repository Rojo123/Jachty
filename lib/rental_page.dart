import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import "package:yacht_rental/confirmation_page.dart";
import "package:webview_flutter/webview_flutter.dart";
import "dart:convert";
import "package:crypto/crypto.dart";
import "package:xml/xml.dart" as xml;
import "package:provider/provider.dart";
import "package:yacht_rental/db.dart";
import "package:yacht_rental/constants.dart";
import "package:yacht_rental/main.dart";

class RentalPage extends StatefulWidget {
  final String qrCode;

  const RentalPage({required this.qrCode});

  @override
  State<RentalPage> createState() => RentalPageState();
}

class RentalPageState extends State<RentalPage> {
  String yachtName = "";
  String yachtNumber = "";
  double yachtPrice = 0.00;
  String error = "";
  Widget webviewSlot = Container();
  Widget statusSlot = Container();
  late IsolateStateNotifier isolateState;

  void routeToResult(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfirmationPage())
    );
  }

  Future<void> sendTpayRequest() async {
    String apiKey = '0c5deb570f21b7c037006be6c142740012c0f688';
    String apiUrl = 'https://secure.tpay.com/api/gw/$apiKey/transaction/create';
    String locError = "";

    String tranId = "27782";
    String tranAmount = yachtPrice.toString();
    String tranCrc = "test";
    String tranCode = "6Ls6ZQY83zRyrBtD";
    String tranMd5sum = md5.convert(utf8.encode('$tranId&$tranAmount&$tranCrc&$tranCode')).toString();

    Map<String, String> headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    Map<String, dynamic> requestBody = {
      'api_password': "Praktyki23",
      'id': tranId,
      'amount': tranAmount.toString(),
      'description': 'Opis transakcji',
      'crc': tranCrc,
      'md5sum': tranMd5sum,
      'group': "150",
      'email': "asddasd@wp.pl",
      'name': "John",
    };

    try {
      final response = await http.post(Uri.parse(apiUrl), headers: headers, body: requestBody);

      if (response.statusCode == 200) {

        var document = xml.XmlDocument.parse(response.body);
        var responseParsed = document.findElements("response").first;
        var resultElement = responseParsed.findElements("result").first.innerText;
        
        if(resultElement == "1"){
          var urlElement = responseParsed.findElements("url").first;

          String transactionUrl = urlElement.innerText;
          
          webviewSlot = WebView(
            initialUrl: transactionUrl,
            javascriptMode: JavascriptMode.unrestricted,
            onPageFinished: (String url) {
              if (url.contains('return')) {
                doQuery("UPDATE wypozyczalnia SET status = 1 WHERE qrcode = $yachtNumber");
                isolateState.startIsolate();
                routeToResult();
              }
            }
          );
        }

      } else {
        locError = 'Błąd podczas komunikacji z tpay. Kod błędu: ${response.statusCode}';
      }
    } catch (e) {
      locError = 'Błąd sieci: $e';
    }

    setState(() {
      error = locError;
    });
  }

  Future<void> getYachtInfo() async{
    String qrCode = widget.qrCode;
    var result = await doQuery("SELECT jacht, qrcode, status, cena FROM wypozyczalnia WHERE qrcode = $qrCode");
    
    if(result.isNotEmpty){
      var row = result.first;

      if(row[2] != 1){
        setState(() {
          yachtName = row != null ? row[0] : "Brak danych";
          yachtNumber = row != null ? row[1] : "Brak danych";
          yachtPrice = row != null ? row[3] : "Brak danych";
        });
      } else {
        setState(() {
          statusSlot = Center(child: Container(width: 300, height: 300, decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [BoxShadow(color: secondaryColor, spreadRadius: 3)],
            borderRadius: BorderRadius.circular(10)
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Wybrany jacht jest już zarezerwowany"),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: (){
              Navigator.of(context).popUntil((route) => route.isFirst);
            }, child: const Text("Wróć do mapy"))
          ])));
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getYachtInfo();
    Future.delayed(Duration.zero, (){
      isolateState = Provider.of<IsolateStateNotifier>(context, listen: false);
    });
    
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text("Wynajmij jacht")),
      body: Stack(children: [
        SizedBox.expand(child: FittedBox(fit: BoxFit.fill, child: Image.asset("assets/BackgroundBoat.jpg"))),

        Center(child: Container(width: 300, height: 300, decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [BoxShadow(color: secondaryColor, spreadRadius: 3)],
          borderRadius: BorderRadius.circular(10)
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 10),

            Text("Model: $yachtName"),

            const SizedBox(height: 10),

            Text("Numer: $yachtNumber"),

            const SizedBox(height: 10),

            Text("Cena: $yachtPrice\u{00A0}zł/h"),

            const SizedBox(height: 40),

            ElevatedButton(child: const Text("Wynajmij"), onPressed: (){sendTpayRequest();}),

            const SizedBox(height: 10),

            Text(error)
        ]))),

        if(webviewSlot != Container())webviewSlot,

        if(statusSlot != Container()) statusSlot
      ])
    );
  }
}