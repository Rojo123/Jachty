import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:yacht_rental/confirmation_page.dart";
import "package:webview_flutter/webview_flutter.dart";
import "dart:convert";
import "package:crypto/crypto.dart";
import "package:xml/xml.dart" as xml;
import "package:yacht_rental/db.dart";
import "package:yacht_rental/constants.dart";
import "package:yacht_rental/config.dart";
import "package:yacht_rental/file_handler.dart";
import "package:intl/intl.dart";
import "package:email_validator/email_validator.dart";

class RentalPage extends StatefulWidget {
  final String qrCode;

  const RentalPage({super.key, required this.qrCode});

  @override
  State<RentalPage> createState() => RentalPageState();
}

class RentalPageState extends State<RentalPage> {
  String yachtName = "";
  String yachtNumber = "";
  double yachtPrice = 0.0;
  int rentTime = 1;
  String error = "";
  Widget webviewSlot = Container();
  Widget statusSlot = Container();
  Widget loadingTpay = Container();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  bool validEmail = true;

  void routeToResult(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfirmationPage())
    );
  }

  //Wypozyczenie: ID, JachtID, Start, Koniec

  void createTempFile() async {
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(hours: rentTime));
    final yachtIdQuery = await doQuery("SELECT id FROM wypozyczalnia WHERE qrcode = $yachtNumber");
    final yachtId = yachtIdQuery.first[0];

    await handleFile(true, "$yachtId;${DateFormat("yyyy-MM-dd HH:mm:ss").format(startTime)};${DateFormat("yyyy-MM-dd HH:mm:ss").format(endTime)}");

    //await doQuery("INSERT INTO wypozyczenie(JachtID, Start, Koniec) VALUES('$yachtId', '$startTime', '$endTime')");
  }

  Future<void> sendTpayRequest() async {
    if(!validEmail) return;

    String apiKey = tpayApi;
    String apiUrl = 'https://secure.tpay.com/api/gw/$apiKey/transaction/create';
    String locError = "";
    
    rentTime = int.parse(_timeController.text);

    String tranId = tpayId;
    String tranAmount = (yachtPrice * rentTime).toString();
    String tranCrc = "${DateFormat('yyyy-MM-dd').format(DateTime.now())} ${_nameController.text}";
    String tranCode = tpayCode;
    String tranMd5sum = md5.convert(utf8.encode('$tranId&$tranAmount&$tranCrc&$tranCode')).toString();

    Map<String, String> headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    Map<String, dynamic> requestBody = {
      'api_password': tpayPass,
      'id': tranId,
      'amount': tranAmount.toString(),
      'description': 'Wynajem jachtu',
      'crc': tranCrc,
      'md5sum': tranMd5sum,
      'group': "150",
      'email': _emailController.text,
      'name': _nameController.text,
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
          
          setState(() {
            loadingTpay = Center(child: Container(width: 90, height: 90, decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [BoxShadow(color: secondaryColor, spreadRadius: 3)],
              borderRadius: BorderRadius.circular(10)
            ),
              child: const SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: secondaryColor,))));
          });

          webviewSlot = WebView(
            initialUrl: transactionUrl,
            javascriptMode: JavascriptMode.unrestricted,
            onPageFinished: (String url) {
              if (url.contains('return')) {
                doQuery("UPDATE wypozyczalnia SET status = 1 WHERE qrcode = $yachtNumber");
                createTempFile();
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

      if(row[2] != 1 && mounted){
        setState(() {
          yachtName = row != null ? row[0] : "Brak danych";
          yachtNumber = row != null ? row[1] : "Brak danych";
          yachtPrice = row != null ? row[3] : "Brak danych";
        });
      } else if(mounted){
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
  }

  @override
  void dispose() {

    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text("Wynajmij jacht")),
      body: Stack(children: [
        SizedBox.expand(child: FittedBox(fit: BoxFit.fill, child: Image.asset("assets/BackgroundBoat.jpg"))),

        Center(child: Container(width: 300, height: 500, decoration: BoxDecoration(
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

            const SizedBox(height: 20),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Ile godzin?"),

              const SizedBox(width: 20),

              SizedBox(width: 50, height: 30, child: TextField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if(value != "" && !value.contains(".")){
                    int valueInt = int.parse(value);
                    if(valueInt < 1){
                      error = "Niepoprawny okres czasu";
                    }
                  } else {
                    error = "Niepoprawny okres czasu";
                  }
                },
                maxLines: 1,
                decoration: const InputDecoration(
                  iconColor: primaryColor,
                  border: OutlineInputBorder(),
                ),
              )),
            ],),

            const SizedBox(height: 20),

            const Text("Twoje imię i nazwisko:"),

            const SizedBox(height: 10),

            SizedBox(width: 280, height: 30, child: TextField(
              controller: _nameController,
              maxLines: 1,
              decoration: const InputDecoration(
                iconColor: primaryColor,
                border: OutlineInputBorder(),
              ),
            )),

            const SizedBox(height: 10),

            const Text("Twój email:"),

            const SizedBox(height: 10),

            SizedBox(width: 280, height: 30, child: TextField(
              controller: _emailController,
              onChanged: (value) {
                if(!EmailValidator.validate(value)){
                  validEmail = false;
                  setState(() {
                    error = "Niepoprawny email";
                  });

                } else if(EmailValidator.validate(value)){
                  validEmail = true;
                  setState(() {
                    error = "";
                  });
                }
              },
              maxLines: 1,
              decoration: const InputDecoration(
                iconColor: primaryColor,
                border: OutlineInputBorder(),
              ),
            )),

            const SizedBox(height: 20),

            ElevatedButton(child: const Text("Wynajmij"), onPressed: (){sendTpayRequest();}),

            const SizedBox(height: 10),

            Text(error)
        ]))),

        if(statusSlot != Container()) statusSlot,

        if(loadingTpay != Container()) loadingTpay,

        if(webviewSlot != Container())webviewSlot,
      ])
    );
  }
}