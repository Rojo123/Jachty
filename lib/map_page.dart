import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:yacht_rental/constants.dart';
import 'package:yacht_rental/db.dart';
import 'package:yacht_rental/scan_page.dart';
import 'package:yacht_rental/file_handler.dart';
import 'package:yacht_rental/camera.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  bool loaded = false;
  late bool displayRentInfo;
  List<dynamic> boatData = [];
  List<Marker> markers = [];
  Widget rentInfo = Container();
  List readResult = [];
  DateTime endTime = DateTime(0);
  String timeLeft = "";

  final Completer<GoogleMapController> _controller = Completer();

  LocationData? currentLocation;

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  void onPagePopped(){
    updateData();
  }

  void getMarkers() async{
    var results = await doQuery("SELECT id, gps FROM wypozyczalnia WHERE status = 0");

    for(var row in results){
      var gps = row[1].split(", ");
      
      boatData.add([LatLng(double.parse(gps[0]), double.parse(gps[1])), row[0]]);
    }

    for(var marker in boatData){
      markers.add(Marker(
        markerId: MarkerId("Boat${marker[1].toString()}}"),
        icon: sourceIcon,
        position: marker[0]
      ));
    }
  }

  void getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if(!serviceEnabled){
      serviceEnabled = await location.requestService();
      if(!serviceEnabled){
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if(permissionGranted == PermissionStatus.denied){
      permissionGranted = await location.requestPermission();
      if(permissionGranted != PermissionStatus.granted){
        return;
      }
    }

    if(serviceEnabled || permissionGranted == PermissionStatus.granted){
      location.getLocation().then(
        (location) {
          currentLocation = location;
          setState(() {
            loaded = true;
          });
        },
      );

      location.onLocationChanged.listen((LocationData currentLocation) {
        location.getLocation().then(
          (location) {
            setState(() {
              currentLocation = location;
            });
          },
        );
      });
    }
  }

  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/Pin_source.png")
        .then(
          (icon) {
        sourceIcon = icon;
      },
    );
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/Pin_current_location.png")
        .then(
          (icon) {
        currentLocationIcon = icon;
      },
    );
  }

  void endRental() async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraPage()));

    await handleFile(true, "");
    displayRentInfo = false;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }

  @override
  void initState() {
    super.initState();
    setCustomMarkerIcon();
    updateData();
  }

  void updateData() async {
    List readResultLoc = [];

    getCurrentLocation();
    getMarkers();
    await Future.delayed(const Duration(seconds: 5));
    markers.add(Marker(
      markerId: const MarkerId("currentLocation"),
      icon: currentLocationIcon,
      position: currentLocation != null ? LatLng(
      currentLocation!.latitude!, currentLocation!.longitude!) : const LatLng(53.854647, 22.986731),
    ));

    readResultLoc = await handleFile(false);
    if(mounted) {setState(() {
      readResult = readResultLoc;
      endTime = readResult[2] != "0" ? DateTime.parse(readResult[2]) : DateTime(0);
      displayRentInfo = DateTime.now().isBefore(endTime) ? true : false;

      timeLeft = formatDuration(endTime.difference(DateTime.now()));

      if(displayRentInfo){
        rentInfo = Center(child: Container(width: 300, height: 300, decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [BoxShadow(color: secondaryColor, spreadRadius: 3)],
            borderRadius: BorderRadius.circular(10)
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Czas rozpoczęcia: ${readResult[1]}"),

              const SizedBox(height: 5),

              Text("Czas zakończenia: ${readResult[2]}"),

              const SizedBox(height: 5),

              Text("Pozostały czas: $timeLeft"),

              const SizedBox(height: 20),

              ElevatedButton(onPressed: (){endRental();}, child: const Text("ZAKOŃCZ")),
            ]),
          ));
      }
    });}

    // Timer.periodic(const Duration(seconds: 1), (Timer timer) {
    //   setState(() {
    //     timeLeft = formatDuration(endTime.difference(DateTime.now()));
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa",),),
      body:loaded == false
          ? const Center(child:
          Column(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, children: [
              CircularProgressIndicator(color: secondaryColor),
              Text("Usługi lokalizacyjne mogą być wyłączone")
            ]
          ))
          :  Stack(alignment: Alignment.center, children: [
            GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  currentLocation!.latitude!, currentLocation!.longitude!),
              zoom: 13.5,
            ),
            markers: Set<Marker>.of(markers),
            onMapCreated: (mapController) {
              _controller.complete(mapController);
            },
        ),

        Positioned(bottom: 50, child: Row(children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0x00000000)
          ),

          const SizedBox(width: 30),

          ElevatedButton(child: const Text("SKANUJ"),
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanPage(mode: "rent"))
            );
          }),
          

          const SizedBox(width: 30),

          CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor,
            child: IconButton(icon: const Icon(CupertinoIcons.wrench_fill, color: Colors.white), onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanPage(mode: "issue"))
              );
            }))
        ])),

        if(rentInfo != Container()) rentInfo,
      ])
    );
  }
}
